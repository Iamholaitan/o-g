// -----------------------------------------------------------------------------
// Reservoir Product Setup (FR-03, FR-06)
// Subpage: which items a reservoir is permitted to produce, with default UOM
// and posting location. Configurable per reservoir - no code change needed
// to add a new producible item.
// -----------------------------------------------------------------------------
page 70033 "Reservoir Product Setup"
{
    PageType = ListPart;
    SourceTable = "Reservoir Product Setup";
    Caption = 'Permitted Produced Items';
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'An item permitted for production on this reservoir (FR-03).';
                }
                field(DefaultUOM; Rec."Default Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Default entry UOM for this item on this reservoir production lines (FR-11).';
                }
                field(LocationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Default posting location, e.g. Wellhead / Flow Station (FR-08, FR-16).';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Removes the item from selection on new production lines without deleting history.';
                }
                field(BSWApplicable; Rec."BS&W Applicable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tick where this item on this reservoir requires BS&W treatment: Net Quantity = Gross x (1 - BS&W%) (FR-12).';
                }
            }
        }
    }
}
