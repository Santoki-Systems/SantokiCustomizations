// Stock for the B2B site: on hand at the location, less every open sales order at that location,
// never below zero. Agreed with Geary at the Nov 11th, 2026 Project List Review and confirmed by
// email on Nov 12th.
//
// Why the standard choices don't fit:
// - "Free Inventory (not reserved)" only takes off reserved quantities, and Santoki doesn't reserve
//   sales orders, so it shows the full on-hand quantity.
// - "Projected Available Balance at Today" adds inbound with a receipt date up to today. In-transit
//   containers carry the sailing date as their receipt date, so stock that hasn't arrived shows as
//   available (KE246H showed 2,004 with nothing on hand).
//
// The connector calls GetStock with the item filtered to the shop location's Location Filter and
// the variant, and with Date Filter set to 0D..Today. "Qty. on Sales Order" honours Date Filter on
// the shipment date, so the filter is cleared here to count every open order, whatever its date.
// The connector converts the result from the base unit to the variant's unit afterwards.
codeunit 50202 "Santoki On Hand Less Orders" implements "Shpfy Stock Calculation"
{
    procedure GetStock(var Item: Record Item): Decimal
    var
        StockItem: Record Item;
        Stock: Decimal;
    begin
        StockItem.Get(Item."No.");
        StockItem.CopyFilters(Item);
        StockItem.SetRange("Date Filter");
        StockItem.CalcFields(Inventory, "Qty. on Sales Order");

        Stock := StockItem.Inventory - StockItem."Qty. on Sales Order";
        if Stock < 0 then
            exit(0);
        exit(Stock);
    end;
}
