// The rules that decide what happens to each returned unit. Finance maintains them.
page 50203 "Amazon Return Dispositions"
{
    PageType = List;
    Caption = 'Amazon Return Dispositions';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Amazon Return Disposition";

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field("Detailed Disposition"; Rec."Detailed Disposition") { }
                field("Amazon Status"; Rec."Amazon Status") { }
                field("Action"; Rec.Action) { }
                field("Location Code"; Rec."Location Code") { }
                field("Reason Code"; Rec."Reason Code") { }
                field(Description; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddRecommendedRules)
            {
                Caption = 'Add Recommended Rules';
                Image = Default;
                ToolTip = 'Add the recommended rules: sellable back to stock, defective and customer-damaged to the unsellable location, Amazon-damaged and reimbursed units left to the settlement, pending repackaging on hold. Rules that already exist are kept.';

                trigger OnAction()
                var
                    Rule: Record "Amazon Return Disposition";
                begin
                    Message(AddedMsg, Rule.InsertRecommendedRules());
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(AddRecommendedRules_Promoted; AddRecommendedRules) { }
        }
    }

    var
        AddedMsg: Label '%1 rules were added.', Comment = '%1 = count';
}
