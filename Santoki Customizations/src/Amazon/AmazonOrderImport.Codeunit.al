// Reads one inbox delivery into a staged order and its lines.
//
// The delivery is the Selling Partner API order object with its order items attached as an
// "OrderItems" array, which is how Celigo is asked to send it. Field names follow the Orders API.
//
// Rules:
// - A delivery older than what is already staged is ignored, so late redeliveries can't roll an
//   order back.
// - An order that already has a sales order only has its Amazon status refreshed. If Amazon has
//   since cancelled it, the order is put in error for someone to review, because a sales order
//   exists for it.
// - Any other existing order is overwritten and sent back through validation.
codeunit 50227 "Amazon Order Import"
{
    TableNo = "Amazon Order Inbox";

    trigger OnRun()
    var
        OrderJson: JsonObject;
    begin
        if not OrderJson.ReadFrom(Rec.GetPayload()) then
            Error(InvalidPayloadErr);
        ImportOrder(OrderJson, Rec);
    end;

    var
        InvalidPayloadErr: Label 'The delivery is not a valid JSON order.';
        MissingOrderIdErr: Label 'The delivery has no AmazonOrderId.';
        MissingOrderItemIdErr: Label 'An order item on Amazon order %1 has no OrderItemId.', Comment = '%1 = Amazon order id';
        CancelledAfterOrderMsg: Label 'Amazon cancelled this order after sales order %1 was created. Review the sales order.', Comment = '%1 = sales order no.';

    local procedure ImportOrder(OrderJson: JsonObject; var Inbox: Record "Amazon Order Inbox")
    var
        StagedOrder: Record "Amazon Staged Order";
        AmazonOrderId: Code[30];
        LastUpdate: DateTime;
        IsNew: Boolean;
    begin
        AmazonOrderId := CopyStr(GetText(OrderJson, 'AmazonOrderId'), 1, MaxStrLen(AmazonOrderId));
        if AmazonOrderId = '' then
            Error(MissingOrderIdErr);
        LastUpdate := GetDateTime(OrderJson, 'LastUpdateDate');

        IsNew := not StagedOrder.Get(AmazonOrderId);
        if not IsNew then begin
            // A redelivery that is older than what we already hold changes nothing.
            if (LastUpdate <> 0DT) and (StagedOrder."Last Update Date" <> 0DT) and (LastUpdate < StagedOrder."Last Update Date") then
                exit;

            if StagedOrder."Sales Order No." <> '' then begin
                RefreshAmazonStatus(StagedOrder, OrderJson, Inbox);
                exit;
            end;
        end;

        if IsNew then begin
            StagedOrder.Init();
            StagedOrder."Amazon Order Id" := AmazonOrderId;
            StagedOrder."Received At" := CurrentDateTime();
        end;

        CopyHeader(StagedOrder, OrderJson);
        StagedOrder."Inbox Entry No." := Inbox."Entry No.";
        StagedOrder.SetPayload(Inbox.GetPayload());
        StagedOrder.Status := StagedOrder.Status::Received;
        StagedOrder."Status Message" := '';

        if IsNew then
            StagedOrder.Insert(true)
        else
            StagedOrder.Modify(true);

        ReplaceLines(StagedOrder, OrderJson);

        if Inbox."Amazon Order Id" = '' then
            Inbox."Amazon Order Id" := AmazonOrderId;
        if Inbox."Marketplace Id" = '' then
            Inbox."Marketplace Id" := StagedOrder."Marketplace Id";
        Inbox.Modify();
    end;

    local procedure RefreshAmazonStatus(var StagedOrder: Record "Amazon Staged Order"; OrderJson: JsonObject; Inbox: Record "Amazon Order Inbox")
    begin
        StagedOrder."Amazon Order Status" := CopyStr(GetText(OrderJson, 'OrderStatus'), 1, MaxStrLen(StagedOrder."Amazon Order Status"));
        StagedOrder."Last Update Date" := GetDateTime(OrderJson, 'LastUpdateDate');
        StagedOrder."Inbox Entry No." := Inbox."Entry No.";
        if StagedOrder."Amazon Order Status" = 'Canceled' then begin
            StagedOrder.Status := StagedOrder.Status::Error;
            StagedOrder."Status Message" := StrSubstNo(CancelledAfterOrderMsg, StagedOrder."Sales Order No.");
        end;
        StagedOrder.Modify(true);
    end;

    local procedure CopyHeader(var StagedOrder: Record "Amazon Staged Order"; OrderJson: JsonObject)
    var
        AddressJson: JsonObject;
        BuyerJson: JsonObject;
        CurrencyCode: Code[10];
    begin
        StagedOrder."Marketplace Id" := CopyStr(GetText(OrderJson, 'MarketplaceId'), 1, MaxStrLen(StagedOrder."Marketplace Id"));
        StagedOrder."Amazon Order Status" := CopyStr(GetText(OrderJson, 'OrderStatus'), 1, MaxStrLen(StagedOrder."Amazon Order Status"));
        StagedOrder."Fulfillment Channel" := CopyStr(GetText(OrderJson, 'FulfillmentChannel'), 1, MaxStrLen(StagedOrder."Fulfillment Channel"));
        StagedOrder."Sales Channel" := CopyStr(GetText(OrderJson, 'SalesChannel'), 1, MaxStrLen(StagedOrder."Sales Channel"));
        StagedOrder."Purchase Date" := GetDateTime(OrderJson, 'PurchaseDate');
        StagedOrder."Last Update Date" := GetDateTime(OrderJson, 'LastUpdateDate');
        StagedOrder."Order Total" := GetMoney(OrderJson, 'OrderTotal', CurrencyCode);
        StagedOrder."Currency Code" := CurrencyCode;
        StagedOrder."Is Business Order" := GetBoolean(OrderJson, 'IsBusinessOrder');
        StagedOrder."Is Prime" := GetBoolean(OrderJson, 'IsPrime');
        StagedOrder."Ship Service Level" := CopyStr(GetText(OrderJson, 'ShipServiceLevel'), 1, MaxStrLen(StagedOrder."Ship Service Level"));

        // Address and buyer details are restricted data. They are absent until the order is
        // finalised and until Celigo is authorised to request them, so blanks are expected.
        if GetObject(OrderJson, 'ShippingAddress', AddressJson) then begin
            StagedOrder."Ship-to Name" := CopyStr(GetText(AddressJson, 'Name'), 1, MaxStrLen(StagedOrder."Ship-to Name"));
            StagedOrder."Ship-to Address" := CopyStr(GetText(AddressJson, 'AddressLine1'), 1, MaxStrLen(StagedOrder."Ship-to Address"));
            StagedOrder."Ship-to Address 2" := CopyStr(JoinNonBlank(GetText(AddressJson, 'AddressLine2'), GetText(AddressJson, 'AddressLine3')), 1, MaxStrLen(StagedOrder."Ship-to Address 2"));
            StagedOrder."Ship-to City" := CopyStr(GetText(AddressJson, 'City'), 1, MaxStrLen(StagedOrder."Ship-to City"));
            StagedOrder."Ship-to County" := CopyStr(GetText(AddressJson, 'StateOrRegion'), 1, MaxStrLen(StagedOrder."Ship-to County"));
            StagedOrder."Ship-to Post Code" := CopyStr(GetText(AddressJson, 'PostalCode'), 1, MaxStrLen(StagedOrder."Ship-to Post Code"));
            StagedOrder."Ship-to Country Code" := CopyStr(GetText(AddressJson, 'CountryCode'), 1, MaxStrLen(StagedOrder."Ship-to Country Code"));
            StagedOrder."Ship-to Phone" := CopyStr(GetText(AddressJson, 'Phone'), 1, MaxStrLen(StagedOrder."Ship-to Phone"));
        end;
        if GetObject(OrderJson, 'BuyerInfo', BuyerJson) then
            StagedOrder."Buyer Email" := CopyStr(GetText(BuyerJson, 'BuyerEmail'), 1, MaxStrLen(StagedOrder."Buyer Email"));
    end;

    local procedure ReplaceLines(StagedOrder: Record "Amazon Staged Order"; OrderJson: JsonObject)
    var
        StagedLine: Record "Amazon Staged Order Line";
        ItemsToken: JsonToken;
        ItemToken: JsonToken;
        ItemsArray: JsonArray;
        ItemJson: JsonObject;
        Index: Integer;
    begin
        StagedLine.SetRange("Amazon Order Id", StagedOrder."Amazon Order Id");
        StagedLine.DeleteAll();

        if not OrderJson.Get('OrderItems', ItemsToken) then
            exit;
        if not ItemsToken.IsArray() then
            exit;
        ItemsArray := ItemsToken.AsArray();

        for Index := 0 to ItemsArray.Count() - 1 do begin
            ItemsArray.Get(Index, ItemToken);
            if ItemToken.IsObject() then begin
                ItemJson := ItemToken.AsObject();
                InsertLine(StagedOrder, ItemJson);
            end;
        end;
    end;

    local procedure InsertLine(StagedOrder: Record "Amazon Staged Order"; ItemJson: JsonObject)
    var
        StagedLine: Record "Amazon Staged Order Line";
        CurrencyCode: Code[10];
    begin
        StagedLine.Init();
        StagedLine."Amazon Order Id" := StagedOrder."Amazon Order Id";
        StagedLine."Order Item Id" := CopyStr(GetText(ItemJson, 'OrderItemId'), 1, MaxStrLen(StagedLine."Order Item Id"));
        if StagedLine."Order Item Id" = '' then
            Error(MissingOrderItemIdErr, StagedOrder."Amazon Order Id");
        StagedLine.ASIN := CopyStr(GetText(ItemJson, 'ASIN'), 1, MaxStrLen(StagedLine.ASIN));
        StagedLine."Seller SKU" := CopyStr(GetText(ItemJson, 'SellerSKU'), 1, MaxStrLen(StagedLine."Seller SKU"));
        StagedLine.Title := CopyStr(GetText(ItemJson, 'Title'), 1, MaxStrLen(StagedLine.Title));
        StagedLine."Quantity Ordered" := GetDecimal(ItemJson, 'QuantityOrdered');
        StagedLine."Quantity Shipped" := GetDecimal(ItemJson, 'QuantityShipped');
        StagedLine."Item Price" := GetMoney(ItemJson, 'ItemPrice', CurrencyCode);
        StagedLine."Item Tax" := GetMoney(ItemJson, 'ItemTax', CurrencyCode);
        StagedLine."Shipping Price" := GetMoney(ItemJson, 'ShippingPrice', CurrencyCode);
        StagedLine."Shipping Tax" := GetMoney(ItemJson, 'ShippingTax', CurrencyCode);
        StagedLine."Shipping Discount" := GetMoney(ItemJson, 'ShippingDiscount', CurrencyCode);
        StagedLine."Promotion Discount" := GetMoney(ItemJson, 'PromotionDiscount', CurrencyCode);
        if CurrencyCode = '' then
            CurrencyCode := StagedOrder."Currency Code";
        StagedLine."Currency Code" := CurrencyCode;
        StagedLine."Quantity per" := 1;
        StagedLine.Insert(true);
    end;

    // Returns a JSON value as text whether Amazon sent it as a string or a number.
    local procedure GetText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
        RawValue: Text;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        Token.WriteTo(RawValue);
        if CopyStr(RawValue, 1, 1) = '"' then
            exit(Token.AsValue().AsText());
        exit(RawValue);
    end;

    local procedure GetObject(JsonObj: JsonObject; PropertyName: Text; var Result: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsObject() then
            exit(false);
        Result := Token.AsObject();
        exit(true);
    end;

    local procedure GetDecimal(JsonObj: JsonObject; PropertyName: Text): Decimal
    var
        Value: Decimal;
        ValueText: Text;
    begin
        ValueText := GetText(JsonObj, PropertyName);
        if ValueText = '' then
            exit(0);
        if not Evaluate(Value, ValueText, 9) then
            exit(0);
        exit(Value);
    end;

    local procedure GetBoolean(JsonObj: JsonObject; PropertyName: Text): Boolean
    begin
        // GetText returns the raw literal for JSON booleans, and the text for "true" sent as a string.
        exit(LowerCase(GetText(JsonObj, PropertyName)) = 'true');
    end;

    local procedure GetDateTime(JsonObj: JsonObject; PropertyName: Text): DateTime
    var
        Value: DateTime;
        ValueText: Text;
    begin
        ValueText := GetText(JsonObj, PropertyName);
        if ValueText = '' then
            exit(0DT);
        if not Evaluate(Value, ValueText, 9) then
            exit(0DT);
        exit(Value);
    end;

    // Selling Partner API money is an object: { "CurrencyCode": "USD", "Amount": "12.99" }.
    local procedure GetMoney(JsonObj: JsonObject; PropertyName: Text; var CurrencyCode: Code[10]): Decimal
    var
        MoneyJson: JsonObject;
    begin
        if not GetObject(JsonObj, PropertyName, MoneyJson) then
            exit(0);
        if CurrencyCode = '' then
            CurrencyCode := CopyStr(GetText(MoneyJson, 'CurrencyCode'), 1, MaxStrLen(CurrencyCode));
        exit(GetDecimal(MoneyJson, 'Amount'));
    end;

    local procedure JoinNonBlank(First: Text; Second: Text): Text
    begin
        if Second = '' then
            exit(First);
        if First = '' then
            exit(Second);
        exit(First + ', ' + Second);
    end;
}
