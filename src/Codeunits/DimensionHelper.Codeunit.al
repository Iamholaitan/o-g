// -----------------------------------------------------------------------------
// Dimension Helper (FR-07)
// Dimension codes come from O&G Setup. Both lookups and posting use the same
// configured codes; no FIELD/WELL/etc. constants are used by these routines.
// -----------------------------------------------------------------------------
codeunit 70077 "Dimension Helper"
{
    var
        DimMgt: Codeunit DimensionManagement;

    procedure GetDimensionSetID(OGSetup: Record "O&G Setup"; FieldBlockCode: Code[20]; WellCode: Code[20]; ReservoirCode: Code[20]; CostCenterCode: Code[20]; JVPartnerCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        BuildDimensionBuffer(TempDimSetEntry, OGSetup, FieldBlockCode, WellCode, ReservoirCode, CostCenterCode, JVPartnerCode);
        if TempDimSetEntry.IsEmpty() then
            exit(0);
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    procedure GetDimensionSetID(OGSetup: Record "O&G Setup"; FieldBlockCode: Code[20]; WellCode: Code[20]; ReservoirCode: Code[20]; CostCenterCode: Code[20]; JVPartnerCode: Code[20]; EntityCode: Code[20]): Integer
    var
        TempEntry: Record "Dimension Set Entry" temporary;
        EntityMgt: Codeunit "O&G Entity Mgt.";
    begin
        BuildDimensionBuffer(TempEntry, OGSetup, FieldBlockCode, WellCode, ReservoirCode, CostCenterCode, JVPartnerCode);
        EntityMgt.AddEntity(TempEntry, EntityCode);
        if TempEntry.IsEmpty() then
            exit(0);
        exit(DimMgt.GetDimensionSetID(TempEntry));
    end;

    procedure BuildDimensionBuffer(var TempDimSetEntry: Record "Dimension Set Entry" temporary; OGSetup: Record "O&G Setup"; FieldBlockCode: Code[20]; WellCode: Code[20]; ReservoirCode: Code[20]; CostCenterCode: Code[20]; JVPartnerCode: Code[20])
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll(false);
        AddDimension(TempDimSetEntry, OGSetup."Field/Block Dimension Code", FieldBlockCode);
        AddDimension(TempDimSetEntry, OGSetup."Well Dimension Code", WellCode);
        AddDimension(TempDimSetEntry, OGSetup."Reservoir Dimension Code", ReservoirCode);
        AddDimension(TempDimSetEntry, OGSetup."Cost Center Dimension Code", CostCenterCode);
        AddDimension(TempDimSetEntry, OGSetup."JV Partner Dimension Code", JVPartnerCode);
    end;

    procedure LookupDimensionValue(DimensionCode: Code[20]; var ValueCode: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
        CurrentDimValue: Record "Dimension Value";
        DimValueList: Page "Dimension Value List";
    begin
        if DimensionCode = '' then
            Error('The dimension code is not configured. Ask the accountant to complete the dimension codes in O&G Setup.');
        DimValue.SetRange("Dimension Code", DimensionCode);
        DimValue.SetRange(Blocked, false);
        DimValue.SetRange("Dimension Value Type", DimValue."Dimension Value Type"::Standard);
        DimValueList.SetTableView(DimValue);
        if CurrentDimValue.Get(DimensionCode, ValueCode) then
            if (not CurrentDimValue.Blocked) and (CurrentDimValue."Dimension Value Type" = CurrentDimValue."Dimension Value Type"::Standard) then
                DimValueList.SetRecord(CurrentDimValue);
        DimValueList.LookupMode(true);
        if DimValueList.RunModal() <> Action::LookupOK then
            exit(false);
        DimValueList.GetRecord(DimValue);
        ValueCode := DimValue.Code;
        exit(true);
    end;

    procedure ValidateDimensionValue(DimensionCode: Code[20]; ValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        if ValueCode = '' then
            exit;
        if DimensionCode = '' then
            Error('A dimension code is missing in O&G Setup. Configure it before selecting value %1.', ValueCode);
        if not DimValue.Get(DimensionCode, ValueCode) then
            Error('Value %1 does not exist for dimension %2, as selected in O&G Setup.', ValueCode, DimensionCode);
        DimValue.TestField(Blocked, false);
        DimValue.TestField("Dimension Value Type", DimValue."Dimension Value Type"::Standard);
    end;

    local procedure AddDimension(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimensionCode: Code[20]; ValueCode: Code[20])
    begin
        if ValueCode = '' then
            exit;
        ValidateDimensionValue(DimensionCode, ValueCode);
        if TempDimSetEntry.Get(0, DimensionCode) then
            Error('Dimension %1 is assigned to more than one production dimension in O&G Setup. Use distinct dimension codes.', DimensionCode);
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Set ID" := 0;
        TempDimSetEntry.Validate("Dimension Code", DimensionCode);
        TempDimSetEntry.Validate("Dimension Value Code", ValueCode);
        TempDimSetEntry.Insert(false);
    end;
}
