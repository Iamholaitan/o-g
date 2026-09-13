// -----------------------------------------------------------------------------
// Reserve Revision History (FR-05, FR-23, FR-32)
// Audit trail for internally-estimated (non-certified) reserve figures.
// -----------------------------------------------------------------------------
table 70003 "Reserve Revision History"
{
    Caption = 'Reserve Revision History';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reservoir";
        }
        field(3; "Revision Date"; Date)
        {
            Caption = 'Revision Date';
            DataClassification = ToBeClassified;
            Description = 'Date the revision was recorded.';
        }
        field(4; "Previous Reserves (BOE)"; Decimal)
        {
            Caption = 'Previous Reserves (BOE)';
            DataClassification = ToBeClassified;
            Description = 'Figure before this revision (FR-05).';
        }
        field(5; "Revised Reserves (BOE)"; Decimal)
        {
            Caption = 'Revised Reserves (BOE)';
            DataClassification = ToBeClassified;
            Description = 'Figure after this revision (FR-05).';
        }
        field(6; "Estimation Basis"; Text[250])
        {
            Caption = 'Estimation Basis';
            DataClassification = ToBeClassified;
            Description = 'Method/reason for the revision (FR-05).';
        }
        field(7; "Prepared By"; Text[100])
        {
            Caption = 'Prepared By';
            DataClassification = ToBeClassified;
            Description = 'Person/team responsible for the revised figure (FR-05).';
        }
        field(8; "Estimator User Security ID"; Guid)
        {
            Caption = 'Estimator User Security ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
        field(9; "Estimation Method Code"; Code[20])
        {
            Caption = 'Estimation Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Reserve Estimation Method".Code;
        }
        field(10; "Changed By User Security ID"; Guid)
        {
            Caption = 'Changed By User Security ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID";
        }
        field(11; "Changed By"; Text[100])
        {
            Caption = 'Changed By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PrimaryKey; "Entry No.")
        {
            Clustered = true;
        }
        key(ReservoirDate; "Reservoir Code", "Revision Date")
        {
        }
    }
}
