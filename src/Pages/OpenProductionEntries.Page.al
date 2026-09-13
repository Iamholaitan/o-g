// -----------------------------------------------------------------------------
// Open Production Entries (FR-10)
// Cue part for the Field Operator Role Center: unposted daily production.
// -----------------------------------------------------------------------------
page 70052 "Open Production Entries"
{
    PageType = ListPart;
    SourceTable = "Production Entry Header";
    SourceTableView = where(Posted = const(false), Cancelled = const(false));
    CardPageId = "Production Entry Card";
    Caption = 'Open Production Entries';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(DocumentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Production Entry Card", Rec);
                    end;
                }
                field(Entity; Rec."Entity Code") { ApplicationArea = All; }
                field(ProductionDate; Rec."Production Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(TotalBOE; Rec."Calculated BOE")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
