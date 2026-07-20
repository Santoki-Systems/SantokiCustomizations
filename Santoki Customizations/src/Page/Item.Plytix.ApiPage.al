page 50211 "Item API Plytix"
{
    PageType = API;
    Caption = 'Items (Plytix)';
    APIPublisher = 'santoki';
    APIGroup = 'plytix';
    APIVersion = 'v1.0';
    EntityName = 'item';
    EntitySetName = 'items';
    SourceTable = Item;
    ODataKeyFields = SystemId;
    Editable = false;
    Extensible = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(commonItemNo; Rec."Common Item No.") { Caption = 'Common Item No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure") { Caption = 'Base Unit of Measure'; }
                field(gtin; Rec.GTIN) { Caption = 'GTIN'; }
                field(itemCategoryCode; Rec."Item Category Code") { Caption = 'Item Category Code'; }
                field(tariffNo; Rec."Tariff No.") { Caption = 'Tariff No.'; }
                field(countryRegionOfOriginCode; Rec."Country/Region of Origin Code") { Caption = 'Country/Region of Origin Code'; }
                field(unitPrice; Rec."Unit Price") { Caption = 'Unit Price'; }
                field(excludeFromPlytix; Rec."Exclude from Plytix") { Caption = 'Exclude from Plytix'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
            }
        }
    }
}
