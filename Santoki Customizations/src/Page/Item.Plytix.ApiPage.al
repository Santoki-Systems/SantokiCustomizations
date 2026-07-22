// Flat, one-row-per-item feed for the BC -> Celigo -> Plytix product sync.
//
// The unit-of-measure dimensions and the item attribute values both live in child tables
// (one row per item per UoM, one row per item per attribute). Plytix wants a single flat
// product record, so they are pivoted onto columns here rather than joined in Celigo --
// that keeps the integration to one export and one import with no extra API calls.
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
                field(number; Rec."No.") { Caption = 'Number'; }
                field(commonItemNo; Rec."Common Item No.") { Caption = 'Common Item No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure") { Caption = 'Base Unit of Measure'; }
                field(gtin; Rec.GTIN) { Caption = 'GTIN'; }
                field(itemCategoryCode; Rec."Item Category Code") { Caption = 'Item Category Code'; }
                field(tariffNo; Rec."Tariff No.") { Caption = 'Tariff No.'; }
                field(countryRegionOfOriginCode; Rec."Country/Region of Origin Code") { Caption = 'Country/Region of Origin Code'; }
                field(unitPrice; Rec."Unit Price") { Caption = 'Unit Price'; }
                field(excludeFromPlytix; Rec."Exclude from Plytix") { Caption = 'Exclude from Plytix'; }

                // --- Unit of measure dimensions, flattened from "Item Unit of Measure" ---
                field(eaQty; EAQty) { Caption = 'EA Qty per Unit of Measure'; Editable = false; }
                field(eaHeight; EAHeight) { Caption = 'EA Height'; Editable = false; }
                field(eaWidth; EAWidth) { Caption = 'EA Width'; Editable = false; }
                field(eaLength; EALength) { Caption = 'EA Length'; Editable = false; }
                field(eaCubage; EACubage) { Caption = 'EA Cubage'; Editable = false; }
                field(eaWeight; EAWeight) { Caption = 'EA Weight'; Editable = false; }

                field(innerQty; InnerQty) { Caption = 'Inner Qty per Unit of Measure'; Editable = false; }
                field(innerHeight; InnerHeight) { Caption = 'Inner Height'; Editable = false; }
                field(innerWidth; InnerWidth) { Caption = 'Inner Width'; Editable = false; }
                field(innerLength; InnerLength) { Caption = 'Inner Length'; Editable = false; }
                field(innerCubage; InnerCubage) { Caption = 'Inner Cubage'; Editable = false; }
                field(innerWeight; InnerWeight) { Caption = 'Inner Weight'; Editable = false; }

                field(masterQty; MasterQty) { Caption = 'Master Qty per Unit of Measure'; Editable = false; }
                field(masterHeight; MasterHeight) { Caption = 'Master Height'; Editable = false; }
                field(masterWidth; MasterWidth) { Caption = 'Master Width'; Editable = false; }
                field(masterLength; MasterLength) { Caption = 'Master Length'; Editable = false; }
                field(masterCubage; MasterCubage) { Caption = 'Master Cubage'; Editable = false; }
                field(masterWeight; MasterWeight) { Caption = 'Master Weight'; Editable = false; }

                // --- Item attribute values, flattened from "Item Attribute Value" ---
                field(itemCategory; ItemCategoryValue) { Caption = 'Item Category'; Editable = false; }
                field(itemSubCategory; ItemSubCategoryValue) { Caption = 'Item Sub Category'; Editable = false; }
                field(itemProperty; ItemPropertyValue) { Caption = 'Item Property'; Editable = false; }
                field(itemStatus; ItemStatusValue) { Caption = 'Item Status'; Editable = false; }
                field(masterPackGtin; MasterPackGtinValue) { Caption = 'Master Pack GTIN'; Editable = false; }
                field(innerPackGtin; InnerPackGtinValue) { Caption = 'Inner Pack GTIN'; Editable = false; }
                field(amazonAsin; AmazonAsinValue) { Caption = 'Amazon ASIN'; Editable = false; }
                field(brand; BrandValue) { Caption = 'Brand'; Editable = false; }
                field(launchDate; LaunchDateValue) { Caption = 'Launch Date'; Editable = false; }

                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
            }
        }
    }

    var
        EAQty, EAHeight, EAWidth, EALength, EACubage, EAWeight : Decimal;
        InnerQty, InnerHeight, InnerWidth, InnerLength, InnerCubage, InnerWeight : Decimal;
        MasterQty, MasterHeight, MasterWidth, MasterLength, MasterCubage, MasterWeight : Decimal;
        ItemCategoryValue, ItemSubCategoryValue, ItemPropertyValue, ItemStatusValue : Text[250];
        MasterPackGtinValue, InnerPackGtinValue, AmazonAsinValue, BrandValue, LaunchDateValue : Text[250];
        // Unit of measure codes as they exist in Santoki's BC data.
        EACodeLbl: Label 'EA', Locked = true;
        InnerCodeLbl: Label 'INNER', Locked = true;
        MasterCodeLbl: Label 'MASTER', Locked = true;
        // Item attribute names as they are spelled in BC. These must match exactly --
        // renaming an attribute in BC will silently stop it flowing to Plytix.
        ItemCategoryAttrLbl: Label 'Item Category', Locked = true;
        ItemSubCategoryAttrLbl: Label 'Item Sub Category', Locked = true;
        ItemPropertyAttrLbl: Label 'Item Property', Locked = true;
        ItemStatusAttrLbl: Label 'Item Status', Locked = true;
        MasterPackGtinAttrLbl: Label 'Master Pack GTIN', Locked = true;
        InnerPackGtinAttrLbl: Label 'Inner Pack GTIN', Locked = true;
        AmazonAsinAttrLbl: Label 'Amazon ASIN', Locked = true;
        BrandAttrLbl: Label 'Brand', Locked = true;
        LaunchDateAttrLbl: Label 'Launch Date (MM-YYYY)', Locked = true;

    trigger OnAfterGetRecord()
    begin
        // Buffers must be cleared first -- otherwise an item without, say, an INNER unit of
        // measure would inherit the previous item's values.
        ClearPlytixBuffers();
        LoadUnitOfMeasureDimensions();
        LoadItemAttributes();
    end;

    local procedure ClearPlytixBuffers()
    begin
        EAQty := 0;
        EAHeight := 0;
        EAWidth := 0;
        EALength := 0;
        EACubage := 0;
        EAWeight := 0;

        InnerQty := 0;
        InnerHeight := 0;
        InnerWidth := 0;
        InnerLength := 0;
        InnerCubage := 0;
        InnerWeight := 0;

        MasterQty := 0;
        MasterHeight := 0;
        MasterWidth := 0;
        MasterLength := 0;
        MasterCubage := 0;
        MasterWeight := 0;

        ItemCategoryValue := '';
        ItemSubCategoryValue := '';
        ItemPropertyValue := '';
        ItemStatusValue := '';
        MasterPackGtinValue := '';
        InnerPackGtinValue := '';
        AmazonAsinValue := '';
        BrandValue := '';
        LaunchDateValue := '';
    end;

    local procedure LoadUnitOfMeasureDimensions()
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        if ItemUoM.Get(Rec."No.", EACodeLbl) then begin
            EAQty := ItemUoM."Qty. per Unit of Measure";
            EAHeight := ItemUoM.Height;
            EAWidth := ItemUoM.Width;
            EALength := ItemUoM.Length;
            EACubage := ItemUoM.Cubage;
            EAWeight := ItemUoM.Weight;
        end;

        if ItemUoM.Get(Rec."No.", InnerCodeLbl) then begin
            InnerQty := ItemUoM."Qty. per Unit of Measure";
            InnerHeight := ItemUoM.Height;
            InnerWidth := ItemUoM.Width;
            InnerLength := ItemUoM.Length;
            InnerCubage := ItemUoM.Cubage;
            InnerWeight := ItemUoM.Weight;
        end;

        if ItemUoM.Get(Rec."No.", MasterCodeLbl) then begin
            MasterQty := ItemUoM."Qty. per Unit of Measure";
            MasterHeight := ItemUoM.Height;
            MasterWidth := ItemUoM.Width;
            MasterLength := ItemUoM.Length;
            MasterCubage := ItemUoM.Cubage;
            MasterWeight := ItemUoM.Weight;
        end;
    end;

    local procedure LoadItemAttributes()
    var
        ValueMapping: Record "Item Attribute Value Mapping";
        AttributeValue: Record "Item Attribute Value";
        ItemAttribute: Record "Item Attribute";
    begin
        ValueMapping.SetRange("Table ID", Database::Item);
        ValueMapping.SetRange("No.", Rec."No.");
        if not ValueMapping.FindSet() then
            exit;

        repeat
            if AttributeValue.Get(ValueMapping."Item Attribute ID", ValueMapping."Item Attribute Value ID") then
                // Blocked values are retired in BC and should not be published to Plytix.
                if not AttributeValue.Blocked then
                    if ItemAttribute.Get(AttributeValue."Attribute ID") then
                        AssignAttribute(ItemAttribute.Name, AttributeValue.Value);
        until ValueMapping.Next() = 0;
    end;

    local procedure AssignAttribute(AttributeName: Text[250]; AttributeText: Text[250])
    begin
        case true of
            AttributeName = ItemCategoryAttrLbl:
                ItemCategoryValue := AttributeText;
            AttributeName = ItemSubCategoryAttrLbl:
                ItemSubCategoryValue := AttributeText;
            AttributeName = ItemPropertyAttrLbl:
                ItemPropertyValue := AttributeText;
            AttributeName = ItemStatusAttrLbl:
                ItemStatusValue := AttributeText;
            AttributeName = MasterPackGtinAttrLbl:
                MasterPackGtinValue := AttributeText;
            AttributeName = InnerPackGtinAttrLbl:
                InnerPackGtinValue := AttributeText;
            AttributeName = AmazonAsinAttrLbl:
                AmazonAsinValue := AttributeText;
            AttributeName = BrandAttrLbl:
                BrandValue := AttributeText;
            AttributeName = LaunchDateAttrLbl:
                LaunchDateValue := AttributeText;
        end;
    end;
}
