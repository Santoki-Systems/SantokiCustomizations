// Maps each kind of line on an Amazon settlement report to the G/L account it posts to.
//
// A settlement line is identified by its transaction type, amount type and amount description,
// for example Order / ItemFees / Commission. Finance maintains this table; the settlement import
// (built in a later stage) summarises the report by these keys before posting.
table 50219 "Amazon Fee Mapping"
{
    Caption = 'Amazon Fee Mapping';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Fee Mappings";
    DrillDownPageId = "Amazon Fee Mappings";

    fields
    {
        field(1; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            TableRelation = "Amazon Marketplace Setup";
            ToolTip = 'Specifies the marketplace this mapping applies to. Leave blank to apply it to every marketplace.';
        }
        field(2; "Transaction Type"; Text[50])
        {
            Caption = 'Transaction Type';
            ToolTip = 'Specifies the transaction type on the settlement report, such as Order, Refund or ServiceFee.';
        }
        field(3; "Amount Type"; Text[50])
        {
            Caption = 'Amount Type';
            ToolTip = 'Specifies the amount type on the settlement report, such as ItemPrice or ItemFees.';
        }
        field(4; "Amount Description"; Text[100])
        {
            Caption = 'Amount Description';
            ToolTip = 'Specifies the amount description on the settlement report, such as Principal or Commission.';
        }
        field(5; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
            ToolTip = 'Specifies the account this kind of amount posts to.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a note about what this amount is.';
        }
        field(7; Ignore; Boolean)
        {
            Caption = 'Ignore';
            ToolTip = 'Specifies that this kind of amount is deliberately not posted, for example because it is already posted from the sales order.';
        }
    }

    keys
    {
        key(PK; "Marketplace Id", "Transaction Type", "Amount Type", "Amount Description") { Clustered = true; }
    }
}
