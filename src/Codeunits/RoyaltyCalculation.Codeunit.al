codeunit 70075 "Royalty Calculation"
{
    var
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        EntityMgt: Codeunit "O&G Entity Mgt.";
        JnlHelper: Codeunit "Journal Helper";

    procedure SuggestLines(PostingDate: Date)
    begin
        SuggestLines(Helper.PeriodStartByMonth(PostingDate), PostingDate);
    end;

    procedure SuggestLines(FromDate: Date; ToDate: Date)
    begin
        SuggestLinesWithResult(FromDate, ToDate);
    end;

    procedure SuggestLinesWithResult(FromDate: Date; ToDate: Date): Integer
    var
        Worksheet: Record "Royalty Worksheet";
        Existing: Record "Royalty Worksheet";
        Term: Record "Royalty Term";
        Header: Record "Production Entry Header";
        Line: Record "Production Entry Line";
        Setup: Record "O&G Setup";
        Entity: Code[20];
        Rate: Decimal;
        Volume: Decimal;
        RoyaltyValue: Decimal;
        Eligible: Boolean;
        Count: Integer;
        PeriodHeaders: Record "Production Entry Header";
        AllPeriodDocuments: Integer;
        TermsChecked: Integer;
        MatchedDocuments: Integer;
        SourceLinesChecked: Integer;
        AlreadyProcessedLines: Integer;
        ZeroVolumeLines: Integer;
        ReversedDocuments: Integer;
        ZeroRateTerms: Integer;
    begin
        if (FromDate = 0D) or (ToDate = 0D) or (FromDate > ToDate) then
            Error('Choose a valid From Date and To Date.');
        Helper.GetSetup(Setup);
        PeriodHeaders.SetRange(Posted, true);
        PeriodHeaders.SetRange(Cancelled, false);
        PeriodHeaders.SetRange("Record Kind", PeriodHeaders."Record Kind"::Production);
        PeriodHeaders.SetRange("Production Date", FromDate, ToDate);
        AllPeriodDocuments := PeriodHeaders.Count();
        Existing.SetRange(Posted, false);
        if Existing.FindSet(true) then
            repeat
                if ((Existing."Period Start" = FromDate) and (Existing."Period End" = ToDate)) or
                   ((Existing."Period Start" = 0D) and (Existing."Posting Date" = ToDate)) then
                    Existing.Delete(true);
            until Existing.Next() = 0;
        if not Term.FindSet() then begin
            Message('No royalty lines were created: no Royalty Terms are configured. Create a term for the Field/Block Code on the production document, with a positive rate or a positive O&G Setup default rate. Sent production documents in %1 to %2: %3.', FromDate, ToDate, AllPeriodDocuments);
            exit(0);
        end;
        repeat
            TermsChecked += 1;
            CheckLegacyPostedPeriod(Term."Field/Block Code", FromDate, ToDate);
            Rate := Term."Royalty Rate %";
            if Rate = 0 then
                Rate := Setup."Default Royalty Rate %";
            if Rate = 0 then
                ZeroRateTerms += 1;
            if (Rate < 0) or (Rate > 100) then
                Error('Royalty rate must be between 0 and 100 for field %1.', Term."Field/Block Code");
            Header.Reset();
            Header.SetRange(Posted, true);
            Header.SetRange(Cancelled, false);
            Header.SetRange("Record Kind", Header."Record Kind"::Production);
            Header.SetRange("Field/Block Code", Term."Field/Block Code");
            Header.SetRange("Production Date", FromDate, ToDate);
            if Header.FindSet() then
                repeat
                    MatchedDocuments += 1;
                    if HasActiveReversal(Header) then
                        ReversedDocuments += 1;
                    // Reversal/cancellation is not an instruction to silently undo
                    // existing financial journals. Omit inactive originals from NEW
                    // royalty suggestions and require review of already posted fees.
                    if not HasActiveReversal(Header) then begin
                        Entity := EntityMgt.ProductionEntity(Header);
                        Line.SetRange("Document No.", Header."Document No.");
                        if Line.FindSet() then
                            repeat
                                SourceLinesChecked += 1;
                                if AlreadyJournalised(Line."Document No.", Line."Line No.", 0) then
                                    AlreadyProcessedLines += 1;
                                if not AlreadyJournalised(Line."Document No.", Line."Line No.", 0) then begin
                                    Volume := Round(Line."Net Quantity" * Rate / 100, 0.001);
                                    RoyaltyValue := Round(Volume * Term."Unit Price", 0.01);
                                    Eligible := Volume > 0;
                                    if (Term."Royalty Basis" = Term."Royalty Basis"::Revenue) and (Line."Net Quantity" > 0) and (Rate > 0) then begin
                                        if Term."Unit Price" <= 0 then
                                            Error('A positive reference price is required for production-value royalty on field %1. The extension does not read sales invoices or fetch statutory fiscal prices.', Term."Field/Block Code");
                                        RoyaltyValue := Round(Line."Net Quantity" * Term."Unit Price" * Rate / 100, 0.01);
                                        Eligible := RoyaltyValue > 0;
                                    end;
                                    if not Eligible then
                                        ZeroVolumeLines += 1;
                                    if Eligible then begin
                                        Worksheet.Init();
                                        Worksheet."Entry No." := 0;
                                        Worksheet."Posting Date" := ToDate;
                                        Worksheet."Period Start" := FromDate;
                                        Worksheet."Period End" := ToDate;
                                        Worksheet."Entity Code" := Entity;
                                        Worksheet."Production Document No." := Header."Document No.";
                                        Worksheet."Production Line No." := Line."Line No.";
                                        Worksheet."Field/Block Code" := Header."Field/Block Code";
                                        Worksheet."Reservoir Code" := Header."Reservoir Code";
                                        Worksheet."Item No." := Line."Item No.";
                                        Worksheet."Item Description" := Line."Item Description";
                                        Worksheet."Unit of Measure Code" := Line."Unit of Measure Code";
                                        Worksheet."Gross Volume" := Line."Net Quantity";
                                        Worksheet."Royalty Rate %" := Rate;
                                        Worksheet."Royalty Volume" := Volume;
                                        Worksheet."Settlement Method" := Term."Settlement Method";
                                        Worksheet."Unit Price" := Term."Unit Price";
                                        Worksheet."Royalty Basis" := Term."Royalty Basis";
                                        Worksheet."Rate Reference" := Term."Rate Reference";
                                        Worksheet."Price Reference" := Term."Price Reference";
                                        Worksheet."Royalty Amount" := RoyaltyValue;
                                        Worksheet."Location Code" := Line."Location Code";
                                        Worksheet."Dimension Set ID" := DimHelper.GetDimensionSetID(Setup, Header."Field/Block Code", Header."Well Code", Header."Reservoir Code", Header."Cost Center Code", '', Entity);
                                        Worksheet.Insert(true);
                                        Count += 1;
                                    end;
                                end;
                            until Line.Next() = 0;
                    end;
                until Header.Next() = 0;
        until Term.Next() = 0;
        if Count = 0 then
            Message('No royalty lines were created for Production Dates %1 to %2. Active sent documents in the window: %3; royalty terms checked: %4; documents matching term Field/Block codes: %5; source lines checked: %6; already journalised lines: %7; zero/rounded-zero royalty volumes: %8; reversed documents: %9; zero-rate terms after setup fallback: %10. Match Royalty Term Field/Block Code to the source document and check its rate/net quantity. No rate has been guessed.', FromDate, ToDate, AllPeriodDocuments, TermsChecked, MatchedDocuments, SourceLinesChecked, AlreadyProcessedLines, ZeroVolumeLines, ReversedDocuments, ZeroRateTerms)
        else
            Message('%1 royalty line(s) suggested for %2 to %3. The worksheet now shows unposted rows for this window. Produced water remains included where its net volume has royalty; existing financial journals are not automatically reversed.', Count, FromDate, ToDate);
        exit(Count);
    end;

    procedure PostWorksheet()
    var
        Worksheet: Record "Royalty Worksheet";
    begin
        Worksheet.SetRange(Posted, false);
        PostWorksheet(Worksheet);
    end;

    procedure PostWorksheet(var Selected: Record "Royalty Worksheet")
    var
        Worksheet: Record "Royalty Worksheet";
        Header: Record "Production Entry Header";
        SourceLine: Record "Production Entry Line";
        Term: Record "Royalty Term";
        Setup: Record "O&G Setup";
        JournalLine: Record "Item Journal Line";
        GenLine: Record "Gen. Journal Line";
        Template: Record "Item Journal Template";
        PostingSetup: Record "General Posting Setup";
        Batch: Code[10];
        DocumentNo: Code[20];
        ExpenseAccount: Code[20];
        PayableAccount: Code[20];
        LineNo: Integer;
        Count: Integer;
    begin
        Helper.GetSetup(Setup);
        if Selected.FindSet() then
            repeat
                Worksheet.Get(Selected."Entry No.");
                if not Worksheet.Posted then begin
                    Worksheet.TestField("Production Document No.");
                    Header.Get(Worksheet."Production Document No.");
                    Header.TestField(Posted, true);
                    Header.TestField(Cancelled, false);
                    if HasActiveReversal(Header) then
                        Error('Production %1 has been reversed. Re-suggest royalty and separately review any existing royalty journals.', Header."Document No.");
                    SourceLine.Get(Header."Document No.", Worksheet."Production Line No.");
                    if (SourceLine."Net Quantity" <> Worksheet."Gross Volume") or
                       (SourceLine."Item No." <> Worksheet."Item No.") or
                       (EntityMgt.ProductionEntity(Header) <> Worksheet."Entity Code") then
                        Error('Production changed after royalty was suggested. Re-run Suggest Royalty.');
                    if AlreadyJournalised(Header."Document No.", SourceLine."Line No.", Worksheet."Entry No.") then
                        Error('Royalty for production %1 line %2 has already been journalised.', Header."Document No.", SourceLine."Line No.");
                    EntityMgt.ValidateEntity(Worksheet."Entity Code");
                    Term.Get(Worksheet."Field/Block Code");
                    Batch := JnlHelper.MakeBatchName('ROY', Worksheet."Posting Date");
                    DocumentNo := CopyStr('ROY' + Format(Worksheet."Entry No.", 0, 9), 1, 20);
                    if Worksheet."Settlement Method" = Worksheet."Settlement Method"::"In-Kind" then begin
                        if Worksheet."Royalty Volume" <= 0 then
                            Error('The in-kind royalty quantity rounds to zero. Review quantity precision or use the approved cash settlement instead of posting a zero stock movement.');
                        Setup.TestField("Royalty Gen. Bus. Post. Group");
                        JnlHelper.EnsureItemJournalBatch(Batch, Setup."Item Journal Template Name");
                        Template.Get(Setup."Item Journal Template Name");
                        JournalLine.LockTable();
                        JournalLine.Init();
                        JournalLine."Journal Template Name" := Setup."Item Journal Template Name";
                        JournalLine."Journal Batch Name" := Batch;
                        JournalLine."Line No." := JnlHelper.NextItemJnlLineNo(Setup."Item Journal Template Name", Batch);
                        JournalLine."Source Code" := Template."Source Code";
                        JournalLine.Validate("Posting Date", Worksheet."Posting Date");
                        JournalLine."Document No." := DocumentNo;
                        JournalLine.Validate("Entry Type", JournalLine."Entry Type"::"Negative Adjmt.");
                        JournalLine.Validate("Item No.", Worksheet."Item No.");
                        JournalLine.Validate("Location Code", Worksheet."Location Code");
                        JournalLine.Validate("Unit of Measure Code", Worksheet."Unit of Measure Code");
                        JournalLine.Validate("Gen. Bus. Posting Group", Setup."Royalty Gen. Bus. Post. Group");
                        PostingSetup.Get(JournalLine."Gen. Bus. Posting Group", JournalLine."Gen. Prod. Posting Group");
                        PostingSetup.TestField("Inventory Adjmt. Account");
                        // Negative Adjmt. already supplies the inventory sign.
                        JournalLine.Validate(Quantity, Worksheet."Royalty Volume");
                        JournalLine.Validate("Dimension Set ID", Worksheet."Dimension Set ID");
                        JournalLine.Description := CopyStr('Royalty in-kind ' + Worksheet."Field/Block Code", 1, MaxStrLen(JournalLine.Description));
                        JournalLine.Insert(true);
                        Worksheet."Journal Template Name" := Setup."Item Journal Template Name";
                    end else begin
                        if Worksheet."Royalty Amount" <= 0 then
                            Error('Set a positive Unit Price/royalty amount for cash royalty before posting entry %1.', Worksheet."Entry No.");
                        ExpenseAccount := Term."Royalty Expense Account";
                        if ExpenseAccount = '' then
                            ExpenseAccount := Setup."Royalty Expense Account";
                        PayableAccount := Term."Royalty Payable Account";
                        if PayableAccount = '' then
                            PayableAccount := Setup."Royalty Payable Account";
                        JnlHelper.EnsureGenJournalBatch(Batch, Setup."Gen. Journal Template Name");
                        GenLine.LockTable();
                        LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                        JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, Worksheet."Posting Date", DocumentNo, ExpenseAccount, Worksheet."Royalty Amount", 0, 'Royalty cash ' + Worksheet."Field/Block Code", Worksheet."Dimension Set ID");
                        LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                        JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, Worksheet."Posting Date", DocumentNo, PayableAccount, 0, Worksheet."Royalty Amount", 'Royalty cash ' + Worksheet."Field/Block Code", Worksheet."Dimension Set ID");
                        Worksheet."Journal Template Name" := Setup."Gen. Journal Template Name";
                    end;
                    Worksheet."Journal Batch Name" := Batch;
                    Worksheet.Posted := true;
                    Worksheet.Modify(true);
                    Count += 1;
                end;
            until Selected.Next() = 0;
        Message('%1 royalty line(s) sent to journals. Review/Preview/Post in standard BC.', Count);
    end;

    local procedure HasActiveReversal(Header: Record "Production Entry Header"): Boolean
    var
        Reversal: Record "Production Entry Header";
    begin
        if Header."Reversed By Document No." = '' then
            exit(false);
        Reversal.Get(Header."Reversed By Document No.");
        exit(Reversal.Posted and not Reversal.Cancelled);
    end;

    local procedure AlreadyJournalised(DocumentNo: Code[20]; LineNo: Integer; ExceptEntry: Integer): Boolean
    var
        Existing: Record "Royalty Worksheet";
    begin
        Existing.SetRange(Posted, true);
        Existing.SetRange("Production Document No.", DocumentNo);
        Existing.SetRange("Production Line No.", LineNo);
        Existing.SetFilter("Entry No.", '<>%1', ExceptEntry);
        exit(not Existing.IsEmpty());
    end;

    local procedure CheckLegacyPostedPeriod(FieldCode: Code[20]; FromDate: Date; ToDate: Date)
    var
        Existing: Record "Royalty Worksheet";
    begin
        Existing.SetRange(Posted, true);
        Existing.SetRange("Production Document No.", '');
        Existing.SetRange("Field/Block Code", FieldCode);
        if Existing.FindSet() then
            repeat
                if (Helper.PeriodStartByMonth(Existing."Posting Date") <= ToDate) and
                   (Helper.PeriodEndByMonth(Existing."Posting Date") >= FromDate) then
                    Error('Legacy royalty entry %1 overlaps this period but has no source-document links. Reconcile it before recalculating; duplicate royalty will not be generated.', Existing."Entry No.");
            until Existing.Next() = 0;
    end;
}
