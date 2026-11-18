report 50200 "Santoki Bill of Lading"
{
    // Straight bill of lading (LTL, non-negotiable) printed from posted sales shipments, one page per shipment.
    // Layout follows Geary's standard BOL template (Oct 28th 2026).
    // Trailer, seal, PRO, pallets, freight terms and references are typed on the request page when printing.
    Caption = 'Bill of Lading';
    UsageCategory = Documents;
    ApplicationArea = All;
    DefaultRenderingLayout = BOLWord;
    WordMergeDataItem = Header;

    dataset
    {
        dataitem(Header; "Sales Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "Posting Date";
            RequestFilterHeading = 'Posted Sales Shipment';

            column(BOLNumber; Header."No.")
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
            column(ProNumber; ProNumberTxt)
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
            column(ShipToName; ShipToNameTxt)
            {
            }
            column(ShipToAddress; ShipToAddress)
            {
            }
            column(ShipToCityStateZip; ShipToCityStateZip)
            {
            }
            column(BillToParty; BillToPartyTxt)
            {
            }
            column(PONumber; Header."External Document No.")
            {
            }
            column(RoutingReference; RoutingRef)
            {
            }
            column(AppointmentReference; AppointmentRef)
            {
            }
            column(TotalPallets; TotalPalletsTxt)
            {
            }
            column(TotalCartons; TotalCartonsTxt)
            {
            }
            column(TotalWeight; TotalWeightTxt)
            {
            }
            column(FreightTerms; FreightTermsTxt)
            {
            }
            column(SpecialInstructions; SpecialInstructions)
            {
            }
            dataitem(FreightLine; "Santoki BOL Freight Line")
            {
                DataItemTableView = sorting("Entry No.");
                UseTemporary = true;

                column(Commodity; CommodityTxt)
                {
                }
                column(LinePallets; LinePalletsTxt)
                {
                }
                column(LineCartons; LineCartonsTxt)
                {
                }
                column(LineWeight; LineWeightTxt)
                {
                }
                column(LineNMFCClass; LineNMFCClassTxt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if FreightLine."Line Count" = 1 then
                        CommodityTxt := StrSubstNo(CommodityOneTxtLbl, FreightLine.Description)
                    else
                        CommodityTxt := StrSubstNo(CommodityTxtLbl, FreightLine.Description, FreightLine."Line Count");
                    LinePalletsTxt := '';
                    if (FreightLineCount = 1) and (TotalPallets > 0) then
                        LinePalletsTxt := Format(TotalPallets);
                    LineCartonsTxt := BOLBuilder.FormatWhole(FreightLine.Cartons);
                    if CartonsOverride > 0 then
                        if FreightLineCount = 1 then
                            LineCartonsTxt := Format(CartonsOverride)
                        else
                            LineCartonsTxt := '';
                    LineWeightTxt := BOLBuilder.FormatWhole(FreightLine.Weight);
                    LineNMFCClassTxt := BOLBuilder.FormatNMFCClass(FreightLine."NMFC No.", FreightLine."Freight Class");
                end;
            }

            trigger OnAfterGetRecord()
            var
                TotalCartons: Decimal;
                TotalWeight: Decimal;
                MissingData: Boolean;
            begin
                BOLBuilder.BuildFreightLines(Header."No.", FreightLine);
                BOLBuilder.SumFreightLines(FreightLine, TotalCartons, TotalWeight, FreightLineCount, MissingData);
                TotalCartonsTxt := BOLBuilder.FormatWhole(TotalCartons);
                if CartonsOverride > 0 then
                    TotalCartonsTxt := Format(CartonsOverride);
                TotalWeightTxt := BOLBuilder.FormatWhole(TotalWeight);
                TotalPalletsTxt := '';
                if TotalPallets > 0 then
                    TotalPalletsTxt := Format(TotalPallets);

                BOLBuilder.GetCarrier(Header."Shipping Agent Code", CarrierName, CarrierSCAC);
                ProNumberTxt := ProNo;
                if ProNumberTxt = '' then
                    ProNumberTxt := Header."Package Tracking No.";
                if PickupDate <> 0D then
                    PickupDateTxt := BOLBuilder.FormatDate(PickupDate)
                else
                    PickupDateTxt := BOLBuilder.FormatDate(Header."Shipment Date");

                BOLBuilder.GetShipFrom(Header."Location Code", ShipFromName, ShipFromContact, ShipFromAddress, ShipFromCityStateZip);
                ShipToNameTxt := BOLBuilder.JoinText(Header."Ship-to Name", Header."Ship-to Name 2", ' ');
                ShipToAddress := BOLBuilder.JoinText(Header."Ship-to Address", Header."Ship-to Address 2", ', ');
                ShipToCityStateZip := BOLBuilder.FormatCityStateZip(Header."Ship-to City", Header."Ship-to County", Header."Ship-to Post Code");
                FreightTermsTxt := BOLBuilder.FreightTermsText(FreightTerms);
                BillToPartyTxt := BOLBuilder.BillToPartyText(FreightTerms, ShipToNameTxt, ThirdPartyBillTo);
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

                    field(PickupDateField; PickupDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Pickup Date';
                        ToolTip = 'Specifies the pickup date to print. Leave it blank to use each shipment''s shipment date.';
                    }
                    field(ProNoField; ProNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Carrier PRO / Tracking';
                        ToolTip = 'Specifies the carrier PRO number. Leave it blank to use the shipment''s package tracking number.';
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
                        ToolTip = 'Specifies the number of pallets (handling units). It prints in the totals, and on the freight line when there is only one.';
                    }
                    field(CartonsOverrideField; CartonsOverride)
                    {
                        ApplicationArea = All;
                        Caption = 'Total Cartons (actual)';
                        MinValue = 0;
                        ToolTip = 'Specifies the actual carton count from the warehouse. Leave it at 0 to print the cartons estimated from each item''s master carton quantity.';
                    }
                }
                group(Freight)
                {
                    Caption = 'Freight and References';

                    field(FreightTermsField; FreightTerms)
                    {
                        ApplicationArea = All;
                        Caption = 'Freight Terms';
                        ToolTip = 'Specifies who pays the freight: prepaid by Santoki, collect from the consignee, or a third party.';
                    }
                    field(ThirdPartyBillToField; ThirdPartyBillTo)
                    {
                        ApplicationArea = All;
                        Caption = 'Third-Party Bill-To';
                        ToolTip = 'Specifies the freight payment party when the freight terms are Third Party.';
                    }
                    field(RoutingRefField; RoutingRef)
                    {
                        ApplicationArea = All;
                        Caption = 'Shipment / Routing Reference';
                        ToolTip = 'Specifies the retailer''s routing or load reference.';
                    }
                    field(AppointmentRefField; AppointmentRef)
                    {
                        ApplicationArea = All;
                        Caption = 'Appointment / Delivery Reference';
                        ToolTip = 'Specifies the delivery appointment reference.';
                    }
                    field(SpecialInstructionsField; SpecialInstructions)
                    {
                        ApplicationArea = All;
                        Caption = 'Special Instructions';
                        MultiLine = true;
                        ToolTip = 'Specifies special instructions, accessorials or handling notes to print.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(BOLWord)
        {
            Type = Word;
            LayoutFile = './src/BOL/Layouts/SantokiBillOfLading.docx';
            Caption = 'Bill of Lading (Word)';
            Summary = 'Straight bill of lading, one page per posted shipment, in the layout of Geary''s template.';
        }
    }

    var
        BOLBuilder: Codeunit "Santoki BOL Builder";
        FreightTerms: Enum "Santoki BOL Freight Terms";
        PickupDate: Date;
        ProNo: Text[50];
        TrailerNo: Text[30];
        SealNo: Text[30];
        TotalPallets: Integer;
        CartonsOverride: Integer;
        ThirdPartyBillTo: Text[100];
        RoutingRef: Text[50];
        AppointmentRef: Text[50];
        SpecialInstructions: Text[250];
        FreightLineCount: Integer;
        PickupDateTxt: Text;
        CarrierName: Text;
        CarrierSCAC: Text;
        ProNumberTxt: Text;
        ShipFromName: Text;
        ShipFromContact: Text;
        ShipFromAddress: Text;
        ShipFromCityStateZip: Text;
        ShipToNameTxt: Text;
        ShipToAddress: Text;
        ShipToCityStateZip: Text;
        BillToPartyTxt: Text;
        TotalPalletsTxt: Text;
        TotalCartonsTxt: Text;
        TotalWeightTxt: Text;
        FreightTermsTxt: Text;
        CommodityTxt: Text;
        LinePalletsTxt: Text;
        LineCartonsTxt: Text;
        LineWeightTxt: Text;
        LineNMFCClassTxt: Text;
        CommodityTxtLbl: Label '%1 (%2 SKUs)', Comment = '%1 = commodity description, %2 = number of item lines';
        CommodityOneTxtLbl: Label '%1 (1 SKU)', Comment = '%1 = commodity description';
}
