table 70025 "Depletion Ledger Link"
{
    Caption = 'Depletion Ledger Link';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "FA Ledger Entry No."; Integer)
        {
            Caption = 'FA Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "FA Ledger Entry";
        }
        field(2; "Depletion Entry No."; Integer)
        {
            Caption = 'Depletion Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Depletion Worksheet";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            DataClassification = CustomerContent;
            TableRelation = "Fixed Asset";
        }
        field(4; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = CustomerContent;
            
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            
        }
        field(6; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = CustomerContent;
            
        }
        field(7; "G/L Posting Date"; Date)
        {
            Caption = 'G/L Posting Date';
            DataClassification = CustomerContent;
            
        }
        field(8; "Amount"; Decimal)
        {
            Caption = 'Amount';
            DataClassification = CustomerContent;
            
        }
        field(9; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Entry";
        }
        field(10; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
            
        }
        field(11; "Recorded At"; DateTime)
        {
            Caption = 'Recorded At';
            DataClassification = CustomerContent;
            
        }
        field(12; "Recorded By"; Guid)
        {
            Caption = 'Recorded By';
            DataClassification = CustomerContent;
            
        }
    }
    keys
    {
        key(PrimaryKey; "FA Ledger Entry No.") { Clustered = true; }
        key(Source; "Depletion Entry No.") { }
    }
}
