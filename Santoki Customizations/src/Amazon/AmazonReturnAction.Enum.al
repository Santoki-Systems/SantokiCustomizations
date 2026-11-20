// What Business Central does with one returned unit, chosen from its Amazon disposition and status
// by the Amazon Return Dispositions setup.
enum 50217 "Amazon Return Action"
{
    Extensible = false;
    Caption = 'Amazon Return Action';

    value(0; " ") { Caption = ' '; }
    // Back into sellable stock at the marketplace location (AMZ).
    value(1; "Add to Stock") { Caption = 'Add to Stock'; }
    // Into the unsellable location, so it never counts as available stock.
    value(2; "Move to Unsellable") { Caption = 'Move to Unsellable Location'; }
    // Added and written off in the same posting, like the WOAMZDEF document today.
    value(3; "Add and Write Off") { Caption = 'Add and Write Off'; }
    // Amazon pays for the unit through the settlement, so stock does not move.
    value(4; "No Movement") { Caption = 'No Stock Movement'; }
    // Amazon has not finished with the unit yet; wait for a later report.
    value(5; Hold) { Caption = 'Hold'; }
}
