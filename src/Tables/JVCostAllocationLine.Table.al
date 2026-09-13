// -----------------------------------------------------------------------------
// JV Cost Allocation Line (FR-27)
// Cost lines (G/L expense accounts) to be allocated to JV partners.
// -----------------------------------------------------------------------------
table 70011 "JV Cost Allocation Line"
{
    Caption = 'JV Cost Allocation Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
            TableRelation = "JV Cost Allocation Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Lifting/operating cost account to be shared with partners (FR-27).';
        }
        field(4; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
            DataClassification = ToBeClassified;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PrimaryKey; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        CheckOpenHeader();
    end;
    trigger OnModify()
    begin
        CheckOpenHeader();
    end;
    trigger OnDelete()
    begin
        CheckOpenHeader();
    end;
    local procedure CheckOpenHeader()
    var
        Header: Record "JV Cost Allocation Header";
    begin
        Header.Get(Rec."Document No.");
        Header.TestField(Posted, false);
    end;
}
