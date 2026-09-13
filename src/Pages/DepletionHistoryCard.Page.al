page 70096 "Depletion History Card"
{
    PageType = Card;
    SourceTable = "Depletion Worksheet";
    SourceTableView = where(Posted = const(true));
    Caption = 'Depletion History';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(Entries)
            {
                field(Status; StatusText) { ApplicationArea = All; Caption = 'Status'; }
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(DocumentNo; Rec."Document No.") { ApplicationArea = All; }
                field(PostingDate; Rec."Posting Date") { ApplicationArea = All; }
                field(PeriodStart; Rec."Period Start") { ApplicationArea = All; }
                field(PeriodEnd; Rec."Period End") { ApplicationArea = All; }
                field(ReservoirCode; Rec."Reservoir Code") { ApplicationArea = All; }
                field(EntityCode; Rec."Entity Code") { ApplicationArea = All; }
                field(FixedAssetNo; Rec."Fixed Asset No.") { ApplicationArea = All; }
                field(DepreciationBookCode; Rec."Depreciation Book Code") { ApplicationArea = All; }
                field(PeriodProductionBOE; Rec."Period Production BOE") { ApplicationArea = All; }
                field(DepletionRateperBOE; Rec."Depletion Rate per BOE") { ApplicationArea = All; }
                field(DepletionAmount; Rec."Depletion Amount") { ApplicationArea = All; }
                field(TotalCapitalisedCost; Rec."Total Capitalised Cost") { ApplicationArea = All; }
                field(AccumulatedDepletion; Rec."Accumulated Depletion") { ApplicationArea = All; }
                field(RemainingNBV; Rec."Remaining NBV") { ApplicationArea = All; }
                field(RemainingReservesBOE; Rec."Remaining Reserves BOE") { ApplicationArea = All; }
                field(FAPostingGroup; Rec."FA Posting Group") { ApplicationArea = All; }
                field(PostingRoute; Rec."Posting Route") { ApplicationArea = All; }
                field(GenJournalTemplateName; Rec."Gen. Journal Template Name") { ApplicationArea = All; }
                field(JournalBatchName; Rec."Journal Batch Name") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenJournal)
            {
                ApplicationArea = All;
                Caption = 'Open Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    Mgt: Codeunit "FA Depletion Posting";
                begin
                    Mgt.OpenJournal(Rec);
                end;
            }
            action(OpenFALedger)
            {
                ApplicationArea = All;
                Caption = 'FA Ledger Entries';
                Image = LedgerEntries;
                trigger OnAction()
                var
                    Mgt: Codeunit "FA Depletion Posting";
                begin
                    Mgt.OpenFALedger(Rec);
                end;
            }
            action(OpenAsset)
            {
                ApplicationArea = All;
                Caption = 'Fixed Asset';
                RunObject = page "Fixed Asset Card";
                RunPageLink = "No." = field("Fixed Asset No.");
            }
            action(ShowDimensions)
            {
                ApplicationArea = All;
                Caption = 'Dimensions';
                trigger OnAction()
                var
                    DimMgt: Codeunit DimensionManagement;
                begin
                    DimMgt.ShowDimensionSet(Rec."Dimension Set ID", CopyStr('Depletion ' + Rec."Document No.", 1, 250));
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        Mgt: Codeunit "FA Depletion Posting";
    begin
        StatusText := Mgt.StatusText(Rec);
    end;
    var
        StatusText: Text[50];
}
