// The working screen for Amazon customer returns. Filter to Errors to see every return that has
// not made it into a journal, with the reason; On Hold shows returns waiting on Amazon or go-live.
page 50202 "Amazon Returns"
{
    PageType = List;
    Caption = 'Amazon Returns';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Amazon Inventory Event";
    SourceTableView = sorting("Entry No.") order(descending) where("Event Type" = const("Customer Return"));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Returns)
            {
                field("Return Date"; Rec."Return Date") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field("Amazon Order Id"; Rec."Amazon Order Id") { }
                field("Seller SKU"; Rec."Seller SKU") { }
                field(Quantity; Rec.Quantity) { }
                field("Detailed Disposition"; Rec."Detailed Disposition") { }
                field("Amazon Status"; Rec."Amazon Status") { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field("Status Message"; Rec."Status Message") { }
                field("Action"; Rec.Action) { }
                field("Item No."; Rec."Item No.") { }
                field("Variant Code"; Rec."Variant Code") { }
                field("Location Code"; Rec."Location Code") { }
                field("Quantity (Base)"; Rec."Quantity (Base)") { }
                field("Document No."; Rec."Document No.") { }
                field("Posting Date"; Rec."Posting Date") { }
                field(Reason; Rec.Reason) { }
                field("Fulfillment Center Id"; Rec."Fulfillment Center Id") { }
                field("License Plate No."; Rec."License Plate No.") { }
                field(ASIN; Rec.ASIN) { Visible = false; }
                field(FNSKU; Rec.FNSKU) { Visible = false; }
                field("Product Name"; Rec."Product Name") { Visible = false; }
                field("Received At"; Rec."Received At") { Visible = false; }
                field("Last Changed At"; Rec."Last Changed At") { Visible = false; }
                field("Inbox Entry No."; Rec."Inbox Entry No.") { Visible = false; }
                field("Entry No."; Rec."Entry No.") { Visible = false; }
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
                ToolTip = 'Read new returns deliveries, check received returns and build each marketplace''s returns journal now, instead of waiting for the job queue. If a run is already going, this says so and stops.';

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Amazon Return Job");
                    CurrPage.Update(false);
                end;
            }
            action(Reprocess)
            {
                Caption = 'Reprocess';
                Image = Refresh;
                ToolTip = 'Send the selected returns back through checking, for example after adding a SKU mapping or a disposition rule. Returns already in a journal are skipped.';

                trigger OnAction()
                var
                    InventoryEvent: Record "Amazon Inventory Event";
                    EventToReset: Record "Amazon Inventory Event";
                    ResetCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(InventoryEvent);
                    InventoryEvent.SetRange("Document No.", '');
                    InventoryEvent.SetFilter(Status, '%1|%2|%3', InventoryEvent.Status::Error, InventoryEvent.Status::"On Hold", InventoryEvent.Status::Ignored);
                    if InventoryEvent.FindSet() then
                        repeat
                            // Changed through a second record so the loop's status filter is not disturbed.
                            EventToReset.Get(InventoryEvent."Entry No.");
                            EventToReset.ResetForReprocessing();
                            ResetCount += 1;
                        until InventoryEvent.Next() = 0;
                    Message(ReprocessedMsg, ResetCount);
                    CurrPage.Update(false);
                end;
            }
            action(MarkReviewed)
            {
                Caption = 'Mark Reviewed';
                Image = Approve;
                ToolTip = 'For returns Amazon changed after they went into a journal: confirm you have dealt with the change, and put the return back to In Journal or Posted. Nothing is posted by this action.';

                trigger OnAction()
                var
                    InventoryEvent: Record "Amazon Inventory Event";
                    EventToMark: Record "Amazon Inventory Event";
                    MarkedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(InventoryEvent);
                    InventoryEvent.SetFilter("Document No.", '<>%1', '');
                    InventoryEvent.SetRange(Status, InventoryEvent.Status::Error);
                    if InventoryEvent.FindSet() then
                        repeat
                            EventToMark.Get(InventoryEvent."Entry No.");
                            if EventToMark."Posted At" <> 0DT then
                                EventToMark.Status := EventToMark.Status::Posted
                            else
                                EventToMark.Status := EventToMark.Status::"In Journal";
                            EventToMark."Status Message" := CopyStr(StrSubstNo(ReviewedTxt, UserId(), CurrentDateTime()), 1, MaxStrLen(EventToMark."Status Message"));
                            EventToMark.Modify(true);
                            MarkedCount += 1;
                        until InventoryEvent.Next() = 0;
                    Message(MarkedMsg, MarkedCount);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Dispositions)
            {
                Caption = 'Return Dispositions';
                Image = Setup;
                RunObject = page "Amazon Return Dispositions";
                ToolTip = 'Open the rules that decide what happens to each returned unit.';
            }
            action(Deliveries)
            {
                Caption = 'Report Deliveries';
                Image = Import;
                RunObject = page "Amazon Report Deliveries";
                ToolTip = 'Open the deliveries Celigo has sent from Amazon''s reports.';
            }
            action(MarketplaceSetup)
            {
                Caption = 'Marketplace Setup';
                Image = SetupList;
                RunObject = page "Amazon Marketplace Setup";
                ToolTip = 'Open the marketplace setup, including the returns go-live date, locations and journal.';
            }
        }
        area(Promoted)
        {
            actionref(ProcessNow_Promoted; ProcessNow) { }
            actionref(Reprocess_Promoted; Reprocess) { }
            actionref(MarkReviewed_Promoted; MarkReviewed) { }
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
        view(InJournal)
        {
            Caption = 'In Journal';
            Filters = where(Status = const("In Journal"));
        }
    }

    var
        StatusStyle: Text;
        ReprocessedMsg: Label '%1 returns were sent back for checking. Choose Process Now to check them straight away.', Comment = '%1 = count';
        MarkedMsg: Label '%1 returns were marked reviewed.', Comment = '%1 = count';
        ReviewedTxt: Label 'Change reviewed by %1 at %2.', Comment = '%1 = user, %2 = date and time';

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::"On Hold":
                StatusStyle := 'Ambiguous';
            Rec.Status::Posted, Rec.Status::"In Journal":
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
