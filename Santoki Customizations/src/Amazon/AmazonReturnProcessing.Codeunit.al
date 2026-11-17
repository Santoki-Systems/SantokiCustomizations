// Checks one received return and decides what Business Central does with it.
//
// Ready:    the SKU resolved, a disposition rule says to move stock, and the location is known.
//           The posting run picks it up.
// On Hold:  returns aren't switched on for the marketplace yet, or Amazon hasn't finished with the
//           unit (for example Pending repackaging). A later delivery checks it again.
// Ignored:  processed by Amazon before returns went live (the monthly manual document covers it),
//           or the rule says no stock movement (Amazon-damaged or reimbursed units).
// Error:    something the team can fix: no setup, no rule for the disposition, an unmapped SKU,
//           no unsellable location. The reason is in the status message; nothing is thrown.
codeunit 50204 "Amazon Return Processing"
{
    TableNo = "Amazon Inventory Event";

    trigger OnRun()
    begin
        if Rec.Status = Rec.Status::Received then
            CheckEvent(Rec);
    end;

    var
        NoSetupMsg: Label 'There is no Amazon Marketplace Setup for marketplace %1.', Comment = '%1 = marketplace id';
        NotLiveMsg: Label 'Returns are not switched on for marketplace %1: Process Returns From is blank.', Comment = '%1 = marketplace id';
        NoReturnDateMsg: Label 'The return has no return date, so it can''t be placed before or after go-live.';
        BeforeGoLiveMsg: Label 'Processed by Amazon on %1, before returns went live on %2. The monthly manual document covers it.', Comment = '%1 = return date, %2 = go-live date';
        NoQuantityMsg: Label 'The return has no quantity.';
        NoRuleMsg: Label 'No return disposition rule for disposition %1 with status %2. Add one in Amazon Return Dispositions, then Reprocess.', Comment = '%1 = detailed disposition, %2 = Amazon status';
        NoActionMsg: Label 'The return disposition rule for %1 / %2 has no action.', Comment = '%1 = detailed disposition, %2 = Amazon status';
        HoldMsg: Label 'On hold (%1 / %2): %3', Comment = '%1 = detailed disposition, %2 = Amazon status, %3 = rule description';
        NoMovementMsg: Label 'No stock movement (%1 / %2): %3', Comment = '%1 = detailed disposition, %2 = Amazon status, %3 = rule description';
        ItemBlockedMsg: Label 'Item %1 is blocked.', Comment = '%1 = item no.';
        NoUnsellableLocationMsg: Label 'Marketplace %1 has no unsellable location set up, so the unsellable unit has nowhere to go.', Comment = '%1 = marketplace id';
        NoLocationMsg: Label 'No location to post the return to. Set a location on marketplace %1.', Comment = '%1 = marketplace id';

    local procedure CheckEvent(var InventoryEvent: Record "Amazon Inventory Event")
    var
        Setup: Record "Amazon Marketplace Setup";
        Rule: Record "Amazon Return Disposition";
        Item: Record Item;
        SkuResolver: Codeunit "Amazon SKU Resolver";
        Problem: Text;
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        QuantityPer: Decimal;
    begin
        InventoryEvent.ClearResolution();

        if not Setup.Get(InventoryEvent."Marketplace Id") then begin
            SetError(InventoryEvent, StrSubstNo(NoSetupMsg, InventoryEvent."Marketplace Id"));
            exit;
        end;
        if Setup."Process Returns From" = 0D then begin
            SetOnHold(InventoryEvent, StrSubstNo(NotLiveMsg, Setup."Marketplace Id"));
            exit;
        end;
        if InventoryEvent."Return Date" = 0DT then begin
            SetError(InventoryEvent, NoReturnDateMsg);
            exit;
        end;
        if DT2Date(InventoryEvent."Return Date") < Setup."Process Returns From" then begin
            SetIgnored(InventoryEvent, StrSubstNo(BeforeGoLiveMsg, DT2Date(InventoryEvent."Return Date"), Setup."Process Returns From"));
            exit;
        end;
        if InventoryEvent.Quantity <= 0 then begin
            SetError(InventoryEvent, NoQuantityMsg);
            exit;
        end;

        if not Rule.FindRule(InventoryEvent."Detailed Disposition", InventoryEvent."Amazon Status") then begin
            SetError(InventoryEvent, StrSubstNo(NoRuleMsg, InventoryEvent."Detailed Disposition", InventoryEvent."Amazon Status"));
            exit;
        end;
        InventoryEvent.Action := Rule.Action;
        InventoryEvent."Reason Code" := Rule."Reason Code";
        case Rule.Action of
            Rule.Action::" ":
                begin
                    SetError(InventoryEvent, StrSubstNo(NoActionMsg, Rule."Detailed Disposition", Rule."Amazon Status"));
                    exit;
                end;
            Rule.Action::Hold:
                begin
                    SetOnHold(InventoryEvent, StrSubstNo(HoldMsg, InventoryEvent."Detailed Disposition", InventoryEvent."Amazon Status", Rule.Description));
                    exit;
                end;
            Rule.Action::"No Movement":
                begin
                    SetIgnored(InventoryEvent, StrSubstNo(NoMovementMsg, InventoryEvent."Detailed Disposition", InventoryEvent."Amazon Status", Rule.Description));
                    exit;
                end;
        end;

        if not SkuResolver.Resolve(InventoryEvent."Seller SKU", Setup."Marketplace Id", Setup."Location Code", ItemNo, VariantCode, LocationCode, QuantityPer, Problem) then begin
            SetError(InventoryEvent, Problem);
            exit;
        end;
        Item.Get(ItemNo);
        if Item.Blocked then begin
            SetError(InventoryEvent, StrSubstNo(ItemBlockedMsg, ItemNo));
            exit;
        end;

        case Rule.Action of
            Rule.Action::"Add to Stock", Rule.Action::"Add and Write Off":
                if Rule."Location Code" <> '' then
                    LocationCode := Rule."Location Code";
            Rule.Action::"Move to Unsellable":
                begin
                    LocationCode := Rule."Location Code";
                    if LocationCode = '' then
                        LocationCode := Setup."Unsellable Location Code";
                    if LocationCode = '' then begin
                        SetError(InventoryEvent, StrSubstNo(NoUnsellableLocationMsg, Setup."Marketplace Id"));
                        exit;
                    end;
                end;
        end;
        if LocationCode = '' then begin
            SetError(InventoryEvent, StrSubstNo(NoLocationMsg, Setup."Marketplace Id"));
            exit;
        end;

        InventoryEvent."Item No." := ItemNo;
        InventoryEvent."Variant Code" := VariantCode;
        InventoryEvent."Location Code" := LocationCode;
        InventoryEvent."Quantity per" := QuantityPer;
        InventoryEvent."Quantity (Base)" := Round(InventoryEvent.Quantity * QuantityPer, 0.00001);
        InventoryEvent.Status := InventoryEvent.Status::Ready;
        InventoryEvent."Status Message" := '';
        InventoryEvent.Modify(true);
    end;

    local procedure SetError(var InventoryEvent: Record "Amazon Inventory Event"; Problem: Text)
    begin
        InventoryEvent.Status := InventoryEvent.Status::Error;
        InventoryEvent."Status Message" := CopyStr(Problem, 1, MaxStrLen(InventoryEvent."Status Message"));
        InventoryEvent.Modify(true);
    end;

    local procedure SetOnHold(var InventoryEvent: Record "Amazon Inventory Event"; Reason: Text)
    begin
        InventoryEvent.Status := InventoryEvent.Status::"On Hold";
        InventoryEvent."Status Message" := CopyStr(Reason, 1, MaxStrLen(InventoryEvent."Status Message"));
        InventoryEvent.Modify(true);
    end;

    local procedure SetIgnored(var InventoryEvent: Record "Amazon Inventory Event"; Reason: Text)
    begin
        InventoryEvent.Status := InventoryEvent.Status::Ignored;
        InventoryEvent."Status Message" := CopyStr(Reason, 1, MaxStrLen(InventoryEvent."Status Message"));
        InventoryEvent.Modify(true);
    end;
}
