page 70099 "Royalty History"
{
    PageType = List;
    SourceTable = "Royalty Worksheet";
    SourceTableView = where(Posted = const(true));
    Caption = 'Royalty History (Sent to Journal)';
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(PostingDate; Rec."Posting Date") { ApplicationArea = All; }
                field(PeriodStart; Rec."Period Start") { ApplicationArea = All; }
                field(PeriodEnd; Rec."Period End") { ApplicationArea = All; }
                field(EntityCode; Rec."Entity Code") { ApplicationArea = All; }
                field(FieldBlockCode; Rec."Field/Block Code") { ApplicationArea = All; }
                field(ReservoirCode; Rec."Reservoir Code") { ApplicationArea = All; }
                field(ProductionDocumentNo; Rec."Production Document No.") { ApplicationArea = All; }
                field(ProductionLineNo; Rec."Production Line No.") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(UnitofMeasureCode; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(GrossVolume; Rec."Gross Volume") { ApplicationArea = All; }
                field(RoyaltyRate; Rec."Royalty Rate %") { ApplicationArea = All; }
                field(RoyaltyVolume; Rec."Royalty Volume") { ApplicationArea = All; }
                field(RoyaltyAmount; Rec."Royalty Amount") { ApplicationArea = All; }
                field(SettlementMethod; Rec."Settlement Method") { ApplicationArea = All; }
                field(JournalTemplateName; Rec."Journal Template Name") { ApplicationArea = All; }
                field(JournalBatchName; Rec."Journal Batch Name") { ApplicationArea = All; }
            }
        }
    }
}
