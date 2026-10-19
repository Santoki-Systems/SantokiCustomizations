// The one endpoint Celigo posts Amazon orders to.
//
// POST .../api/santoki/amazon/v1.0/companies({id})/orderDeliveries
// { "amazonOrderId": "...", "marketplaceId": "...", "payload": "<order JSON with OrderItems>" }
//
// Every POST is stored as a new delivery and nothing else happens in the call, so it returns
// quickly and never fails because of order content. The job reads deliveries afterwards.
page 50220 "Amazon Order Inbox API"
{
    PageType = API;
    Caption = 'Amazon Order Deliveries';
    APIPublisher = 'santoki';
    APIGroup = 'amazon';
    APIVersion = 'v1.0';
    EntityName = 'orderDelivery';
    EntitySetName = 'orderDeliveries';
    SourceTable = "Amazon Order Inbox";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(entryNo; Rec."Entry No.") { Caption = 'Entry No.'; Editable = false; }
                field(amazonOrderId; Rec."Amazon Order Id") { Caption = 'Amazon Order Id'; }
                field(marketplaceId; Rec."Marketplace Id") { Caption = 'Marketplace Id'; }
                field(payload; PayloadText) { Caption = 'Payload'; }
                field(receivedAt; Rec."Received At") { Caption = 'Received At'; Editable = false; }
                field(processed; Rec.Processed) { Caption = 'Processed'; Editable = false; }
                field(errorMessage; Rec."Error Message") { Caption = 'Error Message'; Editable = false; }
            }
        }
    }

    var
        PayloadText: Text;
        EmptyPayloadErr: Label 'The delivery has no payload.';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if PayloadText = '' then
            Error(EmptyPayloadErr);
        Rec."Received At" := CurrentDateTime();
        Rec.SetPayload(PayloadText);
        exit(true);
    end;
}
