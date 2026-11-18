report 50201 "Santoki Master Bill of Lading"
{
    // Master bill of lading for a consolidated carrier pickup: one row per posted shipment (its own BOL), with totals.
    // Layout follows Geary's master BOL template (Oct 28th 2026).
    // Select the shipments on Posted Sales Shipments and choose Print Master BOL, or filter them on the request page.
    Caption = 'Master Bill of Lading';
    UsageCategory = Documents;
    ApplicationArea = All;
    DefaultRenderingLayout = MasterBOLWord;

    dataset
    {
        dataitem(Shipment; "Sales Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Posting Date", "Location Code", "Shipping Agent Code";
            RequestFilterHeading = 'Posted Sales Shipments';

            // Master-level values: the same on every row; the layout reads them from the first row.
            column(MasterBOLNumber; MasterBOLNumberTxt)
            {
            }
            column(PickupDate; PickupDateTxt)
            {
            }
            column(CarrierName; CarrierName)
            {
            }
            column(CarrierSCAC; CarrierSCAC)
            {
            }
            column(ProNumber; ProNo)
            {
            }
            column(TrailerNumber; TrailerNo)
            {
            }
            column(SealNumber; SealNo)
            {
            }
            column(ShipFromName; ShipFromName)
            {
            }
            column(ShipFromContact; ShipFromContact)
            {
            }
            column(ShipFromAddress; ShipFromAddress)
            {
            }
            column(ShipFromCityStateZip; ShipFromCityStateZip)
            {
            }
            column(NumberOfBOLs; Format(ShipmentCount))
            {
            }
            column(TotalPallets; TotalPalletsTxt)
            {
            }
            column(TotalCartons; BOLBuilder.FormatWhole(MasterCartons))
            {
            }
            column(TotalWeight; BOLBuilder.FormatWhole(MasterWeight))
            {
            }
            column(FreightTerms; FreightTermsTxt)
            {
            }
            column(Notes; Notes)
            {
            }
            // Row values.
            column(ChildBOLNumber; Shipment."No.")
            {
            }
            column(Consignee; ConsigneeTxt)
            {
            }
            column(PONumber; Shipment."External Document No.")
            {
            }
            column(RowPallets; '')
            {
            }
            column(RowCartons; RowCartonsTxt)
            {
            }
            column(RowWeight; RowWeightTxt)
            {
            }

            trigger OnPreDataItem()
            begin
                CalcMasterTotals();
            end;

            trigger OnAfterGetRecord()
            var
                RowCartons: Decimal;
                RowWeight: Decimal;
                LineCount: Integer;
                MissingData: Boolean;
            begin
                BOLBuilder.BuildFreightLines(Shipment."No.", TempFreightLine);
                BOLBuilder.SumFreightLines(TempFreightLine, RowCartons, RowWeight, LineCount, MissingData);
                RowCartonsTxt := BOLBuilder.FormatWhole(RowCartons);
                RowWeightTxt := BOLBuilder.FormatWhole(RowWeight);
                ConsigneeTxt := BOLBuilder.JoinText(Shipment."Ship-to Name",
                    BOLBuilder.FormatCityStateZip(Shipment."Ship-to City", Shipment."Ship-to County", ''), ' - ');
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(Content)
            {
                group(Pickup)
                {
                    Caption = 'Pickup';

                    field(MasterBOLNoField; MasterBOLNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Master BOL Number';
                        ToolTip = 'Specifies the master BOL number. Leave it blank to use MBOL- followed by the first shipment number.';
                    }
                    field(PickupDateField; PickupDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Pickup Date';
                        ToolTip = 'Specifies the pickup date. Leave it blank to use today''s date.';
                    }
                    field(ShippingAgentField; ShippingAgentCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Carrier (Shipping Agent)';
                        TableRelation = "Shipping Agent";
                        ToolTip = 'Specifies the carrier picking up. Leave it blank to use the first shipment''s shipping agent.';
                    }
                    field(ProNoField; ProNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Carrier PRO / Tracking';
                        ToolTip = 'Specifies the carrier PRO number for the consolidated load.';
                    }
                    field(TrailerNoField; TrailerNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Trailer Number';
                        ToolTip = 'Specifies the trailer number to print.';
                    }
                    field(SealNoField; SealNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Seal Number';
                        ToolTip = 'Specifies the seal number to print.';
                    }
                    field(TotalPalletsField; TotalPallets)
                    {
                        ApplicationArea = All;
                        Caption = 'Total Pallets';
                        MinValue = 0;
                        ToolTip = 'Specifies the total number of pallets on the load.';
                    }
                }
                group(Freight)
                {
                    Caption = 'Freight and Notes';

                    field(FreightTermsField; FreightTerms)
                    {
                        ApplicationArea = All;
                        Caption = 'Freight Terms';
                        ToolTip = 'Specifies who pays the freight: prepaid by Santoki, collect from the consignee, or a third party.';
                    }
                    field(NotesField; Notes)
                    {
                        ApplicationArea = All;
                        Caption = 'Additional BOLs / Manifest Reference / Notes';
                        MultiLine = true;
                        ToolTip = 'Specifies notes to print, such as a manifest reference or BOLs not listed.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(MasterBOLWord)
        {
            Type = Word;
            LayoutFile = './src/BOL/Layouts/SantokiMasterBOL.docx';
            Caption = 'Master Bill of Lading (Word)';
            Summary = 'Master bill of lading listing each underlying shipment, in the layout of Geary''s template.';
        }
    }

    var
        TempFreightLine: Record "Santoki BOL Freight Line" temporary;
        BOLBuilder: Codeunit "Santoki BOL Builder";
        FreightTerms: Enum "Santoki BOL Freight Terms";
        MasterBOLNo: Text[30];
        PickupDate: Date;
        ShippingAgentCode: Code[10];
        ProNo: Text[50];
        TrailerNo: Text[30];
        SealNo: Text[30];
        TotalPallets: Integer;
        Notes: Text[250];
        ShipmentCount: Integer;
        MasterCartons: Decimal;
        MasterWeight: Decimal;
        MasterBOLNumberTxt: Text;
        PickupDateTxt: Text;
        CarrierName: Text;
        CarrierSCAC: Text;
        ShipFromName: Text;
        ShipFromContact: Text;
        ShipFromAddress: Text;
        ShipFromCityStateZip: Text;
        TotalPalletsTxt: Text;
        FreightTermsTxt: Text;
        ConsigneeTxt: Text;
        RowCartonsTxt: Text;
        RowWeightTxt: Text;
        MasterPrefixTxt: Label 'MBOL-%1', Comment = '%1 = first shipment number';

    local procedure CalcMasterTotals()
    var
        ShipHdr: Record "Sales Shipment Header";
        RowCartons: Decimal;
        RowWeight: Decimal;
        LineCount: Integer;
        MissingData: Boolean;
        FirstShipment: Boolean;
        FirstAgent: Code[10];
        FirstLocation: Code[10];
    begin
        ShipmentCount := 0;
        MasterCartons := 0;
        MasterWeight := 0;
        FirstShipment := true;
        ShipHdr.CopyFilters(Shipment);
        ShipHdr.SetCurrentKey("No.");
        if ShipHdr.FindSet() then
            repeat
                if FirstShipment then begin
                    FirstShipment := false;
                    if MasterBOLNo = '' then
                        MasterBOLNumberTxt := StrSubstNo(MasterPrefixTxt, ShipHdr."No.");
                    FirstAgent := ShipHdr."Shipping Agent Code";
                    FirstLocation := ShipHdr."Location Code";
                end;
                ShipmentCount += 1;
                BOLBuilder.BuildFreightLines(ShipHdr."No.", TempFreightLine);
                BOLBuilder.SumFreightLines(TempFreightLine, RowCartons, RowWeight, LineCount, MissingData);
                MasterCartons += RowCartons;
                MasterWeight += RowWeight;
            until ShipHdr.Next() = 0;

        if MasterBOLNo <> '' then
            MasterBOLNumberTxt := MasterBOLNo;
        if ShippingAgentCode <> '' then
            FirstAgent := ShippingAgentCode;
        BOLBuilder.GetCarrier(FirstAgent, CarrierName, CarrierSCAC);
        BOLBuilder.GetShipFrom(FirstLocation, ShipFromName, ShipFromContact, ShipFromAddress, ShipFromCityStateZip);
        if PickupDate = 0D then
            PickupDateTxt := BOLBuilder.FormatDate(Today())
        else
            PickupDateTxt := BOLBuilder.FormatDate(PickupDate);
        TotalPalletsTxt := '';
        if TotalPallets > 0 then
            TotalPalletsTxt := Format(TotalPallets);
        FreightTermsTxt := BOLBuilder.FreightTermsText(FreightTerms);
    end;
}
