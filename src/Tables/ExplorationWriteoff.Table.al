// -----------------------------------------------------------------------------
// Exploration Write-off (FR-09, FR-24)
// Dry-hole / unsuccessful exploration cost write-off document.
// Behaviour depends on the elected Accounting Method in O&G Setup.
// -----------------------------------------------------------------------------
table 70016 "Exploration Write-off"
{
    Caption = 'Exploration Write-off';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = ToBeClassified;
        }
        field(3; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reservoir";
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = ToBeClassified;
            Description = 'Unsuccessful exploration cost to be written off (FR-24).';
        }
        field(5; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = ToBeClassified;
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name;
            Description = 'Journal batch created (empty under Full Cost, where no posting is required) (FR-24).';
        }
    }

    keys
    {
        key(PrimaryKey; "Document No.")
        {
            Clustered = true;
        }
    }
}
