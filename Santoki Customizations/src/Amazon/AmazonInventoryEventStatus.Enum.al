// Where an Amazon stock event is on its way into the item ledger.
enum 50216 "Amazon Inventory Event Status"
{
    Extensible = false;
    Caption = 'Amazon Inventory Event Status';

    value(0; Received) { Caption = 'Received'; }
    value(1; Ready) { Caption = 'Ready'; }
    // The journal lines exist but have not been posted, because the marketplace is set to leave
    // returns for review (the side-by-side run).
    value(2; "In Journal") { Caption = 'In Journal'; }
    value(3; Posted) { Caption = 'Posted'; }
    value(4; Error) { Caption = 'Error'; }
    value(5; "On Hold") { Caption = 'On Hold'; }
    value(6; Ignored) { Caption = 'Ignored'; }
}
