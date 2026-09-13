// -----------------------------------------------------------------------------
// JV Cost Allocation List (FR-27)
// -----------------------------------------------------------------------------
page 70044 "JV Cost Allocation List"
{
    PageType = List;
    SourceTable = "JV Cost Allocation Header";
    Caption = 'JV Cost Allocations';
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
                field(Entity; Rec."Entity Code") { ApplicationArea = All; ShowMandatory = true; }
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(TotalAmount; Rec."Total Amount")
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
