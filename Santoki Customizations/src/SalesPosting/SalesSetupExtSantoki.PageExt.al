pageextension 50204 "Sales Setup Ext. Santoki" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("Posting Date Check on Posting")
        {
            field("Move Closed-Period Dates"; Rec."Move Closed-Period Dates")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that a sales order or invoice dated before the allowed posting period is posted on the first allowed date instead of failing. Dates inside the allowed period are never changed, and dates after it still fail as normal. The allowed period comes from the user''s User Setup, or from General Ledger Setup when the user has none.';
            }
        }
    }
}
