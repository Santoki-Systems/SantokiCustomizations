// Lets the SKU mappings be loaded and maintained in bulk, rather than typed in one at a time.
//
// GET/POST/PATCH/DELETE .../api/santoki/amazon/v1.0/companies({id})/skuMappings
// { "sellerSku": "51736FBA", "marketplaceId": "", "itemNo": "51736", "quantityPer": 1 }
//
// A blank marketplace id applies the mapping to every marketplace, as on the Amazon SKU Mappings page.
page 50204 "Amazon SKU Mapping API"
{
    PageType = API;
    Caption = 'Amazon SKU Mappings';
    APIPublisher = 'santoki';
    APIGroup = 'amazon';
    APIVersion = 'v1.0';
    EntityName = 'skuMapping';
    EntitySetName = 'skuMappings';
    SourceTable = "Amazon SKU Mapping";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(sellerSku; Rec."Seller SKU") { Caption = 'Seller SKU'; }
                field(marketplaceId; Rec."Marketplace Id") { Caption = 'Marketplace Id'; }
                field(itemNo; Rec."Item No.") { Caption = 'Item No.'; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(quantityPer; Rec."Quantity per") { Caption = 'Quantity per'; }
                field(blocked; Rec.Blocked) { Caption = 'Blocked'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
            }
        }
    }
}
