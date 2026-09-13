// -----------------------------------------------------------------------------
// Royalty Term (FR-25, FR-26)
// Per-field royalty terms: configurable rate, basis and settlement method.
// -----------------------------------------------------------------------------
table 70007 "Royalty Term"
{
    Caption = 'Royalty Term';
    DataClassification = ToBeClassified;
    LookupPageId = "Royalty Term List";
    DrillDownPageId = "Royalty Term List";

    fields
    {
        field(1; "Field/Block Code"; Code[20])
        {
            Caption = 'Field/Block Code';
            DataClassification = ToBeClassified;
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                Setup: Record "O&G Setup";
                Helper: Codeunit "Production Entry Helper";
                DimHelper: Codeunit "Dimension Helper";
                ValueCode: Code[20];
            begin
                Helper.GetSetup(Setup);
                ValueCode := Rec."Field/Block Code";
                if DimHelper.LookupDimensionValue(Setup."Field/Block Dimension Code", ValueCode) then
                    Rec.Validate("Field/Block Code", ValueCode);
            end;
            trigger OnValidate()
            var
                Setup: Record "O&G Setup";
                DimValue: Record "Dimension Value";
                Helper: Codeunit "Production Entry Helper";
                DimHelper: Codeunit "Dimension Helper";
            begin
                Helper.GetSetup(Setup);
                DimHelper.ValidateDimensionValue(Setup."Field/Block Dimension Code", Rec."Field/Block Code");
                if (Rec.Description = '') and DimValue.Get(Setup."Field/Block Dimension Code", Rec."Field/Block Code") then
                    Rec.Description := CopyStr(DimValue.Name, 1, MaxStrLen(Rec.Description));
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
            Description = 'Contract / area description (FR-25).';
        }
        field(3; "Royalty Rate %"; Decimal)
        {
            Caption = 'Royalty Rate %';
            DataClassification = ToBeClassified;
            Description = 'Configured effective rate for the applicable production period/field; 0 uses the O&G Setup default. Not an automatic Nigerian statutory rate calculator.';
            MinValue = 0;
            MaxValue = 100;
        }
        field(4; "Royalty Basis"; Option)
        {
            Caption = 'Royalty Basis';
            DataClassification = ToBeClassified;
            OptionMembers = Volume,Revenue;
            OptionCaption = 'Production Volume,Production Reference Value';
            Description = 'Both bases use eligible production, not sales invoices. Revenue is retained as the stored option name for compatibility and labelled Production Reference Value.';
        }
        field(5; "Settlement Method"; Option)
        {
            Caption = 'Settlement Method';
            DataClassification = ToBeClassified;
            OptionMembers = Cash,"In-Kind";
            Description = 'Cash = Royalty Payable liability; In-Kind = negative inventory volume adjustment (FR-26).';
        }
        field(6; "Royalty Expense Account"; Code[20])
        {
            Caption = 'Royalty Expense Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Overrides the O&G Setup default royalty expense account for this field (FR-26).';
        }
        field(7; "Royalty Payable Account"; Code[20])
        {
            Caption = 'Royalty Payable Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Overrides the O&G Setup default royalty payable account for this field (FR-26).';
        }
        field(8; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = ToBeClassified;
            Description = 'Approved/fiscal reference price per source production UOM in company LCY. Not automatically a customer sales price or a fetched fiscal price.';
            MinValue = 0;
        }
        field(9; "Rate Reference"; Text[100])
        {
            Caption = 'Rate / Agreement Reference';
            DataClassification = CustomerContent;
        }
        field(10; "Price Reference"; Text[100])
        {
            Caption = 'Reference Price Source';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Field/Block Code")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Field/Block Code", Description) { }
    }

    trigger OnInsert()
    begin
        Rec.TestField("Field/Block Code");
    end;

    trigger OnRename()
    begin
        Error('Create a new royalty term for a different Field/Block; do not rename the key of an existing term and detach its history.');
    end;
}
