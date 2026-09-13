// -----------------------------------------------------------------------------
// Daily production input and immutable journalised source document (FR-11-19).
// Posted means SENT TO ITEM JOURNAL, not posted to the Item Ledger/G/L.
// Existing field IDs/types are retained. v1.0.11 adds fields 9-12 only.
// -----------------------------------------------------------------------------
table 70004 "Production Entry Header"
{
    Caption = 'Production Entry Header';
    DataClassification = ToBeClassified;
    LookupPageId = "Open Production List";
    DrillDownPageId = "Production Entry List";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Production Date"; Date)
        {
            Caption = 'Production Date';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                TestOpen();
            end;
        }
        field(3; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = Reservoir."Reservoir Code";
            trigger OnValidate()
            var
                ProdLine: Record "Production Entry Line";
            begin
                TestOpen();
                if Rec."Reservoir Code" = xRec."Reservoir Code" then
                    exit;
                ProdLine.SetRange("Document No.", Rec."Document No.");
                if not ProdLine.IsEmpty() then
                    Error('Remove the existing production lines before changing the reservoir on document %1. Their item setup and calculations belong to the current reservoir.', Rec."Document No.");
                SetReservoirDefaults(true);
            end;
        }
        field(4; "Field/Block Code"; Code[20])
        {
            Caption = 'Field/Block Code';
            DataClassification = ToBeClassified;
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            Description = 'Defaults from Reservoir; may be changed while open. Validated against the dimension code in O&G Setup.';
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                ValueCode := Rec."Field/Block Code";
                if DimHelper.LookupDimensionValue(OGSetup."Field/Block Dimension Code", ValueCode) then
                    Rec.Validate("Field/Block Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Field/Block Dimension Code", Rec."Field/Block Code");
            end;
        }
        field(5; "Well Code"; Code[20])
        {
            Caption = 'Well Code';
            DataClassification = ToBeClassified;
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            Description = 'Defaults from Reservoir; may be changed while open. Validated against the dimension code in O&G Setup.';
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                ValueCode := Rec."Well Code";
                if DimHelper.LookupDimensionValue(OGSetup."Well Dimension Code", ValueCode) then
                    Rec.Validate("Well Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Well Dimension Code", Rec."Well Code");
            end;
        }
        field(6; "Total BOE"; Decimal)
        {
            Caption = 'Total Produced (BOE)';
            DataClassification = ToBeClassified;
            Editable = false;
            Description = 'Frozen total when sent to the item journal. Live draft totals use Calculated BOE; the original Normal field is retained for upgrade compatibility.';
        }
        field(7; Posted; Boolean)
        {
            Caption = 'Sent to Item Journal';
            DataClassification = ToBeClassified;
            Editable = false;
            Description = 'Locks header and lines once journalised. Does not confirm Item Ledger or G/L posting.';
        }
        field(8; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item Journal Batch Name';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Journal Template Name"));
        }
        field(9; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item Journal Template Name';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Item Journal Template";
            Description = 'Template copied from O&G Setup at journal generation and preserved for history.';
        }
        field(10; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            DataClassification = ToBeClassified;
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                ValueCode := Rec."Cost Center Code";
                if DimHelper.LookupDimensionValue(OGSetup."Cost Center Dimension Code", ValueCode) then
                    Rec.Validate("Cost Center Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                TestOpen();
                Helper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Cost Center Dimension Code", Rec."Cost Center Code");
            end;
        }
        field(11; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "Dimension Set Entry";
            Description = 'Production dimension snapshot at journal generation. Later setup/master changes do not rewrite history.';
        }
        field(12; "Calculated BOE"; Decimal)
        {
            Caption = 'Total Produced (BOE)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Production Entry Line"."BOE Quantity" where("Document No." = field("Document No.")));
            Description = 'Live draft total. New field: no conversion of the existing stored Total BOE field.';
        }
        field(13; "Entity Code"; Code[20])
        {
            Caption = 'Entity';
            DataClassification = CustomerContent;
            TableRelation = "O&G Entity"."Entity Code" where(Blocked = const(false));
            trigger OnValidate()
            var
                EntityMgt: Codeunit "O&G Entity Mgt.";
            begin
                TestOpen();
                if Rec."Entity Code" <> '' then
                    EntityMgt.ValidateEntity(Rec."Entity Code");
            end;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Record Kind"; Enum "Production Record Kind")
        {
            Caption = 'Record Kind';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(16; "Reverses Document No."; Code[20])
        {
            Caption = 'Reverses Document No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Entry Header";
        }
        field(17; "Reversed By Document No."; Code[20])
        {
            Caption = 'Reversed By Document No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Entry Header";
        }
        field(18; Cancelled; Boolean)
        {
            Caption = 'Cancelled Before Posting';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(19; "Cancellation Reason"; Text[250])
        {
            Caption = 'Cancellation Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Cancelled At"; DateTime)
        {
            Caption = 'Cancelled At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Cancelled By"; Guid)
        {
            Caption = 'Cancelled By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(22; "Correction Reason"; Text[250])
        {
            Caption = 'Correction Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "Inventory Posting State"; Enum "Production Posting State")
        {
            Caption = 'Inventory Posting State';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "Corrects Document No."; Code[20])
        {
            Caption = 'Corrects Document No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Entry Header";
        }
        field(25; "Dimension Correction No."; Integer)
        {
            Caption = 'Dimension Correction No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Dim. Correction";
        }
    }

    keys
    {
        key(PrimaryKey; "Document No.") { Clustered = true; }
        key(DateReservoir; "Production Date", "Reservoir Code") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Production Date", "Reservoir Code") { }
    }

    trigger OnInsert()
    var
        NumberSeries: Codeunit "No. Series";
        ExistingNumber: Record "Production Entry Header";
        Attempts: Integer;
    begin
        if not Rec.IsTemporary() then begin
            if Rec."Document No." <> '' then
                Error('Production document numbers are automatic. Leave Document No. blank; configure Production Nos. in O&G Setup.');
            Helper.GetSetup(OGSetup);
            OGSetup.TestField("Production Nos.");
            NumberSeries.TestAutomatic(OGSetup."Production Nos.");
            Rec."No. Series" := OGSetup."Production Nos.";
            if Rec."Production Date" = 0D then
                Rec."Production Date" := WorkDate();
            repeat
                Rec."Document No." := NumberSeries.GetNextNo(Rec."No. Series", WorkDate());
                Attempts += 1;
                if Attempts > 1000 then
                    Error('Production number series overlaps too many existing document numbers. Correct its starting number before continuing.');
            until not ExistingNumber.Get(Rec."Document No.");
        end;
        Rec.TestField("Document No.");
        InitializeOpenDefaults();
        SetReservoirDefaults(false);
    end;

    var
        OGSetup: Record "O&G Setup";
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";

    procedure TestOpen()
    var
        StoredHeader: Record "Production Entry Header";
    begin
        if Rec.Posted or Rec.Cancelled then
            Error('Production document %1 has been sent to the item journal and cannot be changed or deleted.', Rec."Document No.");
        if Rec.IsTemporary() then
            exit;
        // Read-only check here: lookups must not hold update locks while a modal
        // selector is open. The database-event guard locks on actual writes.
        if StoredHeader.Get(Rec."Document No.") then
            if StoredHeader.Posted then
                Error('Production document %1 has been sent to the item journal in another session. Refresh the page; changes are not allowed.', Rec."Document No.");
    end;

    procedure InitializeOpenDefaults()
    begin
        TestOpen();
        Helper.GetSetup(OGSetup);
        Rec."Item Journal Template Name" := OGSetup."Item Journal Template Name";
        if Rec."Production Date" = 0D then
            Rec."Production Date" := WorkDate();
    end;

    procedure SetReservoirDefaults(ReplaceExisting: Boolean)
    var
        Reservoir: Record Reservoir;
    begin
        TestOpen();
        if Rec."Reservoir Code" = '' then begin
            if ReplaceExisting then begin
                Rec."Field/Block Code" := '';
                Rec."Well Code" := '';
                Rec."Cost Center Code" := '';
            end;
            exit;
        end;
        Reservoir.Get(Rec."Reservoir Code");
        if ReplaceExisting or (Rec."Field/Block Code" = '') then
            Rec.Validate("Field/Block Code", Reservoir."Field/Block Code");
        if ReplaceExisting or (Rec."Well Code" = '') then
            Rec.Validate("Well Code", Reservoir."Well Code");
        if ReplaceExisting or (Rec."Cost Center Code" = '') then
            Rec.Validate("Cost Center Code", Reservoir."Cost Center Code");
    end;
}
