// Lets the fee mappings be loaded and maintained in bulk, for example from Suite Engine's mapping
// once finance has checked it.
//
// GET/POST/PATCH/DELETE .../api/santoki/amazon/v1.0/companies({id})/feeMappings
// { "transactionType": "ORDER", "amountType": "ItemFees", "amountDescription": "Commission", "glAccountNo": "5909" }
//
// A blank marketplace id applies the mapping to every marketplace, as on the Amazon Fee Mappings page.
page 50205 "Amazon Fee Mapping API"
{
    PageType = API;
    Caption = 'Amazon Fee Mappings';
    APIPublisher = 'santoki';
    APIGroup = 'amazon';
    APIVersion = 'v1.0';
    EntityName = 'feeMapping';
    EntitySetName = 'feeMappings';
    SourceTable = "Amazon Fee Mapping";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(marketplaceId; Rec."Marketplace Id") { Caption = 'Marketplace Id'; }
                field(transactionType; Rec."Transaction Type") { Caption = 'Transaction Type'; }
                field(amountType; Rec."Amount Type") { Caption = 'Amount Type'; }
                field(amountDescription; Rec."Amount Description") { Caption = 'Amount Description'; }
                field(glAccountNo; Rec."G/L Account No.") { Caption = 'G/L Account No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(ignore; Rec.Ignore) { Caption = 'Ignore'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time'; Editable = false; }
            }
        }
    }
}
