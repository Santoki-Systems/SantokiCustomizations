// One Amazon order, held as Amazon described it, before and after it becomes a sales order.
//
// This replaces Suite Engine's Channel Orders table. The status tells the team where each order
// is, and a failed order carries its reason, when it was last tried, and how many times.
table 50215 "Amazon Staged Order"
{
    Caption = 'Amazon Staged Order';
    DataClassification = CustomerContent;
    LookupPageId = "Amazon Staged Orders";
    DrillDownPageId = "Amazon Staged Orders";

    fields
    {
        field(1; "Amazon Order Id"; Code[30])
        {
            Caption = 'Amazon Order Id';
            NotBlank = true;
            ToolTip = 'Specifies the Amazon order number.';
        }
        field(2; "Marketplace Id"; Code[20])
        {
            Caption = 'Marketplace Id';
            TableRelation = "Amazon Marketplace Setup";
            ToolTip = 'Specifies the Amazon marketplace the order was placed on.';
        }
        field(3; "Amazon Order Status"; Text[30])
        {
            Caption = 'Amazon Order Status';
            ToolTip = 'Specifies the order status as last reported by Amazon, such as Pending, Unshipped, Shipped or Canceled.';
        }
        field(4; "Fulfillment Channel"; Code[10])
        {
            Caption = 'Fulfillment Channel';
            ToolTip = 'Specifies who fulfils the order: AFN is Fulfilled by Amazon, MFN is fulfilled by Santoki.';
        }
        field(5; "Sales Channel"; Text[50])
        {
            Caption = 'Sales Channel';
            ToolTip = 'Specifies the Amazon sales channel, such as Amazon.com or Amazon.ca.';
        }
        field(6; "Purchase Date"; DateTime)
        {
            Caption = 'Purchase Date';
            ToolTip = 'Specifies when the customer placed the order.';
        }
        field(7; "Last Update Date"; DateTime)
        {
            Caption = 'Last Update Date';
            ToolTip = 'Specifies when Amazon last changed the order. Deliveries older than this are ignored.';
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency Amazon reported for the order.';
        }
        field(9; "Order Total"; Decimal)
        {
            Caption = 'Order Total';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the order total as reported by Amazon.';
        }
        field(10; "Is Business Order"; Boolean)
        {
            Caption = 'Is Business Order';
            ToolTip = 'Specifies whether the order was placed through Amazon Business.';
        }
        field(11; "Is Prime"; Boolean)
        {
            Caption = 'Is Prime';
            ToolTip = 'Specifies whether the order is a Prime order.';
        }
        field(12; "Ship Service Level"; Text[50])
        {
            Caption = 'Ship Service Level';
            ToolTip = 'Specifies the shipping service level Amazon reported.';
        }
        field(20; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the name the order ships to. Amazon only releases this once the order is finalised.';
        }
        field(21; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the first line of the delivery address.';
        }
        field(22; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the second line of the delivery address.';
        }
        field(23; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the delivery city.';
        }
        field(24; "Ship-to County"; Text[30])
        {
            Caption = 'Ship-to State';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the delivery state or province.';
        }
        field(25; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to ZIP Code';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the delivery ZIP or postal code.';
        }
        field(26; "Ship-to Country Code"; Code[10])
        {
            Caption = 'Ship-to Country Code';
            ToolTip = 'Specifies the delivery country.';
        }
        field(27; "Ship-to Phone"; Text[30])
        {
            Caption = 'Ship-to Phone';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the delivery phone number, where Amazon provides one.';
        }
        field(28; "Buyer Email"; Text[80])
        {
            Caption = 'Buyer Email';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the anonymised buyer email Amazon provides.';
        }
        field(40; Status; Enum "Amazon Staging Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies where the order is: Received, Ready, In Progress, Order Created, Error, On Hold or Cancelled.';
        }
        field(41; "Status Message"; Text[2048])
        {
            Caption = 'Status Message';
            ToolTip = 'Specifies why the order is in error or on hold.';
        }
        field(42; Attempts; Integer)
        {
            Caption = 'Attempts';
            ToolTip = 'Specifies how many times Business Central has tried to process the order.';
        }
        field(43; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            ToolTip = 'Specifies when Business Central last tried to process the order.';
        }
        field(44; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            ToolTip = 'Specifies the sales order created from this Amazon order.';
        }
        field(45; "Received At"; DateTime)
        {
            Caption = 'Received At';
            ToolTip = 'Specifies when the order first arrived from Amazon.';
        }
        field(46; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            ToolTip = 'Specifies when the sales order was created.';
        }
        field(47; "Inbox Entry No."; BigInteger)
        {
            Caption = 'Inbox Entry No.';
            TableRelation = "Amazon Order Inbox";
            ToolTip = 'Specifies the delivery the order was last updated from.';
        }
        field(48; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(49; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            CalcFormula = count("Amazon Staged Order Line" where("Amazon Order Id" = field("Amazon Order Id")));
            Editable = false;
            ToolTip = 'Specifies how many order items the order has.';
        }
    }

    keys
    {
        key(PK; "Amazon Order Id") { Clustered = true; }
        key(Status; Status, "Purchase Date") { }
        key(Marketplace; "Marketplace Id", "Purchase Date") { }
        key(Purchased; "Purchase Date") { }
    }

    trigger OnDelete()
    var
        StagedLine: Record "Amazon Staged Order Line";
    begin
        StagedLine.SetRange("Amazon Order Id", Rec."Amazon Order Id");
        StagedLine.DeleteAll();
    end;

    procedure SetPayload(PayloadText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec.Payload);
        Rec.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadText);
    end;

    procedure GetPayload(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        Rec.CalcFields(Payload);
        if not Rec.Payload.HasValue() then
            exit('');
        Rec.Payload.CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;

    // Sends an order back through validation, e.g. after a SKU mapping has been added.
    // An order that already has a sales order is never reset, so it cannot be created twice.
    procedure ResetForReprocessing()
    var
        AlreadyCreatedErr: Label 'Amazon order %1 already has sales order %2 and cannot be reprocessed.', Comment = '%1 = Amazon order id, %2 = sales order no.';
    begin
        if Rec."Sales Order No." <> '' then
            Error(AlreadyCreatedErr, Rec."Amazon Order Id", Rec."Sales Order No.");
        Rec.Status := Rec.Status::Received;
        Rec."Status Message" := '';
        Rec.Modify(true);
    end;

    procedure OpenSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Sales Order No." = '' then
            exit;
        if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Sales Order No.") then
            Page.Run(Page::"Sales Order", SalesHeader);
    end;
}
