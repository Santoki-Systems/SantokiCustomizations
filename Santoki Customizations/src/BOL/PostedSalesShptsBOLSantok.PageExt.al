pageextension 50209 "Posted Sales Shpts. BOL Santok" extends "Posted Sales Shipments"
{
    actions
    {
        addafter("&Print")
        {
            action(SantokiPrintBOL)
            {
                ApplicationArea = All;
                Caption = 'Print Bill of Lading';
                Image = PrintDocument;
                ToolTip = 'Print a bill of lading for each selected shipment, one page per shipment.';

                trigger OnAction()
                var
                    SalesShipmentHeader: Record "Sales Shipment Header";
                begin
                    CurrPage.SetSelectionFilter(SalesShipmentHeader);
                    Report.RunModal(Report::"Santoki Bill of Lading", true, false, SalesShipmentHeader);
                end;
            }
            action(SantokiPrintMasterBOL)
            {
                ApplicationArea = All;
                Caption = 'Print Master Bill of Lading';
                Image = PrintReport;
                ToolTip = 'Print one master bill of lading listing the selected shipments, for a consolidated carrier pickup.';

                trigger OnAction()
                var
                    SalesShipmentHeader: Record "Sales Shipment Header";
                begin
                    CurrPage.SetSelectionFilter(SalesShipmentHeader);
                    Report.RunModal(Report::"Santoki Master Bill of Lading", true, false, SalesShipmentHeader);
                end;
            }
        }
        addlast(Category_Category7)
        {
            actionref(SantokiPrintBOL_Promoted; SantokiPrintBOL)
            {
            }
            actionref(SantokiPrintMasterBOL_Promoted; SantokiPrintMasterBOL)
            {
            }
        }
    }
}
