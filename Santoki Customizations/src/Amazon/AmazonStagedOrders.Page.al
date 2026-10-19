// The team's working screen for Amazon orders, replacing Suite Engine's Channel Orders.
// Filter to Errors to see every order that has not made it through, with the reason.
page 50221 "Amazon Staged Orders"
{
    PageType = List;
    Caption = 'Amazon Orders';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Amazon Staged Order";
    SourceTableView = sorting("Purchase Date") order(descending);
    CardPageId = "Amazon Staged Order";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Orders)
            {
                field("Amazon Order Id"; Rec."Amazon Order Id") { }
                field("Purchase Date"; Rec."Purchase Date") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field("Status Message"; Rec."Status Message") { }
                field("Amazon Order Status"; Rec."Amazon Order Status") { }
                field("Fulfillment Channel"; Rec."Fulfillment Channel") { }
                field("No. of Lines"; Rec."No. of Lines") { }
                field("Order Total"; Rec."Order Total") { }
                field("Currency Code"; Rec."Currency Code") { }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    trigger OnDrillDown()
                    begin
                        Rec.OpenSalesOrder();
                    end;
                }
                field(Attempts; Rec.Attempts) { }
                field("Last Attempt At"; Rec."Last Attempt At") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessNow)
            {
                Caption = 'Process Now';
                Image = Start;
                ToolTip = 'Read new deliveries from Amazon and process received and ready orders now, instead of waiting for the job queue. If a run is already going, this says so and stops.';

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Amazon Order Job");
                    CurrPage.Update(false);
                end;
            }
            action(Reprocess)
            {
                Caption = 'Reprocess';
                Image = Refresh;
                ToolTip = 'Send the selected orders back through checking, for example after adding a SKU mapping. Orders that already have a sales order are skipped.';

                trigger OnAction()
                var
                    StagedOrder: Record "Amazon Staged Order";
                    OrderToReset: Record "Amazon Staged Order";
                    ResetCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(StagedOrder);
                    StagedOrder.SetRange("Sales Order No.", '');
                    StagedOrder.SetFilter(Status, '%1|%2|%3', StagedOrder.Status::Error, StagedOrder.Status::"On Hold", StagedOrder.Status::Cancelled);
                    if StagedOrder.FindSet() then
                        repeat
                            // Changed through a second record so the loop's status filter is not disturbed.
                            OrderToReset.Get(StagedOrder."Amazon Order Id");
                            OrderToReset.ResetForReprocessing();
                            ResetCount += 1;
                        until StagedOrder.Next() = 0;
                    Message(ReprocessMsg, ResetCount);
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
            action(Inbox)
            {
                Caption = 'Deliveries';
                Image = Import;
                RunObject = page "Amazon Order Inbox";
                ToolTip = 'Show every delivery received from Celigo.';
            }
            action(MarketplaceSetup)
            {
                Caption = 'Marketplace Setup';
                Image = Setup;
                RunObject = page "Amazon Marketplace Setup";
                ToolTip = 'Set up the customer, location and accounts for each Amazon marketplace.';
            }
            action(SkuMappings)
            {
                Caption = 'SKU Mappings';
                Image = Item;
                RunObject = page "Amazon SKU Mappings";
                ToolTip = 'Map Amazon SKUs to the items that are stocked.';
            }
            action(FeeMappings)
            {
                Caption = 'Fee Mappings';
                Image = ChartOfAccounts;
                RunObject = page "Amazon Fee Mappings";
                ToolTip = 'Map settlement report amounts to G/L accounts.';
            }
        }
        area(Promoted)
        {
            actionref(ProcessNow_Promoted; ProcessNow) { }
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(SalesOrder_Promoted; SalesOrder) { }
        }
    }

    views
    {
        view(Errors)
        {
            Caption = 'Errors';
            Filters = where(Status = const(Error));
        }
        view(OnHold)
        {
            Caption = 'On Hold';
            Filters = where(Status = const("On Hold"));
        }
        view(InProgress)
        {
            Caption = 'In Progress';
            Filters = where(Status = const("In Progress"));
        }
    }

    var
        StatusStyle: Text;
        ReprocessMsg: Label '%1 orders were sent back for checking. Choose Process Now to run them.', Comment = '%1 = number of orders';

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::"On Hold", Rec.Status::"In Progress":
                StatusStyle := 'Ambiguous';
            Rec.Status::Posted:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
