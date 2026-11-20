// Builds one summarised item journal per run for a marketplace's ready returns, and posts it if the
// marketplace is set to.
//
// Lines are summed by action, item, variant, location and reason code under one document number
// per day (AMZRET-261116), so a week of returns is a handful of lines, like the monthly AMZRETURNS
// document today.
// - Add to Stock and Move to Unsellable Location: a positive adjustment at the location.
// - Add and Write Off: a positive and a negative adjustment of the same quantity.
// Returns are stock only. The refund money is already in the settlement, so there is no credit memo.
//
// When the marketplace posts automatically, the batch must be empty when the run starts, so the run
// never posts someone else's lines. When it doesn't (the side-by-side run), each run's lines are
// added under that day's document number and left for review. The journal, the posting and the
// event updates are one transaction: if anything fails, nothing is kept and the job marks the
// events with the error.
codeunit 50205 "Amazon Return Posting"
{
    TableNo = "Amazon Marketplace Setup";

    trigger OnRun()
    begin
        PostReadyReturns(Rec);
    end;

    var
        BatchNotEmptyErr: Label 'Item journal batch %1 %2 already has lines. Post or delete them first; the Amazon returns run only posts lines it created.', Comment = '%1 = template, %2 = batch';
        DocumentNoTxt: Label 'AMZRET-%1', Locked = true, Comment = '%1 = posting date as YYMMDD';
        ReturnDescriptionTxt: Label 'Amazon customer returns';
        WriteOffDescriptionTxt: Label 'Amazon returns written off';
        GroupSeparatorTxt: Label '|', Locked = true;

    local procedure PostReadyReturns(Setup: Record "Amazon Marketplace Setup")
    var
        InventoryEvent: Record "Amazon Inventory Event";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        Totals: Dictionary of [Text, Decimal];
        GroupKeys: List of [Text];
        EntryNos: List of [BigInteger];
        GroupKey: Text;
        DocumentNo: Code[20];
        PostingDate: Date;
        LineNo: Integer;
    begin
        InventoryEvent.SetCurrentKey(Status, "Marketplace Id", "Return Date");
        InventoryEvent.SetRange(Status, InventoryEvent.Status::Ready);
        InventoryEvent.SetRange("Marketplace Id", Setup."Marketplace Id");
        if not InventoryEvent.FindSet() then
            exit;

        Setup.TestField("Returns Jnl. Template Name");
        Setup.TestField("Returns Jnl. Batch Name");
        ItemJnlLine.SetRange("Journal Template Name", Setup."Returns Jnl. Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Setup."Returns Jnl. Batch Name");
        if Setup."Post Returns Automatically" then begin
            // Posting posts the whole batch, so it must hold only this run's lines.
            if not ItemJnlLine.IsEmpty() then
                Error(BatchNotEmptyErr, Setup."Returns Jnl. Template Name", Setup."Returns Jnl. Batch Name");
        end else
            // Left for review: add after any lines still waiting from earlier runs.
            if ItemJnlLine.FindLast() then
                LineNo := ItemJnlLine."Line No.";

        repeat
            GroupKey := MakeGroupKey(InventoryEvent);
            if Totals.ContainsKey(GroupKey) then
                Totals.Set(GroupKey, Totals.Get(GroupKey) + InventoryEvent."Quantity (Base)")
            else begin
                Totals.Add(GroupKey, InventoryEvent."Quantity (Base)");
                GroupKeys.Add(GroupKey);
            end;
            EntryNos.Add(InventoryEvent."Entry No.");
        until InventoryEvent.Next() = 0;

        // The posting date is the run date (an assumption in the scoping note, for Michele to confirm).
        PostingDate := Today();
        DocumentNo := CopyStr(StrSubstNo(DocumentNoTxt, Format(PostingDate, 0, '<Year,2><Month,2><Day,2>')), 1, MaxStrLen(DocumentNo));

        foreach GroupKey in GroupKeys do
            AddGroupLines(Setup, GroupKey, Totals.Get(GroupKey), DocumentNo, PostingDate, LineNo);

        if Setup."Post Returns Automatically" then begin
            ItemJnlLine.FindFirst();
            ItemJnlPostBatch.SetSuppressCommit(true);
            ItemJnlPostBatch.Run(ItemJnlLine);
        end;

        MarkEvents(EntryNos, DocumentNo, PostingDate, Setup."Post Returns Automatically");
    end;

    local procedure MakeGroupKey(InventoryEvent: Record "Amazon Inventory Event"): Text
    begin
        exit(
          Format(InventoryEvent.Action.AsInteger()) + GroupSeparatorTxt +
          InventoryEvent."Item No." + GroupSeparatorTxt +
          InventoryEvent."Variant Code" + GroupSeparatorTxt +
          InventoryEvent."Location Code" + GroupSeparatorTxt +
          InventoryEvent."Reason Code");
    end;

    local procedure AddGroupLines(Setup: Record "Amazon Marketplace Setup"; GroupKey: Text; QuantityBase: Decimal; DocumentNo: Code[20]; PostingDate: Date; var LineNo: Integer)
    var
        Parts: List of [Text];
        ReturnAction: Enum "Amazon Return Action";
        ActionNo: Integer;
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        ReasonCode: Code[10];
    begin
        if QuantityBase = 0 then
            exit;
        Parts := GroupKey.Split(GroupSeparatorTxt);
        Evaluate(ActionNo, Parts.Get(1));
        ReturnAction := Enum::"Amazon Return Action".FromInteger(ActionNo);
        ItemNo := CopyStr(Parts.Get(2), 1, MaxStrLen(ItemNo));
        VariantCode := CopyStr(Parts.Get(3), 1, MaxStrLen(VariantCode));
        LocationCode := CopyStr(Parts.Get(4), 1, MaxStrLen(LocationCode));
        ReasonCode := CopyStr(Parts.Get(5), 1, MaxStrLen(ReasonCode));

        LineNo += 10000;
        AddLine(Setup, Enum::"Item Ledger Entry Type"::"Positive Adjmt.", ItemNo, VariantCode, LocationCode, ReasonCode, QuantityBase, DocumentNo, PostingDate, LineNo, ReturnDescriptionTxt);
        if ReturnAction = ReturnAction::"Add and Write Off" then begin
            LineNo += 10000;
            AddLine(Setup, Enum::"Item Ledger Entry Type"::"Negative Adjmt.", ItemNo, VariantCode, LocationCode, ReasonCode, QuantityBase, DocumentNo, PostingDate, LineNo, WriteOffDescriptionTxt);
        end;
    end;

    local procedure AddLine(Setup: Record "Amazon Marketplace Setup"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ReasonCode: Code[10]; QuantityBase: Decimal; DocumentNo: Code[20]; PostingDate: Date; LineNo: Integer; LineDescription: Text)
    var
        ItemJnlLine: Record "Item Journal Line";
        LastItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := Setup."Returns Jnl. Template Name";
        ItemJnlLine."Journal Batch Name" := Setup."Returns Jnl. Batch Name";
        ItemJnlLine."Line No." := LineNo;
        // Picks up the template's source code and the batch's reason code and posting no. series.
        ItemJnlLine.SetUpNewLine(LastItemJnlLine);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine.Validate("Item No.", ItemNo);
        if VariantCode <> '' then
            ItemJnlLine.Validate("Variant Code", VariantCode);
        ItemJnlLine.Validate("Location Code", LocationCode);
        // Quantities are in the base unit, because the SKU mapping's Quantity per is in base units.
        ItemJnlLine.Validate("Unit of Measure Code", GetBaseUnitOfMeasure(ItemNo));
        ItemJnlLine.Validate(Quantity, QuantityBase);
        // Validating the item already brought in its current unit cost for a positive adjustment.
        if (EntryType = EntryType::"Positive Adjmt.") and (Setup."Return Cost Rule" = Setup."Return Cost Rule"::Zero) then
            ItemJnlLine.Validate("Unit Amount", 0);
        if ReasonCode <> '' then
            ItemJnlLine.Validate("Reason Code", ReasonCode);
        ItemJnlLine.Description := CopyStr(LineDescription, 1, MaxStrLen(ItemJnlLine.Description));
        ItemJnlLine.Insert(true);
    end;

    local procedure GetBaseUnitOfMeasure(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure MarkEvents(EntryNos: List of [BigInteger]; DocumentNo: Code[20]; PostingDate: Date; Posted: Boolean)
    var
        InventoryEvent: Record "Amazon Inventory Event";
        EntryNo: BigInteger;
    begin
        foreach EntryNo in EntryNos do begin
            InventoryEvent.Get(EntryNo);
            InventoryEvent."Document No." := DocumentNo;
            InventoryEvent."Posting Date" := PostingDate;
            if Posted then begin
                InventoryEvent.Status := InventoryEvent.Status::Posted;
                InventoryEvent."Posted At" := CurrentDateTime();
            end else
                InventoryEvent.Status := InventoryEvent.Status::"In Journal";
            InventoryEvent."Status Message" := '';
            InventoryEvent.Modify(true);
        end;
    end;
}
