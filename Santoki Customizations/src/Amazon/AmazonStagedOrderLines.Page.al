page 50223 "Amazon Staged Order Lines"
{
    PageType = ListPart;
    Caption = 'Amazon Order Items';
    ApplicationArea = All;
    SourceTable = "Amazon Staged Order Line";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Items)
            {
                field("Seller SKU"; Rec."Seller SKU") { }
                field(ASIN; Rec.ASIN) { Visible = false; }
                field(Title; Rec.Title) { }
                field("Quantity Ordered"; Rec."Quantity Ordered") { }
                field("Quantity Shipped"; Rec."Quantity Shipped") { }
                field("Item Price"; Rec."Item Price") { }
                field("Promotion Discount"; Rec."Promotion Discount") { }
                field("Shipping Price"; Rec."Shipping Price") { }
                field("Item Tax"; Rec."Item Tax") { Visible = false; }
                field("Item No."; Rec."Item No.") { }
                field("Variant Code"; Rec."Variant Code") { Visible = false; }
                field("Location Code"; Rec."Location Code") { }
                field("Quantity per"; Rec."Quantity per") { }
                field("Line Message"; Rec."Line Message") { Style = Unfavorable; }
                field("Order Item Id"; Rec."Order Item Id") { Visible = false; }
            }
        }
    }
}
