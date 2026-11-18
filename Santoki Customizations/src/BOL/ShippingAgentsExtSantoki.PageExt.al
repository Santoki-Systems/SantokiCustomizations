pageextension 50205 "Shipping Agents Ext. Santoki" extends "Shipping Agents"
{
    layout
    {
        addafter(Name)
        {
            field("Santoki SCAC"; Rec."Santoki SCAC")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the carrier''s Standard Carrier Alpha Code (2 to 4 letters). It prints on the bill of lading and master bill of lading.';
            }
        }
    }
}
