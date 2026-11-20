// What Celigo has delivered from Amazon's reports, and any delivery that could not be read.
page 50201 "Amazon Report Deliveries"
{
    PageType = List;
    Caption = 'Amazon Report Deliveries';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Amazon Report Inbox";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Deliveries)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Report Type"; Rec."Report Type") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field("Amazon Report Id"; Rec."Amazon Report Id") { }
                field("Received At"; Rec."Received At") { }
                field(Processed; Rec.Processed) { }
                field("Processed At"; Rec."Processed At") { }
                field("Rows Read"; Rec."Rows Read") { }
                field(Attempts; Rec.Attempts) { }
                field("Error Message"; Rec."Error Message") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryDelivery)
            {
                Caption = 'Retry';
                Image = Refresh;
                ToolTip = 'Let the returns job try the selected unread deliveries again, for example after a fix. The next run reads them.';

                trigger OnAction()
                var
                    Inbox: Record "Amazon Report Inbox";
                begin
                    CurrPage.SetSelectionFilter(Inbox);
                    Inbox.SetRange(Processed, false);
                    Inbox.ModifyAll(Attempts, 0);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RetryDelivery_Promoted; RetryDelivery) { }
        }
    }
}
