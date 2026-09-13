// Work queue for open input documents; kept separate from immutable history.
page 70054 "Open Production List"
{
    PageType = List;
    SourceTable = "Production Entry Header";
    SourceTableView = where(Posted = const(false), Cancelled = const(false));
    CardPageId = "Production Entry Card";
    Caption = 'Daily Production Entries';
    UsageCategory = Documents;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(OpenDocuments)
            {
                field(DocumentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(Entity; Rec."Entity Code") { ApplicationArea = All; }
                field(ProductionDate; Rec."Production Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                }
                field(WellCode; Rec."Well Code")
                {
                    ApplicationArea = All;
                }
                field(CostCenterCode; Rec."Cost Center Code")
                {
                    ApplicationArea = All;
                }
                field(TotalBOE; Rec."Calculated BOE")
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
            action(NewProductionEntry)
            {
                ApplicationArea = All;
                Caption = 'New Production Entry';
                RunObject = page "Production Entry Card";
                RunPageMode = Create;
            }
            action(PostToItemJournal)
            {
                ApplicationArea = All;
                Caption = 'Post to Item Journal';
                AccessByPermission = codeunit "Post Daily Production" = X;
                ToolTip = 'Send the selected open document to the configured item journal, then lock the source.';
                trigger OnAction()
                var
                    Poster: Codeunit "Post Daily Production";
                begin
                    Poster.Post(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PostAllOpen)
            {
                ApplicationArea = All;
                Caption = 'Post All Open Entries';
                AccessByPermission = codeunit "Post Daily Production" = X;
                ToolTip = 'Send all open production documents in the selected date range to the item journal. Nothing is posted to inventory automatically.';
                trigger OnAction()
                var
                    PeriodDialog: Page "Date Range";
                    Poster: Codeunit "Post Daily Production";
                    Result: Action;
                    FromDate: Date;
                    ToDate: Date;
                begin
                    PeriodDialog.SetDates(WorkDate(), WorkDate());
                    Result := PeriodDialog.RunModal();
                    if not PeriodDialog.IsConfirmed(Result) then
                        exit;
                    PeriodDialog.GetDates(FromDate, ToDate);
                    Poster.PostAllOpen(FromDate, ToDate);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
