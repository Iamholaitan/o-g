// -----------------------------------------------------------------------------
// Journal Helper
// Shared routines for creating standard BC journal batches and journal lines
// (Item Journal / Gen. Journal). The extension only CREATES journal lines and
// monthly batches - posting stays with the accountant (FR-18). Journal
// templates are NEVER created by the extension: you create and select them in
// O&G Setup (Gen. Journal Template Name / Item Journal Template Name).
// -----------------------------------------------------------------------------
codeunit 70079 "Journal Helper"
{
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";

    // Builds a predictable batch name, e.g. 'PROD202609' (FR-16).
    procedure MakeBatchName(Prefix: Code[10]; PostingDate: Date): Code[10]
    var
        YearStr: Text;
        MonthStr: Text;
    begin
        YearStr := Format(Date2DMY(PostingDate, 3), 0, 0);
        MonthStr := Format(Date2DMY(PostingDate, 2), 0, 0);
        if StrLen(MonthStr) = 1 then
            MonthStr := '0' + MonthStr;
        exit(CopyStr(Prefix + YearStr + MonthStr, 1, 10));
    end;

    // FR-16: one Item Journal batch per calendar month, e.g. PROD202609.
    // The template is NOT created here - you create it in Business Central
    // (Item Journal Templates) and select it in O&G Setup; if it is missing
    // or not selected, posting stops with a clear message.
    procedure EnsureItemJournalBatch(BatchName: Code[10]; TemplateName: Code[10])
    var
        JournalNavigation: Codeunit "O&G Item Journal Navigation";
    begin
        JournalNavigation.ValidateTemplate(TemplateName);
        if TemplateName = '' then
            Error('No Item Journal template is selected. Open O&G Setup and enter the Item Journal Template Name you created (Item Journal Templates).');

        if not ItemJournalTemplate.Get(TemplateName) then
            Error('Item Journal template %1 does not exist. Create it in Business Central (Item Journal Templates) and select it in O&G Setup.', TemplateName);

        ItemJournalBatch.LockTable();
        if not ItemJournalBatch.Get(TemplateName, BatchName) then begin
            ItemJournalBatch.Init();
            ItemJournalBatch."Journal Template Name" := TemplateName;
            ItemJournalBatch."Name" := BatchName;
            ItemJournalBatch.Description := 'O&G production posting ' + BatchName;
            ItemJournalBatch.Insert(true);
        end;
    end;

    // General Journal batch for depletion / royalty / JV / write-off lines.
    // The template is NOT created here - it must exist and be selected in
    // O&G Setup (Gen. Journal Template Name); posting stops with a clear
    // message if it is missing or not selected.
    procedure EnsureGenJournalBatch(BatchName: Code[10]; TemplateName: Code[10])
    begin
        if TemplateName = '' then
            Error('No General Journal template is selected. Open O&G Setup and enter the Gen. Journal Template Name you created (General Journal Templates).');

        if not GenJnlTemplate.Get(TemplateName) then
            Error('Gen. Journal template %1 does not exist. Create it in Business Central (General Journal Templates) and select it in O&G Setup.', TemplateName);

        GenJnlBatch.LockTable();
        if not GenJnlBatch.Get(TemplateName, BatchName) then begin
            GenJnlBatch.Init();
            GenJnlBatch."Journal Template Name" := TemplateName;
            GenJnlBatch."Name" := BatchName;
            GenJnlBatch.Description := 'O&G posting ' + BatchName;
            GenJnlBatch.Insert();
        end;
    end;

    // Next free line number in the batch (10000, 20000, ...).
    procedure NextGenJnlLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);
        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;

    // Creates one Gen. Journal line (G/L account, debit or credit).
    procedure CreateGenJournalLine(TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer; PostingDate: Date; DocumentNo: Code[20]; AccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; Description: Text; DimSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        IDs: array[10] of Integer;
        CombinedID: Integer;
    begin
        GenJnlTemplate.Get(TemplateName);
        GenJnlBatch.Get(TemplateName, BatchName);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := TemplateName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine."Line No." := LineNo;
        GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
        GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document No." := CopyStr(DocumentNo, 1, MaxStrLen(GenJnlLine."Document No."));
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.Description := CopyStr(Description, 1, MaxStrLen(GenJnlLine.Description));
        // Standard validation sets Amount, debit/credit amounts and LCY fields.
        GenJnlLine.Validate(Amount, DebitAmount - CreditAmount);
        IDs[1] := GenJnlLine."Dimension Set ID";
        IDs[2] := DimSetID;
        CombinedID := DimMgt.GetCombinedDimensionSetID(IDs, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
        GenJnlLine.Validate("Dimension Set ID", CombinedID);
        GenJnlLine.Insert(true);
    end;

    // Backwards-compatible overload for existing royalty callers.
    procedure NextItemJnlLineNo(BatchName: Code[10]): Integer
    var
        OGSetup: Record "O&G Setup";
        ProductionHelper: Codeunit "Production Entry Helper";
    begin
        ProductionHelper.GetSetup(OGSetup);
        exit(NextItemJnlLineNo(OGSetup."Item Journal Template Name", BatchName));
    end;

    // Complete primary-key scope: same batch names may exist under different templates.
    procedure NextItemJnlLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", TemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", BatchName);
        if ItemJournalLine.FindLast() then
            exit(ItemJournalLine."Line No." + 10000);
        exit(10000);
    end;
}
