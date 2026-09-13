// -----------------------------------------------------------------------------
// JV Cost Allocation Card (FR-27)
// Header with cost lines; posts partner shares to JV Receivable.
// -----------------------------------------------------------------------------
page 70045 "JV Cost Allocation Card"
{
    PageType = Card;
    SourceTable = "JV Cost Allocation Header";
    Caption = 'JV Cost Allocation';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = not Rec.Posted;
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
                    Editable = false;
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
            group(CostLinesGroup)
            {
                Caption = 'Cost Lines';
                part(CostLines; "JV Cost Allocation Line")
                {
                    ApplicationArea = All;
                    Caption = 'Cost Lines';
                    Editable = not Rec.Posted;
                    SubPageLink = "Document No." = FIELD("Document No.");
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostAllocation)
            {
                ApplicationArea = All;
                Caption = 'Post Allocation';
                ToolTip = 'Creates Gen. Journal lines: Dr JV Receivable per partner / Cr cost account (FR-27). The accountant then posts the batch.';
                trigger OnAction()
                var
                    Allocator: Codeunit "JV Cost Allocation";
                begin
                    Allocator.Post(Rec);
                    CurrPage.Update();
                end;
            }
        }
    }
}
