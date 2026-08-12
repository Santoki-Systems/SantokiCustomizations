pageextension 50201 "Item Card Ext. Plytix" extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group(PlytixIntegration)
            {
                Caption = 'Plytix Integration';

                field("Exclude from Plytix"; Rec."Exclude from Plytix")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that this item is excluded from the Plytix product feed. Enabled items are filtered out of the BC -> Celigo -> Plytix integration.';
                }

                field(MSRP; Rec.MSRP)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the manufacturer suggested retail price used on marketplace listings. This is sent to Plytix and out to Amazon, Walmart and other channels. It is not used to price sales orders.';
                }
            }
        }
    }
}
