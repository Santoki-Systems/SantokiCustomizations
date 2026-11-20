// Every Amazon report delivery from Celigo lands here first, exactly as sent, one row per delivery.
//
// Returns now, settlements later. Celigo only ever inserts: it requests the report, waits for it,
// downloads it and posts the rows as one delivery. Reading the rows, matching them to what is
// already held and deciding what to do happens afterwards in Business Central, so a redelivered
// report can't create duplicates. The order inbox (table 50203) stays as it is.
table 50200 "Amazon Report Inbox"
{
    Caption = 'Amazon Report Inbox';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Report Deliveries";
    DrillDownPageId = "Amazon Report Deliveries";

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the sequence number of the delivery.';
        }
        field(2; "Report Type"; Enum "Amazon Report Type")
        {
            Caption = 'Report Type';
            ToolTip = 'Specifies which Amazon report the delivery carries.';
        }
        field(3; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            ToolTip = 'Specifies the Amazon marketplace the report is for.';
        }
        field(4; "Amazon Report Id"; Code[50])
        {
            Caption = 'Amazon Report Id';
            ToolTip = 'Specifies Amazon''s id for the report, if Celigo sent it.';
        }
        field(5; "Received At"; DateTime)
        {
            Caption = 'Received At';
            ToolTip = 'Specifies when Business Central received the delivery.';
        }
        field(6; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; Processed; Boolean)
        {
            Caption = 'Processed';
            ToolTip = 'Specifies whether the delivery has been read.';
        }
        field(8; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            ToolTip = 'Specifies when the delivery was read.';
        }
        field(9; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times Business Central has tried to read the delivery. Deliveries that fail three times are left for review.';
        }
        field(10; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies why the delivery could not be read.';
        }
        field(11; "Rows Read"; Integer)
        {
            Caption = 'Rows Read';
            ToolTip = 'Specifies how many report rows the delivery held.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Unprocessed; "Report Type", Processed, Attempts, "Entry No.") { }
    }

    procedure SetPayload(PayloadText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec.Payload);
        Rec.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadText);
    end;

    procedure GetPayload(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        Rec.CalcFields(Payload);
        if not Rec.Payload.HasValue() then
            exit('');
        Rec.Payload.CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;
}
