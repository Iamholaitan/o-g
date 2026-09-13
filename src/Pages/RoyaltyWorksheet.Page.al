// -----------------------------------------------------------------------------
// Royalty Worksheet (FR-25, FR-26)
// Reviewable royalty calculation: cash or in-kind per field.
// -----------------------------------------------------------------------------
page 70041 "Royalty Worksheet"
{
    PageType = List;
    SourceTable = "Royalty Worksheet";
    Caption = 'Royalty Worksheet';
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
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(GrossVolume; Rec."Gross Volume")
                {
                    ApplicationArea = All;
                }
                field(RoyaltyRate; Rec."Royalty Rate %")
                {
                    ApplicationArea = All;
                }
                field(RoyaltyVolume; Rec."Royalty Volume")
                {
                    ApplicationArea = All;
                }
                field(SettlementMethod; Rec."Settlement Method")
                {
                    ApplicationArea = All;
                }
                field(RoyaltyAmount; Rec."Royalty Amount")
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
            action(SuggestRoyalty)
            {
                ApplicationArea = All;
                Caption = 'Suggest Royalty';
                ToolTip = 'Calculates royalty from posted production for the selected period (FR-25).';
                trigger OnAction()
                var
                    PeriodDialog: Page "Date Range";
                    RoyaltyCalc: Codeunit "Royalty Calculation";
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
                    SuggestedCount := RoyaltyCalc.SuggestLinesWithResult(FromDate, ToDate);
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
            action(RoyaltyHistory)
            {
                ApplicationArea = All;
                Caption = 'Royalty History';
                Image = History;
                RunObject = page "Royalty History";
            }
            action(PostRoyalty)
            {
                ApplicationArea = All;
                Caption = 'Post Royalty';
                ToolTip = 'Creates journal lines per the field settlement method: cash (Royalty Payable) or in-kind (inventory adjustment) (FR-26).';
                trigger OnAction()
                var
                    Worksheet: Record "Royalty Worksheet";
                    RoyaltyCalc: Codeunit "Royalty Calculation";
                begin
                    CurrPage.SetSelectionFilter(Worksheet);
                    if Worksheet.IsEmpty() then
                        Error('The royalty worksheet is empty. Run the Suggest Royalty action first.');
                    if Confirm('Create journals for selected royalty lines? Journal batches will be created for the accountant to post.') then
                        RoyaltyCalc.PostWorksheet(Worksheet);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
