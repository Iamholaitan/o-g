codeunit 70083 "O&G Entity Mgt."
{
    procedure DimensionCode(): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Global Dimension 1 Code");
        exit(GLSetup."Global Dimension 1 Code");
    end;

    procedure LookupValue(var EntityCode: Code[20]): Boolean
    var
        DimHelper: Codeunit "Dimension Helper";
    begin
        exit(DimHelper.LookupDimensionValue(DimensionCode(), EntityCode));
    end;

    procedure ValidateDimensionValue(EntityCode: Code[20])
    var
        DimHelper: Codeunit "Dimension Helper";
    begin
        if EntityCode = '' then
            exit;
        DimHelper.ValidateDimensionValue(DimensionCode(), EntityCode);
    end;

    procedure ValidateEntity(EntityCode: Code[20])
    var
        Entity: Record "O&G Entity";
    begin
        if EntityCode = '' then
            Error('Select an Entity (Global Dimension 1) on the document.');
        ValidateDimensionValue(EntityCode);
        if not Entity.Get(EntityCode) then
            Error('Classify Entity %1 in O&G Entities as Joint Operation or Operator before using it.', EntityCode);
        Entity.TestField(Blocked, false);
    end;

    procedure AddEntity(var TempEntry: Record "Dimension Set Entry" temporary; EntityCode: Code[20])
    var
        Code: Code[20];
    begin
        if EntityCode = '' then
            exit;
        ValidateEntity(EntityCode);
        Code := DimensionCode();
        if TempEntry.Get(0, Code) then
            Error('Global Dimension 1 (%1) is reserved for Entity in this setup and cannot also be a Field/Well/Reservoir/Cost Center dimension.', Code);
        TempEntry.Init();
        TempEntry."Dimension Set ID" := 0;
        TempEntry.Validate("Dimension Code", Code);
        TempEntry.Validate("Dimension Value Code", EntityCode);
        TempEntry.Insert(false);
    end;

    procedure SetEntity(DimensionSetID: Integer; EntityCode: Code[20]): Integer
    var
        TempEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        Code: Code[20];
    begin
        if EntityCode = '' then
            exit(DimensionSetID);
        ValidateEntity(EntityCode);
        Code := DimensionCode();
        DimMgt.GetDimensionSet(TempEntry, DimensionSetID);
        TempEntry.Reset();
        if TempEntry.Get(DimensionSetID, Code) then
            TempEntry.Delete();
        TempEntry.Init();
        TempEntry."Dimension Set ID" := DimensionSetID;
        TempEntry.Validate("Dimension Code", Code);
        TempEntry.Validate("Dimension Value Code", EntityCode);
        TempEntry.Insert(false);
        exit(DimMgt.GetDimensionSetID(TempEntry));
    end;
    procedure FromDimensionSet(DimSetID: Integer): Code[20]
    var
        Entry: Record "Dimension Set Entry";
    begin
        if Entry.Get(DimSetID, DimensionCode()) then
            exit(Entry."Dimension Value Code");
        exit('');
    end;

    procedure ProductionEntity(Header: Record "Production Entry Header"): Code[20]
    var
        Link: Record "Production Posting Link";
        Journal: Record "Item Journal Line";
        Value: Code[20];
        Candidate: Code[20];
        DimensionCorrection: Codeunit "Production Dimension Mgt.";
    begin
        DimensionCorrection.CheckNoActiveCorrection(Header."Document No.");
        if Header."Entity Code" <> '' then begin
            ValidateEntity(Header."Entity Code");
            exit(Header."Entity Code");
        end;
        // Legacy source: use reviewed/actual journal dimension evidence, not a
        // guessed operator default or today's reservoir ownership.
        Link.SetRange("Document No.", Header."Document No.");
        Link.SetFilter(State, '<>%1', Link.State::Cancelled);
        if Link.FindSet() then
            repeat
                Candidate := FromDimensionSet(Link."Dimension Set ID");
                MergeLegacyValue(Value, Candidate, Header."Document No.");
            until Link.Next() = 0
        else begin
            Journal.SetRange("Journal Template Name", Header."Item Journal Template Name");
            Journal.SetRange("Journal Batch Name", Header."Item Journal Batch Name");
            Journal.SetRange("Document No.", Header."Document No.");
            if Journal.FindSet() then
                repeat
                    Candidate := FromDimensionSet(Journal."Dimension Set ID");
                    MergeLegacyValue(Value, Candidate, Header."Document No.");
                until Journal.Next() = 0;
        end;
        if Value = '' then
            Value := FromDimensionSet(Header."Dimension Set ID");
        if Value = '' then
            Error('Production %1 has no reliable Entity classification. Use Correct Dimensions on Production Entries; the workflow will verify the related postings and record the selected Entity. An owner will not be guessed.', Header."Document No.");
        ValidateEntity(Value);
        exit(Value);
    end;

    local procedure MergeLegacyValue(var Value: Code[20]; Candidate: Code[20]; DocumentNo: Code[20])
    begin
        if Candidate = '' then
            Error('Production %1 has a related posting without Entity. Open Production Entries, choose Correct Dimensions, select the correct Entity and complete the correction, then suggest this worksheet again.', DocumentNo);
        if (Value <> '') and (Value <> Candidate) then
            Error('Legacy document %1 contains multiple Entities. Reconcile/split its source classification before a document-level depletion calculation.', DocumentNo);
        Value := Candidate;
    end;
}
