// Adds "On Hand less Open Sales Orders" to the Stock Calculation choices on Shopify Locations.
// Set it on the SANTOKIB2B shop's eShip location only. The D2C shop keeps its own setting.
enumextension 50201 "Santoki Stock Calculation Ext." extends "Shpfy Stock Calculation"
{
    value(50200; "Santoki On Hand Less Orders")
    {
        Caption = 'On Hand less Open Sales Orders';
        Implementation = "Shpfy Stock Calculation" = "Santoki On Hand Less Orders",
                         "Shpfy IStock Available" = "Shpfy Can Have Stock";
    }
}
