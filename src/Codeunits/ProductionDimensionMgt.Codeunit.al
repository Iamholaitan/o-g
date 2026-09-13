// Audited classification correction. G/L changes use the STANDARD BC dimension
// correction engine. Inventory/value/source changes are applied only after the
// native G/L stage succeeds; native commits make this a resumable workflow.
// No quantities, posting dates, costs or amounts are edited here.
codeunit 70087 "Production Dimension Mgt."
{
    Permissions = tabledata "Production Dim. Correction" = RIMD,
                  tabledata "Production Dim. Change" = RIMD,
                  tabledata "Production Entry Header" = RM,
                  tabledata "Production Posting Link" = RM,
                  tabledata "Production Ledger Link" = RM,
                  tabledata "Item Journal Line" = RM,
                  tabledata "Item Ledger Entry" = RM,
                  tabledata "Value Entry" = RM;

    var
        DimMgt: Codeunit DimensionManagement;
        EntityMgt: Codeunit "O&G Entity Mgt.";
        DimHelper: Codeunit "Dimension Helper";
        NativeMgt: Codeunit "Dimension Correction Mgt";

    procedure CheckNoActiveCorrection(DocumentNo: Code[20])
    var
        Correction: Record "Production Dim. Correction";
    begin
        Correction.SetRange("Document No.", DocumentNo);
        Correction.SetFilter(State, '<>%1&<>%2', Correction.State::Completed, Correction.State::Cancelled);
        if Correction.FindFirst() then
            Error('Dimension correction %1 for %2 is unfinished. Open Dimension History and resume/review it before posting, reversing or calculating new financial entries.', Correction."Entry No.", DocumentNo);
    end;

    procedure Prepare(DocumentNo: Code[20]; NewEntity: Code[20]; NewField: Code[20]; NewWell: Code[20]; NewCostCenter: Code[20]; ChangeField: Boolean; ChangeWell: Boolean; ChangeCostCenter: Boolean; Reason: Text[250]): Integer
    var
        Header: Record "Production Entry Header";
        Setup: Record "O&G Setup";
        Correction: Record "Production Dim. Correction";
        Helper: Codeunit "Production Entry Helper";
    begin
        if Reason = '' then
            Error('Enter a reason for correcting the dimensions.');
        CheckNoActiveCorrection(DocumentNo);
        Header.LockTable();
        Header.Get(DocumentNo);
        CheckNoActiveCorrection(DocumentNo);
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        Header.TestField("Record Kind", Header."Record Kind"::Production);
        if Header."Reversed By Document No." <> '' then
            Error('This source already has a reversal. Correct both sides through a reviewed accounting process; this action will not retag only one side.');
        Helper.GetSetup(Setup);
        EntityMgt.ValidateEntity(NewEntity);
        Correction.Init();
        Correction."Entry No." := 0;
        Correction."Document No." := DocumentNo;
        Correction.Reason := Reason;
        Correction."Created At" := CurrentDateTime();
        Correction."Created By" := UserSecurityId();
        Correction."Last Run By" := UserSecurityId();
        Correction."Old Source Dimension Set ID" := Header."Dimension Set ID";
        Correction."Old Entity Code" := Header."Entity Code";
        Correction."New Entity Code" := NewEntity;
        Correction."Old Field Code" := Header."Field/Block Code";
        Correction."New Field Code" := Header."Field/Block Code";
        Correction."Old Well Code" := Header."Well Code";
        Correction."New Well Code" := Header."Well Code";
        Correction."Old Cost Center Code" := Header."Cost Center Code";
        Correction."New Cost Center Code" := Header."Cost Center Code";
        Correction."Entity Dimension Code" := EntityMgt.DimensionCode();
        Correction."Field Dimension Code" := Setup."Field/Block Dimension Code";
        Correction."Well Dimension Code" := Setup."Well Dimension Code";
        Correction."Cost Center Dimension Code" := Setup."Cost Center Dimension Code";
        Correction."Reservoir Code" := Header."Reservoir Code";
        Correction."Change Field" := ChangeField;
        Correction."Change Well" := ChangeWell;
        Correction."Change Cost Center" := ChangeCostCenter;
        if ChangeField then begin
            DimHelper.ValidateDimensionValue(Correction."Field Dimension Code", NewField);
            Correction."New Field Code" := NewField;
        end;
        if ChangeWell then begin
            DimHelper.ValidateDimensionValue(Correction."Well Dimension Code", NewWell);
            Correction."New Well Code" := NewWell;
        end;
        if ChangeCostCenter then begin
            DimHelper.ValidateDimensionValue(Correction."Cost Center Dimension Code", NewCostCenter);
            Correction."New Cost Center Code" := NewCostCenter;
        end;
        CheckCorrectionPolicy(Correction."Entity Dimension Code", NewEntity);
        if ChangeField then
            CheckCorrectionPolicy(Correction."Field Dimension Code", NewField);
        if ChangeWell then
            CheckCorrectionPolicy(Correction."Well Dimension Code", NewWell);
        if ChangeCostCenter then
            CheckCorrectionPolicy(Correction."Cost Center Dimension Code", NewCostCenter);
        Correction."New Source Dimension Set ID" := TargetDimensionSet(Correction, Header."Dimension Set ID");
        Correction.Insert(true);
        BuildPlan(Correction, Header);
        if not HasAnyChange(Correction) then
            Error('The source and all verified related postings already have the selected dimensions. Nothing was changed.');
        CreateNativeCorrection(Correction);
        Correction.Modify(true);
        exit(Correction."Entry No.");
    end;

    procedure RunPrepared(CorrectionNo: Integer)
    var
        Correction: Record "Production Dim. Correction";
        Native: Record "Dimension Correction";
        Failure: Text;
    begin
        Correction.LockTable();
        Correction.Get(CorrectionNo);
        if Correction.State = Correction.State::Completed then begin
            Message('The dimension correction is already complete.');
            exit;
        end;
        if not (Correction.State in [Correction.State::Prepared, Correction.State::Failed]) then
            Error('This correction is already running or was interrupted while running. Do not launch a second writer. Ask an administrator to verify the native correction/session before recovery.');
        Correction.State := Correction.State::"G/L Correction";
        Correction."Last Run At" := CurrentDateTime();
        Correction."Last Run By" := UserSecurityId();
        Correction."Error Text" := '';
        Correction.Modify(true);
        // Deliberate checkpoint: the native BC G/L dimension-correction engine
        // commits internally. The audit/plan must survive a failure for resume.
        // This is NOT a COMMIT workaround before an input dialog or journal posting.
        Commit();
        ClearLastError();
        if Codeunit.Run(Codeunit::"Production Dim. Apply", Correction) then begin
            Correction.Get(CorrectionNo);
            Message('Dimensions corrected for %1. The production source and verified related postings now use the selected classification. Quantities and amounts were not changed. Review/re-suggest unposted depletion and royalty worksheets; review already journalised downstream accounting and analysis views separately.', Correction."Document No.");
        end else begin
            Failure := GetLastErrorText();
            Correction.Get(CorrectionNo);
            Correction.State := Correction.State::Failed;
            Correction."Error Text" := CopyStr(Failure, 1, MaxStrLen(Correction."Error Text"));
            Correction.Modify(true);
            if Correction."G/L Correction Entry No." <> 0 then
                if Native.Get(Correction."G/L Correction Entry No.") then
                    if not Native.Completed then begin
                        Native.Status := Native.Status::Failed;
                        Native."Error Message" := CopyStr(Failure, 1, MaxStrLen(Native."Error Message"));
                        Native.Modify(true);
                    end;
            Commit();
            Message('Correction for %1 is NOT complete. The native G/L stage may have committed some changes; do not create another correction or reverse this source yet. Open Dimension History and Resume after resolving: %2', Correction."Document No.", Failure);
        end;
    end;

    procedure ApplyPrepared(CorrectionNo: Integer)
    var
        Correction: Record "Production Dim. Correction";
        Native: Record "Dimension Correction";
        NativeRun: Codeunit "Dim Correction Run";
        Header: Record "Production Entry Header";
        Change: Record "Production Dim. Change";
        GLSetup: Record "General Ledger Setup";
        EntryLock: Record "Item Ledger Entry";
        ValueLock: Record "Value Entry";
    begin
        Correction.Get(CorrectionNo);
        if Correction.State = Correction.State::Completed then
            exit;
        Header.Get(Correction."Document No.");
        GLSetup.Get();
        GLSetup.TestField("Global Dimension 1 Code", Correction."Entity Dimension Code");
        CheckCorrectionPolicy(Correction."Entity Dimension Code", Correction."New Entity Code");
        if Correction."Change Field" then
            CheckCorrectionPolicy(Correction."Field Dimension Code", Correction."New Field Code");
        if Correction."Change Well" then
            CheckCorrectionPolicy(Correction."Well Dimension Code", Correction."New Well Code");
        if Correction."Change Cost Center" then
            CheckCorrectionPolicy(Correction."Cost Center Dimension Code", Correction."New Cost Center Code");
        CheckSourceUnchanged(Header, Correction);
        CheckScopeStillComplete(Correction);
        ValidatePlan(Correction, false);
        if Correction."G/L Correction Entry No." <> 0 then begin
            Native.Get(Correction."G/L Correction Entry No.");
            if not Native.Completed then begin
                VerifyNativeRequest(Correction, Native);
                NativeMgt.VerifyCanStartJob(Native);
                Correction.State := Correction.State::"G/L Correction";
                Correction.Modify(true);
                NativeRun.RunDimensionCorrection(Native);
            end;
            Native.Get(Correction."G/L Correction Entry No.");
            Native.TestField(Completed, true);
            Native.TestField(Status, Native.Status::Completed);
        end;
        // The inventory/source phase is one transaction, AFTER native GL success.
        // Block and recheck concurrent changes; no quantity or amount assignment.
        Header.LockTable();
        EntryLock.LockTable();
        ValueLock.LockTable();
        Header.Get(Correction."Document No.");
        CheckSourceUnchanged(Header, Correction);
        CheckScopeStillComplete(Correction);
        ValidatePlan(Correction, true);
        Correction.Get(CorrectionNo);
        Correction.State := Correction.State::"Applying Source";
        Correction.Modify(true);
        Change.SetRange("Correction Entry No.", CorrectionNo);
        if Change.FindSet(true) then
            repeat
                ApplyChange(Change);
                Change.Applied := true;
                Change.Modify(true);
            until Change.Next() = 0;
        Header."Entity Code" := Correction."New Entity Code";
        Header."Field/Block Code" := Correction."New Field Code";
        Header."Well Code" := Correction."New Well Code";
        Header."Cost Center Code" := Correction."New Cost Center Code";
        Header."Dimension Set ID" := Correction."New Source Dimension Set ID";
        Header."Dimension Correction No." := CorrectionNo;
        Header.Modify(false);
        Correction.State := Correction.State::Completed;
        Correction."Completed At" := CurrentDateTime();
        Correction."Error Text" := '';
        Correction.Modify(true);
    end;

    procedure ValidateSourceChange(NewHeader: Record "Production Entry Header"; OldHeader: Record "Production Entry Header")
    var
        Correction: Record "Production Dim. Correction";
        Native: Record "Dimension Correction";
    begin
        if NewHeader."Dimension Correction No." = 0 then
            Error('Use Correct Dimensions; posted source dimensions cannot be edited directly.');
        Correction.Get(NewHeader."Dimension Correction No.");
        Correction.TestField("Document No.", OldHeader."Document No.");
        Correction.TestField(State, Correction.State::"Applying Source");
        Correction.TestField("Last Run By", UserSecurityId());
        CheckSourceUnchanged(OldHeader, Correction);
        NewHeader.TestField("Entity Code", Correction."New Entity Code");
        NewHeader.TestField("Field/Block Code", Correction."New Field Code");
        NewHeader.TestField("Well Code", Correction."New Well Code");
        NewHeader.TestField("Cost Center Code", Correction."New Cost Center Code");
        NewHeader.TestField("Dimension Set ID", Correction."New Source Dimension Set ID");
        if Correction."G/L Correction Entry No." <> 0 then begin
            Native.Get(Correction."G/L Correction Entry No.");
            Native.TestField(Completed, true);
            Native.TestField(Status, Native.Status::Completed);
        end;
    end;

    procedure CancelUnfinished(CorrectionNo: Integer)
    var
        Correction: Record "Production Dim. Correction";
        Native: Record "Dimension Correction";
        Change: Record "Production Dim. Change";
    begin
        Correction.LockTable();
        Correction.Get(CorrectionNo);
        if not (Correction.State in [Correction.State::Prepared, Correction.State::Failed]) then
            Error('Only a prepared or failed request may be cancelled. A running/completed correction is not deleted.');
        Change.SetRange("Correction Entry No.", CorrectionNo);
        Change.SetRange(Applied, true);
        if not Change.IsEmpty() then
            Error('This request has applied source/inventory changes. Complete or review it; do not cancel only the audit record.');
        if Correction.State = Correction.State::Completed then
            Error('A completed correction is not deleted. Use a new audited correction if values need changing again.');
        if Correction."G/L Correction Entry No." <> 0 then begin
            Native.Get(Correction."G/L Correction Entry No.");
            if (Native."Total Updated Ledger Entries" <> 0) and (Native.Status <> Native.Status::"Undo Completed") then
                Error('Some G/L entries changed. First complete or undo native G/L dimension correction %1 in standard BC; cancelling only this source request would leave inconsistent ledgers.', Native."Entry No.");
        end;
        Correction.State := Correction.State::Cancelled;
        Correction.Modify(true);
    end;

    local procedure HasAnyChange(Correction: Record "Production Dim. Correction"): Boolean
    var
        Change: Record "Production Dim. Change";
    begin
        if (Correction."Old Source Dimension Set ID" <> Correction."New Source Dimension Set ID") or
           (Correction."Old Entity Code" <> Correction."New Entity Code") or
           (Correction."Old Field Code" <> Correction."New Field Code") or
           (Correction."Old Well Code" <> Correction."New Well Code") or
           (Correction."Old Cost Center Code" <> Correction."New Cost Center Code") then
            exit(true);
        Change.SetRange("Correction Entry No.", Correction."Entry No.");
        if Change.FindSet() then
            repeat
                if Change."Old Dimension Set ID" <> Change."New Dimension Set ID" then
                    exit(true);
            until Change.Next() = 0;
        exit(false);
    end;

    local procedure BuildPlan(var Correction: Record "Production Dim. Correction"; Header: Record "Production Entry Header")
    var
        Link: Record "Production Posting Link";
        LedgerLink: Record "Production Ledger Link";
        Journal: Record "Item Journal Line";
        Entry: Record "Item Ledger Entry";
        Value: Record "Value Entry";
        Relation: Record "G/L - Item Ledger Relation";
        GLEntry: Record "G/L Entry";
        NewID: Integer;
    begin
        Link.SetRange("Document No.", Header."Document No.");
        Link.SetFilter(State, '<>%1', Link.State::Cancelled);
        if not Link.FindSet() then
            Error('No verified posting evidence is available for this source.');
        repeat
            if Journal.Get(Link."Journal Template Name", Link."Journal Batch Name", Link."Journal Line No.") and
               (Journal."O&G Production Link No." = Link."Entry No.") then begin
                NewID := TargetDimensionSet(Correction, Journal."Dimension Set ID");
                CheckItemDimensions(Journal."Item No.", NewID);
                if AddPlan(Correction, Database::"Item Journal Line", Journal.RecordId, Journal.SystemId, Journal."Line No.", Journal."Dimension Set ID", NewID, Journal.Quantity, Journal.Amount, Journal."Item No.") then
                    Correction."Journal Line Count" += 1;
            end else
                if Link.State in [Link.State::Pending, Link.State::Partial] then
                    Error('A pending source journal row is missing. Reconcile the posting before correcting dimensions.');
            AddPlan(Correction, Database::"Production Posting Link", Link.RecordId, Link.SystemId, Link."Entry No.", Link."Dimension Set ID", TargetDimensionSet(Correction, Link."Dimension Set ID"), Link.Quantity, 0, 'Posting evidence');
        until Link.Next() = 0;
        LedgerLink.SetRange("Document No.", Header."Document No.");
        if LedgerLink.FindSet() then
            repeat
                Entry.Get(LedgerLink."Item Ledger Entry No.");
                NewID := TargetDimensionSet(Correction, Entry."Dimension Set ID");
                CheckItemDimensions(Entry."Item No.", NewID);
                if AddPlan(Correction, Database::"Item Ledger Entry", Entry.RecordId, Entry.SystemId, Entry."Entry No.", Entry."Dimension Set ID", NewID, Entry.Quantity, 0, Entry."Item No.") then
                    Correction."Item Entry Count" += 1;
                AddPlan(Correction, Database::"Production Ledger Link", LedgerLink.RecordId, LedgerLink.SystemId, LedgerLink."Item Ledger Entry No.", LedgerLink."Dimension Set ID", NewID, LedgerLink."Quantity Base", 0, 'Ledger evidence');
                Value.Reset();
                Value.SetRange("Item Ledger Entry No.", Entry."Entry No.");
                if Value.FindSet() then
                    repeat
                        if AddPlan(Correction, Database::"Value Entry", Value.RecordId, Value.SystemId, Value."Entry No.", Value."Dimension Set ID", TargetDimensionSet(Correction, Value."Dimension Set ID"), Value."Item Ledger Entry Quantity", Value."Cost Amount (Actual)" + Value."Cost Amount (Expected)", Value."Item No.") then
                            Correction."Value Entry Count" += 1;
                        Relation.SetRange("Value Entry No.", Value."Entry No.");
                        if Relation.IsEmpty() and ((Value."Cost Posted to G/L" <> 0) or (Value."Expected Cost Posted to G/L" <> 0)) then
                            Error('Value entry %1 says cost was posted to G/L, but its G/L relation is missing. Reconcile the ledger evidence before an all-postings dimension correction.', Value."Entry No.");
                        if Relation.FindSet() then
                            repeat
                                GLEntry.Get(Relation."G/L Entry No.");
                                NewID := TargetDimensionSet(Correction, GLEntry."Dimension Set ID");
                                if NewID <> GLEntry."Dimension Set ID" then begin
                                    CheckExclusiveGLEntry(GLEntry."Entry No.", Header."Document No.");
                                    CheckGLDimensions(GLEntry, NewID);
                                end;
                                if AddPlan(Correction, Database::"G/L Entry", GLEntry.RecordId, GLEntry.SystemId, GLEntry."Entry No.", GLEntry."Dimension Set ID", NewID, 0, GLEntry.Amount, GLEntry."G/L Account No.") then
                                    if NewID <> GLEntry."Dimension Set ID" then
                                        Correction."G/L Entry Count" += 1;
                            until Relation.Next() = 0;
                    until Value.Next() = 0;
            until LedgerLink.Next() = 0;
    end;

    local procedure AddPlan(Correction: Record "Production Dim. Correction"; TableID: Integer; ID: RecordId; SystemID: Guid; EntryNo: Integer; OldID: Integer; NewID: Integer; Quantity: Decimal; Amount: Decimal; Description: Text): Boolean
    var
        Change: Record "Production Dim. Change";
        NextNo: Integer;
    begin
        Change.SetRange("Correction Entry No.", Correction."Entry No.");
        Change.SetRange("Table ID", TableID);
        Change.SetRange("System ID", SystemID);
        if not Change.IsEmpty() then
            exit(false);
        Change.Reset();
        Change.SetRange("Correction Entry No.", Correction."Entry No.");
        if Change.FindLast() then
            NextNo := Change."Line No." + 1
        else
            NextNo := 1;
        Change.Init();
        Change."Correction Entry No." := Correction."Entry No.";
        Change."Line No." := NextNo;
        Change."Table ID" := TableID;
        Change."Record ID" := ID;
        Change."System ID" := SystemID;
        Change."Entry No." := EntryNo;
        Change."Old Dimension Set ID" := OldID;
        Change."New Dimension Set ID" := NewID;
        Change."Quantity Snapshot" := Quantity;
        Change."Amount Snapshot" := Amount;
        Change.Description := CopyStr(Description, 1, MaxStrLen(Change.Description));
        Change.Insert(true);
        exit(true);
    end;

    local procedure CreateNativeCorrection(var Correction: Record "Production Dim. Correction")
    var
        Change: Record "Production Dim. Change";
        GLEntry: Record "G/L Entry";
        Native: Record "Dimension Correction";
    begin
        if Correction."G/L Entry Count" = 0 then
            exit;
        Change.SetRange("Correction Entry No.", Correction."Entry No.");
        Change.SetRange("Table ID", Database::"G/L Entry");
        if Change.FindSet() then
            repeat
                if Change."Old Dimension Set ID" <> Change."New Dimension Set ID" then begin
                    GLEntry.Get(Change."Entry No.");
                    GLEntry.Mark(true);
                end;
            until Change.Next() = 0;
        GLEntry.MarkedOnly(true);
        Native.LockTable();
        NativeMgt.CreateCorrectionFromSelection(GLEntry, Native);
        Native.Description := CopyStr('Production ' + Correction."Document No." + ': ' + Correction.Reason, 1, MaxStrLen(Native.Description));
        // No scheduling dialog is opened from this controlled synchronous stage.
        // Rebuild G/L/item analysis views after the complete cross-ledger correction.
        Native."Update Analysis Views" := false;
        Native.Modify(true);
        SetNativeChange(Native."Entry No.", Correction."Entity Dimension Code", Correction."New Entity Code");
        if Correction."Change Field" then
            SetNativeChange(Native."Entry No.", Correction."Field Dimension Code", Correction."New Field Code");
        if Correction."Change Well" then
            SetNativeChange(Native."Entry No.", Correction."Well Dimension Code", Correction."New Well Code");
        if Correction."Change Cost Center" then
            SetNativeChange(Native."Entry No.", Correction."Cost Center Dimension Code", Correction."New Cost Center Code");
        Correction."G/L Correction Entry No." := Native."Entry No.";
    end;

    local procedure SetNativeChange(CorrectionNo: Integer; DimensionCode: Code[20]; ValueCode: Code[20])
    var
        Change: Record "Dim Correction Change";
    begin
        if not Change.Get(CorrectionNo, DimensionCode) then begin
            Change.Init();
            Change."Dimension Correction Entry No." := CorrectionNo;
            Change."Dimension Code" := DimensionCode;
            Change."Change Type" := Change."Change Type"::Add;
            Change.Insert(true);
        end;
        if ValueCode = '' then
            Change.Validate("Change Type", Change."Change Type"::Remove)
        else
            Change.Validate("New Value", ValueCode);
        Change.Modify(true);
    end;

    local procedure VerifyNativeRequest(Correction: Record "Production Dim. Correction"; Native: Record "Dimension Correction")
    var
        Criteria: Record "Dim Correct Selection Criteria";
        NativeChange: Record "Dim Correction Change";
        Change: Record "Production Dim. Change";
        Entry: Record "G/L Entry";
        FilterText: Text;
        ExpectedValue: Code[20];
        Allowed: Boolean;
        Count: Integer;
    begin
        // Native audit pages are accessible for review/recovery. Do not execute
        // a request whose selection or values were changed outside this source plan.
        Criteria.SetRange("Dimension Correction Entry No.", Native."Entry No.");
        if Criteria.Count() <> 1 then
            Error('The native G/L correction selection was changed. Review it before resuming this production correction.');
        Criteria.FindFirst();
        Criteria.TestField("Filter Type", Criteria."Filter Type"::Manual);
        Criteria.GetSelectionFilter(FilterText);
        Entry.SetView(FilterText);
        if Entry.FindSet() then
            repeat
                Change.Reset();
                Change.SetRange("Correction Entry No.", Correction."Entry No.");
                Change.SetRange("Table ID", Database::"G/L Entry");
                Change.SetRange("System ID", Entry.SystemId);
                if not Change.FindFirst() then
                    Error('The native G/L correction includes an entry outside this production plan.');
                if Change."Old Dimension Set ID" = Change."New Dimension Set ID" then
                    Error('The native G/L correction selection differs from the prepared plan.');
                Count += 1;
            until Entry.Next() = 0;
        if Count <> Correction."G/L Entry Count" then
            Error('The native G/L correction no longer selects the complete prepared entry set.');
        NativeChange.SetRange("Dimension Correction Entry No.", Native."Entry No.");
        NativeChange.SetFilter("Change Type", '<>%1', NativeChange."Change Type"::"No Change");
        if NativeChange.FindSet() then
            repeat
                Allowed := false;
                ExpectedValue := '';
                if NativeChange."Dimension Code" = Correction."Entity Dimension Code" then begin
                    Allowed := true; ExpectedValue := Correction."New Entity Code";
                end;
                if Correction."Change Field" and (NativeChange."Dimension Code" = Correction."Field Dimension Code") then begin
                    Allowed := true; ExpectedValue := Correction."New Field Code";
                end;
                if Correction."Change Well" and (NativeChange."Dimension Code" = Correction."Well Dimension Code") then begin
                    Allowed := true; ExpectedValue := Correction."New Well Code";
                end;
                if Correction."Change Cost Center" and (NativeChange."Dimension Code" = Correction."Cost Center Dimension Code") then begin
                    Allowed := true; ExpectedValue := Correction."New Cost Center Code";
                end;
                if not Allowed then
                    Error('The native correction contains an unrequested dimension change.');
                if ExpectedValue = '' then
                    NativeChange.TestField("Change Type", NativeChange."Change Type"::Remove)
                else begin
                    if not (NativeChange."Change Type" in [NativeChange."Change Type"::Add, NativeChange."Change Type"::Change]) then
                        Error('The native dimension change type differs from the prepared request.');
                    NativeChange.TestField("New Value", ExpectedValue);
                end;
            until NativeChange.Next() = 0;
        RequireNativeChange(Native."Entry No.", Correction."Entity Dimension Code");
        if Correction."Change Field" then
            RequireNativeChange(Native."Entry No.", Correction."Field Dimension Code");
        if Correction."Change Well" then
            RequireNativeChange(Native."Entry No.", Correction."Well Dimension Code");
        if Correction."Change Cost Center" then
            RequireNativeChange(Native."Entry No.", Correction."Cost Center Dimension Code");
    end;

    local procedure RequireNativeChange(CorrectionNo: Integer; DimensionCode: Code[20])
    var
        Change: Record "Dim Correction Change";
    begin
        Change.Get(CorrectionNo, DimensionCode);
        if Change."Change Type" = Change."Change Type"::"No Change" then
            Error('A requested native dimension change was removed. Review the prepared request.');
    end;

    local procedure TargetDimensionSet(Correction: Record "Production Dim. Correction"; OldID: Integer): Integer
    var
        Temp: Record "Dimension Set Entry" temporary;
        NewID: Integer;
    begin
        DimMgt.GetDimensionSet(Temp, OldID);
        ReplaceValue(Temp, OldID, Correction."Entity Dimension Code", Correction."New Entity Code");
        if Correction."Change Field" then
            ReplaceValue(Temp, OldID, Correction."Field Dimension Code", Correction."New Field Code");
        if Correction."Change Well" then
            ReplaceValue(Temp, OldID, Correction."Well Dimension Code", Correction."New Well Code");
        if Correction."Change Cost Center" then
            ReplaceValue(Temp, OldID, Correction."Cost Center Dimension Code", Correction."New Cost Center Code");
        NewID := DimMgt.GetDimensionSetID(Temp);
        if not DimMgt.CheckDimIDComb(NewID) then
            Error(DimMgt.GetDimCombErr());
        exit(NewID);
    end;

    local procedure ReplaceValue(var Temp: Record "Dimension Set Entry" temporary; SetID: Integer; DimensionCode: Code[20]; ValueCode: Code[20])
    begin
        if DimensionCode = '' then
            Error('A selected dimension code is missing from setup.');
        if Temp.Get(SetID, DimensionCode) then
            Temp.Delete(false);
        if ValueCode = '' then
            exit;
        DimHelper.ValidateDimensionValue(DimensionCode, ValueCode);
        Temp.Init();
        Temp."Dimension Set ID" := SetID;
        Temp.Validate("Dimension Code", DimensionCode);
        Temp.Validate("Dimension Value Code", ValueCode);
        Temp.Insert(false);
    end;

    local procedure CheckCorrectionPolicy(DimensionCode: Code[20]; ValueCode: Code[20])
    var
        NativeChange: Record "Dim Correction Change" temporary;
    begin
        NativeChange."Dimension Code" := DimensionCode;
        NativeMgt.VerifyIfDimensionCanBeChanged(NativeChange);
        if ValueCode <> '' then
            DimHelper.ValidateDimensionValue(DimensionCode, ValueCode);
    end;

    local procedure CheckItemDimensions(ItemNo: Code[20]; DimID: Integer)
    var
        Tables: array[10] of Integer;
        Nos: array[10] of Code[20];
    begin
        Tables[1] := Database::Item;
        Nos[1] := ItemNo;
        if not DimMgt.CheckDimValuePosting(Tables, Nos, DimID) then
            Error(DimMgt.GetDimValuePostingErr());
    end;

    local procedure CheckGLDimensions(Entry: Record "G/L Entry"; DimID: Integer)
    var
        Tables: array[10] of Integer;
        Nos: array[10] of Code[20];
    begin
        Tables[1] := Database::"G/L Account";
        Nos[1] := Entry."G/L Account No.";
        if not DimMgt.CheckDimValuePosting(Tables, Nos, DimID) then
            Error(DimMgt.GetDimValuePostingErr());
    end;

    local procedure CheckExclusiveGLEntry(GLNo: Integer; DocumentNo: Code[20])
    var
        Relation: Record "G/L - Item Ledger Relation";
        Value: Record "Value Entry";
        Link: Record "Production Ledger Link";
    begin
        Relation.SetRange("G/L Entry No.", GLNo);
        if Relation.FindSet() then
            repeat
                Value.Get(Relation."Value Entry No.");
                if not Link.Get(Value."Item Ledger Entry No.") then
                    Error('G/L entry %1 also represents inventory outside %2. Correcting its dimension would retag another transaction. Use a reviewed reclassification or a correction covering all related sources.', GLNo, DocumentNo);
                Link.TestField("Document No.", DocumentNo);
            until Relation.Next() = 0;
    end;

    local procedure CheckSourceUnchanged(Header: Record "Production Entry Header"; Correction: Record "Production Dim. Correction")
    begin
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        Header.TestField("Reversed By Document No.", '');
        Header.TestField("Reservoir Code", Correction."Reservoir Code");
        Header.TestField("Entity Code", Correction."Old Entity Code");
        Header.TestField("Field/Block Code", Correction."Old Field Code");
        Header.TestField("Well Code", Correction."Old Well Code");
        Header.TestField("Cost Center Code", Correction."Old Cost Center Code");
        Header.TestField("Dimension Set ID", Correction."Old Source Dimension Set ID");
    end;

    local procedure ValidatePlan(Correction: Record "Production Dim. Correction"; GLMustBeComplete: Boolean)
    var
        Change: Record "Production Dim. Change";
        Ref: RecordRef;
        GL: Record "G/L Entry";
        ItemEntry: Record "Item Ledger Entry";
        Value: Record "Value Entry";
        Journal: Record "Item Journal Line";
        Link: Record "Production Posting Link";
        LedgerLink: Record "Production Ledger Link";
        DimID: Integer;
        ID: Guid;
    begin
        Change.SetRange("Correction Entry No.", Correction."Entry No.");
        if Change.FindSet() then
            repeat
                Ref.Get(Change."Record ID");
                case Change."Table ID" of
                    Database::"G/L Entry": begin
                        Ref.SetTable(GL); DimID := GL."Dimension Set ID"; ID := GL.SystemId;
                        GL.TestField(Amount, Change."Amount Snapshot");
                        if Change."Old Dimension Set ID" <> Change."New Dimension Set ID" then begin
                            CheckExclusiveGLEntry(GL."Entry No.", Correction."Document No.");
                            CheckGLDimensions(GL, Change."New Dimension Set ID");
                        end;
                        if GLMustBeComplete then
                            GL.TestField("Dimension Set ID", Change."New Dimension Set ID");
                    end;
                    Database::"Item Ledger Entry": begin
                        Ref.SetTable(ItemEntry); DimID := ItemEntry."Dimension Set ID"; ID := ItemEntry.SystemId;
                        ItemEntry.TestField(Quantity, Change."Quantity Snapshot");
                    end;
                    Database::"Value Entry": begin
                        Ref.SetTable(Value); DimID := Value."Dimension Set ID"; ID := Value.SystemId;
                        Value.TestField("Item Ledger Entry Quantity", Change."Quantity Snapshot");
                    end;
                    Database::"Item Journal Line": begin
                        Ref.SetTable(Journal); DimID := Journal."Dimension Set ID"; ID := Journal.SystemId;
                        Journal.TestField(Quantity, Change."Quantity Snapshot");
                    end;
                    Database::"Production Posting Link": begin
                        Ref.SetTable(Link); DimID := Link."Dimension Set ID"; ID := Link.SystemId;
                        Link.TestField(Quantity, Change."Quantity Snapshot");
                    end;
                    Database::"Production Ledger Link": begin
                        Ref.SetTable(LedgerLink); DimID := LedgerLink."Dimension Set ID"; ID := LedgerLink.SystemId;
                        LedgerLink.TestField("Quantity Base", Change."Quantity Snapshot");
                    end;
                end;
                if ID <> Change."System ID" then
                    Error('A planned record was replaced. Review the correction before continuing.');
                if (DimID <> Change."Old Dimension Set ID") and (DimID <> Change."New Dimension Set ID") then
                    Error('A planned dimension set changed outside this correction. Review/resume instead of overwriting another change.');
                Ref.Close();
            until Change.Next() = 0;
    end;

    local procedure ApplyChange(Change: Record "Production Dim. Change")
    var
        Ref: RecordRef;
        Entry: Record "Item Ledger Entry";
        Value: Record "Value Entry";
        Journal: Record "Item Journal Line";
        Link: Record "Production Posting Link";
        LedgerLink: Record "Production Ledger Link";
    begin
        if Change."Table ID" = Database::"G/L Entry" then
            exit; // never directly edit GL here: native correction engine owns it
        Ref.Get(Change."Record ID");
        case Change."Table ID" of
            Database::"Item Ledger Entry": begin
                Ref.SetTable(Entry);
                Entry."Dimension Set ID" := Change."New Dimension Set ID";
                DimMgt.UpdateGlobalDimFromDimSetID(Entry."Dimension Set ID", Entry."Global Dimension 1 Code", Entry."Global Dimension 2 Code");
                Entry.Modify(true);
            end;
            Database::"Value Entry": begin
                Ref.SetTable(Value);
                Value."Dimension Set ID" := Change."New Dimension Set ID";
                DimMgt.UpdateGlobalDimFromDimSetID(Value."Dimension Set ID", Value."Global Dimension 1 Code", Value."Global Dimension 2 Code");
                Value.Modify(true);
            end;
            Database::"Item Journal Line": begin
                Ref.SetTable(Journal);
                Journal.Validate("Dimension Set ID", Change."New Dimension Set ID");
                Journal.Modify(true);
            end;
            Database::"Production Posting Link": begin
                Ref.SetTable(Link);
                Link."Dimension Set ID" := Change."New Dimension Set ID";
                Link.Modify(true);
            end;
            Database::"Production Ledger Link": begin
                Ref.SetTable(LedgerLink);
                LedgerLink."Dimension Set ID" := Change."New Dimension Set ID";
                LedgerLink.Modify(true);
            end;
        end;
        Ref.Close();
    end;

    local procedure CheckScopeStillComplete(Correction: Record "Production Dim. Correction")
    var
        Link: Record "Production Posting Link";
        LedgerLink: Record "Production Ledger Link";
        Journal: Record "Item Journal Line";
        Entry: Record "Item Ledger Entry";
        Value: Record "Value Entry";
        Relation: Record "G/L - Item Ledger Relation";
        GL: Record "G/L Entry";
    begin
        Link.SetRange("Document No.", Correction."Document No.");
        Link.SetFilter(State, '<>%1', Link.State::Cancelled);
        if Link.FindSet() then
            repeat
                RequirePlanned(Correction."Entry No.", Database::"Production Posting Link", Link.SystemId);
                if Journal.Get(Link."Journal Template Name", Link."Journal Batch Name", Link."Journal Line No.") and
                   (Journal."O&G Production Link No." = Link."Entry No.") then
                    RequirePlanned(Correction."Entry No.", Database::"Item Journal Line", Journal.SystemId);
            until Link.Next() = 0;
        LedgerLink.SetRange("Document No.", Correction."Document No.");
        if LedgerLink.FindSet() then
            repeat
                RequirePlanned(Correction."Entry No.", Database::"Production Ledger Link", LedgerLink.SystemId);
                Entry.Get(LedgerLink."Item Ledger Entry No.");
                RequirePlanned(Correction."Entry No.", Database::"Item Ledger Entry", Entry.SystemId);
                Value.SetRange("Item Ledger Entry No.", Entry."Entry No.");
                if Value.FindSet() then
                    repeat
                        RequirePlanned(Correction."Entry No.", Database::"Value Entry", Value.SystemId);
                        Relation.SetRange("Value Entry No.", Value."Entry No.");
                        if Relation.FindSet() then
                            repeat
                                GL.Get(Relation."G/L Entry No.");
                                RequirePlanned(Correction."Entry No.", Database::"G/L Entry", GL.SystemId);
                            until Relation.Next() = 0;
                    until Value.Next() = 0;
            until LedgerLink.Next() = 0;
    end;

    local procedure RequirePlanned(CorrectionNo: Integer; TableID: Integer; ID: Guid)
    var
        Change: Record "Production Dim. Change";
    begin
        Change.SetRange("Correction Entry No.", CorrectionNo);
        Change.SetRange("Table ID", TableID);
        Change.SetRange("System ID", ID);
        if Change.IsEmpty() then
            Error('Related posting/cost entries changed after this correction was prepared. Stop concurrent posting/cost adjustment and review the unfinished correction; new rows will not be silently omitted.');
    end;
}
