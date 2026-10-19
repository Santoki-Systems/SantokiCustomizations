// Takes one staged Amazon order a step further.
//
// Received:    check the order can become a sales order. Problems the team can fix (an unmapped
//              SKU, missing setup) put the order in Error with the reason; orders Amazon has not
//              finalised, or that belong to the previous system, go On Hold. Otherwise Ready.
// In Progress: create the sales order. The job sets In Progress and commits before calling this,
//              so a run that is interrupted part way leaves a visible order, never a silent retry.
//
// Notes for go-live:
// - The Amazon order number goes in External Document No., and the duplicate check looks there.
//   Suite Engine leaves that field blank and uses its own AMZ order numbers (checked 17 Sep 2026),
//   so the check only catches orders this integration created. Orders Suite Engine handled are
//   kept out by each marketplace's Process Orders From date instead.
// - The Amazon customers are not tax liable, and Amazon collects and pays marketplace tax, so tax
//   is not added to the sales order.
// - Both Amazon customers currently have no currency, so Canada posts in US dollars. Confirm with
//   Finance before setting a currency on the Canada marketplace.
// - Posting (shipping and invoicing) is not done here yet. That is a later stage.
codeunit 50228 "Amazon Order Processing"
{
    TableNo = "Amazon Staged Order";

    trigger OnRun()
    begin
        case Rec.Status of
            Rec.Status::Received:
                ValidateOrder(Rec);
            Rec.Status::"In Progress":
                CreateSalesOrder(Rec);
        end;
    end;

    var
        NoSetupErr: Label 'There is no Amazon Marketplace Setup for marketplace %1.', Comment = '%1 = marketplace id';
        NoCustomerErr: Label 'Marketplace %1 has no customer set up.', Comment = '%1 = marketplace id';
        NoLinesErr: Label 'The order has no items.';
        UnexpectedStatusErr: Label 'Amazon reports the order as %1, which is not handled.', Comment = '%1 = Amazon order status';
        AlreadyExistsErr: Label 'This Amazon order already exists in Business Central as %1.', Comment = '%1 = document no.';
        PendingMsg: Label 'Waiting for Amazon to finalise the order.';
        DisabledMsg: Label 'Marketplace %1 is not enabled, so the order is being held.', Comment = '%1 = marketplace id';
        BeforeGoLiveMsg: Label 'Placed before this marketplace went live on the new integration, so it belongs to the previous system.';
        NoSkuMsg: Label 'The order item has no SKU.';
        SkuBlockedMsg: Label 'SKU %1 is blocked in the Amazon SKU mappings.', Comment = '%1 = seller SKU';
        NoMatchMsg: Label 'SKU %1 does not match an item. Add it to the Amazon SKU mappings.', Comment = '%1 = seller SKU';
        ItemMissingMsg: Label 'SKU %1 is mapped to item %2, which does not exist.', Comment = '%1 = seller SKU, %2 = item no.';
        ItemBlockedMsg: Label 'Item %1 is blocked for sales.', Comment = '%1 = item no.';
        NoShippingAccountMsg: Label 'The order has a shipping charge but marketplace %1 has no shipping G/L account.', Comment = '%1 = marketplace id';
        LineProblemTxt: Label 'SKU %1: %2', Comment = '%1 = seller SKU, %2 = problem';
        ShippingDescriptionTxt: Label 'Amazon shipping';

    local procedure ValidateOrder(var StagedOrder: Record "Amazon Staged Order")
    var
        Setup: Record "Amazon Marketplace Setup";
        StagedLine: Record "Amazon Staged Order Line";
        Problems: TextBuilder;
        ExistingDocumentNo: Code[20];
        HasShipping: Boolean;
    begin
        if not Setup.Get(StagedOrder."Marketplace Id") then begin
            SetError(StagedOrder, StrSubstNo(NoSetupErr, StagedOrder."Marketplace Id"));
            exit;
        end;

        if StagedOrder."Amazon Order Status" = 'Pending' then begin
            SetOnHold(StagedOrder, PendingMsg);
            exit;
        end;
        if StagedOrder."Amazon Order Status" = 'Canceled' then begin
            StagedOrder.Status := StagedOrder.Status::Cancelled;
            StagedOrder."Status Message" := '';
            StagedOrder.Modify(true);
            exit;
        end;
        if not IsFinalisedStatus(StagedOrder."Amazon Order Status") then begin
            SetError(StagedOrder, StrSubstNo(UnexpectedStatusErr, StagedOrder."Amazon Order Status"));
            exit;
        end;

        if (Setup."Process Orders From" <> 0DT) and (StagedOrder."Purchase Date" < Setup."Process Orders From") then begin
            SetOnHold(StagedOrder, BeforeGoLiveMsg);
            exit;
        end;
        if not Setup.Enabled then begin
            SetOnHold(StagedOrder, StrSubstNo(DisabledMsg, Setup."Marketplace Id"));
            exit;
        end;
        if Setup."Customer No." = '' then begin
            SetError(StagedOrder, StrSubstNo(NoCustomerErr, Setup."Marketplace Id"));
            exit;
        end;

        ExistingDocumentNo := FindExistingDocument(Setup."Customer No.", StagedOrder."Amazon Order Id");
        if ExistingDocumentNo <> '' then begin
            SetError(StagedOrder, StrSubstNo(AlreadyExistsErr, ExistingDocumentNo));
            exit;
        end;

        StagedLine.SetRange("Amazon Order Id", StagedOrder."Amazon Order Id");
        if not StagedLine.FindSet(true) then begin
            SetError(StagedOrder, NoLinesErr);
            exit;
        end;
        repeat
            if not ResolveLine(StagedLine, Setup) then
                Problems.AppendLine(StrSubstNo(LineProblemTxt, StagedLine."Seller SKU", StagedLine."Line Message"));
            if (StagedLine."Shipping Price" - StagedLine."Shipping Discount") <> 0 then
                HasShipping := true;
            StagedLine.Modify(true);
        until StagedLine.Next() = 0;

        if HasShipping and (Setup."Shipping G/L Account No." = '') then
            Problems.AppendLine(StrSubstNo(NoShippingAccountMsg, Setup."Marketplace Id"));

        if Problems.Length() > 0 then begin
            SetError(StagedOrder, Problems.ToText());
            exit;
        end;

        StagedOrder.Status := StagedOrder.Status::Ready;
        StagedOrder."Status Message" := '';
        StagedOrder.Modify(true);
    end;

    // Amazon order statuses that mean the order is real, priced and addressed.
    local procedure IsFinalisedStatus(AmazonOrderStatus: Text): Boolean
    begin
        exit(AmazonOrderStatus in ['Unshipped', 'PartiallyShipped', 'Shipped', 'InvoiceUnconfirmed']);
    end;

    local procedure ResolveLine(var StagedLine: Record "Amazon Staged Order Line"; Setup: Record "Amazon Marketplace Setup"): Boolean
    var
        Mapping: Record "Amazon SKU Mapping";
        Item: Record Item;
    begin
        StagedLine."Line Message" := '';
        StagedLine."Item No." := '';
        StagedLine."Variant Code" := '';
        StagedLine."Location Code" := Setup."Location Code";
        StagedLine."Quantity per" := 1;

        if StagedLine."Seller SKU" = '' then
            exit(SetLineProblem(StagedLine, NoSkuMsg));

        if FindMapping(StagedLine."Seller SKU", Setup."Marketplace Id", Mapping) then begin
            if Mapping.Blocked then
                exit(SetLineProblem(StagedLine, StrSubstNo(SkuBlockedMsg, StagedLine."Seller SKU")));
            StagedLine."Item No." := Mapping."Item No.";
            StagedLine."Variant Code" := Mapping."Variant Code";
            if Mapping."Location Code" <> '' then
                StagedLine."Location Code" := Mapping."Location Code";
            if Mapping."Quantity per" > 0 then
                StagedLine."Quantity per" := Mapping."Quantity per";
        end else
            // No mapping: fall back to an item with the same number as the SKU.
            if StrLen(StagedLine."Seller SKU") <= MaxStrLen(Item."No.") then
                if Item.Get(CopyStr(StagedLine."Seller SKU", 1, MaxStrLen(Item."No."))) then
                    StagedLine."Item No." := Item."No.";

        if StagedLine."Item No." = '' then
            exit(SetLineProblem(StagedLine, StrSubstNo(NoMatchMsg, StagedLine."Seller SKU")));
        if not Item.Get(StagedLine."Item No.") then
            exit(SetLineProblem(StagedLine, StrSubstNo(ItemMissingMsg, StagedLine."Seller SKU", StagedLine."Item No.")));
        if Item.Blocked or Item."Sales Blocked" then
            exit(SetLineProblem(StagedLine, StrSubstNo(ItemBlockedMsg, Item."No.")));

        exit(true);
    end;

    local procedure FindMapping(SellerSku: Code[50]; MarketplaceId: Code[20]; var Mapping: Record "Amazon SKU Mapping"): Boolean
    begin
        if Mapping.Get(SellerSku, MarketplaceId) then
            exit(true);
        exit(Mapping.Get(SellerSku, ''));
    end;

    local procedure SetLineProblem(var StagedLine: Record "Amazon Staged Order Line"; Problem: Text): Boolean
    begin
        StagedLine."Line Message" := CopyStr(Problem, 1, MaxStrLen(StagedLine."Line Message"));
        exit(false);
    end;

    local procedure FindExistingDocument(CustomerNo: Code[20]; AmazonOrderId: Code[30]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("External Document No.", AmazonOrderId);
        if SalesHeader.FindFirst() then
            exit(SalesHeader."No.");

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("External Document No.", AmazonOrderId);
        if SalesInvoiceHeader.FindFirst() then
            exit(SalesInvoiceHeader."No.");

        exit('');
    end;

    local procedure CreateSalesOrder(var StagedOrder: Record "Amazon Staged Order")
    var
        Setup: Record "Amazon Marketplace Setup";
        SalesHeader: Record "Sales Header";
        StagedLine: Record "Amazon Staged Order Line";
        ExistingDocumentNo: Code[20];
        ShippingTotal: Decimal;
        LineNo: Integer;
    begin
        Setup.Get(StagedOrder."Marketplace Id");
        Setup.TestField("Customer No.");

        // Checked again here: another run, or someone keying by hand, may have created it since.
        ExistingDocumentNo := FindExistingDocument(Setup."Customer No.", StagedOrder."Amazon Order Id");
        if ExistingDocumentNo <> '' then
            Error(AlreadyExistsErr, ExistingDocumentNo);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Setup."Customer No.");
        if StagedOrder."Purchase Date" <> 0DT then
            SalesHeader.Validate("Order Date", DT2Date(StagedOrder."Purchase Date"));
        SalesHeader.Validate("External Document No.", CopyStr(StagedOrder."Amazon Order Id", 1, MaxStrLen(SalesHeader."External Document No.")));
        if (Setup."Currency Code" <> '') and (SalesHeader."Currency Code" <> Setup."Currency Code") then
            SalesHeader.Validate("Currency Code", Setup."Currency Code");
        if Setup."Location Code" <> '' then
            SalesHeader.Validate("Location Code", Setup."Location Code");
        CopyShipTo(SalesHeader, StagedOrder);
        SalesHeader.Modify(true);

        StagedLine.SetRange("Amazon Order Id", StagedOrder."Amazon Order Id");
        StagedLine.SetFilter("Quantity Ordered", '>0');
        if StagedLine.FindSet() then
            repeat
                LineNo += 10000;
                AddItemLine(SalesHeader, StagedLine, LineNo);
                ShippingTotal += StagedLine."Shipping Price" - StagedLine."Shipping Discount";
            until StagedLine.Next() = 0;

        if ShippingTotal <> 0 then begin
            LineNo += 10000;
            AddShippingLine(SalesHeader, Setup, ShippingTotal, LineNo);
        end;

        StagedOrder."Sales Order No." := SalesHeader."No.";
        StagedOrder.Status := StagedOrder.Status::Posted;
        StagedOrder."Status Message" := '';
        StagedOrder."Processed At" := CurrentDateTime();
        StagedOrder.Modify(true);
    end;

    // Delivery details are copied as Amazon sent them, without the post code lookups a Validate
    // would trigger. When Amazon has not released an address, the customer's own ship-to is kept.
    local procedure CopyShipTo(var SalesHeader: Record "Sales Header"; StagedOrder: Record "Amazon Staged Order")
    begin
        if StagedOrder."Ship-to Name" = '' then
            exit;
        SalesHeader."Ship-to Code" := '';
        SalesHeader."Ship-to Name" := StagedOrder."Ship-to Name";
        SalesHeader."Ship-to Address" := StagedOrder."Ship-to Address";
        SalesHeader."Ship-to Address 2" := StagedOrder."Ship-to Address 2";
        SalesHeader."Ship-to City" := StagedOrder."Ship-to City";
        SalesHeader."Ship-to County" := StagedOrder."Ship-to County";
        SalesHeader."Ship-to Post Code" := StagedOrder."Ship-to Post Code";
        SalesHeader."Ship-to Country/Region Code" := StagedOrder."Ship-to Country Code";
    end;

    local procedure AddItemLine(SalesHeader: Record "Sales Header"; StagedLine: Record "Amazon Staged Order Line"; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        Quantity := StagedLine."Quantity Ordered" * StagedLine."Quantity per";

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", StagedLine."Item No.");
        if StagedLine."Variant Code" <> '' then
            SalesLine.Validate("Variant Code", StagedLine."Variant Code");
        if StagedLine."Location Code" <> '' then
            SalesLine.Validate("Location Code", StagedLine."Location Code");
        SalesLine.Validate(Quantity, Quantity);
        // Amazon's item price covers the whole quantity ordered, not one unit.
        SalesLine.Validate("Unit Price", Round(StagedLine."Item Price" / Quantity, 0.00001));
        if StagedLine."Promotion Discount" <> 0 then
            SalesLine.Validate("Line Discount Amount", StagedLine."Promotion Discount");
        SalesLine.Insert(true);
    end;

    local procedure AddShippingLine(SalesHeader: Record "Sales Header"; Setup: Record "Amazon Marketplace Setup"; ShippingTotal: Decimal; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        Setup.TestField("Shipping G/L Account No.");

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", Setup."Shipping G/L Account No.");
        SalesLine.Description := ShippingDescriptionTxt;
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", ShippingTotal);
        SalesLine.Insert(true);
    end;

    local procedure SetError(var StagedOrder: Record "Amazon Staged Order"; Problem: Text)
    begin
        StagedOrder.Status := StagedOrder.Status::Error;
        StagedOrder."Status Message" := CopyStr(Problem, 1, MaxStrLen(StagedOrder."Status Message"));
        StagedOrder.Modify(true);
    end;

    local procedure SetOnHold(var StagedOrder: Record "Amazon Staged Order"; Reason: Text)
    begin
        StagedOrder.Status := StagedOrder.Status::"On Hold";
        StagedOrder."Status Message" := CopyStr(Reason, 1, MaxStrLen(StagedOrder."Status Message"));
        StagedOrder.Modify(true);
    end;
}
