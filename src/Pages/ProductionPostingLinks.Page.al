page 70060 "Production Posting Links"
{
    PageType = List;
    SourceTable = "Production Posting Link";
    Caption = 'Production Posting Links';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(DocumentNo; Rec."Document No.") { ApplicationArea = All; }
                field(ProductionLineNo; Rec."Production Line No.") { ApplicationArea = All; }
                field(State; Rec."State") { ApplicationArea = All; }
                field(JournalTemplateName; Rec."Journal Template Name") { ApplicationArea = All; }
                field(JournalBatchName; Rec."Journal Batch Name") { ApplicationArea = All; }
                field(JournalLineNo; Rec."Journal Line No.") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(EntryType; Rec."Entry Type") { ApplicationArea = All; }
                field(Quantity; Rec."Quantity") { ApplicationArea = All; }
                field(QuantityBase; Rec."Quantity Base") { ApplicationArea = All; }
                field(PostingDate; Rec."Posting Date") { ApplicationArea = All; }
                field(ReversesLedgerEntryNo; Rec."Reverses Ledger Entry No.") { ApplicationArea = All; }
            }
        }
    }
}
