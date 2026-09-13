codeunit 70072 "Depletion Calculation"
{
    var
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        EntityMgt: Codeunit "O&G Entity Mgt.";
        JnlHelper: Codeunit "Journal Helper";
        FAPosting: Codeunit "FA Depletion Posting";

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
        Worksheet: Record "Depletion Worksheet";
        Existing: Record "Depletion Worksheet";
        Temp: Record "Depletion Worksheet" temporary;
        Header: Record "Production Entry Header";
        Reservoir: Record Reservoir;
        OGSetup: Record "O&G Setup";
        Entity: Code[20];
        N: Integer;
        Count: Integer;
        RemainingNBV: Decimal;
        RemainingReserves: Decimal;
        Rate: Decimal;
        PeriodTotal: Decimal;
        TotalAmount: Decimal;
        Allocated: Decimal;
        Amount: Decimal;
        Position: Integer;
        ReservoirsChecked: Integer;
        MatchedDocuments: Integer;
        ReservoirsWithoutPeriodBOE: Integer;
        ReservoirsWithoutNBV: Integer;
        WindowBOE: Decimal;
    begin
        ValidatePeriod(FromDate, ToDate);
        Helper.GetSetup(OGSetup);
        // Replace only unposted drafts for the same requested window, not all
        // users' worksheets or unrelated periods. No dialog is opened here.
        Existing.SetRange(Posted, false);
        if Existing.FindSet(true) then
            repeat
                if ((Existing."Period Start" = FromDate) and (Existing."Period End" = ToDate)) or
                   ((Existing."Period Start" = 0D) and (Existing."Posting Date" = ToDate)) then
                    Existing.Delete(true);
            until Existing.Next() = 0;
        Reservoir.SetRange(Status, Reservoir.Status::Producing);
        if not Reservoir.FindSet() then
            Error('No Reservoir has Status = Producing. Posting a production document does not change Reservoir Status automatically. Set the appropriate Reservoir to Producing before suggesting depletion.');
        repeat
            ReservoirsChecked += 1;
            FAPosting.CheckHistoryConsistency(Reservoir."Reservoir Code");
            Temp.Reset();
            Temp.DeleteAll(false);
            N := 0;
            PeriodTotal := 0;
            Header.Reset();
            Header.SetRange(Posted, true);
            Header.SetRange(Cancelled, false);
            Header.SetRange("Reservoir Code", Reservoir."Reservoir Code");
            Header.SetRange("Production Date", FromDate, ToDate);
            if Header.FindSet() then
                repeat
                    MatchedDocuments += 1;
                    WindowBOE += Header."Total BOE";
                    Entity := EntityMgt.ProductionEntity(Header);
                    Temp.SetRange("Entity Code", Entity);
                    if not Temp.FindFirst() then begin
                        N += 1;
                        Temp.Init();
                        Temp."Entry No." := N;
                        Temp."Entity Code" := Entity;
                        Temp.Insert(false);
                    end;
                    Temp."Period Production BOE" += Header."Total BOE";
                    Temp.Modify(false);
                    PeriodTotal += Header."Total BOE";
                    Temp.Reset();
                until Header.Next() = 0;
            if PeriodTotal = 0 then
                ReservoirsWithoutPeriodBOE += 1;
            if PeriodTotal < 0 then
                Error('Reservoir %1 has negative net production in this window after corrections. A reviewed depletion adjustment is required; a negative expense will not be silently generated.', Reservoir."Reservoir Code");
            if PeriodTotal > 0 then begin
                Reservoir.CalcFields("Cumulative Production BOE", "Accumulated Depletion");
                RemainingNBV := Reservoir."Total Capitalised Cost" - Reservoir."Accumulated Depletion";
                if RemainingNBV <= 0 then begin
                    RemainingNBV := 0;
                    ReservoirsWithoutNBV += 1;
                end;
                RemainingReserves := Reservoir."Proved Reserves (1P)" - Reservoir."Cumulative Production BOE";
                if (RemainingNBV > 0) and (RemainingReserves <= 0) then
                    Error('Remaining reserves for %1 are zero/negative. Review reserve estimates before depletion.', Reservoir."Reservoir Code");
                if RemainingNBV > 0 then begin
                    Rate := RemainingNBV / RemainingReserves;
                    TotalAmount := Round(PeriodTotal * Rate, 0.01);
                    if TotalAmount > RemainingNBV then
                        TotalAmount := RemainingNBV;
                    Allocated := 0;
                    Position := 0;
                    Temp.SetFilter("Period Production BOE", '<>0');
                    if Temp.FindSet() then
                        repeat
                            if Temp."Period Production BOE" < 0 then
                                Error('Entity %1 has negative production. Review the correction and depletion basis before posting.', Temp."Entity Code");
                            CheckNoPostedOverlap(Reservoir."Reservoir Code", Temp."Entity Code", FromDate, ToDate, 0);
                            Position += 1;
                            if Position = Temp.Count() then
                                Amount := TotalAmount - Allocated
                            else
                                Amount := Round(TotalAmount * Temp."Period Production BOE" / PeriodTotal, 0.01);
                            Allocated += Amount;
                            Worksheet.Init();
                            Worksheet."Entry No." := 0;
                            Worksheet."Posting Date" := ToDate;
                            Worksheet."Period Start" := FromDate;
                            Worksheet."Period End" := ToDate;
                            Worksheet."Reservoir Code" := Reservoir."Reservoir Code";
                            Worksheet."Entity Code" := Temp."Entity Code";
                            Worksheet."Fixed Asset No." := Reservoir."Fixed Asset No.";
                            Worksheet."Depreciation Book Code" := Reservoir."Depreciation Book Code";
                            Worksheet."Total Capitalised Cost" := Reservoir."Total Capitalised Cost";
                            Worksheet."Accumulated Depletion" := Reservoir."Accumulated Depletion";
                            Worksheet."Remaining NBV" := RemainingNBV;
                            Worksheet."Remaining Reserves BOE" := RemainingReserves;
                            Worksheet."Period Production BOE" := Temp."Period Production BOE";
                            Worksheet."Depletion Rate per BOE" := Rate;
                            Worksheet."Depletion Amount" := Amount;
                            Worksheet."Cost Center Code" := Reservoir."Cost Center Code";
                            Worksheet."Dimension Set ID" := DimHelper.GetDimensionSetID(OGSetup, Reservoir."Field/Block Code", '', Reservoir."Reservoir Code", Reservoir."Cost Center Code", '', Temp."Entity Code");
                            Worksheet.Insert(true);
                            Worksheet."Document No." := CopyStr('DEPL' + Format(Worksheet."Entry No.", 0, 9), 1, MaxStrLen(Worksheet."Document No."));
                            Worksheet.Modify(true);
                            Count += 1;
                        until Temp.Next() = 0;
                end;
            end;
        until Reservoir.Next() = 0;
        if Count = 0 then
            Message('No depletion lines were created for Production Dates %1 to %2. Producing reservoirs checked: %3; matching sent production documents: %4; net period BOE: %5; reservoirs with no period BOE: %6; reservoirs with production but no remaining capitalised cost: %7. Check the SOURCE Production Date and Reservoir Total Capitalised Cost minus Accumulated Depletion. Cumulative BOE is all-time production, not this selected-period total. No cost or reserve value has been invented.', FromDate, ToDate, ReservoirsChecked, MatchedDocuments, WindowBOE, ReservoirsWithoutPeriodBOE, ReservoirsWithoutNBV)
        else
            Message('%1 depletion line(s) suggested for %2 to %3. The worksheet now shows unposted rows for this window. Amounts use the existing UOP basis and are split by production Entity; no journal has been posted.', Count, FromDate, ToDate);
        exit(Count);
    end;

    procedure PostWorksheet()
    var
        Worksheet: Record "Depletion Worksheet";
    begin
        Worksheet.SetRange(Posted, false);
        PostWorksheet(Worksheet);
    end;

    procedure PostWorksheet(var Selected: Record "Depletion Worksheet")
    var
        Worksheet: Record "Depletion Worksheet";
        Reservoir: Record Reservoir;
        OGSetup: Record "O&G Setup";
        Count: Integer;
    begin
        Helper.GetSetup(OGSetup);
        OGSetup.TestField("FA G/L Journal Template");
        FAPosting.ValidateTemplate(OGSetup."FA G/L Journal Template");
        if Selected.FindSet() then
            repeat
                Worksheet.Get(Selected."Entry No.");
                if not Worksheet.Posted then begin
                    ValidatePeriod(Worksheet."Period Start", Worksheet."Period End");
                    EntityMgt.ValidateEntity(Worksheet."Entity Code");
                    CheckNoPostedOverlap(Worksheet."Reservoir Code", Worksheet."Entity Code", Worksheet."Period Start", Worksheet."Period End", Worksheet."Entry No.");
                    if Abs(CurrentProduction(Worksheet) - Worksheet."Period Production BOE") > 0.00001 then
                        Error('Production changed after depletion was suggested. Run Suggest Lines again before posting entry %1.', Worksheet."Entry No.");
                    if Worksheet."Depletion Amount" <= 0 then
                        Error('Depletion amount must be positive on entry %1.', Worksheet."Entry No.");
                    Reservoir.Get(Worksheet."Reservoir Code");
                    if (Worksheet."Fixed Asset No." <> Reservoir."Fixed Asset No.") or
                       (Worksheet."Depreciation Book Code" <> Reservoir."Depreciation Book Code") then
                        Error('The Reservoir asset/book mapping changed after calculation. Re-suggest the unposted depletion worksheet before sending it to the FA journal.');
                    if Worksheet."Total Capitalised Cost" <> Reservoir."Total Capitalised Cost" then
                        Error('The capitalised cost basis changed after calculation. Re-suggest depletion.');
                    // The linked FA/book now owns the posting. Do not also
                    // create the old direct expense/accumulated-depletion pair.
                    FAPosting.CreateJournal(Worksheet);
                    Reservoir.Get(Worksheet."Reservoir Code");
                    Reservoir."Depletion Rate per BOE" := Worksheet."Depletion Rate per BOE";
                    Reservoir.Modify(true);
                    Worksheet.Posted := true;
                    Worksheet.Modify(true);
                    Count += 1;
                end;
            until Selected.Next() = 0;
        Message('%1 depletion line(s) sent to the Fixed Asset G/L Journal. They are retained in Depletion History. Review and post the standard FA journal to update the selected asset/book and G/L; journal creation is not final ledger posting.', Count);
    end;

    local procedure CurrentProduction(Worksheet: Record "Depletion Worksheet"): Decimal
    var
        Header: Record "Production Entry Header";
        Total: Decimal;
    begin
        Header.SetRange(Posted, true);
        Header.SetRange(Cancelled, false);
        Header.SetRange("Reservoir Code", Worksheet."Reservoir Code");
        Header.SetRange("Production Date", Worksheet."Period Start", Worksheet."Period End");
        if Header.FindSet() then
            repeat
                if EntityMgt.ProductionEntity(Header) = Worksheet."Entity Code" then
                    Total += Header."Total BOE";
            until Header.Next() = 0;
        exit(Total);
    end;

    local procedure CheckNoPostedOverlap(ReservoirCode: Code[20]; EntityCode: Code[20]; FromDate: Date; ToDate: Date; ExceptEntry: Integer)
    var
        Existing: Record "Depletion Worksheet";
        Starts: Date;
        Ends: Date;
    begin
        Existing.SetRange(Posted, true);
        Existing.SetRange("Reservoir Code", ReservoirCode);
        if Existing.FindSet() then
            repeat
                Starts := Existing."Period Start";
                Ends := Existing."Period End";
                if Starts = 0D then begin
                    Starts := Helper.PeriodStartByMonth(Existing."Posting Date");
                    Ends := Helper.PeriodEndByMonth(Existing."Posting Date");
                end;
                if (Existing."Entry No." <> ExceptEntry) and (Starts <= ToDate) and (Ends >= FromDate) and
                   ((Existing."Entity Code" = '') or (Existing."Entity Code" = EntityCode)) then
                    Error('Depletion for Reservoir %1 / Entity %2 overlaps already journalised entry %3. Review an adjustment instead of posting the period twice.', ReservoirCode, EntityCode, Existing."Entry No.");
            until Existing.Next() = 0;
    end;

    local procedure ValidatePeriod(FromDate: Date; ToDate: Date)
    begin
        if (FromDate = 0D) or (ToDate = 0D) or (FromDate > ToDate) then
            Error('Choose a valid From Date and To Date. Legacy unsent worksheets must be re-suggested to record their period and Entity.');
    end;
}
