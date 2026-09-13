table 70024 "Production Dim. Change"
{
    Caption = 'Production Dim. Change';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Correction Entry No."; Integer)
        {
            Caption = 'Correction Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Dim. Correction";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
        }
        field(4; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(5; "System ID"; Guid)
        {
            Caption = 'System ID';
            DataClassification = CustomerContent;
        }
        field(6; "Old Dimension Set ID"; Integer)
        {
            Caption = 'Old Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(7; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(8; "Quantity Snapshot"; Decimal)
        {
            Caption = 'Quantity Snapshot';
            DataClassification = CustomerContent;
        }
        field(9; "Amount Snapshot"; Decimal)
        {
            Caption = 'Amount Snapshot';
            DataClassification = CustomerContent;
        }
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(11; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Applied"; Boolean)
        {
            Caption = 'Applied';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PrimaryKey; "Correction Entry No.", "Line No.") { Clustered = true; }
    }
}
