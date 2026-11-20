tableextension 50204 "Item Freight Ext. Santoki" extends Item
{
    fields
    {
        // Freight classification for the bill of lading. Blank values fall back to the item category's.
        field(50202; "Santoki NMFC No."; Code[20])
        {
            Caption = 'NMFC No.';
            DataClassification = CustomerContent;
        }
        field(50203; "Santoki Freight Class"; Code[10])
        {
            Caption = 'Freight Class';
            DataClassification = CustomerContent;
        }
    }
}
