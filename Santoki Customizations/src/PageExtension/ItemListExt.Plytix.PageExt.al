pageextension 50202 "Item List Ext. Plytix" extends "Item List"
{
    layout
    {
        addafter(Description)
        {
            field("Exclude from Plytix"; Rec."Exclude from Plytix")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that this item is excluded from the Plytix product feed. Enabled items are filtered out of the BC -> Celigo -> Plytix integration.';
                Visible = false;
            }
        }
    }
}
