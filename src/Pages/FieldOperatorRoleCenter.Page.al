// -----------------------------------------------------------------------------
// Field Operator Role Center (FR-10)
// Landing page for field-operator users: open entries cue and quick action
// into Daily Production Entry. No financial/posting actions exposed.
// NOTE: Role Center pages cannot contain AL code (triggers) - all actions are
// property-based (RunObject); the filtering happens on the pages they open.
// -----------------------------------------------------------------------------
page 70047 "Field Operator Role Center"
{
    PageType = RoleCenter;
    Caption = 'Field Operator';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(OpenEntries; "Open Production Entries")
            {
                ApplicationArea = All;
                Caption = 'Open Production Entries';
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(NewProductionEntry)
            {
                ApplicationArea = All;
                Caption = 'New Production Entry';
                ToolTip = 'Creates a new daily production document (FR-11).';
                RunObject = page "Production Entry Card";
                RunPageMode = Create;
            }
            action(OpenProductionDocuments)
            {
                ApplicationArea = All;
                Caption = 'Daily Production Entries';
                ToolTip = 'Open production documents that can still be edited.';
                RunObject = page "Open Production List";
            }
            action(Reservoirs)
            {
                ApplicationArea = All;
                Caption = 'Reservoirs';
                ToolTip = 'View Reservoir masters and their configured production items.';
                RunObject = page "Reservoir List";
            }
            action(ProductionEntryList)
            {
                ApplicationArea = All;
                Caption = 'Production Entries';
                ToolTip = 'Read-only history of production documents sent to the item journal.';
                RunObject = page "Production Entry List";
            }
        }
    }
}
