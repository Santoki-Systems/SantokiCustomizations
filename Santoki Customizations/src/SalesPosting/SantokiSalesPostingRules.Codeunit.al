// Two small sales posting rules agreed with Santoki in October 2026:
//
// 1. Forced location. When a customer has a Forced Location Code, that location replaces the one
//    on its order and invoice lines. Set on WALM001 = WFS, because Shopify imports most Walmart
//    orders at ESHIP or AMZ and accounting was correcting each one by hand.
//
// 2. Closed-period posting dates. With the Sales & Receivables Setup switch on, an order or invoice
//    dated before the allowed posting period posts on the first allowed date instead of failing.
//
// Both hook into base-app events only, so they work whichever app created the order.
codeunit 50200 "Santoki Sales Posting Rules"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    // Release raises this only for documents that are not released yet. It covers Shopify's
    // auto-release straight after import, so draft invoices already show the forced location.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeReleaseSalesDoc', '', false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ApplyForcedLocation(SalesHeader);
    end;

    // Sales-Post raises this before it copies the lines and before it checks the posting date, so
    // whatever is changed here is what gets posted. It also catches documents released before the
    // rule existed. When posting later releases the document, the release hook finds nothing to do.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        MoveClosedPeriodPostingDate(SalesHeader);
        ApplyForcedLocation(SalesHeader);
    end;

    local procedure ApplyForcedLocation(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ForcedLocationCode: Code[10];
        SavedHideValidationDialog: Boolean;
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;
        if SalesHeader."Sell-to Customer No." = '' then
            exit;

        Customer.SetLoadFields("Forced Location Code");
        if not Customer.Get(SalesHeader."Sell-to Customer No.") then
            exit;
        ForcedLocationCode := Customer."Forced Location Code";
        if ForcedLocationCode = '' then
            exit;

        // The document may already be released (Shopify releases on import), so suspend the
        // status check rather than reopening it. Hide dialogs so nothing pops up mid-posting.
        SavedHideValidationDialog := SalesHeader.GetHideValidationDialog();
        SalesHeader.SetHideValidationDialog(true);

        if SalesHeader."Location Code" <> ForcedLocationCode then begin
            SalesHeader.SuspendStatusCheck(true);
            SalesHeader.Validate("Location Code", ForcedLocationCode);
            SalesHeader.Modify();
            SalesHeader.SuspendStatusCheck(false);
        end;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        if SalesLine.FindSet(true) then
            repeat
                if (SalesLine."Location Code" <> ForcedLocationCode) and CanMoveLine(SalesLine) then begin
                    SalesLine.SuspendStatusCheck(true);
                    SalesLine.SetHideValidationDialog(true);
                    SalesLine.Validate("Location Code", ForcedLocationCode);
                    SalesLine.Modify(true);
                end;
            until SalesLine.Next() = 0;

        SalesHeader.SetHideValidationDialog(SavedHideValidationDialog);
    end;

    // Leaves a line alone when moving it would fail validation or split it from stock or warehouse
    // work that already sits at the old location.
    local procedure CanMoveLine(var SalesLine: Record "Sales Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if SalesLine."Drop Shipment" or SalesLine."Special Order" then
            exit(false);
        if SalesLine."Job No." <> '' then
            exit(false);
        if (SalesLine."Quantity Shipped" <> 0) or (SalesLine."Shipment No." <> '') then
            exit(false);
        if SalesLine."Qty. to Asm. to Order (Base)" <> 0 then
            exit(false);

        SalesLine.CalcFields("Reserved Qty. (Base)");
        if SalesLine."Reserved Qty. (Base)" <> 0 then
            exit(false);

        WarehouseShipmentLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
        WarehouseShipmentLine.SetRange("Source Line No.", SalesLine."Line No.");
        if not WarehouseShipmentLine.IsEmpty() then
            exit(false);

        WarehouseActivityLine.SetRange("Source Type", Database::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        WarehouseActivityLine.SetRange("Source Line No.", SalesLine."Line No.");
        if not WarehouseActivityLine.IsEmpty() then
            exit(false);

        exit(true);
    end;

    local procedure MoveClosedPeriodPostingDate(var SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        FirstAllowedDate: Date;
        SavedHideValidationDialog: Boolean;
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;
        if SalesHeader."Posting Date" = 0D then
            exit;

        SalesSetup.SetLoadFields("Move Closed-Period Dates");
        if not SalesSetup.Get() then
            exit;
        if not SalesSetup."Move Closed-Period Dates" then
            exit;

        // Posting periods set per journal template are a different setup. Leave those to the
        // standard check rather than guess.
        GLSetup.SetLoadFields("Journal Templ. Name Mandatory");
        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            exit;

        // A date in the allowed period is never touched.
        if UserSetupManagement.IsPostingDateValid(SalesHeader."Posting Date") then
            exit;

        // Only move dates that are too early. A date after the allowed period still fails as normal.
        FirstAllowedDate := GetAllowPostingFrom();
        if (FirstAllowedDate = 0D) or (SalesHeader."Posting Date" >= FirstAllowedDate) then
            exit;
        if not UserSetupManagement.IsPostingDateValid(FirstAllowedDate) then
            exit;

        SavedHideValidationDialog := SalesHeader.GetHideValidationDialog();
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", FirstAllowedDate);
        SalesHeader.Modify();
        SalesHeader.SetHideValidationDialog(SavedHideValidationDialog);
    end;

    // Same order as the standard check in User Setup Management: the user's own range wins,
    // otherwise the General Ledger Setup range. Date formulas are resolved the same way.
    local procedure GetAllowPostingFrom(): Date
    var
        UserSetup: Record "User Setup";
        GLSetup: Record "General Ledger Setup";
        UserSetupManagement: Codeunit "User Setup Management";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
    begin
        if UserId() <> '' then
            if UserSetup.Get(UserId()) then begin
                AllowPostingFrom := UserSetup."Allow Posting From";
                AllowPostingTo := UserSetup."Allow Posting To";
                UserSetupManagement.GetDateRange(
                    AllowPostingFrom, AllowPostingTo,
                    UserSetup."Allow Posting From DateFormula", UserSetup."Allow Posting To DateFormula",
                    UserSetup.RecordId());
            end;

        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            GLSetup.Get();
            AllowPostingFrom := GLSetup."Allow Posting From";
            AllowPostingTo := GLSetup."Allow Posting To";
            UserSetupManagement.GetDateRange(
                AllowPostingFrom, AllowPostingTo,
                GLSetup."Allow Posting From DateFormula", GLSetup."Allow Posting To DateFormula",
                GLSetup.RecordId());
        end;

        exit(AllowPostingFrom);
    end;
}
