page 50210 "Item UoM API Plytix"
{
    PageType = API;
    Caption = 'Item Units of Measure (Plytix)';
    APIPublisher = 'santoki';
    APIGroup = 'plytix';
    APIVersion = 'v1.0';
    EntityName = 'itemUnitOfMeasure';
    EntitySetName = 'itemUnitsOfMeasure';
    SourceTable = "Item Unit of Measure";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(itemNo; Rec."Item No.") { Caption = 'Item No.'; }
                field(code; Rec.Code) { Caption = 'Code'; }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure") { Caption = 'Qty per Unit of Measure'; }
                field(height; Rec.Height) { Caption = 'Height'; }
                field(width; Rec.Width) { Caption = 'Width'; }
                field(length; Rec.Length) { Caption = 'Length'; }
                field(cubage; Rec.Cubage) { Caption = 'Cubage'; }
                field(weight; Rec.Weight) { Caption = 'Weight'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
            }
        }
    }
}
