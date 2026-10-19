// Maps the SKU an Amazon order arrives under to the item that is actually stocked.
//
// Amazon orders can arrive as KE123, KE123H or KE123HEC for what is physically one product, with
// stock held under only one of them. The business maintains this table; a SKU with no mapping is
// matched to an item of the same number, and anything still unmatched is left as an error with
// the reason, never dropped.
table 50218 "Amazon SKU Mapping"
{
    Caption = 'Amazon SKU Mapping';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon SKU Mappings";
    DrillDownPageId = "Amazon SKU Mappings";

    fields
    {
        field(1; "Seller SKU"; Code[50])
        {
            Caption = 'Seller SKU';
            NotBlank = true;
            ToolTip = 'Specifies the SKU as it appears on Amazon orders.';
        }
        field(2; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            TableRelation = "Amazon Marketplace Setup";
            ToolTip = 'Specifies the marketplace this mapping applies to. Leave blank to apply it to every marketplace.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            ToolTip = 'Specifies the Business Central item to sell.';

            trigger OnValidate()
            begin
                if Rec."Item No." <> xRec."Item No." then
                    Rec."Variant Code" := '';
            end;
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ToolTip = 'Specifies the item variant to sell, if any.';
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
            ToolTip = 'Specifies a location to ship from instead of the marketplace default.';
        }
        field(6; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            MinValue = 0.00001;
            ToolTip = 'Specifies how many Business Central units make up one Amazon unit, for example 3 for a three-pack.';
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that orders for this SKU should stop with an error instead of being created.';
        }
    }

    keys
    {
        key(PK; "Seller SKU", "Marketplace Id") { Clustered = true; }
        key(Item; "Item No.") { }
    }
}
