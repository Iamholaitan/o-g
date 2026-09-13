// Pending production batches in the template configured in O&G Setup.
// Temporary view: excludes empty batches; selecting one opens the actual journal.
page 70053 "Pending Item Jnl Batches"
{
    PageType = ListPart;
    SourceTable = "Item Journal Batch";
    SourceTableTemporary = true;
    Caption = 'Pending Production Item Journals';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Batches)
            {
                field(TemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field(BatchName; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
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
            action(OpenJournal)
            {
                ApplicationArea = All;
                Caption = 'Open Item Journal';
                trigger OnAction()
                var
                    JournalNavigation: Codeunit "O&G Item Journal Navigation";
                begin
                    Rec.TestField(Name);
                    JournalNavigation.OpenBatch(Rec."Journal Template Name", Rec.Name, '');
                end;
            }
            action(RefreshBatches)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                trigger OnAction()
                begin
                    LoadPendingBatches();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadPendingBatches();
    end;

    local procedure LoadPendingBatches()
    var
        OGSetup: Record "O&G Setup";
        Batch: Record "Item Journal Batch";
        JournalLine: Record "Item Journal Line";
    begin
        Rec.Reset();
        Rec.DeleteAll(false);
        if not OGSetup.Get('DEFAULT') then
            exit;
        if OGSetup."Item Journal Template Name" = '' then
            exit;
        Batch.SetRange("Journal Template Name", OGSetup."Item Journal Template Name");
        Batch.SetFilter(Name, 'PROD*|REV*');
        if Batch.FindSet() then
            repeat
                JournalLine.SetRange("Journal Template Name", Batch."Journal Template Name");
                JournalLine.SetRange("Journal Batch Name", Batch.Name);
                if not JournalLine.IsEmpty() then begin
                    Rec := Batch;
                    Rec.Insert(false);
                end;
            until Batch.Next() = 0;
    end;
}
