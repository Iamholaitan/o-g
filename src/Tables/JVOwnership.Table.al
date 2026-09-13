table 70021 "JV Ownership"
{
    Caption = 'JV Ownership';
    DataClassification = CustomerContent;
    LookupPageId = "JV Ownership List";
    DrillDownPageId = "JV Ownership List";

    fields
    {
        field(1; "Entity Code"; Code[20])
        {
            Caption = 'Entity Code';
            DataClassification = CustomerContent;
            TableRelation = "O&G Entity"."Entity Code" where(Type = const("Joint Operation"), Blocked = const(false));
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;
        }
        field(3; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Operator Interest %"; Decimal)
        {
            Caption = 'Operator Interest %';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 100;
        }
        field(5; "Operator Cost Entity"; Code[20])
        {
            Caption = 'Operator Cost Entity';
            DataClassification = CustomerContent;
            TableRelation = "O&G Entity"."Entity Code" where(Type = const(Operator), Blocked = const(false));
        }
    }

    keys
    {
        key(PrimaryKey; "Entity Code", "Starting Date") { Clustered = true; }
    }
    trigger OnInsert()
    begin
        Rec.TestField("Entity Code");
        Rec.TestField("Starting Date");
    end;
    trigger OnModify()
    begin
        CheckUnused();
    end;
    trigger OnDelete()
    var
        Member: Record "JV Ownership Partner";
    begin
        CheckUnused();
        Member.SetRange("Entity Code", Rec."Entity Code");
        Member.SetRange("Starting Date", Rec."Starting Date");
        Member.DeleteAll(true);
    end;
    trigger OnRename()
    begin
        Error('Ownership keys cannot be renamed. Create a new effective-dated ownership version.');
    end;
    procedure CheckUnused()
    var
        Allocation: Record "JV Cost Allocation Header";
    begin
        Allocation.SetRange(Posted, true);
        Allocation.SetRange("Entity Code", Rec."Entity Code");
        Allocation.SetRange("Ownership Starting Date", Rec."Starting Date");
        if not Allocation.IsEmpty() then
            Error('This ownership version has been used. Create a new Starting Date for future ownership changes.');
    end;
}
