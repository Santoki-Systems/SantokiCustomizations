// One row per Amazon marketplace: which customer its orders post to, where they ship from, and
// which clearing account its money settles through.
//
// Each marketplace has its own clearing account so each can be reconciled to the statement Amazon
// actually produces. Each also has its own go-live date, because the reserve accounts close on
// different days and switch over one at a time.
table 50217 "Amazon Marketplace Setup"
{
    Caption = 'Amazon Marketplace Setup';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Marketplace Setup";
    DrillDownPageId = "Amazon Marketplace Setup";

    fields
    {
        field(1; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            NotBlank = true;
            ToolTip = 'Specifies Amazon''s marketplace identifier, for example ATVPDKIKX0DER for the US.';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a name for the marketplace, such as Amazon US.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies whether orders from this marketplace become sales orders. While this is off, orders are received and held, which is how the side-by-side run works.';
        }
        field(4; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the customer that orders from this marketplace are created for.';
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies the default location orders ship from, for example AMZ or AMZ CANADA.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the currency this marketplace settles in. Leave blank for US dollars.';
        }
        field(7; "Clearing G/L Account No."; Code[20])
        {
            Caption = 'Clearing G/L Account No.';
            TableRelation = "G/L Account";
            ToolTip = 'Specifies the account this marketplace''s sales clear to until Amazon settles them.';
        }
        field(8; "Shipping G/L Account No."; Code[20])
        {
            Caption = 'Shipping G/L Account No.';
            TableRelation = "G/L Account";
            ToolTip = 'Specifies the account shipping charged to the customer is posted to.';
        }
        field(9; "Process Orders From"; DateTime)
        {
            Caption = 'Process Orders From';
            ToolTip = 'Specifies the go-live point for this marketplace. Orders placed before it stay with the previous system and are held here, not created again.';
        }
        // Returns go live on their own date, separate from orders, so returns can run while
        // Suite Engine still handles orders.
        field(10; "Process Returns From"; Date)
        {
            Caption = 'Process Returns From';
            ToolTip = 'Specifies the go-live date for customer returns on this marketplace. Returns processed by Amazon before it belong to the monthly manual document and are ignored. Leave blank to hold every return.';
        }
        field(11; "Unsellable Location Code"; Code[10])
        {
            Caption = 'Unsellable Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies the location for returned units Amazon can''t sell (its unsellable inventory), so they never count as available stock.';
        }
        field(12; "Returns Jnl. Template Name"; Code[10])
        {
            Caption = 'Returns Jnl. Template Name';
            TableRelation = "Item Journal Template".Name where(Type = const(Item), Recurring = const(false));
            ToolTip = 'Specifies the item journal template returns are posted through.';

            trigger OnValidate()
            begin
                if Rec."Returns Jnl. Template Name" <> xRec."Returns Jnl. Template Name" then
                    Rec."Returns Jnl. Batch Name" := '';
            end;
        }
        field(13; "Returns Jnl. Batch Name"; Code[10])
        {
            Caption = 'Returns Jnl. Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Returns Jnl. Template Name"));
            ToolTip = 'Specifies the item journal batch returns are posted through. Use a batch kept for Amazon returns, with no No. Series. When returns post automatically, each run expects it to be empty.';
        }
        field(14; "Return Cost Rule"; Enum "Amazon Return Cost Rule")
        {
            Caption = 'Return Cost Rule';
            ToolTip = 'Specifies the cost returned units come back at: the item''s current unit cost, or zero.';
        }
        field(15; "Post Returns Automatically"; Boolean)
        {
            Caption = 'Post Returns Automatically';
            ToolTip = 'Specifies whether each run posts the returns journal. While this is off, the journal is built and left in the batch for review, which is how the side-by-side run works.';
        }
    }

    keys
    {
        key(PK; "Marketplace Id") { Clustered = true; }
    }
}
