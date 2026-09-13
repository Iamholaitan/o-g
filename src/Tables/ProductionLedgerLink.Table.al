table 70019 "Production Ledger Link"
{
    Caption = 'Production Ledger Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Item Ledger Entry";
        }
        field(2; "Posting Link No."; Integer)
        {
            Caption = 'Posting Link No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Posting Link";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(4; "Production Line No."; Integer)
        {
            Caption = 'Production Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Quantity Base"; Decimal)
        {
            Caption = 'Quantity Base';
            DataClassification = CustomerContent;
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(7; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(9; "Reverses Ledger Entry No."; Integer)
        {
            Caption = 'Reverses Ledger Entry No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Item Ledger Entry No.") { Clustered = true; }
    }
}
