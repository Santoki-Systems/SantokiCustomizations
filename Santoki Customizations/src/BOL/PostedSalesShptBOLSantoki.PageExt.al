pageextension 50208 "Posted Sales Shpt. BOL Santoki" extends "Posted Sales Shipment"
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
                ToolTip = 'Print a bill of lading for this shipment. Trailer, seal, PRO, pallets and freight terms are entered when printing.';

                trigger OnAction()
                var
                    SalesShipmentHeader: Record "Sales Shipment Header";
                begin
                    SalesShipmentHeader := Rec;
                    SalesShipmentHeader.SetRecFilter();
                    Report.RunModal(Report::"Santoki Bill of Lading", true, false, SalesShipmentHeader);
                end;
            }
        }
        addlast(Category_Category6)
        {
            actionref(SantokiPrintBOL_Promoted; SantokiPrintBOL)
            {
            }
        }
    }
}
