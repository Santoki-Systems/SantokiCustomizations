page 50222 "Amazon Staged Order"
{
    PageType = Document;
    Caption = 'Amazon Order';
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Amazon Staged Order";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Amazon Order Id"; Rec."Amazon Order Id") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field("Sales Channel"; Rec."Sales Channel") { }
                field("Purchase Date"; Rec."Purchase Date") { }
                field("Last Update Date"; Rec."Last Update Date") { }
                field("Amazon Order Status"; Rec."Amazon Order Status") { }
                field("Fulfillment Channel"; Rec."Fulfillment Channel") { }
                field("Ship Service Level"; Rec."Ship Service Level") { }
                field("Is Prime"; Rec."Is Prime") { }
                field("Is Business Order"; Rec."Is Business Order") { }
                field("Order Total"; Rec."Order Total") { }
                field("Currency Code"; Rec."Currency Code") { }
            }
            group(Processing)
            {
                Caption = 'Processing';
                field(Status; Rec.Status) { }
                field("Status Message"; Rec."Status Message") { MultiLine = true; }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesOrder();
                    end;
                }
                field(Attempts; Rec.Attempts) { }
                field("Last Attempt At"; Rec."Last Attempt At") { }
                field("Received At"; Rec."Received At") { }
                field("Processed At"; Rec."Processed At") { }
                field("Inbox Entry No."; Rec."Inbox Entry No.") { }
            }
            part(Lines; "Amazon Staged Order Lines")
            {
                Caption = 'Items';
                SubPageLink = "Amazon Order Id" = field("Amazon Order Id");
            }
            group(ShipTo)
            {
                Caption = 'Ship-to';
                field("Ship-to Name"; Rec."Ship-to Name") { }
                field("Ship-to Address"; Rec."Ship-to Address") { }
                field("Ship-to Address 2"; Rec."Ship-to Address 2") { }
                field("Ship-to City"; Rec."Ship-to City") { }
                field("Ship-to County"; Rec."Ship-to County") { }
                field("Ship-to Post Code"; Rec."Ship-to Post Code") { }
                field("Ship-to Country Code"; Rec."Ship-to Country Code") { }
                field("Ship-to Phone"; Rec."Ship-to Phone") { }
                field("Buyer Email"; Rec."Buyer Email") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                Caption = 'Reprocess';
                Image = Refresh;
                ToolTip = 'Send this order back through checking, for example after adding a SKU mapping.';

                trigger OnAction()
                begin
                    Rec.ResetForReprocessing();
                    CurrPage.Update(false);
                end;
            }
            action(ShowAmazonData)
            {
                Caption = 'Show Amazon Data';
                Image = XMLFile;
                ToolTip = 'Show the order exactly as Amazon sent it.';

                trigger OnAction()
                begin
                    Message('%1', Rec.GetPayload());
                end;
            }
        }
        area(Navigation)
        {
            action(SalesOrder)
            {
                Caption = 'Sales Order';
                Image = Document;
                ToolTip = 'Open the sales order created from this Amazon order.';

                trigger OnAction()
                begin
                    Rec.OpenSalesOrder();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(SalesOrder_Promoted; SalesOrder) { }
        }
    }
}
