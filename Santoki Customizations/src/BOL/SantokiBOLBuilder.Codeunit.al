codeunit 50209 "Santoki BOL Builder"
{
    // Shared logic for the bill of lading reports (50200 single, 50201 master).
    //
    // Freight detail: posted shipment item lines are grouped by NMFC No. + Freight Class (item first, then its item
    // category and parent categories).
    // Cartons: the item's MASTER unit of measure is the shipping carton (INNER if there is no MASTER). Each line gives
    // its full cartons plus a share of a carton for the loose units (loose qty / carton qty). Within a commodity group
    // the shares are added up and rounded up, so small quantities of several items count as the cartons they would
    // fill together, not one carton per line. This is an estimate: eShip's actual carton count sits in TrueCommerce's
    // package tables, and the request page lets the warehouse type the real total.
    // Weight (lb): full cartons at the carton weight, loose units at the base unit weight (Item Unit of Measure).
    // Lines without carton or weight data fall back to one carton per base unit and the shipment line's gross weight,
    // and the group is marked "Missing Data".

    var
        DefaultCommodityTxt: Label 'Merchandise';
        PrepaidTxt: Label 'PPD (Prepaid)';
        CollectTxt: Label 'COLL (Collect)';
        ThirdPartyTxt: Label '3P (Third Party)';
        NMFCPrefixTxt: Label 'NMFC %1', Comment = '%1 = NMFC item number';
        ClassPrefixTxt: Label 'Class %1', Comment = '%1 = freight class';
        MasterUoMTok: Label 'MASTER', Locked = true;
        InnerUoMTok: Label 'INNER', Locked = true;

    procedure BuildFreightLines(ShipmentNo: Code[20]; var FreightLine: Record "Santoki BOL Freight Line" temporary)
    var
        ShipLine: Record "Sales Shipment Line";
        Item: Record Item;
        NMFCNo: Code[20];
        FreightClass: Code[10];
        CategoryDesc: Text;
        FullCartons: Decimal;
        PartShare: Decimal;
        Weight: Decimal;
        Complete: Boolean;
        NextEntryNo: Integer;
    begin
        FreightLine.Reset();
        FreightLine.DeleteAll();
        ShipLine.SetRange("Document No.", ShipmentNo);
        ShipLine.SetRange(Type, ShipLine.Type::Item);
        ShipLine.SetFilter("Quantity (Base)", '>0');
        if not ShipLine.FindSet() then
            exit;
        repeat
            if Item.Get(ShipLine."No.") then begin
                GetFreightCodes(Item, NMFCNo, FreightClass, CategoryDesc);
                Complete := CalcCartonsAndWeight(Item, ShipLine, FullCartons, PartShare, Weight);
                FreightLine.SetCurrentKey("NMFC No.", "Freight Class");
                FreightLine.SetRange("NMFC No.", NMFCNo);
                FreightLine.SetRange("Freight Class", FreightClass);
                if FreightLine.FindFirst() then begin
                    AddDescription(FreightLine, CategoryDesc);
                    FreightLine."Line Count" += 1;
                    FreightLine.Quantity += ShipLine."Quantity (Base)";
                    FreightLine."Full Cartons" += FullCartons;
                    FreightLine."Part Carton Share" += PartShare;
                    FreightLine.Weight += Weight;
                    if not Complete then
                        FreightLine."Missing Data" := true;
                    FreightLine.Modify();
                end else begin
                    NextEntryNo += 1;
                    FreightLine.Init();
                    FreightLine."Entry No." := NextEntryNo;
                    FreightLine."NMFC No." := NMFCNo;
                    FreightLine."Freight Class" := FreightClass;
                    FreightLine.Description := CopyStr(CategoryDesc, 1, MaxStrLen(FreightLine.Description));
                    FreightLine."Line Count" := 1;
                    FreightLine.Quantity := ShipLine."Quantity (Base)";
                    FreightLine."Full Cartons" := FullCartons;
                    FreightLine."Part Carton Share" := PartShare;
                    FreightLine.Weight := Weight;
                    FreightLine."Missing Data" := not Complete;
                    FreightLine.Insert();
                end;
                FreightLine.Reset();
            end;
        until ShipLine.Next() = 0;

        // Loose units in a group share cartons: round the added-up shares, not each line's.
        FreightLine.SetCurrentKey("Entry No.");
        if FreightLine.FindSet() then
            repeat
                FreightLine.Cartons := FreightLine."Full Cartons" + Round(FreightLine."Part Carton Share", 1, '>');
                FreightLine.Modify();
            until FreightLine.Next() = 0;
    end;

    procedure SumFreightLines(var FreightLine: Record "Santoki BOL Freight Line" temporary; var TotalCartons: Decimal; var TotalWeight: Decimal; var LineCount: Integer; var MissingData: Boolean)
    begin
        TotalCartons := 0;
        TotalWeight := 0;
        LineCount := 0;
        MissingData := false;
        if FreightLine.FindSet() then
            repeat
                TotalCartons += FreightLine.Cartons;
                TotalWeight += FreightLine.Weight;
                LineCount += 1;
                if FreightLine."Missing Data" then
                    MissingData := true;
            until FreightLine.Next() = 0;
    end;

    procedure GetFreightCodes(Item: Record Item; var NMFCNo: Code[20]; var FreightClass: Code[10]; var CategoryDesc: Text)
    var
        ItemCategory: Record "Item Category";
        CategoryCode: Code[20];
        Depth: Integer;
    begin
        NMFCNo := Item."Santoki NMFC No.";
        FreightClass := Item."Santoki Freight Class";
        CategoryDesc := '';
        CategoryCode := Item."Item Category Code";
        Depth := 0;
        while (CategoryCode <> '') and (Depth < 10) do begin
            Depth += 1;
            if not ItemCategory.Get(CategoryCode) then
                break;
            if CategoryDesc = '' then
                CategoryDesc := ItemCategory.Description;
            if NMFCNo = '' then
                NMFCNo := ItemCategory."Santoki NMFC No.";
            if FreightClass = '' then
                FreightClass := ItemCategory."Santoki Freight Class";
            if (NMFCNo <> '') and (FreightClass <> '') then
                break;
            CategoryCode := ItemCategory."Parent Category";
        end;
        if CategoryDesc = '' then
            CategoryDesc := DefaultCommodityTxt;
    end;

    procedure CalcCartonsAndWeight(Item: Record Item; ShipLine: Record "Sales Shipment Line"; var FullCartons: Decimal; var PartShare: Decimal; var Weight: Decimal): Boolean
    var
        CartonUoM: Record "Item Unit of Measure";
        BaseUoM: Record "Item Unit of Measure";
        QtyBase: Decimal;
        Remainder: Decimal;
        EachWeight: Decimal;
        CartonWeight: Decimal;
        Complete: Boolean;
    begin
        FullCartons := 0;
        PartShare := 0;
        Weight := 0;
        QtyBase := ShipLine."Quantity (Base)";
        if BaseUoM.Get(Item."No.", Item."Base Unit of Measure") then
            EachWeight := BaseUoM.Weight;
        if EachWeight = 0 then
            EachWeight := Item."Gross Weight";

        if FindCartonUoM(Item."No.", CartonUoM) then begin
            FullCartons := Round(QtyBase / CartonUoM."Qty. per Unit of Measure", 1, '<');
            Remainder := QtyBase - FullCartons * CartonUoM."Qty. per Unit of Measure";
            if Remainder > 0 then
                PartShare := Remainder / CartonUoM."Qty. per Unit of Measure";
            CartonWeight := CartonUoM.Weight;
            if CartonWeight = 0 then
                CartonWeight := EachWeight * CartonUoM."Qty. per Unit of Measure";
            Weight := FullCartons * CartonWeight + Remainder * EachWeight;
            Complete := (CartonWeight > 0) and ((Remainder = 0) or (EachWeight > 0));
        end else begin
            FullCartons := Round(QtyBase, 1, '>');
            Weight := QtyBase * EachWeight;
            Complete := false;
        end;

        if Weight = 0 then begin
            Weight := ShipLine.Quantity * ShipLine."Gross Weight";
            Complete := false;
        end;
        exit(Complete);
    end;

    procedure FindCartonUoM(ItemNo: Code[20]; var CartonUoM: Record "Item Unit of Measure"): Boolean
    begin
        // MASTER is the shipping carton, including case-pack items whose MASTER holds 1.
        if CartonUoM.Get(ItemNo, MasterUoMTok) then
            if CartonUoM."Qty. per Unit of Measure" >= 1 then
                exit(true);
        if CartonUoM.Get(ItemNo, InnerUoMTok) then
            if CartonUoM."Qty. per Unit of Measure" > 1 then
                exit(true);
        Clear(CartonUoM);
        exit(false);
    end;

    procedure GetShipFrom(LocationCode: Code[10]; var Name: Text; var Contact: Text; var Address: Text; var CityStateZip: Text)
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        if LocationCode <> '' then
            if Location.Get(LocationCode) then begin
                Name := Location.Name;
                Contact := JoinText(Location.Contact, Location."Phone No.", ' / ');
                Address := JoinText(Location.Address, Location."Address 2", ', ');
                CityStateZip := FormatCityStateZip(Location.City, Location.County, Location."Post Code");
                exit;
            end;
        CompanyInfo.Get();
        Name := CompanyInfo.Name;
        Contact := CompanyInfo."Phone No.";
        Address := JoinText(CompanyInfo.Address, CompanyInfo."Address 2", ', ');
        CityStateZip := FormatCityStateZip(CompanyInfo.City, CompanyInfo.County, CompanyInfo."Post Code");
    end;

    procedure GetCarrier(ShippingAgentCode: Code[10]; var CarrierName: Text; var CarrierSCAC: Text)
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        CarrierName := ShippingAgentCode;
        CarrierSCAC := '';
        if ShippingAgentCode = '' then
            exit;
        if ShippingAgent.Get(ShippingAgentCode) then begin
            if ShippingAgent.Name <> '' then
                CarrierName := ShippingAgent.Name;
            CarrierSCAC := ShippingAgent."Santoki SCAC";
        end;
    end;

    procedure FreightTermsText(Terms: Enum "Santoki BOL Freight Terms"): Text
    begin
        case Terms of
            Terms::Prepaid:
                exit(PrepaidTxt);
            Terms::Collect:
                exit(CollectTxt);
            Terms::"Third Party":
                exit(ThirdPartyTxt);
        end;
    end;

    procedure BillToPartyText(Terms: Enum "Santoki BOL Freight Terms"; ConsigneeName: Text; ThirdPartyBillTo: Text): Text
    var
        CompanyInfo: Record "Company Information";
    begin
        case Terms of
            Terms::Prepaid:
                begin
                    CompanyInfo.Get();
                    exit(JoinText(CompanyInfo.Name, FormatCityStateZip(CompanyInfo.City, CompanyInfo.County, ''), ', '));
                end;
            Terms::Collect:
                exit(ConsigneeName);
            Terms::"Third Party":
                exit(ThirdPartyBillTo);
        end;
    end;

    procedure FormatNMFCClass(NMFCNo: Code[20]; FreightClass: Code[10]): Text
    var
        NMFCPart: Text;
        ClassPart: Text;
    begin
        if NMFCNo <> '' then
            NMFCPart := StrSubstNo(NMFCPrefixTxt, NMFCNo);
        if FreightClass <> '' then
            if UpperCase(CopyStr(FreightClass, 1, 5)) = 'CLASS' then
                ClassPart := FreightClass
            else
                ClassPart := StrSubstNo(ClassPrefixTxt, FreightClass);
        exit(JoinText(NMFCPart, ClassPart, ' / '));
    end;

    procedure FormatWhole(Value: Decimal): Text
    begin
        exit(Format(Round(Value, 1)));
    end;

    procedure FormatDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Month,2>/<Day,2>/<Year4>'));
    end;

    procedure JoinText(First: Text; Second: Text; Separator: Text): Text
    begin
        if First = '' then
            exit(Second);
        if Second = '' then
            exit(First);
        exit(First + Separator + Second);
    end;

    procedure FormatCityStateZip(City: Text; State: Text; Zip: Text): Text
    begin
        exit(JoinText(JoinText(City, State, ', '), Zip, ' '));
    end;

    local procedure AddDescription(var FreightLine: Record "Santoki BOL Freight Line" temporary; CategoryDesc: Text)
    begin
        if CategoryDesc = '' then
            exit;
        if StrPos(FreightLine.Description, CategoryDesc) > 0 then
            exit;
        FreightLine.Description := CopyStr(JoinText(FreightLine.Description, CategoryDesc, ', '), 1, MaxStrLen(FreightLine.Description));
    end;
}
