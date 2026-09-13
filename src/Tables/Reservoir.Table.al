// -----------------------------------------------------------------------------
// Reservoir (FR-04, FR-05, FR-19, FR-20, FR-22)
// Reservoir/field master with internally-estimated (non-certified) reserves.
// -----------------------------------------------------------------------------
table 70001 "Reservoir"
{
    Caption = 'Reservoir';
    DataClassification = ToBeClassified;
    LookupPageId = "Reservoir List";
    DrillDownPageId = "Reservoir List";

    fields
    {
        field(1; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            Description = 'Reservoir master code - maintained as a value of the RESERVOIR dimension (create it in Business Central Dimensions).';
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                ProdHelper.GetSetup(OGSetup);
                ValueCode := Rec."Reservoir Code";
                if DimHelper.LookupDimensionValue(OGSetup."Reservoir Dimension Code", ValueCode) then
                    Rec.Validate("Reservoir Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                ProdHelper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Reservoir Dimension Code", Rec."Reservoir Code");
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Field/Block Code"; Code[20])
        {
            Caption = 'Field/Block Code';
            DataClassification = ToBeClassified;
            Description = 'Parent field/block - a value of the FIELD dimension (FR-07).';
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                ProdHelper.GetSetup(OGSetup);
                ValueCode := Rec."Field/Block Code";
                if DimHelper.LookupDimensionValue(OGSetup."Field/Block Dimension Code", ValueCode) then
                    Rec.Validate("Field/Block Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                ProdHelper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Field/Block Dimension Code", Rec."Field/Block Code");
            end;
        }
        field(4; "Well Code"; Code[20])
        {
            Caption = 'Well Code';
            DataClassification = ToBeClassified;
            Description = 'Associated well, where a reservoir maps 1:1 to a well - a value of the WELL dimension (FR-07).';
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                ProdHelper.GetSetup(OGSetup);
                ValueCode := Rec."Well Code";
                if DimHelper.LookupDimensionValue(OGSetup."Well Dimension Code", ValueCode) then
                    Rec.Validate("Well Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                ProdHelper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Well Dimension Code", Rec."Well Code");
            end;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            DataClassification = ToBeClassified;
            OptionMembers = Exploration,Development,Producing,"Shut-in",Abandoned;
        }
        field(6; "Original Oil In Place (OOIP)"; Decimal)
        {
            Caption = 'Original Oil In Place (OOIP)';
            DataClassification = ToBeClassified;
            Description = 'Internal engineering estimate, BOE.';
        }
        field(7; "Proved Reserves (1P)"; Decimal)
        {
            Caption = 'Proved Reserves (1P)';
            DataClassification = ToBeClassified;
            Description = 'Internally estimated (not third-party certified) proved reserves, BOE.';
        }
        field(8; "Probable Reserves (2P)"; Decimal)
        {
            Caption = 'Probable Reserves (2P)';
            DataClassification = ToBeClassified;
            Description = 'Internally estimated (not third-party certified) probable reserves, BOE.';
        }
        field(9; "Possible Reserves (3P)"; Decimal)
        {
            Caption = 'Possible Reserves (3P)';
            DataClassification = ToBeClassified;
            Description = 'Internally estimated (not third-party certified) possible reserves, BOE.';
        }
        field(10; "Estimated By"; Text[100])
        {
            Caption = 'Estimated By';
            DataClassification = ToBeClassified;
            Description = 'Snapshot of the selected BC user name. Historical free-text preparers are retained until explicitly reselected.';
            TableRelation = User."User Name" where(State = const(Enabled));
            ValidateTableRelation = false;
            trigger OnLookup()
            begin
                EstimationMgt.LookupEstimatedBy(Rec);
            end;
            trigger OnValidate()
            begin
                EstimationMgt.ValidateEstimatedBy(Rec);
            end;
        }
        field(11; "Estimation Method"; Text[250])
        {
            Caption = 'Estimation Method';
            DataClassification = ToBeClassified;
            Description = 'Short description of how the estimate was derived (FR-04, FR-05).';
        }
        field(12; "Reserve Estimate Date"; Date)
        {
            Caption = 'Reserve Estimate Date';
            DataClassification = ToBeClassified;
            Description = 'Date the current figures were prepared (FR-04, FR-05).';
        }
        field(13; "Cumulative Production BOE"; Decimal)
        {
            Caption = 'Cumulative Production BOE';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("Production Entry Header"."Total BOE" where(Posted = filter(true), Cancelled = filter(false), "Reservoir Code" = field("Reservoir Code")));
            Description = 'Automatically calculated from posted Production Entry documents. Never entered manually (FR-19).';
        }
        field(14; "Remaining Reserves BOE"; Decimal)
        {
            Caption = 'Remaining Reserves BOE';
            DataClassification = ToBeClassified;
            Editable = false;
            Description = '1P reserves minus Cumulative Production BOE - kept in sync automatically (FR-19, FR-20).';
        }
        field(15; "Recovery Factor %"; Decimal)
        {
            Caption = 'Recovery Factor %';
            DataClassification = ToBeClassified;
            Description = 'Estimated ultimate recoverable oil divided by original oil in place, times 100. Informational; does not set reserves or depletion.';
            MinValue = 0;
            MaxValue = 100;
        }
        field(16; "Fixed Asset No."; Code[20])
        {
            Caption = 'Fixed Asset No.';
            DataClassification = ToBeClassified;
            TableRelation = "Fixed Asset";
            Description = 'Linked Fixed Asset used for UOP depletion posting (FR-22).';
        }
        field(17; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = ToBeClassified;
            TableRelation = "Depreciation Book";
            Description = 'Depreciation book used for UOP depletion posting (FR-22).';
        }
        field(18; "Total Capitalised Cost"; Decimal)
        {
            Caption = 'Total Capitalised Cost';
            DataClassification = ToBeClassified;
            Description = 'Development cost basis capitalised for depletion (FR-20).';
        }
        field(19; "Accumulated Depletion"; Decimal)
        {
            Caption = 'Accumulated Depletion';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("Depletion Worksheet"."Depletion Amount" where(Posted = filter(true), "Reservoir Code" = field("Reservoir Code")));
            Description = 'Automatically accumulated from posted Depletion Worksheet lines. Never entered manually (FR-20, FR-21).';
        }
        field(20; "Depletion Rate per BOE"; Decimal)
        {
            Caption = 'Depletion Rate per BOE';
            DataClassification = ToBeClassified;
            Editable = false;
            Description = 'Last calculated period rate - recalculated each period by the Depletion Calculation (FR-20).';
        }
        field(21; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            DataClassification = ToBeClassified;
            Description = 'COST CENTER dimension value used on transactions of this reservoir (FR-07, FR-31).';
            TableRelation = "Dimension Value".Code;
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                ValueCode: Code[20];
            begin
                ProdHelper.GetSetup(OGSetup);
                ValueCode := Rec."Cost Center Code";
                if DimHelper.LookupDimensionValue(OGSetup."Cost Center Dimension Code", ValueCode) then
                    Rec.Validate("Cost Center Code", ValueCode);
            end;
            trigger OnValidate()
            begin
                ProdHelper.GetSetup(OGSetup);
                DimHelper.ValidateDimensionValue(OGSetup."Cost Center Dimension Code", Rec."Cost Center Code");
            end;
        }
        field(22; "Estimation Method Code"; Code[20])
        {
            Caption = 'Estimation Method';
            DataClassification = CustomerContent;
            TableRelation = "Reserve Estimation Method".Code where(Blocked = const(false));
            trigger OnValidate()
            var
                Method: Record "Reserve Estimation Method";
            begin
                if Rec."Estimation Method Code" = '' then begin
                    if xRec."Estimation Method Code" <> '' then
                        Rec."Estimation Method" := '';
                    exit;
                end;
                Method.Get(Rec."Estimation Method Code");
                Method.TestField(Blocked, false);
                Method.TestField(Description);
                Rec."Estimation Method" := Method.Description;
            end;
        }
        field(23; "Estimated By User Security ID"; Guid)
        {
            Caption = 'Estimated By User Security ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Security ID";
            Description = 'Stable identity of the selected preparer. Existing historical names are not guessed or rewritten.';
        }
    }

    keys
    {
        key(PrimaryKey; "Reservoir Code")
        {
            Clustered = true;
        }
        key(FieldBlockWell; "Field/Block Code", "Well Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Reservoir Code", Description, "Field/Block Code", "Well Code") { }
    }

    trigger OnInsert()
    begin
        EstimationMgt.DefaultCurrentEstimator(Rec);
    end;

    // FR-05: automatic audit trail + keep Remaining Reserves in sync.
    trigger OnModify()
    var
        NewRemaining: Decimal;
    begin
        if (xRec."Proved Reserves (1P)" <> Rec."Proved Reserves (1P)") or
           (xRec."Probable Reserves (2P)" <> Rec."Probable Reserves (2P)") or
           (xRec."Possible Reserves (3P)" <> Rec."Possible Reserves (3P)") or
           (xRec."Estimated By" <> Rec."Estimated By") or
           (xRec."Estimation Method" <> Rec."Estimation Method") or
           (xRec."Estimation Method Code" <> Rec."Estimation Method Code") or
           (xRec."Estimated By User Security ID" <> Rec."Estimated By User Security ID") or
           (xRec."Recovery Factor %" <> Rec."Recovery Factor %") or
           (xRec."Reserve Estimate Date" <> Rec."Reserve Estimate Date")
        then begin
            // 1. Write the revision history record (preparer / method / date audit trail).
            Logger.Log(Rec, xRec);

            // Set the value in this same write; do not issue a second Modify
            // from inside the OnModify trigger or generate a duplicate audit event.
            Rec.CalcFields("Cumulative Production BOE");
            NewRemaining := Rec."Proved Reserves (1P)" - Rec."Cumulative Production BOE";
            if NewRemaining < 0 then
                NewRemaining := 0;
            Rec."Remaining Reserves BOE" := NewRemaining;
        end;
    end;

    var
        Logger: Codeunit "Reserve Revision Logger";
        EstimationMgt: Codeunit "Reserve Estimation Mgt.";
        ProdHelper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        OGSetup: Record "O&G Setup";
}
