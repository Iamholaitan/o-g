// -----------------------------------------------------------------------------
// Royalty Term List (FR-25)
// -----------------------------------------------------------------------------
page 70039 "Royalty Term List"
{
    PageType = List;
    SourceTable = "Royalty Term";
    CardPageId = "Royalty Term Card";
    DelayedInsert = true;
    Caption = 'Royalty Terms';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(RoyaltyRate; Rec."Royalty Rate %")
                {
                    ApplicationArea = All;
                }
                field(RoyaltyBasis; Rec."Royalty Basis")
                {
                    ApplicationArea = All;
                }
                field(SettlementMethod; Rec."Settlement Method")
                {
                    ApplicationArea = All;
                }
                field(UnitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
