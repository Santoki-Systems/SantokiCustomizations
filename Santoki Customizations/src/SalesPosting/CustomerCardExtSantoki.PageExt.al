pageextension 50203 "Customer Card Ext. Santoki" extends "Customer Card"
{
    layout
    {
        addafter("Location Code")
        {
            field("Forced Location Code"; Rec."Forced Location Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a location that always replaces the location on this customer''s sales orders and invoices when they are released or posted. Leave it blank for normal behavior. Lines that are already shipped, reserved, on a warehouse document, drop shipped, special order, assembled to order or linked to a job are left as they are.';
            }
        }
    }
}
