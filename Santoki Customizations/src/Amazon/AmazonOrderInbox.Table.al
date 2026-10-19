// Every delivery from Celigo lands here first, exactly as sent, one row per delivery.
//
// Celigo only ever inserts. Turning a delivery into a staged order (and deciding whether it is a
// new order, an update, or a stale redelivery) happens afterwards in Business Central, so Celigo
// never needs to look anything up and a redelivered order cannot create a duplicate.
table 50203 "Amazon Order Inbox"
{
    Caption = 'Amazon Order Inbox';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Order Inbox";
    DrillDownPageId = "Amazon Order Inbox";

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the sequence number of the delivery.';
        }
        field(2; "Amazon Order Id"; Code[30])
        {
            Caption = 'Amazon Order Id';
            ToolTip = 'Specifies the Amazon order number the delivery is for.';
        }
        field(3; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            ToolTip = 'Specifies the Amazon marketplace the order was placed on.';
        }
        field(4; "Received At"; DateTime)
        {
            Caption = 'Received At';
            ToolTip = 'Specifies when Business Central received the delivery.';
        }
        field(5; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; Processed; Boolean)
        {
            Caption = 'Processed';
            ToolTip = 'Specifies whether the delivery has been read into the staged orders.';
        }
        field(7; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            ToolTip = 'Specifies when the delivery was read into the staged orders.';
        }
        field(8; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times Business Central has tried to read the delivery. Deliveries that fail three times are left for review.';
        }
        field(9; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies why the delivery could not be read.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Unprocessed; Processed, Attempts, "Entry No.") { }
        key(Order; "Amazon Order Id", "Entry No.") { }
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
