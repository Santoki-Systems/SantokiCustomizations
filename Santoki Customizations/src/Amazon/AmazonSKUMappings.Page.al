page 50225 "Amazon SKU Mappings"
{
    PageType = List;
    Caption = 'Amazon SKU Mappings';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Amazon SKU Mapping";

    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field("Seller SKU"; Rec."Seller SKU") { }
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field("Item No."; Rec."Item No.") { }
                field("Variant Code"; Rec."Variant Code") { }
                field("Location Code"; Rec."Location Code") { }
                field("Quantity per"; Rec."Quantity per") { }
                field(Blocked; Rec.Blocked) { }
            }
        }
    }
}
