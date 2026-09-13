// -----------------------------------------------------------------------------
// Depletion Worksheet (FR-20, FR-21, FR-22)
// Reviewable calculation of Unit-of-Production depletion per reservoir.
// -----------------------------------------------------------------------------
table 70006 "Depletion Worksheet"
{
    Caption = 'Depletion Worksheet';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = ToBeClassified;
        }
        field(3; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reservoir";
        }
        field(4; "Fixed Asset No."; Code[20])
        {
            Caption = 'Fixed Asset No.';
            DataClassification = ToBeClassified;
            TableRelation = "Fixed Asset";
        }
        field(5; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = ToBeClassified;
            TableRelation = "Depreciation Book";
        }
        field(6; "Total Capitalised Cost"; Decimal)
        {
            Caption = 'Total Capitalised Cost';
            DataClassification = ToBeClassified;
        }
        field(7; "Accumulated Depletion"; Decimal)
        {
            Caption = 'Accumulated Depletion';
            DataClassification = ToBeClassified;
        }
        field(8; "Remaining NBV"; Decimal)
        {
            Caption = 'Remaining NBV';
            DataClassification = ToBeClassified;
            Description = 'Capitalised cost less accumulated depletion (FR-20, FR-21).';
        }
        field(9; "Remaining Reserves BOE"; Decimal)
        {
            Caption = 'Remaining Reserves BOE';
            DataClassification = ToBeClassified;
            Description = 'Remaining reserves after the current reserve basis (FR-20, FR-23).';
        }
        field(10; "Period Production BOE"; Decimal)
        {
            Caption = 'Period Production BOE';
            DataClassification = ToBeClassified;
            Description = 'Posted production BOE in the selected period (FR-20).';
        }
        field(11; "Depletion Rate per BOE"; Decimal)
        {
            Caption = 'Depletion Rate per BOE';
            DataClassification = ToBeClassified;
            Description = 'Remaining NBV / Remaining Reserves (FR-20).';
        }
        field(12; "Depletion Amount"; Decimal)
        {
            Caption = 'Depletion Amount';
            DataClassification = ToBeClassified;
            Description = 'Period Production BOE x Depletion Rate per BOE (FR-20).';
        }
        field(13; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            DataClassification = ToBeClassified;
        }
        field(14; Posted; Boolean)
        {
            Caption = 'Sent to Journal';
            DataClassification = ToBeClassified;
            Description = 'True once journal lines have been created. Actual FA/G/L posting is tracked separately in Depletion Ledger Link.';
        }
        field(15; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name;
            Description = 'Traceability back to the generated Gen. Journal batch - jump to it to review/post (FR-22, FR-18).';
        }
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
            Description = 'Document number used on the generated Gen. Journal lines (FR-22).';
        }
        field(17; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = CustomerContent;
        }
        field(18; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = CustomerContent;
        }
        field(19; "Entity Code"; Code[20])
        {
            Caption = 'Entity Code';
            DataClassification = CustomerContent;
        }
        field(20; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(21; "Gen. Journal Template Name"; Code[10])
        {
            Caption = 'Gen. Journal Template Name';
            DataClassification = CustomerContent;
        }
        field(22; "Posting Route"; Enum "Depletion Posting Route")
        {
            Caption = 'Posting Route';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "FA Journal Line No."; Integer)
        {
            Caption = 'FA Journal Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "FA Journal System ID"; Guid)
        {
            Caption = 'FA Journal System ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(25; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PrimaryKey; "Entry No.")
        {
            Clustered = true;
        }
        key(DateReservoir; "Posting Date", "Reservoir Code")
        {
        }
    }
    trigger OnModify()
    var
        Stored: Record "Depletion Worksheet";
    begin
        if not Rec.IsTemporary() then
            if Stored.Get(Rec."Entry No.") then
                if Stored.Posted then
                    Error('Journalised worksheet entries are historical. Use a reviewed financial adjustment instead of editing them.');
    end;
    trigger OnDelete()
    begin
        if not Rec.IsTemporary() then
            Rec.TestField(Posted, false);
    end;
}
