table 70023 "Production Dim. Correction"
{
    Caption = 'Production Dim. Correction';
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
        field(3; "State"; Enum "Prod. Dim. Correction State")
        {
            Caption = 'State';
            DataClassification = CustomerContent;
        }
        field(4; "Reason"; Text[250])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }
        field(5; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
        }
        field(6; "Created By"; Guid)
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
        }
        field(7; "Last Run At"; DateTime)
        {
            Caption = 'Last Run At';
            DataClassification = CustomerContent;
        }
        field(8; "Last Run By"; Guid)
        {
            Caption = 'Last Run By';
            DataClassification = CustomerContent;
        }
        field(9; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = CustomerContent;
        }
        field(10; "Old Source Dimension Set ID"; Integer)
        {
            Caption = 'Old Source Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(11; "New Source Dimension Set ID"; Integer)
        {
            Caption = 'New Source Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(12; "Old Entity Code"; Code[20])
        {
            Caption = 'Old Entity Code';
            DataClassification = CustomerContent;
        }
        field(13; "New Entity Code"; Code[20])
        {
            Caption = 'New Entity Code';
            DataClassification = CustomerContent;
        }
        field(14; "Old Field Code"; Code[20])
        {
            Caption = 'Old Field Code';
            DataClassification = CustomerContent;
        }
        field(15; "New Field Code"; Code[20])
        {
            Caption = 'New Field Code';
            DataClassification = CustomerContent;
        }
        field(16; "Old Well Code"; Code[20])
        {
            Caption = 'Old Well Code';
            DataClassification = CustomerContent;
        }
        field(17; "New Well Code"; Code[20])
        {
            Caption = 'New Well Code';
            DataClassification = CustomerContent;
        }
        field(18; "Old Cost Center Code"; Code[20])
        {
            Caption = 'Old Cost Center Code';
            DataClassification = CustomerContent;
        }
        field(19; "New Cost Center Code"; Code[20])
        {
            Caption = 'New Cost Center Code';
            DataClassification = CustomerContent;
        }
        field(20; "Entity Dimension Code"; Code[20])
        {
            Caption = 'Entity Dimension Code';
            DataClassification = CustomerContent;
        }
        field(21; "Field Dimension Code"; Code[20])
        {
            Caption = 'Field Dimension Code';
            DataClassification = CustomerContent;
        }
        field(22; "Well Dimension Code"; Code[20])
        {
            Caption = 'Well Dimension Code';
            DataClassification = CustomerContent;
        }
        field(23; "Cost Center Dimension Code"; Code[20])
        {
            Caption = 'Cost Center Dimension Code';
            DataClassification = CustomerContent;
        }
        field(24; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = CustomerContent;
        }
        field(25; "G/L Correction Entry No."; Integer)
        {
            Caption = 'G/L Correction Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction";
        }
        field(26; "G/L Entry Count"; Integer)
        {
            Caption = 'G/L Entry Count';
            DataClassification = CustomerContent;
        }
        field(27; "Item Entry Count"; Integer)
        {
            Caption = 'Item Entry Count';
            DataClassification = CustomerContent;
        }
        field(28; "Value Entry Count"; Integer)
        {
            Caption = 'Value Entry Count';
            DataClassification = CustomerContent;
        }
        field(29; "Journal Line Count"; Integer)
        {
            Caption = 'Journal Line Count';
            DataClassification = CustomerContent;
        }
        field(30; "Error Text"; Text[2048])
        {
            Caption = 'Error Text';
            DataClassification = CustomerContent;
        }
        field(31; "Change Field"; Boolean)
        {
            Caption = 'Change Field';
            DataClassification = CustomerContent;
        }
        field(32; "Change Well"; Boolean)
        {
            Caption = 'Change Well';
            DataClassification = CustomerContent;
        }
        field(33; "Change Cost Center"; Boolean)
        {
            Caption = 'Change Cost Center';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PrimaryKey; "Entry No.") { Clustered = true; }
    }
}
