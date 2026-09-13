// User-maintained method catalogue. Descriptions are copied to the Reservoir
// and revision history, not looked up dynamically on historical records.
table 70017 "Reserve Estimation Method"
{
    Caption = 'Reserve Estimation Method';
    DataClassification = CustomerContent;
    LookupPageId = "Reserve Estimation Methods";
    DrillDownPageId = "Reserve Estimation Methods";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; Code) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description) { }
    }

    trigger OnInsert()
    begin
        Rec.TestField(Code);
        Rec.TestField(Description);
    end;

    trigger OnModify()
    begin
        Rec.TestField(Description);
    end;

    trigger OnDelete()
    begin
        CheckNotUsed();
    end;

    trigger OnRename()
    var
        OriginalMethod: Record "Reserve Estimation Method";
    begin
        OriginalMethod := xRec;
        OriginalMethod.CheckNotUsed();
    end;

    procedure CheckNotUsed()
    var
        Reservoir: Record Reservoir;
        Revision: Record "Reserve Revision History";
    begin
        if Rec.IsTemporary() then
            exit;
        Reservoir.SetRange("Estimation Method Code", Rec.Code);
        Revision.SetRange("Estimation Method Code", Rec.Code);
        if (not Reservoir.IsEmpty()) or (not Revision.IsEmpty()) then
            Error('Estimation method %1 is referenced by a Reservoir or reserve history. Block it for future selection instead of deleting or renaming it.', Rec.Code);
    end;
}
