table 50207 "Santoki BOL Freight Line"
{
    // One commodity group on a bill of lading: the shipment lines that share an NMFC No. and Freight Class.
    Caption = 'BOL Freight Line';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "NMFC No."; Code[20])
        {
            Caption = 'NMFC No.';
        }
        field(3; "Freight Class"; Code[10])
        {
            Caption = 'Freight Class';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Line Count"; Integer)
        {
            Caption = 'Line Count';
        }
        field(6; Quantity; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(7; Cartons; Decimal)
        {
            Caption = 'Cartons';
            DecimalPlaces = 0 : 0;
        }
        field(8; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 2;
        }
        field(9; "Missing Data"; Boolean)
        {
            Caption = 'Missing Carton or Weight Data';
        }
        field(10; "Full Cartons"; Decimal)
        {
            Caption = 'Full Cartons';
            DecimalPlaces = 0 : 0;
        }
        field(11; "Part Carton Share"; Decimal)
        {
            Caption = 'Part Carton Share';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(FreightGroup; "NMFC No.", "Freight Class")
        {
        }
    }
}
