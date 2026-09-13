table 70020 "O&G Entity"
{
    Caption = 'O&G Entity';
    DataClassification = CustomerContent;
    LookupPageId = "O&G Entities";
    DrillDownPageId = "O&G Entities";

    fields
    {
        field(1; "Entity Code"; Code[20])
        {
            Caption = 'Entity Code';
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                Mgt: Codeunit "O&G Entity Mgt.";
                Value: Code[20];
            begin
                Value := Rec."Entity Code";
                if Mgt.LookupValue(Value) then
                    Rec.Validate("Entity Code", Value);
            end;
            trigger OnValidate()
            var
                Mgt: Codeunit "O&G Entity Mgt.";
            begin
                Mgt.ValidateDimensionValue(Rec."Entity Code");
            end;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Type"; Enum "O&G Entity Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(4; "Blocked"; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Entity Code") { Clustered = true; }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Entity Code", Description, Type) { }
    }
    trigger OnInsert()
    var
        Mgt: Codeunit "O&G Entity Mgt.";
    begin
        Rec.TestField("Entity Code");
        Mgt.ValidateDimensionValue(Rec."Entity Code");
    end;
    trigger OnModify()
    var
        Mgt: Codeunit "O&G Entity Mgt.";
    begin
        Mgt.ValidateDimensionValue(Rec."Entity Code");
    end;
    trigger OnRename()
    begin
        Error('Entity codes cannot be renamed here. They refer to Global Dimension 1 values.');
    end;
}
