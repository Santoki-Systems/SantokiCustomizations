// Reads one returns delivery into Amazon Inventory Events.
//
// The delivery is the FBA customer returns report (GET_FBA_FULFILLMENT_CUSTOMER_RETURNS_DATA),
// which Celigo downloads and parses, posted as a JSON array of rows: either the array itself, or
// { "rows": [ ... ] }. Each row is an object keyed by the report's own column names, for example
// "return-date", "order-id", "sku", "license-plate-number". Columns are read by name, so Amazon
// adding or reordering columns changes nothing, and underscores or spaces in a name are treated
// as hyphens. Customer comments are never read.
//
// Rules:
// - A row is matched to the event already held by its Event Key (see table 50201).
// - New rows are added as Received.
// - A changed row that hasn't reached a journal is overwritten and checked again.
// - A changed row that is already in a journal or posted goes to Error for review. Nothing is
//   reversed automatically.
// - An unchanged row that is in Error or On Hold is checked again, so fixing setup and waiting for
//   the next delivery is enough.
// - A row with no order id or SKU is kept as an Error event so it is seen, not dropped.
codeunit 50203 "Amazon Return Import"
{
    TableNo = "Amazon Report Inbox";

    trigger OnRun()
    var
        Rows: JsonArray;
        RowToken: JsonToken;
        Index: Integer;
    begin
        if Rec."Report Type" <> Rec."Report Type"::Returns then
            Error(WrongReportTypeErr, Rec."Report Type");
        ReadRows(Rec.GetPayload(), Rows);
        for Index := 0 to Rows.Count() - 1 do begin
            Rows.Get(Index, RowToken);
            if not RowToken.IsObject() then
                Error(RowNotObjectErr, Index + 1);
            ImportRow(RowToken.AsObject(), Rec, Index + 1);
        end;
        Rec."Rows Read" := Rows.Count();
        Rec.Modify();
    end;

    var
        WrongReportTypeErr: Label 'The delivery is a %1 report, not a returns report.', Comment = '%1 = report type';
        InvalidPayloadErr: Label 'The delivery is not a JSON array of report rows.';
        RowNotObjectErr: Label 'Row %1 of the delivery is not a JSON object.', Comment = '%1 = row number';
        InvalidKeyTxt: Label 'INVALID|%1|%2|%3|%4|%5', Locked = true, Comment = '%1 = order id, %2 = seller SKU, %3 = licence plate no., %4 = return date, %5 = fulfillment center id';
        InvalidRowMsg: Label 'Row %1 of delivery %2 has no order-id or sku, so it can''t be matched to a return.', Comment = '%1 = row number, %2 = delivery entry no.';
        ChangedAfterPostingMsg: Label 'Amazon changed this return after it went into document %1: it was %2 / %3 x %4 and is now %5 / %6 x %7. Nothing was reversed. Adjust stock by hand if needed, then use Mark Reviewed.', Comment = '%1 = document no., %2/%5 = disposition, %3/%6 = Amazon status, %4/%7 = quantity';

    local procedure ReadRows(PayloadText: Text; var Rows: JsonArray)
    var
        PayloadToken: JsonToken;
        RowsToken: JsonToken;
        Wrapper: JsonObject;
    begin
        if not PayloadToken.ReadFrom(PayloadText) then
            Error(InvalidPayloadErr);
        if PayloadToken.IsArray() then begin
            Rows := PayloadToken.AsArray();
            exit;
        end;
        if PayloadToken.IsObject() then begin
            Wrapper := PayloadToken.AsObject();
            if Wrapper.Get('rows', RowsToken) then
                if RowsToken.IsArray() then begin
                    Rows := RowsToken.AsArray();
                    exit;
                end;
        end;
        Error(InvalidPayloadErr);
    end;

    local procedure ImportRow(RowJson: JsonObject; var Inbox: Record "Amazon Report Inbox"; RowNo: Integer)
    var
        TempIncoming: Record "Amazon Inventory Event" temporary;
        Existing: Record "Amazon Inventory Event";
        Columns: Dictionary of [Text, Text];
    begin
        ReadColumns(RowJson, Columns);

        TempIncoming.Init();
        TempIncoming."Event Type" := TempIncoming."Event Type"::"Customer Return";
        TempIncoming."Marketplace Id" := Inbox."Marketplace Id";
        TempIncoming."Amazon Order Id" := CopyStr(Column(Columns, 'order-id'), 1, MaxStrLen(TempIncoming."Amazon Order Id"));
        TempIncoming."Seller SKU" := CopyStr(Column(Columns, 'sku'), 1, MaxStrLen(TempIncoming."Seller SKU"));
        TempIncoming.ASIN := CopyStr(Column(Columns, 'asin'), 1, MaxStrLen(TempIncoming.ASIN));
        TempIncoming.FNSKU := CopyStr(Column(Columns, 'fnsku'), 1, MaxStrLen(TempIncoming.FNSKU));
        TempIncoming."License Plate No." := CopyStr(Column(Columns, 'license-plate-number'), 1, MaxStrLen(TempIncoming."License Plate No."));
        TempIncoming."Return Date" := ParseDateTime(Column(Columns, 'return-date'));
        TempIncoming."Fulfillment Center Id" := CopyStr(Column(Columns, 'fulfillment-center-id'), 1, MaxStrLen(TempIncoming."Fulfillment Center Id"));
        TempIncoming."Detailed Disposition" := CopyStr(Column(Columns, 'detailed-disposition'), 1, MaxStrLen(TempIncoming."Detailed Disposition"));
        TempIncoming."Amazon Status" := CopyStr(Column(Columns, 'status'), 1, MaxStrLen(TempIncoming."Amazon Status"));
        TempIncoming.Reason := CopyStr(Column(Columns, 'reason'), 1, MaxStrLen(TempIncoming.Reason));
        TempIncoming.Quantity := ParseDecimal(Column(Columns, 'quantity'));
        TempIncoming."Product Name" := CopyStr(Column(Columns, 'product-name'), 1, MaxStrLen(TempIncoming."Product Name"));

        if (TempIncoming."Amazon Order Id" = '') or (TempIncoming."Seller SKU" = '') then begin
            InsertInvalidRow(TempIncoming, Inbox, RowNo);
            exit;
        end;
        TempIncoming."Event Key" := BuildEventKey(TempIncoming);

        Existing.SetCurrentKey("Event Type", "Event Key");
        Existing.SetRange("Event Type", TempIncoming."Event Type");
        Existing.SetRange("Event Key", TempIncoming."Event Key");
        if not Existing.FindFirst() then begin
            InsertNew(TempIncoming, Inbox);
            exit;
        end;

        if not HasChanged(Existing, TempIncoming) then begin
            if (not Existing.IsInJournalOrPosted()) and (Existing.Status in [Existing.Status::Error, Existing.Status::"On Hold"]) then begin
                Existing."Inbox Entry No." := Inbox."Entry No.";
                Existing.ResetForReprocessing();
            end;
            exit;
        end;

        if Existing.IsInJournalOrPosted() then begin
            FlagChangedAfterPosting(Existing, TempIncoming, Inbox);
            exit;
        end;

        CopyAmazonFields(Existing, TempIncoming);
        Existing.ClearResolution();
        Existing.Status := Existing.Status::Received;
        Existing."Status Message" := '';
        Existing."Inbox Entry No." := Inbox."Entry No.";
        Existing."Last Changed At" := CurrentDateTime();
        Existing.Modify(true);
    end;

    // The identity of a return across re-sends: order id, SKU and licence plate number. Without a
    // licence plate, the return date and warehouse are added so two returns of the same SKU on one
    // order stay apart.
    local procedure BuildEventKey(TempIncoming: Record "Amazon Inventory Event" temporary): Text[250]
    var
        KeyText: Text;
    begin
        KeyText := TempIncoming."Amazon Order Id" + '|' + TempIncoming."Seller SKU" + '|' + TempIncoming."License Plate No.";
        if TempIncoming."License Plate No." = '' then
            KeyText += '|' + Format(TempIncoming."Return Date", 0, 9) + '|' + TempIncoming."Fulfillment Center Id";
        exit(CopyStr(KeyText, 1, 250));
    end;

    local procedure HasChanged(Existing: Record "Amazon Inventory Event"; TempIncoming: Record "Amazon Inventory Event" temporary): Boolean
    begin
        exit(
          (Existing."Detailed Disposition" <> TempIncoming."Detailed Disposition") or
          (UpperCase(Existing."Amazon Status") <> UpperCase(TempIncoming."Amazon Status")) or
          (Existing.Quantity <> TempIncoming.Quantity) or
          (Existing."Return Date" <> TempIncoming."Return Date"));
    end;

    local procedure InsertNew(TempIncoming: Record "Amazon Inventory Event" temporary; Inbox: Record "Amazon Report Inbox")
    var
        InventoryEvent: Record "Amazon Inventory Event";
    begin
        InventoryEvent.Init();
        CopyAmazonFields(InventoryEvent, TempIncoming);
        InventoryEvent."Event Type" := TempIncoming."Event Type";
        InventoryEvent."Event Key" := TempIncoming."Event Key";
        InventoryEvent.Status := InventoryEvent.Status::Received;
        InventoryEvent."Inbox Entry No." := Inbox."Entry No.";
        InventoryEvent."Received At" := CurrentDateTime();
        InventoryEvent."Last Changed At" := InventoryEvent."Received At";
        InventoryEvent.Insert(true);
    end;

    // Keyed by what the row says, not by the delivery it came in, so the daily re-send of the last
    // 35 days doesn't add the same unusable row again every day.
    local procedure InsertInvalidRow(TempIncoming: Record "Amazon Inventory Event" temporary; Inbox: Record "Amazon Report Inbox"; RowNo: Integer)
    var
        InventoryEvent: Record "Amazon Inventory Event";
        InvalidKey: Text;
    begin
        InvalidKey := StrSubstNo(InvalidKeyTxt, TempIncoming."Amazon Order Id", TempIncoming."Seller SKU",
          TempIncoming."License Plate No.", Format(TempIncoming."Return Date", 0, 9), TempIncoming."Fulfillment Center Id");
        InventoryEvent.SetCurrentKey("Event Type", "Event Key");
        InventoryEvent.SetRange("Event Type", TempIncoming."Event Type");
        InventoryEvent.SetRange("Event Key", CopyStr(InvalidKey, 1, MaxStrLen(InventoryEvent."Event Key")));
        if not InventoryEvent.IsEmpty() then
            exit;

        InventoryEvent.Reset();
        InventoryEvent.Init();
        CopyAmazonFields(InventoryEvent, TempIncoming);
        InventoryEvent."Event Type" := TempIncoming."Event Type";
        InventoryEvent."Event Key" := CopyStr(InvalidKey, 1, MaxStrLen(InventoryEvent."Event Key"));
        InventoryEvent.Status := InventoryEvent.Status::Error;
        InventoryEvent."Status Message" := StrSubstNo(InvalidRowMsg, RowNo, Inbox."Entry No.");
        InventoryEvent."Inbox Entry No." := Inbox."Entry No.";
        InventoryEvent."Received At" := CurrentDateTime();
        InventoryEvent."Last Changed At" := InventoryEvent."Received At";
        InventoryEvent.Insert(true);
    end;

    local procedure FlagChangedAfterPosting(var Existing: Record "Amazon Inventory Event"; TempIncoming: Record "Amazon Inventory Event" temporary; Inbox: Record "Amazon Report Inbox")
    var
        Problem: Text;
    begin
        Problem := StrSubstNo(ChangedAfterPostingMsg, Existing."Document No.",
          Existing."Detailed Disposition", Existing."Amazon Status", Existing.Quantity,
          TempIncoming."Detailed Disposition", TempIncoming."Amazon Status", TempIncoming.Quantity);
        CopyAmazonFields(Existing, TempIncoming);
        Existing.Status := Existing.Status::Error;
        Existing."Status Message" := CopyStr(Problem, 1, MaxStrLen(Existing."Status Message"));
        Existing."Inbox Entry No." := Inbox."Entry No.";
        Existing."Last Changed At" := CurrentDateTime();
        Existing.Modify(true);
    end;

    local procedure CopyAmazonFields(var Target: Record "Amazon Inventory Event"; Source: Record "Amazon Inventory Event" temporary)
    begin
        Target."Marketplace Id" := Source."Marketplace Id";
        Target."Amazon Order Id" := Source."Amazon Order Id";
        Target."Seller SKU" := Source."Seller SKU";
        Target.ASIN := Source.ASIN;
        Target.FNSKU := Source.FNSKU;
        Target."License Plate No." := Source."License Plate No.";
        Target."Return Date" := Source."Return Date";
        Target."Fulfillment Center Id" := Source."Fulfillment Center Id";
        Target."Detailed Disposition" := Source."Detailed Disposition";
        Target."Amazon Status" := Source."Amazon Status";
        Target.Reason := Source.Reason;
        Target.Quantity := Source.Quantity;
        Target."Product Name" := Source."Product Name";
    end;

    local procedure ReadColumns(RowJson: JsonObject; var Columns: Dictionary of [Text, Text])
    var
        ValueToken: JsonToken;
        ColumnName: Text;
    begin
        Clear(Columns);
        foreach ColumnName in RowJson.Keys() do
            if RowJson.Get(ColumnName, ValueToken) then
                Columns.Set(NormaliseColumnName(ColumnName), TokenText(ValueToken));
    end;

    local procedure NormaliseColumnName(ColumnName: Text): Text
    begin
        exit(ConvertStr(LowerCase(DelChr(ColumnName, '<>', ' ')), '_ ', '--'));
    end;

    local procedure Column(Columns: Dictionary of [Text, Text]; ColumnName: Text): Text
    var
        Value: Text;
    begin
        if Columns.Get(ColumnName, Value) then
            exit(DelChr(Value, '<>', ' '));
        exit('');
    end;

    // Returns a JSON value as text whether Celigo sent it as a string or a number.
    local procedure TokenText(ValueToken: JsonToken): Text
    var
        RawValue: Text;
    begin
        if not ValueToken.IsValue() then
            exit('');
        if ValueToken.AsValue().IsNull() then
            exit('');
        ValueToken.WriteTo(RawValue);
        if CopyStr(RawValue, 1, 1) = '"' then
            exit(ValueToken.AsValue().AsText());
        exit(RawValue);
    end;

    // The report gives ISO dates with a time zone, for example 2026-11-10T08:12:33+00:00.
    // A plain date is accepted too.
    local procedure ParseDateTime(ValueText: Text): DateTime
    var
        Value: DateTime;
        DateValue: Date;
    begin
        if ValueText = '' then
            exit(0DT);
        if Evaluate(Value, ValueText, 9) then
            exit(Value);
        if Evaluate(DateValue, CopyStr(ValueText, 1, 10), 9) then
            exit(CreateDateTime(DateValue, 0T));
        exit(0DT);
    end;

    local procedure ParseDecimal(ValueText: Text): Decimal
    var
        Value: Decimal;
    begin
        if ValueText = '' then
            exit(0);
        if not Evaluate(Value, ValueText, 9) then
            exit(0);
        exit(Value);
    end;
}
