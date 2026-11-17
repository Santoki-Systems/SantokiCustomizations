// Assign to the Celigo integration user (to post deliveries) and to anyone who works Amazon orders
// or returns. Posting the returns journal also needs the user's normal item journal permissions.
permissionset 50229 "Amazon Integration"
{
    Caption = 'Amazon Integration';
    Assignable = true;

    Permissions =
        tabledata "Amazon Report Inbox" = RIMD,
        tabledata "Amazon Inventory Event" = RIMD,
        tabledata "Amazon Return Disposition" = RIMD,
        table "Amazon Report Inbox" = X,
        table "Amazon Inventory Event" = X,
        table "Amazon Return Disposition" = X,
        codeunit "Amazon SKU Resolver" = X,
        codeunit "Amazon Return Import" = X,
        codeunit "Amazon Return Processing" = X,
        codeunit "Amazon Return Posting" = X,
        codeunit "Amazon Return Job" = X,
        page "Amazon Report Deliveries API" = X,
        page "Amazon Report Deliveries" = X,
        page "Amazon Returns" = X,
        page "Amazon Return Dispositions" = X,
        tabledata "Amazon Order Inbox" = RIMD,
        tabledata "Amazon Staged Order" = RIMD,
        tabledata "Amazon Staged Order Line" = RIMD,
        tabledata "Amazon Marketplace Setup" = RIMD,
        tabledata "Amazon SKU Mapping" = RIMD,
        tabledata "Amazon Fee Mapping" = RIMD,
        tabledata "Amazon Order Job Lock" = RIMD,
        tabledata "Active Session" = R,
        table "Amazon Order Inbox" = X,
        table "Amazon Staged Order" = X,
        table "Amazon Staged Order Line" = X,
        table "Amazon Marketplace Setup" = X,
        table "Amazon SKU Mapping" = X,
        table "Amazon Fee Mapping" = X,
        table "Amazon Order Job Lock" = X,
        codeunit "Amazon Order Import" = X,
        codeunit "Amazon Order Processing" = X,
        codeunit "Amazon Order Job" = X,
        page "Amazon Order Inbox API" = X,
        page "Amazon SKU Mapping API" = X,
        page "Amazon Fee Mapping API" = X,
        page "Amazon Order Inbox" = X,
        page "Amazon Staged Orders" = X,
        page "Amazon Staged Order" = X,
        page "Amazon Staged Order Lines" = X,
        page "Amazon Marketplace Setup" = X,
        page "Amazon SKU Mappings" = X,
        page "Amazon Fee Mappings" = X;
}
