tableextension 50200 "Item Ext. Plytix" extends Item
{
    fields
    {
        field(50200; "Exclude from Plytix"; Boolean)
        {
            Caption = 'Exclude from Plytix';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that this item is excluded from the Plytix product feed. Enabled items are filtered out of the BC -> Celigo -> Plytix integration.';
        }
    }
}
