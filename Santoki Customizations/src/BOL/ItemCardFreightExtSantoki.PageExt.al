pageextension 50206 "Item Card Freight Ext. Santoki" extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group(SantokiFreight)
            {
                Caption = 'Freight Classification';

                field("Santoki NMFC No."; Rec."Santoki NMFC No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item''s NMFC number, printed on the bill of lading. If it''s blank, the item category''s NMFC number is used.';
                }
                field("Santoki Freight Class"; Rec."Santoki Freight Class")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item''s LTL freight class (for example 55 or 85), printed on the bill of lading. If it''s blank, the item category''s freight class is used.';
                }
            }
        }
    }
}
