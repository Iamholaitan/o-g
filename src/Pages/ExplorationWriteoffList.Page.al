// -----------------------------------------------------------------------------
// Exploration Write-off List (FR-24)
// -----------------------------------------------------------------------------
page 70050 "Exploration Write-off List"
{
    PageType = List;
    SourceTable = "Exploration Write-off";
    Caption = 'Exploration Write-offs';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
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
                }
                field(Posted; Rec.Posted)
                {
                    ApplicationArea = All;
                }
                field(JournalBatchName; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
