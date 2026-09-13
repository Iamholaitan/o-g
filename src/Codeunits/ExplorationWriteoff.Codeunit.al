// -----------------------------------------------------------------------------
// Exploration Write-off (FR-24)
// Accounting-method-aware handling of unsuccessful exploration costs:
//   - Successful Efforts: expense immediately (Dr Exploration Expense /
//     Cr Exploration Costs) through a Gen. Journal batch.
//   - Full Cost: leave the cost capitalised in the cost pool - no posting.
// Accounts and journal template come from O&G Setup.
// -----------------------------------------------------------------------------
codeunit 70073 "Exploration Write-off"
{
    var
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        JnlHelper: Codeunit "Journal Helper";
        FmaSetup: Record "O&G Setup";

    procedure Post(var Writeoff: Record "Exploration Write-off")
    var
        Reservoir: Record "Reservoir";
        TemplateName: Code[10];
        BatchName: Code[10];
        DimSetID: Integer;
        LineNo: Integer;
    begin
        if Writeoff."Document No." = '' then
            Error('No write-off document specified.');

        if not Writeoff.Get(Writeoff."Document No.") then
            Error('Exploration write-off %1 does not exist.', Writeoff."Document No.");

        if Writeoff.Posted then
            Error('Exploration write-off %1 is already posted.', Writeoff."Document No.");

        if Writeoff."Posting Date" = 0D then
            Error('Posting date is missing on %1.', Writeoff."Document No.");

        if Writeoff.Amount = 0 then
            Error('Amount must be greater than zero on %1.', Writeoff."Document No.");

        Helper.GetSetup(FmaSetup);

        if FmaSetup."Accounting Method" = FmaSetup."Accounting Method"::"Full Cost" then begin
            // FR-24: stays capitalised in the relevant Full Cost pool.
            Writeoff.Posted := true;
            Writeoff.Modify();
            Message('Accounting Method is Full Cost: the unsuccessful exploration cost remains capitalised in the cost pool. No journal lines were created (%1).', Writeoff."Document No.");
            exit;
        end;

        // FR-24 / Appendix A: Successful Efforts - expense immediately.
        TemplateName := FmaSetup."Gen. Journal Template Name";
        BatchName := JnlHelper.MakeBatchName('GEN', Writeoff."Posting Date");
        JnlHelper.EnsureGenJournalBatch(BatchName, TemplateName);

        DimSetID := 0;
        if Reservoir.Get(Writeoff."Reservoir Code") then
            DimSetID := DimHelper.GetDimensionSetID(FmaSetup, Reservoir."Field/Block Code", '', Reservoir."Reservoir Code", Reservoir."Cost Center Code", '');

        LineNo := JnlHelper.NextGenJnlLineNo(TemplateName, BatchName);
        JnlHelper.CreateGenJournalLine(TemplateName, BatchName, LineNo, Writeoff."Posting Date", Writeoff."Document No.", FmaSetup."Exploration Expense Account", Writeoff.Amount, 0, 'Exploration write-off ' + Writeoff."Document No.", DimSetID);

        LineNo := JnlHelper.NextGenJnlLineNo(TemplateName, BatchName);
        JnlHelper.CreateGenJournalLine(TemplateName, BatchName, LineNo, Writeoff."Posting Date", Writeoff."Document No.", FmaSetup."Exploration Costs Account", 0, Writeoff.Amount, 'Exploration write-off ' + Writeoff."Document No.", DimSetID);

        Writeoff."Journal Batch Name" := BatchName;
        Writeoff.Posted := true;
        Writeoff.Modify();

        Message('Exploration write-off %1 posted to Gen. Journal batch %2. The accountant must post the batch.', Writeoff."Document No.", BatchName);
    end;
}
