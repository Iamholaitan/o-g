// -----------------------------------------------------------------------------
// Date Range (helper)
// Single-record date range prompt used by batch actions and worksheets.
// -----------------------------------------------------------------------------
table 70015 "Date Range"
{
    Caption = 'Date Range';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "From Date"; Date)
        {
            Caption = 'From Date';
            DataClassification = ToBeClassified;
        }
        field(3; "To Date"; Date)
        {
            Caption = 'To Date';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PrimaryKey; "Primary Key")
        {
            Clustered = true;
        }
    }
}
