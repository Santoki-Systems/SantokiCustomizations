// Returns all item attribute values (Master/Inner GTIN, Item Category, Item Sub Category,
// Item Property, etc.) as one row per item per attribute. Celigo filters/maps by attributeName.
query 50212 "Item Attr Value API Plytix"
{
    QueryType = API;
    Caption = 'Item Attribute Values (Plytix)';
    APIPublisher = 'santoki';
    APIGroup = 'plytix';
    APIVersion = 'v1.0';
    EntityName = 'itemAttributeValue';
    EntitySetName = 'itemAttributeValues';

    elements
    {
        dataitem(mapping; "Item Attribute Value Mapping")
        {
            DataItemTableFilter = "Table ID" = const(27); // 27 = Item
            column(itemNo; "No.") { }

            dataitem(attrValue; "Item Attribute Value")
            {
                DataItemLink = "Attribute ID" = mapping."Item Attribute ID", ID = mapping."Item Attribute Value ID";
                SqlJoinType = InnerJoin;
                column(value; Value) { }
                column(numericValue; "Numeric Value") { }
                column(blocked; Blocked) { }

                dataitem(attribute; "Item Attribute")
                {
                    DataItemLink = ID = attrValue."Attribute ID";
                    SqlJoinType = InnerJoin;
                    column(attributeName; Name) { }
                    column(attributeType; Type) { }
                    column(unitOfMeasure; "Unit of Measure") { }
                }
            }
        }
    }
}
