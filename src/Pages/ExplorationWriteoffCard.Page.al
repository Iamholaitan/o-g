// -----------------------------------------------------------------------------
// Exploration Write-off Card (FR-09, FR-24)
// One action, method-aware behaviour: Successful Efforts expenses the cost,
// Full Cost keeps it capitalised in the pool.
// -----------------------------------------------------------------------------
page 70051 "Exploration Write-off Card"
{
    PageType = Card;
    SourceTable = "Exploration Write-off";
    Caption = 'Exploration Write-off';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(DocumentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(PostingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Unsuccessful exploration cost to be written off (FR-24).';
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JournalBatchName; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostWriteoff)
            {
                ApplicationArea = All;
                Caption = 'Post Write-off';
                ToolTip = 'Expenses the cost immediately (Successful Efforts) or leaves it capitalised (Full Cost), per the method in O&G Setup (FR-24).';
                trigger OnAction()
                var
                    Writeoff: Codeunit "Exploration Write-off";
                begin
                    Writeoff.Post(Rec);
                    CurrPage.Update();
                end;
            }
        }
    }
}
