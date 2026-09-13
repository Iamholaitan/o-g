// SANDBOX ONLY. AutoRollback prevents fixture data from being committed.
// These tests deliberately use Insert/Modify/Delete(false) to test the data
// guards independently of table validation and of UI Editable properties.
codeunit 70200 "Production Entry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentHeaderCannotBeReopenedWithModifyFalse()
    var
        Header: Record "Production Entry Header";
    begin
        MakeHistoryFixture(Header);
        Header.Posted := false;
        asserterror Header.Modify(false);
        CheckGuardError();
        Header.Get(Header."Document No.");
        AssertTrue(Header.Posted, 'Source must remain sent.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentHeaderCannotBeDeletedWithDeleteFalse()
    var
        Header: Record "Production Entry Header";
    begin
        MakeHistoryFixture(Header);
        asserterror Header.Delete(false);
        CheckGuardError();
        AssertTrue(Header.Get(Header."Document No."), 'History header must remain.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentLineCannotBeChangedWithModifyFalse()
    var
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
    begin
        MakeHistoryFixture(Header);
        Line.Get(Header."Document No.", 10000);
        Line.Quantity := 99;
        asserterror Line.Modify(false);
        CheckGuardError();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentLineCannotBeDeletedWithDeleteFalse()
    var
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
    begin
        MakeHistoryFixture(Header);
        Line.Get(Header."Document No.", 10000);
        asserterror Line.Delete(false);
        CheckGuardError();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentDocumentCannotReceiveAnotherLine()
    var
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
    begin
        MakeHistoryFixture(Header);
        Line.Init();
        Line."Document No." := Header."Document No.";
        Line."Line No." := 20000;
        asserterror Line.Insert(false);
        CheckGuardError();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SentDocumentCannotBeSentAgain()
    var
        Header: Record "Production Entry Header";
        Poster: Codeunit "Post Daily Production";
    begin
        MakeHistoryFixture(Header);
        asserterror Poster.Post(Header);
        AssertTrue(StrPos(GetLastErrorText(), 'cannot') > 0, 'Repeat send must be rejected before journal generation.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CannotMarkSentWithoutMatchingJournalLines()
    var
        Header: Record "Production Entry Header";
    begin
        MakeOpenFixture(Header);
        Header."Item Journal Template Name" := NewCode10();
        Header."Item Journal Batch Name" := NewCode10();
        Header.Posted := true;
        asserterror Header.Modify(false);
        AssertTrue(StrPos(GetLastErrorText(), 'no generated item journal lines') > 0, 'A history flag alone must not fabricate journal history.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingOpenHeaderAlsoDeletesItsLines()
    var
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
        DocumentNo: Code[20];
    begin
        MakeOpenFixture(Header);
        AddRawLine(Header."Document No.", 10000, 25);
        DocumentNo := Header."Document No.";
        Header.Delete(false);
        Line.SetRange("Document No.", DocumentNo);
        AssertTrue(Line.IsEmpty(), 'Open header deletion must not leave orphan lines.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LiveTotalUsesSavedLineBOE()
    var
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
    begin
        MakeOpenFixture(Header);
        AddRawLine(Header."Document No.", 10000, 980);
        AddRawLine(Header."Document No.", 20000, 100);
        Header.CalcFields("Calculated BOE");
        AssertTrue(Header."Calculated BOE" = 1080, 'Draft total should be 980 + 100 BOE.');
        Line.Get(Header."Document No.", 20000);
        Line.Delete(false);
        Header.CalcFields("Calculated BOE");
        AssertTrue(Header."Calculated BOE" = 980, 'Deleting a draft line must change the live total.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextJournalLineUsesTemplateAndBatch()
    var
        Helper: Codeunit "Journal Helper";
        Template1: Code[10];
        Template2: Code[10];
        BatchName: Code[10];
    begin
        Template1 := NewCode10();
        Template2 := NewCode10();
        BatchName := NewCode10();
        AddRawJournalLine(Template1, BatchName, 10000, 'QA');
        AddRawJournalLine(Template2, BatchName, 80000, 'QA');
        AssertTrue(Helper.NextItemJnlLineNo(Template1, BatchName) = 20000, 'Line numbering must not read another template.');
        AssertTrue(Helper.NextItemJnlLineNo(Template2, BatchName) = 90000, 'Append must use the selected template/batch.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TemporaryHistoryBuffersAreNotLocked()
    var
        Header: Record "Production Entry Header" temporary;
    begin
        Header."Document No." := NewCode20();
        Header.Posted := true;
        Header.Insert(false);
        Header."Total BOE" := 10;
        Header.Modify(false);
        Header.Delete(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultsAndOverridesUseConfiguredDimensionCodes()
    var
        Setup: Record "O&G Setup";
        Reservoir: Record Reservoir;
        Header: Record "Production Entry Header";
        FieldValue: Code[20];
        WellValue: Code[20];
        OtherWell: Code[20];
        CostValue: Code[20];
        ReservoirValue: Code[20];
    begin
        if not Setup.Get('DEFAULT') then begin
            Setup.Init();
            Setup."Primary Key" := 'DEFAULT';
            Setup.Insert(false);
        end;
        Setup."Field/Block Dimension Code" := NewCode20();
        Setup."Well Dimension Code" := NewCode20();
        Setup."Reservoir Dimension Code" := NewCode20();
        Setup."Cost Center Dimension Code" := NewCode20();
        Setup."Item Journal Template Name" := NewCode10();
        Setup.Modify(false);
        FieldValue := NewCode20();
        WellValue := NewCode20();
        OtherWell := NewCode20();
        CostValue := NewCode20();
        ReservoirValue := NewCode20();
        AddDimensionValue(Setup."Field/Block Dimension Code", FieldValue);
        AddDimensionValue(Setup."Well Dimension Code", WellValue);
        AddDimensionValue(Setup."Well Dimension Code", OtherWell);
        AddDimensionValue(Setup."Cost Center Dimension Code", CostValue);
        AddDimensionValue(Setup."Reservoir Dimension Code", ReservoirValue);
        Reservoir.Init();
        Reservoir."Reservoir Code" := ReservoirValue;
        Reservoir."Field/Block Code" := FieldValue;
        Reservoir."Well Code" := WellValue;
        Reservoir."Cost Center Code" := CostValue;
        Reservoir.Insert(false);
        Header.Init();
        Header."Document No." := NewCode20();
        Header.Insert(true);
        Header.Validate("Reservoir Code", ReservoirValue);
        AssertTrue(Header."Field/Block Code" = FieldValue, 'Reservoir must supply the default field.');
        AssertTrue(Header."Well Code" = WellValue, 'Reservoir must supply the default well.');
        AssertTrue(Header."Cost Center Code" = CostValue, 'Reservoir must supply the default cost center.');
        AssertTrue(Header."Item Journal Template Name" = Setup."Item Journal Template Name", 'Template must come from setup.');
        Header.Validate("Well Code", OtherWell);
        AssertTrue(Header."Well Code" = OtherWell, 'A valid well override must be accepted while open.');
        asserterror Header.Validate("Well Code", FieldValue);
        AssertTrue(StrPos(GetLastErrorText(), 'does not exist for dimension') > 0, 'A field-only value must be rejected as a well.');
    end;

    local procedure MakeOpenFixture(var Header: Record "Production Entry Header")
    begin
        Header.Init();
        Header."Document No." := NewCode20();
        Header."Production Date" := WorkDate();
        Header.Insert(false);
    end;

    local procedure MakeHistoryFixture(var Header: Record "Production Entry Header")
    begin
        MakeOpenFixture(Header);
        AddRawLine(Header."Document No.", 10000, 10);
        Header."Item Journal Template Name" := NewCode10();
        Header."Item Journal Batch Name" := NewCode10();
        AddRawJournalLine(Header."Item Journal Template Name", Header."Item Journal Batch Name", 10000, Header."Document No.");
        Header."Total BOE" := 10;
        Header.Posted := true;
        Header.Modify(false);
    end;

    local procedure AddRawLine(DocumentNo: Code[20]; LineNo: Integer; BOE: Decimal)
    var
        Line: Record "Production Entry Line";
    begin
        Line."Document No." := DocumentNo;
        Line."Line No." := LineNo;
        Line."BOE Quantity" := BOE;
        Line.Insert(false);
    end;

    local procedure AddRawJournalLine(TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer; DocumentNo: Code[20])
    var
        Line: Record "Item Journal Line";
    begin
        Line."Journal Template Name" := TemplateName;
        Line."Journal Batch Name" := BatchName;
        Line."Line No." := LineNo;
        Line."Document No." := DocumentNo;
        Line.Insert(false);
    end;

    local procedure AddDimensionValue(DimensionCode: Code[20]; ValueCode: Code[20])
    var
        Dimension: Record Dimension;
        Value: Record "Dimension Value";
    begin
        if not Dimension.Get(DimensionCode) then begin
            Dimension.Code := DimensionCode;
            Dimension.Insert(false);
        end;
        Value."Dimension Code" := DimensionCode;
        Value.Code := ValueCode;
        Value."Dimension Value Type" := Value."Dimension Value Type"::Standard;
        Value.Insert(false);
    end;

    local procedure CheckGuardError()
    begin
        AssertTrue(StrPos(GetLastErrorText(), 'cannot be modified, deleted, or reopened') > 0, 'Expected the stored-history guard, not an unrelated validation error.');
    end;

    local procedure AssertTrue(Condition: Boolean; Failure: Text)
    begin
        if not Condition then
            Error(Failure);
    end;

    local procedure NewCode20(): Code[20]
    begin
        exit(CopyStr('QA' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;

    local procedure NewCode10(): Code[10]
    begin
        exit(CopyStr(NewCode20(), 1, 10));
    end;
}
