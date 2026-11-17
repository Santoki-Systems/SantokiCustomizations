// One row per row of Amazon's FBA customer returns report: what Amazon sent, what Business Central
// made of it, and where it is on its way into the item ledger.
//
// Amazon re-reports a return for weeks (for example when it changes to Reimbursed), so Celigo
// re-sends a rolling window and each row is matched to what is already held by its Event Key:
// order id, SKU and licence plate number, or, when Amazon gives no licence plate, the return date
// and warehouse as well. A row that changes before it is posted is simply checked again; a row
// that changes after posting goes to Error for review and is never reversed automatically.
//
// The table is named for stock events in general, so reimbursed, found and removed units (R2) add
// event types rather than tables. Customer comments are free text and are not kept.
table 50201 "Amazon Inventory Event"
{
    Caption = 'Amazon Inventory Event';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Returns";
    DrillDownPageId = "Amazon Returns";

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the sequence number of the event.';
        }
        field(2; "Event Type"; Enum "Amazon Inventory Event Type")
        {
            Caption = 'Event Type';
            ToolTip = 'Specifies what kind of stock event Amazon reported.';
        }
        field(3; "Event Key"; Text[250])
        {
            Caption = 'Event Key';
            ToolTip = 'Specifies the identity used to match a re-sent report row to the event already held.';
        }
        field(4; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            ToolTip = 'Specifies the Amazon marketplace the return belongs to.';
        }
        field(5; "Amazon Order Id"; Code[30])
        {
            Caption = 'Amazon Order Id';
            ToolTip = 'Specifies the Amazon order the returned unit was sold on.';
        }
        field(6; "Seller SKU"; Code[50])
        {
            Caption = 'Seller SKU';
            ToolTip = 'Specifies the SKU Amazon reported the return under.';
        }
        field(7; ASIN; Code[20])
        {
            Caption = 'ASIN';
            ToolTip = 'Specifies Amazon''s product identifier.';
        }
        field(8; FNSKU; Code[20])
        {
            Caption = 'FNSKU';
            ToolTip = 'Specifies Amazon''s fulfilment network SKU.';
        }
        field(9; "License Plate No."; Code[50])
        {
            Caption = 'License Plate No.';
            ToolTip = 'Specifies the licence plate number Amazon gave the returned unit, if any.';
        }
        field(10; "Return Date"; DateTime)
        {
            Caption = 'Return Date';
            ToolTip = 'Specifies when Amazon processed the return at its warehouse.';
        }
        field(11; "Fulfillment Center Id"; Code[20])
        {
            Caption = 'Fulfillment Center Id';
            ToolTip = 'Specifies the Amazon warehouse that received the unit.';
        }
        field(12; "Detailed Disposition"; Code[30])
        {
            Caption = 'Detailed Disposition';
            ToolTip = 'Specifies the condition Amazon recorded, for example SELLABLE or CUSTOMER_DAMAGED.';
        }
        field(13; "Amazon Status"; Text[50])
        {
            Caption = 'Amazon Status';
            ToolTip = 'Specifies the status Amazon reported, for example Unit returned to inventory or Reimbursed.';
        }
        field(14; Reason; Text[100])
        {
            Caption = 'Reason';
            ToolTip = 'Specifies the return reason Amazon reported.';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the number of Amazon units returned.';
        }
        field(16; "Product Name"; Text[250])
        {
            Caption = 'Product Name';
            ToolTip = 'Specifies the product name as Amazon reported it.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            ToolTip = 'Specifies the Business Central item the SKU resolved to.';
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ToolTip = 'Specifies the item variant the SKU resolved to, if any.';
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies the location the unit is posted to.';
        }
        field(23; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies how many Business Central units make up one Amazon unit, from the SKU mapping.';
        }
        field(24; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity posted, in the item''s base unit.';
        }
        field(25; "Action"; Enum "Amazon Return Action")
        {
            Caption = 'Action';
            ToolTip = 'Specifies what Business Central does with the unit, from the Amazon Return Dispositions setup.';
        }
        field(26; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            ToolTip = 'Specifies the reason code put on the journal line, from the disposition rule.';
        }
        field(30; Status; Enum "Amazon Inventory Event Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies where the event is: received, ready to post, in a journal, posted, or stopped with an error, on hold or ignored.';
        }
        field(31; "Status Message"; Text[2048])
        {
            Caption = 'Status Message';
            ToolTip = 'Specifies why the event is in error, on hold or ignored.';
        }
        field(32; "Inbox Entry No."; BigInteger)
        {
            Caption = 'Inbox Entry No.';
            TableRelation = "Amazon Report Inbox";
            ToolTip = 'Specifies the delivery the event was last read from.';
        }
        field(33; "Received At"; DateTime)
        {
            Caption = 'Received At';
            ToolTip = 'Specifies when the event was first received.';
        }
        field(34; "Last Changed At"; DateTime)
        {
            Caption = 'Last Changed At';
            ToolTip = 'Specifies when Amazon last reported a change to the return.';
        }
        field(35; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the item journal document the event was posted, or put in a journal, under.';
        }
        field(36; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the journal the event went into.';
        }
        field(37; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            ToolTip = 'Specifies when the journal holding the event was posted.';
        }
        field(38; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times the event has been checked.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(EventKey; "Event Type", "Event Key") { }
        key(Status; Status, "Marketplace Id", "Return Date") { }
    }

    var
        AlreadyPostedErr: Label 'Return %1 is already in item journal document %2, so it can''t be checked again. Use Mark Reviewed once you have dealt with it.', Comment = '%1 = entry no., %2 = document no.';

    // True once the event's units are in a journal or posted. From then on it never moves stock again.
    procedure IsInJournalOrPosted(): Boolean
    begin
        exit(Rec."Document No." <> '');
    end;

    // Sends the event back through checking, for example after adding a SKU mapping or a disposition rule.
    procedure ResetForReprocessing()
    begin
        if Rec.IsInJournalOrPosted() then
            Error(AlreadyPostedErr, Rec."Entry No.", Rec."Document No.");
        Rec.ClearResolution();
        Rec.Status := Rec.Status::Received;
        Rec."Status Message" := '';
        Rec.Modify(true);
    end;

    procedure ClearResolution()
    begin
        Rec."Item No." := '';
        Rec."Variant Code" := '';
        Rec."Location Code" := '';
        Rec."Quantity per" := 0;
        Rec."Quantity (Base)" := 0;
        Rec.Action := Rec.Action::" ";
        Rec."Reason Code" := '';
    end;
}
