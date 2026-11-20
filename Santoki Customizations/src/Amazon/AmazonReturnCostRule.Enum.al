// The cost a returned unit comes back at. Michele answered "at cost" on Nov 11th 2026, so the
// default is the item's current unit cost; Zero matches how September 2026's document was posted.
enum 50218 "Amazon Return Cost Rule"
{
    Extensible = false;
    Caption = 'Amazon Return Cost Rule';

    value(0; "Item Unit Cost") { Caption = 'Item Unit Cost'; }
    value(1; Zero) { Caption = 'Zero'; }
}
