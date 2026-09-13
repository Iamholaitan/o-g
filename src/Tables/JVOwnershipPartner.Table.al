table 70022 "JV Ownership Partner"
{
    Caption = 'JV Ownership Partner';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entity Code"; Code[20])
        {
            Caption = 'Entity Code';
            DataClassification = CustomerContent;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;
        }
        field(3; "Partner Code"; Code[20])
        {
            Caption = 'Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "JV Partner";
        }
        field(4; "Working Interest %"; Decimal)
        {
            Caption = 'Working Interest %';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 100;
        }
    }

    keys
    {
        key(PrimaryKey; "Entity Code", "Starting Date", "Partner Code") { Clustered = true; }
    }
    trigger OnInsert()
    begin
        CheckOwnership();
    end;
    trigger OnModify()
    begin
        CheckOwnership();
    end;
    trigger OnDelete()
    begin
        CheckOwnership();
    end;
    trigger OnRename()
    begin
        Error('Ownership member keys cannot be renamed. Remove/add members on an unused ownership version.');
    end;
    local procedure CheckOwnership()
    var
        Ownership: Record "JV Ownership";
    begin
        Ownership.Get(Rec."Entity Code", Rec."Starting Date");
        Ownership.CheckUnused();
    end;
}
