tableextension 50200 "Item Ext. Plytix" extends Item
{
    fields
    {
        field(50200; "Exclude from Plytix"; Boolean)
        {
            Caption = 'Exclude from Plytix';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that this item is excluded from the Plytix product feed. Enabled items are filtered out of the BC -> Celigo -> Plytix integration.';
        }

        // MSRP is a marketing figure that goes on marketplace listings, not a price we ever
        // transact at, so it lives on the item rather than in a sales price list. One value per
        // item: retailer-specific versions (CB, BN, LM suffixes) are separate item numbers with
        // their own MSRP.
        field(50201; MSRP; Decimal)
        {
            Caption = 'MSRP';
            DataClassification = CustomerContent;
            AutoFormatType = 2;
            MinValue = 0;
            ToolTip = 'Specifies the manufacturer suggested retail price used on marketplace listings. This is sent to Plytix and out to Amazon, Walmart and other channels. It is not used to price sales orders.';
        }
    }
}
