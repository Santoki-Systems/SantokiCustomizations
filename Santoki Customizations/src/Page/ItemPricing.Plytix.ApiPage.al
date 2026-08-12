// Narrow, WRITABLE endpoint for maintaining MSRP in bulk.
//
// Deliberately separate from page 50211 rather than making that page editable. 50211 carries
// unit price, GTIN, tariff, country of origin and the whole flattened UoM/attribute set --
// making it writable would expose all of it to the integration user. This page exposes the
// item number and MSRP and nothing else, so a bulk price load cannot touch anything it should
// not. Add fields here only if they genuinely need to be written from outside.
//
// Read path is unchanged: MSRP is also exposed read-only on 50211 so the existing Plytix feed
// picks it up without a second call.
page 50213 "Item Pricing API Plytix"
{
    PageType = API;
    Caption = 'Item Pricing (Plytix)';
    APIPublisher = 'santoki';
    APIGroup = 'plytix';
    APIVersion = 'v1.0';
    EntityName = 'itemPricing';
    EntitySetName = 'itemPricing';
    SourceTable = Item;
    ODataKeyFields = SystemId;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    Extensible = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(no; Rec."No.") { Caption = 'No.'; Editable = false; }
                field(number; Rec."No.") { Caption = 'Number'; Editable = false; }
                field(description; Rec.Description) { Caption = 'Description'; Editable = false; }
                field(msrp; Rec.MSRP) { Caption = 'MSRP'; }
            }
        }
    }
}
