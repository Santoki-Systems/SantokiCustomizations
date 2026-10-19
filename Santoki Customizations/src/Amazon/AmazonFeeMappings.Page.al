page 50226 "Amazon Fee Mappings"
{
    PageType = List;
    Caption = 'Amazon Fee Mappings';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Amazon Fee Mapping";

    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field("Marketplace Id"; Rec."Marketplace Id") { }
                field("Transaction Type"; Rec."Transaction Type") { }
                field("Amount Type"; Rec."Amount Type") { }
                field("Amount Description"; Rec."Amount Description") { }
                field("G/L Account No."; Rec."G/L Account No.") { }
                field(Ignore; Rec.Ignore) { }
                field(Description; Rec.Description) { }
            }
        }
    }
}
