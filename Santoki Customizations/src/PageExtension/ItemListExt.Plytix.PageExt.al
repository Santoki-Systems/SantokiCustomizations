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

            // Hidden by default but available via Choose Columns -- makes it practical to spot
            // and fill gaps across the catalogue rather than item by item.
            field(MSRP; Rec.MSRP)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the manufacturer suggested retail price used on marketplace listings.';
                Visible = false;
            }
        }
    }
}
