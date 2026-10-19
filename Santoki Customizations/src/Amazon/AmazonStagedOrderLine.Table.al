// One item on a staged Amazon order.
//
// Keyed on Amazon's own OrderItemId rather than a line number, so a redelivered order updates the
// lines it already has instead of adding a second copy of them.
table 50216 "Amazon Staged Order Line"
{
    Caption = 'Amazon Staged Order Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Amazon Order Id"; Code[30])
        {
            Caption = 'Amazon Order Id';
            TableRelation = "Amazon Staged Order";
            ToolTip = 'Specifies the Amazon order number.';
        }
        field(2; "Order Item Id"; Code[30])
        {
            Caption = 'Order Item Id';
            ToolTip = 'Specifies Amazon''s identifier for this item on the order.';
        }
        field(3; ASIN; Code[20])
        {
            Caption = 'ASIN';
            ToolTip = 'Specifies the Amazon product identifier.';
        }
        field(4; "Seller SKU"; Code[50])
        {
            Caption = 'Seller SKU';
            ToolTip = 'Specifies the SKU the order was placed under on Amazon.';
        }
        field(5; Title; Text[250])
        {
            Caption = 'Title';
            ToolTip = 'Specifies the product title on Amazon.';
        }
        field(6; "Quantity Ordered"; Decimal)
        {
            Caption = 'Quantity Ordered';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity the customer ordered, in Amazon units.';
        }
        field(7; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity Amazon reports as shipped.';
        }
        field(8; "Item Price"; Decimal)
        {
            Caption = 'Item Price';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the price for the full quantity ordered, as Amazon reports it.';
        }
        field(9; "Item Tax"; Decimal)
        {
            Caption = 'Item Tax';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the tax Amazon collected on the item.';
        }
        field(10; "Shipping Price"; Decimal)
        {
            Caption = 'Shipping Price';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the shipping the customer paid for this item.';
        }
        field(11; "Shipping Tax"; Decimal)
        {
            Caption = 'Shipping Tax';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the tax Amazon collected on shipping.';
        }
        field(12; "Shipping Discount"; Decimal)
        {
            Caption = 'Shipping Discount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies any discount applied to shipping.';
        }
        field(13; "Promotion Discount"; Decimal)
        {
            Caption = 'Promotion Discount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies any promotional discount applied to the item.';
        }
        field(14; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency of the amounts.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            ToolTip = 'Specifies the Business Central item the SKU was matched to.';
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ToolTip = 'Specifies the item variant the SKU was matched to, if any.';
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies the location the item ships from.';
        }
        field(23; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            ToolTip = 'Specifies how many Business Central units make up one Amazon unit, for example 3 for a three-pack sold under one SKU.';
        }
        field(24; "Line Message"; Text[250])
        {
            Caption = 'Line Message';
            ToolTip = 'Specifies why this line could not be matched.';
        }
    }

    keys
    {
        key(PK; "Amazon Order Id", "Order Item Id") { Clustered = true; }
        key(SKU; "Seller SKU") { }
    }
}
