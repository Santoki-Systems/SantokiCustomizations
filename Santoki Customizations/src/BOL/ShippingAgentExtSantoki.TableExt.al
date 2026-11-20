tableextension 50203 "Shipping Agent Ext. Santoki" extends "Shipping Agent"
{
    fields
    {
        // Standard Carrier Alpha Code, printed on the bill of lading. BC has no SCAC field of its own.
        field(50200; "Santoki SCAC"; Code[4])
        {
            Caption = 'SCAC';
            DataClassification = CustomerContent;
        }
    }
}
