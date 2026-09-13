// -----------------------------------------------------------------------------
// Depletion Worksheet (FR-20, FR-21, FR-22)
// Reviewable UOP depletion calculation; creates Gen. Journal lines using the
// accounts and journal template selected in O&G Setup.
// -----------------------------------------------------------------------------
page 70038 "Depletion Worksheet"
{
    PageType = List;
    SourceTable = "Depletion Worksheet";
    SourceTableView = where(Posted = const(false));
    Caption = 'Depletion Calculation Worksheet';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(EntryNo; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Entity; Rec."Entity Code") { ApplicationArea = All; }
                field(PeriodStart; Rec."Period Start") { ApplicationArea = All; }
                field(PeriodEnd; Rec."Period End") { ApplicationArea = All; }
                field(PostingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(FixedAssetNo; Rec."Fixed Asset No.") { ApplicationArea = All; }
                field(DepreciationBook; Rec."Depreciation Book Code") { ApplicationArea = All; }
                field(TotalCapitalisedCost; Rec."Total Capitalised Cost")
                {
                    ApplicationArea = All;
                }
                field(AccumulatedDepletion; Rec."Accumulated Depletion")
                {
                    ApplicationArea = All;
                }
                field(RemainingNBV; Rec."Remaining NBV")
                {
                    ApplicationArea = All;
                }
                field(RemainingReservesBOE; Rec."Remaining Reserves BOE")
                {
                    ApplicationArea = All;
                }
                field(PeriodProductionBOE; Rec."Period Production BOE")
                {
                    ApplicationArea = All;
                }
                field(DepletionRate; Rec."Depletion Rate per BOE")
                {
                    ApplicationArea = All;
                }
                field(DepletionAmount; Rec."Depletion Amount")
                {
                    ApplicationArea = All;
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SuggestLines)
            {
                ApplicationArea = All;
                Caption = 'Suggest Lines';
                ToolTip = 'Calculates UOP depletion for all producing reservoirs for the selected period (FR-21).';
                trigger OnAction()
                var
                    PeriodDialog: Page "Date Range";
                    DepCalc: Codeunit "Depletion Calculation";
                    Result: Action;
                    FromDate: Date;
                    ToDate: Date;
                    SuggestedCount: Integer;
                begin
                    // Page variables make accepted-result and date readback explicit.
                    // No database/temporary record is inserted before the dialog.
                    PeriodDialog.SetDates(CalcDate('<-CM>', WorkDate()), WorkDate());
                    Result := PeriodDialog.RunModal();
                    if not PeriodDialog.IsConfirmed(Result) then
                        exit;
                    PeriodDialog.GetDates(FromDate, ToDate);
                    SuggestedCount := DepCalc.SuggestLinesWithResult(FromDate, ToDate);
                    if SuggestedCount > 0 then begin
                        // Show the calculated window, rather than hide new rows
                        // behind a previous user/date/Posted filter.
                        Rec.Reset();
                        Rec.SetRange("Period Start", FromDate);
                        Rec.SetRange("Period End", ToDate);
                        Rec.SetRange(Posted, false);
                        if Rec.FindFirst() then;
                    end;
                    CurrPage.Update(false);
                end;
            }
            action(DepletionHistory)
            {
                ApplicationArea = All;
                Caption = 'Depletion History';
                Image = History;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Depletion History";
            }
            action(PostDepletion)
            {
                ApplicationArea = All;
                Caption = 'Send to FA G/L Journal';
                ToolTip = 'Creates depreciation for the linked Fixed Asset and book in the standard FA G/L Journal. Native FA Posting Group supplies the accounts. The sent row remains in Depletion History.';
                trigger OnAction()
                var
                    Worksheet: Record "Depletion Worksheet";
                    DepCalc: Codeunit "Depletion Calculation";
                begin
                    CurrPage.SetSelectionFilter(Worksheet);
                    if Worksheet.IsEmpty() then
                        Error('The depletion worksheet is empty. Run the Suggest Lines action first.');
                    if Confirm('Create FA G/L journal entries for the selected depletion lines? They will move to Depletion History; final posting remains in the standard FA journal.', false) then
                        DepCalc.PostWorksheet(Worksheet);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
