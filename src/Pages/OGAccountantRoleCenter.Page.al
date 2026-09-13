// -----------------------------------------------------------------------------
// O&G Accountant Role Center (FR-10)
// Landing page for accounting users: pending Item Journal batches cue, quick
// actions into the Depletion Worksheet, royalty/JV postings and the reports.
// NOTE: Role Center pages cannot contain AL code (triggers) - all actions are
// property-based (RunObject).
// -----------------------------------------------------------------------------
page 70048 "O&G Accountant Role Center"
{
    PageType = RoleCenter;
    Caption = 'O&G Accountant';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(PendingItemJournalBatches; "Pending Item Jnl Batches")
            {
                ApplicationArea = All;
                Caption = 'Pending Production Item Journal Batches';
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(OpenProductionDocuments)
            {
                ApplicationArea = All;
                Caption = 'Daily Production Entries';
                ToolTip = 'Review open production documents and send them to the item journal.';
                RunObject = page "Open Production List";
            }
            action(ProductionEntryList)
            {
                ApplicationArea = All;
                Caption = 'Production Entries';
                ToolTip = 'Read-only history of production documents sent to the item journal.';
                RunObject = page "Production Entry List";
            }
            action(DepletionWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Depletion Worksheet';
                ToolTip = 'Unit-of-Production depletion calculation (FR-21).';
                RunObject = page "Depletion Worksheet";
            }
            action(DepletionHistory)
            {
                ApplicationArea = All;
                Caption = 'Depletion History';
                RunObject = page "Depletion History";
            }
            action(RoyaltyHistory)
            {
                ApplicationArea = All;
                Caption = 'Royalty History';
                RunObject = page "Royalty History";
            }
            action(RoyaltyWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Royalty Worksheet';
                ToolTip = 'Royalty calculation and posting - cash or in-kind (FR-26).';
                RunObject = page "Royalty Worksheet";
            }
            action(JVAllocations)
            {
                ApplicationArea = All;
                Caption = 'JV Cost Allocations';
                ToolTip = 'Joint venture cost allocation and partner billing (FR-27).';
                RunObject = page "JV Cost Allocation List";
            }
            action(Reservoirs)
            {
                ApplicationArea = All;
                Caption = 'Reservoirs';
                ToolTip = 'Reservoir master and permitted produced items (FR-03, FR-04).';
                RunObject = page "Reservoir List";
            }
            action(Entities)
            {
                ApplicationArea = All;
                Caption = 'Entities';
                RunObject = page "O&G Entities";
            }
            action(Ownership)
            {
                ApplicationArea = All;
                Caption = 'JV Ownership';
                RunObject = page "JV Ownership List";
            }
            action(EstimationMethods)
            {
                ApplicationArea = All;
                Caption = 'Estimation Methods';
                ToolTip = 'Maintain the selectable list of reserve-estimation methods.';
                RunObject = page "Reserve Estimation Methods";
            }
            action(RoyaltyTerms)
            {
                ApplicationArea = All;
                Caption = 'Royalty Terms';
                ToolTip = 'Per-field royalty terms (FR-25).';
                RunObject = page "Royalty Term List";
            }
            action(JVPartners)
            {
                ApplicationArea = All;
                Caption = 'JV Partners';
                ToolTip = 'JV partner working interests (FR-27).';
                RunObject = page "JV Partner List";
            }
            action(OGSetup)
            {
                ApplicationArea = All;
                Caption = 'O&G Setup';
                ToolTip = 'Defaults, accounts and accounting method (FR-01, FR-09).';
                RunObject = page "O&G Setup";
            }
        }
        area(Reporting)
        {
            action(ProductionSummaryReport)
            {
                ApplicationArea = All;
                Caption = 'Production Summary';
                ToolTip = 'Production Summary Report (FR-28).';
                RunObject = report "Production Summary";
            }
            action(ReserveDepletionReport)
            {
                ApplicationArea = All;
                Caption = 'Reserve Depletion Status';
                ToolTip = 'Reserve Depletion Status Report (FR-29).';
                RunObject = report "Reserve Depletion Status";
            }
            action(InventoryPositionReport)
            {
                ApplicationArea = All;
                Caption = 'Product Inventory Position';
                ToolTip = 'Product Inventory Position Report (FR-30).';
                RunObject = report "Product Inventory Position";
            }
            action(LiftingCostReport)
            {
                ApplicationArea = All;
                Caption = 'Lifting Cost per BOE';
                ToolTip = 'Lifting Cost per BOE Report (FR-31).';
                RunObject = report "Lifting Cost per BOE";
            }
            action(ReserveHistoryReport)
            {
                ApplicationArea = All;
                Caption = 'Reserve Estimate & Revision History';
                ToolTip = 'Reserve Estimate & Revision History Report (FR-32).';
                RunObject = report "Reserve Revision History";
            }
        }
    }
}
