// Optional server tests for v1.0.12. Compile status is not an execution result.
codeunit 70201 "Reservoir Journal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MethodSelectionCopiesDescriptionWithoutRetcon()
    var
        Method: Record "Reserve Estimation Method";
        Reservoir: Record Reservoir;
    begin
        MakeMethod(Method);
        Reservoir.Validate("Estimation Method Code", Method.Code);
        AssertTrue(Reservoir."Estimation Method" = Method.Description, 'Method description must be captured.');
        Method.Description := 'Revised catalogue description';
        Method.Modify(true);
        AssertTrue(Reservoir."Estimation Method" <> Method.Description, 'Catalogue edits must not silently rewrite a captured description.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlockedMethodCannotBeSelected()
    var
        Method: Record "Reserve Estimation Method";
        Reservoir: Record Reservoir;
    begin
        MakeMethod(Method);
        Method.Blocked := true;
        Method.Modify(true);
        asserterror Reservoir.Validate("Estimation Method Code", Method.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsedMethodCannotBeDeleted()
    var
        Method: Record "Reserve Estimation Method";
        Reservoir: Record Reservoir;
    begin
        MakeMethod(Method);
        Reservoir."Reservoir Code" := NewCode20();
        Reservoir.Validate("Estimation Method Code", Method.Code);
        Reservoir.Insert(false);
        asserterror Method.Delete(true);
        AssertTrue(StrPos(GetLastErrorText(), 'Block it') > 0, 'Referenced methods must be retained.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownEstimatorIsRejected()
    var
        Reservoir: Record Reservoir;
    begin
        asserterror Reservoir.Validate("Estimated By", NewCode20());
        AssertTrue(StrPos(GetLastErrorText(), 'enabled Business Central user') > 0, 'Only enabled BC users may be selected as a new preparer.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CurrentUserDefaultsOnNewReservoir()
    var
        Estimator: Record User;
        Reservoir: Record Reservoir;
    begin
        Estimator.Get(UserSecurityId());
        Estimator.TestField(State, Estimator.State::Enabled);
        Reservoir."Reservoir Code" := NewCode20();
        Reservoir.Insert(true);
        AssertTrue(Reservoir."Estimated By User Security ID" = UserSecurityId(), 'New Reservoir should reference the current user.');
        AssertTrue(Reservoir."Estimated By" = Estimator."User Name", 'Snapshot should contain the selected BC username.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingPreparerTextIsNotDefaultedAway()
    var
        Reservoir: Record Reservoir;
        EstimationMgt: Codeunit "Reserve Estimation Mgt.";
    begin
        Reservoir."Estimated By" := 'Historical external engineering team';
        EstimationMgt.DefaultCurrentEstimator(Reservoir);
        AssertTrue(Reservoir."Estimated By" = 'Historical external engineering team', 'Existing text must be preserved, not assigned to the current user.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecoveryFactorIsBounded()
    var
        Reservoir: Record Reservoir;
    begin
        Reservoir.Validate("Recovery Factor %", 30);
        AssertTrue(Reservoir."Proved Reserves (1P)" = 0, 'Recovery factor must not auto-set reserves.');
        asserterror Reservoir.Validate("Recovery Factor %", 101);
        asserterror Reservoir.Validate("Recovery Factor %", -1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StandardItemTemplateAccepted()
    var
        Template: Record "Item Journal Template";
        Navigation: Codeunit "O&G Item Journal Navigation";
    begin
        MakeTemplate(Template);
        Navigation.ValidateTemplate(Template.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManufacturingOutputTemplateRejected()
    var
        Template: Record "Item Journal Template";
        Navigation: Codeunit "O&G Item Journal Navigation";
    begin
        MakeTemplate(Template);
        Template.Type := Template.Type::Output;
        Template.Modify(false);
        asserterror Navigation.ValidateTemplate(Template.Name);
        AssertTrue(StrPos(GetLastErrorText(), 'not the Manufacturing Output Journal') > 0, 'Production uses the standard Item Journal, not a manufacturing output template.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WrongTemplatePageRejected()
    var
        Template: Record "Item Journal Template";
        Navigation: Codeunit "O&G Item Journal Navigation";
    begin
        MakeTemplate(Template);
        Template."Page ID" := Page::"Dimension Set Entries";
        Template.Modify(false);
        asserterror Navigation.ValidateTemplate(Template.Name);
        AssertTrue(StrPos(GetLastErrorText(), 'standard Item Journal page') > 0, 'A dimensions page must not be used as the journal destination.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingTemplateIsNotAutoCreated()
    var
        Template: Record "Item Journal Template";
        Navigation: Codeunit "O&G Item Journal Navigation";
        Name: Code[10];
    begin
        Name := CopyStr(NewCode20(), 1, 10);
        asserterror Navigation.ValidateTemplate(Name);
        AssertTrue(not Template.Get(Name), 'Validating a missing template must not create it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingBatchIsNotAutoCreatedOnOpen()
    var
        Template: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        Navigation: Codeunit "O&G Item Journal Navigation";
        Name: Code[10];
    begin
        MakeTemplate(Template);
        Name := CopyStr(NewCode20(), 1, 10);
        asserterror Navigation.OpenBatch(Template.Name, Name, 'QA-DOC');
        AssertTrue(not Batch.Get(Template.Name, Name), 'Navigation must not create an alternative empty batch.');
    end;

    local procedure MakeMethod(var Method: Record "Reserve Estimation Method")
    begin
        Method.Code := NewCode20();
        Method.Description := 'QA client-maintained reserve method';
        Method.Insert(true);
    end;

    local procedure MakeTemplate(var Template: Record "Item Journal Template")
    begin
        Template.Name := CopyStr(NewCode20(), 1, 10);
        Template.Type := Template.Type::Item;
        Template."Page ID" := Page::"Item Journal";
        Template.Recurring := false;
        Template.Insert(false);
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
}
