// -----------------------------------------------------------------------------
// JV Cost Allocation Header (FR-27)
// Header of a joint operations cost allocation document (JV cash call support).
// -----------------------------------------------------------------------------
table 70010 "JV Cost Allocation Header"
{
    Caption = 'JV Cost Allocation Header';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = ToBeClassified;
        }
        field(3; "Field/Block Code"; Code[20])
        {
            Caption = 'Field/Block Code';
            DataClassification = ToBeClassified;
            Description = 'Dimension source field for the joint operation (FR-07, FR-27).';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(5; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
            DataClassification = ToBeClassified;
            Description = 'Total amount to be allocated across partners (FR-27).';
        }
        field(6; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = ToBeClassified;
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name;
            Description = 'Traceability back to the generated General Journal batch - jump to it to review/post (FR-27, FR-18).';
        }
        field(8; "Entity Code"; Code[20])
        {
            Caption = 'Entity';
            DataClassification = CustomerContent;
            TableRelation = "O&G Entity"."Entity Code" where(Type = const("Joint Operation"), Blocked = const(false));
        }
        field(9; "Ownership Starting Date"; Date)
        {
            Caption = 'Ownership Starting Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Operator Interest %"; Decimal)
        {
            Caption = 'Operator Interest %';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "Operator Cost Entity"; Code[20])
        {
            Caption = 'Operator Cost Entity';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PrimaryKey; "Document No.")
        {
            Clustered = true;
        }
        key(FieldDate; "Field/Block Code", "Posting Date")
        {
        }
    }
    trigger OnModify()
    var
        Stored: Record "JV Cost Allocation Header";
    begin
        if Stored.Get(Rec."Document No.") then
            if Stored.Posted then
                Error('Journalised JV allocation %1 cannot be edited.', Rec."Document No.");
    end;
    trigger OnDelete()
    var
        Line: Record "JV Cost Allocation Line";
    begin
        Rec.TestField(Posted, false);
        Line.SetRange("Document No.", Rec."Document No.");
        Line.DeleteAll(true);
    end;
}
