// What an Amazon report delivery carries. Returns are read now; settlements arrive with the
// settlement build (S1) and use the same inbox.
enum 50215 "Amazon Report Type"
{
    Extensible = false;
    Caption = 'Amazon Report Type';

    value(0; Returns) { Caption = 'Returns'; }
    value(1; Settlement) { Caption = 'Settlement'; }
}
