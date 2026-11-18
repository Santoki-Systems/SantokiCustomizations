enum 50220 "Santoki BOL Freight Terms"
{
    Extensible = false;
    Caption = 'BOL Freight Terms';

    value(0; Prepaid)
    {
        Caption = 'Prepaid (PPD)';
    }
    value(1; Collect)
    {
        Caption = 'Collect (COLL)';
    }
    value(2; "Third Party")
    {
        Caption = 'Third Party (3P)';
    }
}
