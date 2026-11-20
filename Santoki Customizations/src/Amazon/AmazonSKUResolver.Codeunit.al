// Turns an Amazon seller SKU into the Business Central item, variant, location and Quantity per,
// using the Amazon SKU Mapping and then an item with the same number. Returns use it now.
//
// It follows the same rules as ResolveLine in Amazon Order Processing (50228), less the check for
// items blocked for sales, which doesn't apply to stock coming back. Moving the order code onto
// this codeunit is a later, separate change, so the order path isn't touched in the returns build.
codeunit 50207 "Amazon SKU Resolver"
{
    var
        NoSkuMsg: Label 'The row has no SKU.';
        SkuBlockedMsg: Label 'SKU %1 is blocked in the Amazon SKU mappings.', Comment = '%1 = seller SKU';
        NoMatchMsg: Label 'SKU %1 does not match an item. Add it to the Amazon SKU mappings.', Comment = '%1 = seller SKU';
        ItemMissingMsg: Label 'SKU %1 is mapped to item %2, which does not exist.', Comment = '%1 = seller SKU, %2 = item no.';

    procedure Resolve(SellerSku: Code[50]; MarketplaceId: Code[20]; DefaultLocationCode: Code[10]; var ItemNo: Code[20]; var VariantCode: Code[10]; var LocationCode: Code[10]; var QuantityPer: Decimal; var Problem: Text): Boolean
    var
        Mapping: Record "Amazon SKU Mapping";
        Item: Record Item;
    begin
        ItemNo := '';
        VariantCode := '';
        LocationCode := DefaultLocationCode;
        QuantityPer := 1;
        Problem := '';

        if SellerSku = '' then begin
            Problem := NoSkuMsg;
            exit(false);
        end;

        if FindMapping(SellerSku, MarketplaceId, Mapping) then begin
            if Mapping.Blocked then begin
                Problem := StrSubstNo(SkuBlockedMsg, SellerSku);
                exit(false);
            end;
            ItemNo := Mapping."Item No.";
            VariantCode := Mapping."Variant Code";
            if Mapping."Location Code" <> '' then
                LocationCode := Mapping."Location Code";
            if Mapping."Quantity per" > 0 then
                QuantityPer := Mapping."Quantity per";
        end else
            // No mapping: fall back to an item with the same number as the SKU.
            if StrLen(SellerSku) <= MaxStrLen(Item."No.") then
                if Item.Get(CopyStr(SellerSku, 1, MaxStrLen(Item."No."))) then
                    ItemNo := Item."No.";

        if ItemNo = '' then begin
            Problem := StrSubstNo(NoMatchMsg, SellerSku);
            exit(false);
        end;
        if not Item.Get(ItemNo) then begin
            Problem := StrSubstNo(ItemMissingMsg, SellerSku, ItemNo);
            exit(false);
        end;
        exit(true);
    end;

    procedure FindMapping(SellerSku: Code[50]; MarketplaceId: Code[20]; var Mapping: Record "Amazon SKU Mapping"): Boolean
    begin
        if Mapping.Get(SellerSku, MarketplaceId) then
            exit(true);
        exit(Mapping.Get(SellerSku, ''));
    end;
}
