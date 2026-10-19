// Every delivery Celigo has sent, newest first. Mostly for troubleshooting: if an order is missing
// from Amazon Orders, this shows whether it ever arrived and why it could not be read.
page 50209 "Amazon Order Inbox"
{
    PageType = List;
    Caption = 'Amazon Order Deliveries';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Amazon Order Inbox";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Deliveries)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Received At"; Rec."Received At") { }
                field("Amazon Order Id"; Rec."Amazon Order Id") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field(Processed; Rec.Processed) { }
                field("Processed At"; Rec."Processed At") { }
                field(Attempts; Rec.Attempts) { }
                field("Error Message"; Rec."Error Message") { StyleExpr = ErrorStyle; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowPayload)
            {
                Caption = 'Show Delivery';
                Image = XMLFile;
                ToolTip = 'Show the delivery exactly as Celigo sent it.';

                trigger OnAction()
                begin
                    Message('%1', Rec.GetPayload());
                end;
            }
            action(Retry)
            {
                Caption = 'Retry';
                Image = Refresh;
                ToolTip = 'Try reading the selected failed deliveries again on the next run.';

                trigger OnAction()
                var
                    Inbox: Record "Amazon Order Inbox";
                    InboxToRetry: Record "Amazon Order Inbox";
                begin
                    CurrPage.SetSelectionFilter(Inbox);
                    Inbox.SetRange(Processed, false);
                    if Inbox.FindSet() then
                        repeat
                            InboxToRetry.Get(Inbox."Entry No.");
                            InboxToRetry.Attempts := 0;
                            InboxToRetry."Error Message" := '';
                            InboxToRetry.Modify();
                        until Inbox.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ErrorStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Error Message" <> '' then
            ErrorStyle := 'Unfavorable'
        else
            ErrorStyle := 'Standard';
    end;
}
