// Generates standard FA G/L journal depreciation for the linked asset/book.
// Native FA posting groups supply accumulated depreciation and expense accounts.
// The accountant still reviews/posts; no extra legacy G/L expense pair is created.
codeunit 70098 "FA Depletion Posting"
{
    InherentPermissions = X;
    Permissions = tabledata "Depletion Ledger Link" = RI;

    var
        Helper: Codeunit "Production Entry Helper";
        JnlHelper: Codeunit "Journal Helper";
        EntityMgt: Codeunit "O&G Entity Mgt.";

    procedure ValidateTemplate(TemplateName: Code[10])
    var
        Template: Record "Gen. Journal Template";
    begin
        if TemplateName = '' then
            Error('Select FA G/L Journal Template in O&G Setup. Create a non-recurring Assets template in standard BC first.');
        Template.Get(TemplateName);
        Template.TestField(Type, Template.Type::Assets);
        Template.TestField(Recurring, false);
        Template.TestField("Page ID", Page::"Fixed Asset G/L Journal");
    end;

    procedure CreateJournal(var Worksheet: Record "Depletion Worksheet")
    var
        Setup: Record "O&G Setup";
        FA: Record "Fixed Asset";
        FABook: Record "FA Depreciation Book";
        Book: Record "Depreciation Book";
        PostingGroup: Record "FA Posting Group";
        Template: Record "Gen. Journal Template";
        Batch: Record "Gen. Journal Batch";
        Journal: Record "Gen. Journal Line";
        BalanceLine: Record "Gen. Journal Line";
        InsertFABalance: Codeunit "FA Insert G/L Account";
        DimMgt: Codeunit DimensionManagement;
        IDs: array[10] of Integer;
        DimID: Integer;
        LastBalanceLineNo: Integer;
        CheckAmount: Decimal;
        SourceLineNo: Integer;
    begin
        Worksheet.TestField(Posted, false);
        Helper.GetSetup(Setup);
        ValidateTemplate(Setup."FA G/L Journal Template");
        ValidateAsset(Worksheet, FA, FABook, Book, PostingGroup);
        CheckPendingBookValue(Worksheet, FABook);
        Template.Get(Setup."FA G/L Journal Template");
        JnlHelper.EnsureGenJournalBatch(JnlHelper.MakeBatchName('DEPL', Worksheet."Posting Date"), Template.Name);
        Batch.Get(Template.Name, JnlHelper.MakeBatchName('DEPL', Worksheet."Posting Date"));
        Batch.TestField("Bal. Account Type", Batch."Bal. Account Type"::"G/L Account");
        Batch.TestField("Bal. Account No.", '');
        Journal.LockTable();
        Journal.Init();
        Journal."Journal Template Name" := Template.Name;
        Journal."Journal Batch Name" := Batch.Name;
        Journal."Line No." := JnlHelper.NextGenJnlLineNo(Template.Name, Batch.Name);
        Journal."Source Code" := Template."Source Code";
        Journal."Reason Code" := Batch."Reason Code";
        Journal.Validate("Posting Date", Worksheet."Posting Date");
        Journal."Document No." := Worksheet."Document No.";
        Journal.Validate("Account Type", Journal."Account Type"::"Fixed Asset");
        Journal.Validate("Account No.", Worksheet."Fixed Asset No.");
        Journal.Validate("Depreciation Book Code", Worksheet."Depreciation Book Code");
        Journal.Validate("FA Posting Type", Journal."FA Posting Type"::Depreciation);
        Journal.Validate("FA Posting Date", Worksheet."Posting Date");
        Journal."Use Duplication List" := false;
        Journal."Duplicate in Depreciation Book" := '';
        Journal."Depr. until FA Posting Date" := false;
        Journal."Depr. Acquisition Cost" := false;
        Journal."No. of Depreciation Days" := 0;
        // A depreciation entry reduces the asset/book value: the FA line is negative.
        Journal.Validate(Amount, -Worksheet."Depletion Amount");
        IDs[1] := Journal."Dimension Set ID";
        IDs[2] := Worksheet."Dimension Set ID";
        DimID := DimMgt.GetCombinedDimensionSetID(IDs, Journal."Shortcut Dimension 1 Code", Journal."Shortcut Dimension 2 Code");
        Journal.Validate("Dimension Set ID", DimID);
        Journal.Description := CopyStr('UOP depletion ' + Worksheet."Reservoir Code", 1, MaxStrLen(Journal.Description));
        Journal."O&G Depletion Entry No." := Worksheet."Entry No.";
        Journal.Insert(true);
        SourceLineNo := Journal."Line No.";
        Worksheet."Posting Route" := Worksheet."Posting Route"::"FA G/L";
        Worksheet."FA Journal Line No." := SourceLineNo;
        Worksheet."FA Journal System ID" := Journal.SystemId;
        Worksheet."FA Posting Group" := FABook."FA Posting Group";
        Worksheet."Gen. Journal Template Name" := Template.Name;
        Worksheet."Journal Batch Name" := Batch.Name;
        // Same native routine as Insert FA Bal. Account. It supports the client's
        // standard FA depreciation allocation setup; no G/L numbers are hardcoded.
        LastBalanceLineNo := InsertFABalance.GetBalAcc(Journal);
        BalanceLine.SetRange("Journal Template Name", Template.Name);
        BalanceLine.SetRange("Journal Batch Name", Batch.Name);
        BalanceLine.SetRange("Document No.", Worksheet."Document No.");
        BalanceLine.SetRange("Line No.", SourceLineNo + 1, LastBalanceLineNo);
        if not BalanceLine.FindSet(true) then
            Error('Native FA balancing did not create an expense line. Check the FA Posting Group.');
        repeat
            BalanceLine.TestField("Account Type", BalanceLine."Account Type"::"G/L Account");
            BalanceLine."O&G Depletion Entry No." := Worksheet."Entry No.";
            // Entity stays on the same operation. Other allocation dimensions
            // remain those supplied by standard FA allocation/posting-group setup.
            BalanceLine.Validate("Dimension Set ID", EntityMgt.SetEntity(BalanceLine."Dimension Set ID", Worksheet."Entity Code"));
            BalanceLine.Modify(true);
            CheckAmount += BalanceLine.Amount;
        until BalanceLine.Next() = 0;
        if Abs(CheckAmount - Worksheet."Depletion Amount") > 0.00001 then
            Error('FA balancing lines do not reconcile to the approved depletion amount. Nothing was committed.');
    end;

    local procedure ValidateAsset(Worksheet: Record "Depletion Worksheet"; var FA: Record "Fixed Asset"; var FABook: Record "FA Depreciation Book"; var Book: Record "Depreciation Book"; var PostingGroup: Record "FA Posting Group")
    begin
        Worksheet.TestField("Fixed Asset No.");
        Worksheet.TestField("Depreciation Book Code");
        if Worksheet."Depletion Amount" <= 0 then
            Error('Depletion amount must be positive.');
        FA.Get(Worksheet."Fixed Asset No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        if not FABook.Get(FA."No.", Worksheet."Depreciation Book Code") then
            Error('Asset %1 has no depreciation-book assignment %2. Assign it on the Fixed Asset Card, then re-suggest depletion.', FA."No.", Worksheet."Depreciation Book Code");
        Book.Get(FABook."Depreciation Book Code");
        Book.TestField("G/L Integration - Depreciation", true);
        FABook.TestField("FA Posting Group");
        if not PostingGroup.GetPostingGroup(FABook."FA Posting Group", Book.Code) then
            Error('The FA Posting Group is missing for this asset/book.');
        PostingGroup.TestField("Accum. Depreciation Account");
        PostingGroup.TestField("Depreciation Expense Acc.");
        FABook.CalcFields("Acquisition Cost", "Book Value");
        if FABook."Acquisition Cost" <= 0 then
            Error('Post acquisition/opening cost for asset %1 in book %2 before FA depletion. Linking an asset does not create its acquisition cost.', FA."No.", Book.Code);
        if FABook."Disposal Date" <> 0D then
            Error('Asset %1 is disposed in book %2.', FA."No.", Book.Code);
        if FABook."Book Value" <= 0 then
            Error('Asset %1 / book %2 has no positive remaining book value.', FA."No.", Book.Code);
    end;

    local procedure CheckPendingBookValue(Worksheet: Record "Depletion Worksheet"; FABook: Record "FA Depreciation Book")
    var
        Pending: Record "Depletion Worksheet";
        Link: Record "Depletion Ledger Link";
        ReservedAmount: Decimal;
        Available: Decimal;
    begin
        Pending.SetRange(Posted, true);
        Pending.SetRange("Posting Route", Pending."Posting Route"::"FA G/L");
        Pending.SetRange("Fixed Asset No.", Worksheet."Fixed Asset No.");
        Pending.SetRange("Depreciation Book Code", Worksheet."Depreciation Book Code");
        if Pending.FindSet() then
            repeat
                Link.SetRange("Depletion Entry No.", Pending."Entry No.");
                if Link.IsEmpty() then
                    ReservedAmount += Pending."Depletion Amount";
            until Pending.Next() = 0;
        Available := FABook."Book Value" - FABook."Ending Book Value" - ReservedAmount;
        if Worksheet."Depletion Amount" > Available + 0.00001 then
            Error('Depletion %1 exceeds available FA book value %2 after pending FA depletion and ending book value. Reconcile the Reservoir cost basis with asset %3/book %4 before posting.', Worksheet."Depletion Amount", Available, Worksheet."Fixed Asset No.", Worksheet."Depreciation Book Code");
    end;

    procedure OpenJournal(Worksheet: Record "Depletion Worksheet")
    var
        Batch: Record "Gen. Journal Batch";
        Journal: Record "Gen. Journal Line";
        Management: Codeunit GenJnlManagement;
    begin
        Worksheet.TestField(Posted, true);
        if Worksheet."Gen. Journal Template Name" = '' then
            Error('This older entry has no recorded journal template. Review the original General Journal/ledger by Document No. %1; the current template will not be guessed.', Worksheet."Document No.");
        if Worksheet."Posting Route" = Worksheet."Posting Route"::"FA G/L" then
            ValidateTemplate(Worksheet."Gen. Journal Template Name");
        Batch.Get(Worksheet."Gen. Journal Template Name", Worksheet."Journal Batch Name");
        Journal.SetRange("Journal Template Name", Batch."Journal Template Name");
        Journal.SetRange("Journal Batch Name", Batch.Name);
        Journal.SetRange("Document No.", Worksheet."Document No.");
        if Journal.IsEmpty() then begin
            Message('No pending journal lines remain for this depletion document. Use FA Ledger Entries or the historical posting details; journal disappearance alone is not proof of posting.');
            exit;
        end;
        Management.TemplateSelectionFromBatch(Batch);
    end;

    procedure OpenFALedger(Worksheet: Record "Depletion Worksheet")
    var
        Entry: Record "FA Ledger Entry";
        Link: Record "Depletion Ledger Link";
    begin
        Link.SetRange("Depletion Entry No.", Worksheet."Entry No.");
        if not Link.FindSet() then begin
            Message('No FA posting is recorded for this depletion row. It may still be pending, or it was an older direct-G/L posting.');
            exit;
        end;
        repeat
            if Entry.Get(Link."FA Ledger Entry No.") then
                Entry.Mark(true);
        until Link.Next() = 0;
        Entry.MarkedOnly(true);
        Page.Run(Page::"FA Ledger Entries", Entry);
    end;

    procedure StatusText(Worksheet: Record "Depletion Worksheet"): Text[50]
    var
        Link: Record "Depletion Ledger Link";
        Entry: Record "FA Ledger Entry";
        Journal: Record "Gen. Journal Line";
    begin
        if not Worksheet.Posted then
            exit('Open calculation');
        if Worksheet."Posting Route" = Worksheet."Posting Route"::"Legacy G/L" then
            exit('Legacy G/L - review original journal');
        Link.SetRange("Depletion Entry No.", Worksheet."Entry No.");
        if Link.FindFirst() then begin
            if not Entry.Get(Link."FA Ledger Entry No.") then
                exit('FA posting needs review');
            if Entry.Reversed or (Entry."Canceled from FA No." <> '') then
                exit('FA posting cancelled/reversed');
            exit('Posted to FA and G/L');
        end;
        Journal.SetRange("Journal Template Name", Worksheet."Gen. Journal Template Name");
        Journal.SetRange("Journal Batch Name", Worksheet."Journal Batch Name");
        Journal.SetRange("O&G Depletion Entry No.", Worksheet."Entry No.");
        Journal.SetRange("Account Type", Journal."Account Type"::"Fixed Asset");
        if not Journal.IsEmpty() then
            exit('Ready in FA G/L Journal');
        exit('Journal missing - review');
    end;

    procedure CheckHistoryConsistency(ReservoirCode: Code[20])
    var
        Worksheet: Record "Depletion Worksheet";
        Link: Record "Depletion Ledger Link";
        Entry: Record "FA Ledger Entry";
    begin
        Worksheet.SetRange(Posted, true);
        Worksheet.SetRange("Reservoir Code", ReservoirCode);
        Worksheet.SetRange("Posting Route", Worksheet."Posting Route"::"FA G/L");
        if Worksheet.FindSet() then
            repeat
                Link.SetRange("Depletion Entry No.", Worksheet."Entry No.");
                if Link.FindSet() then
                    repeat
                        if not Entry.Get(Link."FA Ledger Entry No.") then
                            Error('FA depletion history entry %1 needs reconciliation before further UOP calculation.', Worksheet."Entry No.");
                        if Entry.Reversed or (Entry."Canceled from FA No." <> '') then
                            Error('FA depletion entry %1 was cancelled/reversed in standard BC. Reconcile the source depletion history before calculating the next period; it will not be counted as active depreciation silently.', Worksheet."Entry No.");
                    until Link.Next() = 0;
            until Worksheet.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Make FA Ledger Entry", 'OnAfterCopyFromGenJnlLine', '', false, false)]
    local procedure CopyDepletionTag(var FALedgerEntry: Record "FA Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Fixed Asset") and
           (GenJournalLine."FA Posting Type" = GenJournalLine."FA Posting Type"::Depreciation) and
           (GenJournalLine."FA Error Entry No." = 0) and not GenJournalLine.Correction then
            FALedgerEntry."O&G Depletion Entry No." := GenJournalLine."O&G Depletion Entry No."
        else
            FALedgerEntry."O&G Depletion Entry No." := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforePostFixedAsset', '', false, false)]
    local procedure CheckTaggedFAPosting(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    var
        Worksheet: Record "Depletion Worksheet";
        Link: Record "Depletion Ledger Link";
        Required: Record "Dimension Set Entry";
        Actual: Record "Dimension Set Entry";
        FABook: Record "FA Depreciation Book";
        Book: Record "Depreciation Book";
    begin
        if GenJournalLine."O&G Depletion Entry No." = 0 then
            exit;
        if GenJournalLine."FA Error Entry No." <> 0 then begin
            GenJournalLine."O&G Depletion Entry No." := 0;
            exit; // standard FA cancellation is not a second depletion source posting
        end;
        GenJournalLine.TestField(Correction, false);
        Worksheet.Get(GenJournalLine."O&G Depletion Entry No.");
        Worksheet.TestField(Posted, true);
        Worksheet.TestField("Posting Route", Worksheet."Posting Route"::"FA G/L");
        GenJournalLine.TestField("Journal Template Name", Worksheet."Gen. Journal Template Name");
        GenJournalLine.TestField("Journal Batch Name", Worksheet."Journal Batch Name");
        GenJournalLine.TestField("Document No.", Worksheet."Document No.");
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.TestField("Account No.", Worksheet."Fixed Asset No.");
        GenJournalLine.TestField("Depreciation Book Code", Worksheet."Depreciation Book Code");
        GenJournalLine.TestField("FA Posting Type", GenJournalLine."FA Posting Type"::Depreciation);
        FABook.Get(Worksheet."Fixed Asset No.", Worksheet."Depreciation Book Code");
        FABook.TestField("FA Posting Group", Worksheet."FA Posting Group");
        Book.Get(Worksheet."Depreciation Book Code");
        Book.TestField("G/L Integration - Depreciation", true);
        GenJournalLine.TestField("Currency Code", '');
        GenJournalLine.TestField(Amount, -Worksheet."Depletion Amount");
        GenJournalLine.TestField("Use Duplication List", false);
        GenJournalLine.TestField("Duplicate in Depreciation Book", '');
        Link.SetRange("Depletion Entry No.", Worksheet."Entry No.");
        if not Link.IsEmpty() then
            Error('This depletion row already has an FA ledger posting. Do not post it twice.');
        Required.SetRange("Dimension Set ID", Worksheet."Dimension Set ID");
        if Required.FindSet() then
            repeat
                if not Actual.Get(GenJournalLine."Dimension Set ID", Required."Dimension Code") then
                    Error('A required depletion dimension is missing from the FA journal.');
                Actual.TestField("Dimension Value Code", Required."Dimension Value Code");
            until Required.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Insert Ledger Entry", 'OnInsertFAOnAfterInsertFALedgEntry', '', false, false)]
    local procedure RecordFAPosting(var FALedgerEntry: Record "FA Ledger Entry"; FALedgerEntry3: Record "FA Ledger Entry")
    var
        Worksheet: Record "Depletion Worksheet";
        Link: Record "Depletion Ledger Link";
    begin
        if FALedgerEntry.IsTemporary() or (FALedgerEntry."O&G Depletion Entry No." = 0) then
            exit;
        Worksheet.Get(FALedgerEntry."O&G Depletion Entry No.");
        FALedgerEntry.TestField("FA No.", Worksheet."Fixed Asset No.");
        FALedgerEntry.TestField("Depreciation Book Code", Worksheet."Depreciation Book Code");
        FALedgerEntry.TestField("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.TestField(Amount, -Worksheet."Depletion Amount");
        if Link.Get(FALedgerEntry."Entry No.") then
            exit;
        Link.Init();
        Link."FA Ledger Entry No." := FALedgerEntry."Entry No.";
        Link."Depletion Entry No." := Worksheet."Entry No.";
        Link."FA No." := FALedgerEntry."FA No.";
        Link."Depreciation Book Code" := FALedgerEntry."Depreciation Book Code";
        Link."Document No." := FALedgerEntry."Document No.";
        Link."FA Posting Date" := FALedgerEntry."FA Posting Date";
        Link."G/L Posting Date" := FALedgerEntry."Posting Date";
        Link.Amount := FALedgerEntry.Amount;
        Link."G/L Entry No." := FALedgerEntry."G/L Entry No.";
        Link."Dimension Set ID" := FALedgerEntry."Dimension Set ID";
        Link."Recorded At" := CurrentDateTime();
        Link."Recorded By" := UserSecurityId();
        Link.Insert(true);
    end;
}
