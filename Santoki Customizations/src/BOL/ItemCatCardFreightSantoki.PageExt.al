pageextension 50207 "Item Cat. Card Freight Santoki" extends "Item Category Card"
{
    layout
    {
        addafter("Parent Category")
        {
            field("Santoki NMFC No."; Rec."Santoki NMFC No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default NMFC number for items in this category (and its child categories) that have none of their own.';
            }
            field("Santoki Freight Class"; Rec."Santoki Freight Class")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default freight class for items in this category (and its child categories) that have none of their own.';
            }
        }
    }
}
