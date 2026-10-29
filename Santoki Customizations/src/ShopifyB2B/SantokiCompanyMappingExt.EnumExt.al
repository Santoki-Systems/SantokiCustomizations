// Adds "By External Id (Customer No.)" to the Company Mapping Type choices on the Shopify Shop card.
enumextension 50200 "Santoki Company Mapping Ext." extends "Shpfy Company Mapping"
{
    value(50200; "Santoki By External Id")
    {
        Caption = 'By External Id (Customer No.)';
        Implementation = "Shpfy ICompany Mapping" = "Santoki Comp. By External Id";
    }
}
