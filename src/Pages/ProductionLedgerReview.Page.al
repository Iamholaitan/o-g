page 70061 "Production Ledger Review"
{
    PageType = List;
    SourceTable = "Item Ledger Entry";
    SourceTableTemporary = true;
    Caption = 'Select Related Posting';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(PostingDate; Rec."Posting Date") { ApplicationArea = All; }
                field(DocumentNo; Rec."Document No.") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(EntryType; Rec."Entry Type") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field(RemainingQuantity; Rec."Remaining Quantity") { ApplicationArea = All; }
                field(Location; Rec."Location Code") { ApplicationArea = All; }
                field(UOM; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(DimensionSet; Rec."Dimension Set ID") { ApplicationArea = All; }
            }
        }
    }
    procedure LoadCandidates(DocumentNo: Code[20])
    var
        Entry: Record "Item Ledger Entry";
    begin
        Rec.DeleteAll(false);
        Entry.SetRange("Document No.", DocumentNo);
        Entry.SetFilter("Entry Type", '%1|%2', Entry."Entry Type"::"Positive Adjmt.", Entry."Entry Type"::"Negative Adjmt.");
        if Entry.FindSet() then
            repeat
                Rec := Entry;
                Rec.Insert(false);
            until Entry.Next() = 0;
    end;
    procedure GetSelection(var Selected: Record "Item Ledger Entry" temporary)
    begin
        Selected.Copy(Rec, true);
        CurrPage.SetSelectionFilter(Selected);
    end;
}
