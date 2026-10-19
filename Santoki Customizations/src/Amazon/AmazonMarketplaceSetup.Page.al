// The setup lists the business maintains. Changing them never needs a developer.
page 50224 "Amazon Marketplace Setup"
{
    PageType = List;
    Caption = 'Amazon Marketplace Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Amazon Marketplace Setup";

    layout
    {
        area(Content)
        {
            repeater(Marketplaces)
            {
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field(Description; Rec.Description) { }
                field(Enabled; Rec.Enabled) { }
                field("Process Orders From"; Rec."Process Orders From") { }
                field("Customer No."; Rec."Customer No.") { }
                field("Location Code"; Rec."Location Code") { }
                field("Currency Code"; Rec."Currency Code") { }
                field("Clearing G/L Account No."; Rec."Clearing G/L Account No.") { }
                field("Shipping G/L Account No."; Rec."Shipping G/L Account No.") { }
            }
        }
    }
}
