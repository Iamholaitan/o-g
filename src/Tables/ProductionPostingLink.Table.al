table 70018 "Production Posting Link"
{
    Caption = 'Production Posting Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Entry Header";
        }
        field(3; "Production Line No."; Integer)
        {
            Caption = 'Production Line No.';
            DataClassification = CustomerContent;
        }
        field(4; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
        }
        field(5; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = CustomerContent;
        }
        field(6; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
            DataClassification = CustomerContent;
        }
        field(7; "Journal Line System ID"; Guid)
        {
            Caption = 'Journal Line System ID';
            DataClassification = CustomerContent;
        }
        field(8; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
        }
        field(11; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = CustomerContent;
        }
        field(12; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(13; "Quantity Base"; Decimal)
        {
            Caption = 'Quantity Base';
            DataClassification = CustomerContent;
        }
        field(14; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(15; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(16; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
        }
        field(17; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = CustomerContent;
        }
        field(18; "Unit Amount"; Decimal)
        {
            Caption = 'Unit Amount';
            DataClassification = CustomerContent;
        }
        field(19; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;
        }
        field(20; "State"; Enum "Production Posting State")
        {
            Caption = 'State';
            DataClassification = CustomerContent;
        }
        field(21; "Reverses Ledger Entry No."; Integer)
        {
            Caption = 'Reverses Ledger Entry No.';
            DataClassification = CustomerContent;
        }
        field(22; "Apply To Link No."; Integer)
        {
            Caption = 'Apply To Link No.';
            DataClassification = CustomerContent;
        }
        field(23; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }
        field(24; "Created By"; Guid)
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
        }
        field(25; "Legacy Link"; Boolean)
        {
            Caption = 'Legacy Link';
            DataClassification = CustomerContent;
        }
        field(26; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Entry No.") { Clustered = true; }
    }
}
