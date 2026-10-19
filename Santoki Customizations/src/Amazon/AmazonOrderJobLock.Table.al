// A single row recording which session is running the Amazon order job.
//
// Two runs at once (the job queue and someone choosing Process Now, or Process Now chosen twice)
// work through the same orders and trip over each other's changes. The job takes this lock first,
// and a second run stops straight away instead. A lock left by a session that has ended, or one
// older than any real run, is taken over, so a crashed run can't block the job for good.
table 50206 "Amazon Order Job Lock"
{
    Caption = 'Amazon Order Job Lock';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Server Instance Id"; Integer)
        {
            Caption = 'Server Instance Id';
        }
        field(3; "Session Id"; Integer)
        {
            Caption = 'Session Id';
        }
        field(4; "Started At"; DateTime)
        {
            Caption = 'Started At';
        }
        field(5; "Started By"; Code[50])
        {
            Caption = 'Started By';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
