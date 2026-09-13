// -----------------------------------------------------------------------------
// O&G Setup (FR-01, FR-09)
// Single-record setup page: rates, BOE UOM, accounting method, dimension
// codes, posting accounts and the journal template used for period-end
// postings. Everything is client-configurable - restricted to admin roles.
// -----------------------------------------------------------------------------
page 70030 "O&G Setup"
{
    PageType = Card;
    SourceTable = "O&G Setup";
    Caption = 'O&G Setup';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(RoyaltyTax)
            {
                Caption = 'Royalty & Tax';
                field(DefaultRoyaltyRate; Rec."Default Royalty Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Default royalty percentage used when a field has no specific royalty term (FR-01, FR-25).';
                }
                field(ProductionTaxRate; Rec."Production Tax Rate %")
                {
                    ApplicationArea = All;
                }
            }
            group(Accounting)
            {
                Caption = 'Accounting';
                field(DefaultBOEUOM; Rec."Default BOE UOM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The UOM code (e.g. BOE) that all produced items alternate UOM conversions target (FR-01, FR-02).';
                }
                field(AccountingMethod; Rec."Accounting Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Elected accounting policy: Successful Efforts or Full Cost (FR-09, FR-24).';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions (FR-07)';
                field(FieldBlockDim; Rec."Field/Block Dimension Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Dimension code used for the Field/Block dimension.';
                }
                field(WellDim; Rec."Well Dimension Code")
                {
                    ApplicationArea = All;
                }
                field(ReservoirDim; Rec."Reservoir Dimension Code")
                {
                    ApplicationArea = All;
                }
                field(CostCenterDim; Rec."Cost Center Dimension Code")
                {
                    ApplicationArea = All;
                }
                field(JVPartnerDim; Rec."JV Partner Dimension Code")
                {
                    ApplicationArea = All;
                }
            }
            group(PostingAccounts)
            {
                Caption = 'Posting Accounts';
                field(DepletionExpenseAccount; Rec."Depletion Expense Account")
                {
                    ApplicationArea = All;
                    Caption = 'Legacy Depletion Expense Account';
                    ToolTip = 'Debited on depletion posting (FR-22).';
                }
                field(AccumulatedDepletionAccount; Rec."Accumulated Depletion Account")
                {
                    ApplicationArea = All;
                    Caption = 'Legacy Accumulated Depletion Account';
                    ToolTip = 'Credited (contra-asset) on depletion posting (FR-22).';
                }
                field(RoyaltyExpenseAccount; Rec."Royalty Expense Account")
                {
                    ApplicationArea = All;
                }
                field(RoyaltyPayableAccount; Rec."Royalty Payable Account")
                {
                    ApplicationArea = All;
                }
                field(JVReceivableAccount; Rec."JV Receivable Account")
                {
                    ApplicationArea = All;
                }
                field(ExplorationExpenseAccount; Rec."Exploration Expense Account")
                {
                    ApplicationArea = All;
                }
                field(ExplorationCostsAccount; Rec."Exploration Costs Account")
                {
                    ApplicationArea = All;
                }
            }
            group(Journaling)
            {
                Caption = 'Journaling';
                field(GenJnlTemplateName; Rec."Gen. Journal Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Journal template used for depletion, royalty, JV and write-off journal lines. Select the template here - nothing is hardcoded.';
                }
                field(RoyaltyGenBusPostingGroup; Rec."Royalty Gen. Bus. Post. Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'For in-kind royalty: General Posting Setup for this business group / item product group must use the royalty expense G/L account as Inventory Adjmt. Account.';
                }
                field(BSWGenBusPostingGroup; Rec."BS&W Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Business posting group used only for production BS&W loss lines. In General Posting Setup, combine it with each produced item product group and select the BS&W loss expense account as Inventory Adjmt. Account. Required when BS&W loss is greater than zero.';
                }
                field(FAJournalTemplate; Rec."FA G/L Journal Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Non-recurring Assets-type General Journal template opening the standard FA G/L Journal (page 5628). Depletion accounts come from the linked asset/book FA Posting Group.';
                }
                field(ProductionNos; Rec."Production Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Automatic No. Series for production and reversal documents. Create it in BC with Default Nos. enabled; new production document numbers cannot be entered manually.';
                }
                field(ItemJnlTemplateName; Rec."Item Journal Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a non-recurring template of Type Item that opens the standard Item Journal page. Do not select the Manufacturing Output Journal. The extension uses your existing template and creates only monthly batches and journal lines.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        EnsureDefaultRecord();
        Rec.Get('DEFAULT');
    end;

    local procedure EnsureDefaultRecord()
    var
        Setup: Record "O&G Setup";
        Inserted: Boolean;
    begin
        // Singleton guard: exactly one row ('DEFAULT') must exist.
        // Uses its own record variable (never Rec) so page state cannot
        // interfere, and the Insert() return value is deliberately consumed:
        // by language design that turns a duplicate-key failure into a
        // silent false instead of an error - so this can never raise
        // "already exists", even if two sessions create the row at once.
        if Setup.Get('DEFAULT') then
            exit;
        Setup.Init();
        Setup."Primary Key" := 'DEFAULT';
        Inserted := Setup.Insert(true);
    end;
}
