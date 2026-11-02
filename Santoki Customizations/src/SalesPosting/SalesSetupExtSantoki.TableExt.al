tableextension 50202 "Sales Setup Ext. Santoki" extends "Sales & Receivables Setup"
{
    fields
    {
        // Off by default. Finance turns it on once they are happy with the behavior.
        field(50200; "Move Closed-Period Dates"; Boolean)
        {
            Caption = 'Move Closed-Period Posting Dates';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that a sales order or invoice dated before the allowed posting period is posted on the first allowed date instead of failing. Dates inside the allowed period are never changed, and dates after it still fail as normal. The allowed period comes from the user''s User Setup, or from General Ledger Setup when the user has none.';
        }
    }
}
