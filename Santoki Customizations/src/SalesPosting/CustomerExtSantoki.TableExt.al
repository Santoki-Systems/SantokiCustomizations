tableextension 50201 "Customer Ext. Santoki" extends Customer
{
    fields
    {
        // Walmart orders arrive from Shopify at whatever location Shopify picked (often ESHIP or AMZ),
        // but they always ship from WFS. Setting this on WALM001 lets BC correct the lines itself
        // instead of accounting fixing each invoice by hand.
        field(50200; "Forced Location Code"; Code[10])
        {
            Caption = 'Forced Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies a location that always replaces the location on this customer''s sales orders and invoices when they are released or posted. Leave it blank for normal behavior. Lines that are already shipped, reserved, on a warehouse document, drop shipped, special order, assembled to order or linked to a job are left as they are.';
        }
    }
}
