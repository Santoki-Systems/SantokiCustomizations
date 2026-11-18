tableextension 50205 "Item Category Freight Santoki" extends "Item Category"
{
    fields
    {
        // Defaults for items in this category (or its child categories) that have no NMFC No. or Freight Class of their own.
        field(50200; "Santoki NMFC No."; Code[20])
        {
            Caption = 'NMFC No.';
            DataClassification = CustomerContent;
        }
        field(50201; "Santoki Freight Class"; Code[10])
        {
            Caption = 'Freight Class';
            DataClassification = CustomerContent;
        }
    }
}
