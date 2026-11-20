// The one endpoint Celigo posts Amazon reports to. Returns now; settlements later.
//
// POST .../api/santoki/amazon/v1.0/companies({id})/reportDeliveries
// { "reportType": "Returns", "marketplaceId": "ATVPDKIKX0DER", "amazonReportId": "...",
//   "payload": "[ { \"return-date\": \"...\", \"order-id\": \"...\", \"sku\": \"...\", ... } ]" }
//
// The payload is the report's rows as a JSON array (as a string, like orderDeliveries), keyed by
// Amazon's column names. Leave customer-comments out of the Celigo mapping. Every POST is stored
// as a new delivery and nothing else happens in the call, so it returns quickly and never fails
// because of report content. The returns job reads deliveries afterwards.
page 50200 "Amazon Report Deliveries API"
{
    PageType = API;
    Caption = 'Amazon Report Deliveries';
    APIPublisher = 'santoki';
    APIGroup = 'amazon';
    APIVersion = 'v1.0';
    EntityName = 'reportDelivery';
    EntitySetName = 'reportDeliveries';
    SourceTable = "Amazon Report Inbox";
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
                field(reportType; Rec."Report Type") { Caption = 'Report Type'; }
                field(marketplaceId; Rec."Marketplace Id") { Caption = 'Marketplace Id'; }
                field(amazonReportId; Rec."Amazon Report Id") { Caption = 'Amazon Report Id'; }
                field(payload; PayloadText) { Caption = 'Payload'; }
                field(receivedAt; Rec."Received At") { Caption = 'Received At'; Editable = false; }
                field(processed; Rec.Processed) { Caption = 'Processed'; Editable = false; }
                field(rowsRead; Rec."Rows Read") { Caption = 'Rows Read'; Editable = false; }
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
