page 70066 "Correct Production Dimensions"
{
    PageType = StandardDialog;
    Caption = 'Correct Production Dimensions';
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(Main)
            {
                field(DocumentNo; DocumentNo) { ApplicationArea = All; Caption = 'Production Document'; Editable = false; }
                field(Entity; Entity)
                {
                    ApplicationArea = All;
                    Caption = 'Entity';
                    TableRelation = "O&G Entity"."Entity Code" where(Blocked = const(false));
                    ShowMandatory = true;
                    ToolTip = 'Correct Entity on the source and verified related postings. Amounts and quantities are not changed.';
                }
                field(Reason; Reason) { ApplicationArea = All; Caption = 'Reason'; ShowMandatory = true; MultiLine = true; }
            }
            group(OtherDimensions)
            {
                Caption = 'Other Dimensions (optional)';
                field(ChangeField; ChangeField) { ApplicationArea = All; Caption = 'Also Correct Field/Block'; }
                field(FieldValue; FieldValue)
                {
                    ApplicationArea = All; Caption = 'Field/Block'; Enabled = ChangeField; Lookup = true;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Helper.GetSetup(Setup);
                        exit(DimHelper.LookupDimensionValue(Setup."Field/Block Dimension Code", FieldValue));
                    end;
                }
                field(ChangeWell; ChangeWell) { ApplicationArea = All; Caption = 'Also Correct Well'; }
                field(WellValue; WellValue)
                {
                    ApplicationArea = All; Caption = 'Well'; Enabled = ChangeWell; Lookup = true;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Helper.GetSetup(Setup);
                        exit(DimHelper.LookupDimensionValue(Setup."Well Dimension Code", WellValue));
                    end;
                }
                field(ChangeCostCenter; ChangeCostCenter) { ApplicationArea = All; Caption = 'Also Correct Cost Center'; }
                field(CostCenterValue; CostCenterValue)
                {
                    ApplicationArea = All; Caption = 'Cost Center'; Enabled = ChangeCostCenter; Lookup = true;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Helper.GetSetup(Setup);
                        exit(DimHelper.LookupDimensionValue(Setup."Cost Center Dimension Code", CostCenterValue));
                    end;
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateInput();
        exit(true);
    end;
    var
        DocumentNo: Code[20];
        Entity: Code[20];
        FieldValue: Code[20];
        WellValue: Code[20];
        CostCenterValue: Code[20];
        ChangeField: Boolean;
        ChangeWell: Boolean;
        ChangeCostCenter: Boolean;
        Reason: Text[250];
        Setup: Record "O&G Setup";
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";

    procedure SetSource(Header: Record "Production Entry Header")
    begin
        DocumentNo := Header."Document No.";
        Entity := Header."Entity Code";
        FieldValue := Header."Field/Block Code";
        WellValue := Header."Well Code";
        CostCenterValue := Header."Cost Center Code";
    end;

    procedure PrepareCorrection(): Integer
    var
        Mgt: Codeunit "Production Dimension Mgt.";
    begin
        ValidateInput();
        exit(Mgt.Prepare(DocumentNo, Entity, FieldValue, WellValue, CostCenterValue, ChangeField, ChangeWell, ChangeCostCenter, Reason));
    end;

    local procedure ValidateInput()
    var
        EntityMgt: Codeunit "O&G Entity Mgt.";
    begin
        EntityMgt.ValidateEntity(Entity);
        if Reason = '' then
            Error('Enter a reason for the correction.');
        Helper.GetSetup(Setup);
        if ChangeField then
            DimHelper.ValidateDimensionValue(Setup."Field/Block Dimension Code", FieldValue);
        if ChangeWell then
            DimHelper.ValidateDimensionValue(Setup."Well Dimension Code", WellValue);
        if ChangeCostCenter then
            DimHelper.ValidateDimensionValue(Setup."Cost Center Dimension Code", CostCenterValue);
    end;
}
