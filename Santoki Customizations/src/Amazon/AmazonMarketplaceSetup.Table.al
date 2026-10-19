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
    }

    keys
    {
        key(PK; "Marketplace Id") { Clustered = true; }
    }
}
