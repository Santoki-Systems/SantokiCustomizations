// The kind of stock event a row in Amazon Inventory Events records. Customer returns come first;
// reimbursed, found and removed units (R2) are added here later, not as new tables.
enum 50219 "Amazon Inventory Event Type"
{
    Extensible = false;
    Caption = 'Amazon Inventory Event Type';

    value(0; "Customer Return") { Caption = 'Customer Return'; }
}
