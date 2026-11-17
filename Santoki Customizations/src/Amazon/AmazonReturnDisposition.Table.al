// Setup: what happens to a returned unit, given the condition (detailed disposition) and status
// Amazon reports for it. Finance maintains it.
//
// A rule for a status (with the disposition left blank) wins over a rule for a disposition, so
// Reimbursed or Pending repackaging apply whatever the condition. A combination with no rule
// stops in Error with the reason, never silently.
table 50202 "Amazon Return Disposition"
{
    Caption = 'Amazon Return Disposition';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Return Dispositions";
    DrillDownPageId = "Amazon Return Dispositions";

    fields
    {
        field(1; "Detailed Disposition"; Code[30])
        {
            Caption = 'Detailed Disposition';
            ToolTip = 'Specifies the condition Amazon reports, for example SELLABLE, DEFECTIVE or CUSTOMER_DAMAGED. Leave blank for a rule that applies to a status whatever the condition.';
        }
        field(2; "Amazon Status"; Code[50])
        {
            Caption = 'Amazon Status';
            ToolTip = 'Specifies the status Amazon reports, for example REIMBURSED or PENDING REPACKAGING. Leave blank for a rule that applies to the condition whatever the status.';
        }
        field(3; "Action"; Enum "Amazon Return Action")
        {
            Caption = 'Action';
            ToolTip = 'Specifies what Business Central does with the unit.';
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies a location to post to instead of the marketplace location (Add to Stock, Add and Write Off) or the unsellable location (Move to Unsellable Location).';
        }
        field(5; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            ToolTip = 'Specifies a reason code for the journal lines this rule creates.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies why the rule exists. It is shown on events the rule ignores or holds.';
        }
    }

    keys
    {
        key(PK; "Detailed Disposition", "Amazon Status") { Clustered = true; }
    }

    // Finds the rule for a disposition and status: status and disposition together, then the
    // status alone, then the disposition alone.
    procedure FindRule(Disposition: Text; AmazonStatus: Text): Boolean
    var
        DispositionCode: Code[30];
        StatusCode: Code[50];
    begin
        DispositionCode := CopyStr(UpperCase(DelChr(Disposition, '<>', ' ')), 1, MaxStrLen(DispositionCode));
        StatusCode := CopyStr(UpperCase(DelChr(AmazonStatus, '<>', ' ')), 1, MaxStrLen(StatusCode));
        if (DispositionCode <> '') and (StatusCode <> '') then
            if Rec.Get(DispositionCode, StatusCode) then
                exit(true);
        if StatusCode <> '' then
            if Rec.Get('', StatusCode) then
                exit(true);
        if DispositionCode <> '' then
            if Rec.Get(DispositionCode, '') then
                exit(true);
        exit(false);
    end;

    // The recommended rules from the returns scoping note (Nov 5th 2026) and Michele's answers of
    // Nov 11th 2026: sellable back to Amazon stock, unsellable held apart in Amazon's unsellable
    // inventory, Amazon-damaged and reimbursed units left to the settlement. Existing rules are kept.
    procedure InsertRecommendedRules(): Integer
    var
        Added: Integer;
    begin
        Added += InsertRule('', 'REIMBURSED', Enum::"Amazon Return Action"::"No Movement", 'Amazon pays for the unit through the settlement.');
        Added += InsertRule('', 'PENDING REPACKAGING', Enum::"Amazon Return Action"::Hold, 'Waiting for Amazon to finish repackaging.');
        // Seen in the real returns report (September 2026, cross-border CUSTOMER_DAMAGED returns):
        // Amazon disposes of the unit on receipt, so nothing comes back to stock.
        Added += InsertRule('', 'IMMEDIATE_DISPOSAL', Enum::"Amazon Return Action"::"No Movement", 'Amazon disposed of the unit on receipt; nothing comes back to stock.');
        Added += InsertRule('SELLABLE', '', Enum::"Amazon Return Action"::"Add to Stock", 'Back in sellable stock at Amazon.');
        Added += InsertRule('DEFECTIVE', '', Enum::"Amazon Return Action"::"Move to Unsellable", 'Unsellable; held in Amazon unsellable inventory until removed or destroyed.');
        Added += InsertRule('CUSTOMER_DAMAGED', '', Enum::"Amazon Return Action"::"Move to Unsellable", 'Unsellable; held in Amazon unsellable inventory until removed or destroyed.');
        Added += InsertRule('DAMAGED', '', Enum::"Amazon Return Action"::"No Movement", 'Damaged by Amazon; normally reimbursed through the settlement.');
        Added += InsertRule('CARRIER_DAMAGED', '', Enum::"Amazon Return Action"::"No Movement", 'Damaged in transit; normally reimbursed through the settlement.');
        exit(Added);
    end;

    local procedure InsertRule(Disposition: Code[30]; AmazonStatus: Code[50]; NewAction: Enum "Amazon Return Action"; NewDescription: Text[100]): Integer
    var
        Rule: Record "Amazon Return Disposition";
    begin
        if Rule.Get(Disposition, AmazonStatus) then
            exit(0);
        Rule.Init();
        Rule."Detailed Disposition" := Disposition;
        Rule."Amazon Status" := AmazonStatus;
        Rule.Action := NewAction;
        Rule.Description := NewDescription;
        Rule.Insert(true);
        exit(1);
    end;
}
