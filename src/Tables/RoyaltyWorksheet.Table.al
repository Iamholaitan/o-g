// -----------------------------------------------------------------------------
// Royalty Worksheet (FR-25, FR-26)
// Reviewable royalty calculation before posting (cash or in-kind per field).
// -----------------------------------------------------------------------------
table 70008 "Royalty Worksheet"
{
    Caption = 'Royalty Worksheet';
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
        field(3; "Field/Block Code"; Code[20])
        {
            Caption = 'Field/Block Code';
            DataClassification = ToBeClassified;
            TableRelation = "Royalty Term";
        }
        field(4; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reservoir";
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(6; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = ToBeClassified;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
        }
        field(8; "Gross Volume"; Decimal)
        {
            Caption = 'Net Production Volume';
            DataClassification = ToBeClassified;
            Description = 'Net (marketable) volume produced in the period (FR-25).';
        }
        field(9; "Royalty Rate %"; Decimal)
        {
            Caption = 'Royalty Rate %';
            DataClassification = ToBeClassified;
        }
        field(10; "Royalty Volume"; Decimal)
        {
            Caption = 'Royalty Volume';
            DataClassification = ToBeClassified;
            Description = 'Gross Volume x Royalty Rate % (FR-25, FR-26).';
        }
        field(11; "Settlement Method"; Option)
        {
            Caption = 'Settlement Method';
            DataClassification = ToBeClassified;
            OptionMembers = Cash,"In-Kind";
        }
        field(12; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = ToBeClassified;
        }
        field(13; "Royalty Amount"; Decimal)
        {
            Caption = 'Royalty Amount';
            DataClassification = ToBeClassified;
            Description = 'Royalty Volume x Unit Price; used for cash settlement (FR-25).';
        }
        field(14; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
            TableRelation = Location;
            Description = 'Location used for the in-kind volume adjustment (FR-26).';
        }
        field(15; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = ToBeClassified;
            Description = 'True once journal lines have been created for this row (FR-26).';
        }
        field(16; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = ToBeClassified;
            Description = 'Traceability back to the generated journal batch (FR-26).';
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
        field(20; "Production Document No."; Code[20])
        {
            Caption = 'Production Document No.';
            DataClassification = CustomerContent;
        }
        field(21; "Production Line No."; Integer)
        {
            Caption = 'Production Line No.';
            DataClassification = CustomerContent;
        }
        field(22; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
        }
        field(23; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
        }
        field(24; "Royalty Basis"; Option)
        {
            Caption = 'Royalty Basis';
            DataClassification = CustomerContent;
            OptionMembers = Volume,Revenue;
            OptionCaption = 'Production Volume,Production Reference Value';
        }
        field(25; "Rate Reference"; Text[100])
        {
            Caption = 'Rate / Agreement Reference';
            DataClassification = CustomerContent;
        }
        field(26; "Price Reference"; Text[100])
        {
            Caption = 'Reference Price Source';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Entry No.")
        {
            Clustered = true;
        }
        key(FieldDate; "Field/Block Code", "Posting Date")
        {
        }
    }
    trigger OnModify()
    var
        Stored: Record "Royalty Worksheet";
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
