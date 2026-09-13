// -----------------------------------------------------------------------------
// Royalty Term Card (FR-25, FR-26)
// Per-field/contract royalty terms: rate, basis, settlement method, accounts.
// -----------------------------------------------------------------------------
page 70040 "Royalty Term Card"
{
    PageType = Card;
    SourceTable = "Royalty Term";
    Caption = 'Royalty Term Card';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Select a valid Field/Block dimension value from the code configured in O&G Setup. The term covers all production reservoirs in that field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
            group(Royalty)
            {
                Caption = 'Royalty';
                field(RoyaltyRate; Rec."Royalty Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Royalty percentage per the field contract. 0 = use the O&G Setup default (FR-25).';
                }
                field(RoyaltyBasis; Rec."Royalty Basis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Production volume or production reference value. Both use the selected production period; neither option reads posted sales invoices. Confirm chargeable quantities, effective rate and fiscal/reference price for the applicable licence.';
                }
                field(RateReference; Rec."Rate Reference") { ApplicationArea = All; }
                field(PriceReference; Rec."Price Reference") { ApplicationArea = All; }
                field(SettlementMethod; Rec."Settlement Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cash = Royalty Payable liability; In-Kind = negative inventory volume adjustment (FR-26).';
                }
                field(UnitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Reference Unit Price (LCY)';
                    ToolTip = 'Approved/fiscal reference price per source production UOM in company LCY. Do not apply one price to unlike oil/gas products or UOMs without an approved pricing basis.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting Accounts';
                field(RoyaltyExpenseAccount; Rec."Royalty Expense Account")
                {
                    ApplicationArea = All;
                    ToolTip = 'Overrides the O&G Setup default for this field.';
                }
                field(RoyaltyPayableAccount; Rec."Royalty Payable Account")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SelectReservoir)
            {
                ApplicationArea = All;
                Caption = 'Choose Field from Reservoir';
                ToolTip = 'Use a Reservoir to identify its Field/Block. This does not make the royalty reserve-based or limit the term to only that Reservoir.';
                trigger OnAction()
                var
                    Reservoir: Record Reservoir;
                    Reservoirs: Page "Reservoir List";
                begin
                    Reservoirs.LookupMode(true);
                    if Reservoirs.RunModal() <> Action::LookupOK then
                        exit;
                    Reservoirs.GetRecord(Reservoir);
                    if (Rec."Field/Block Code" <> '') and (Rec."Field/Block Code" <> Reservoir."Field/Block Code") then
                        Error('Create a new term for Field/Block %1 rather than changing an existing term key.', Reservoir."Field/Block Code");
                    Rec.Validate("Field/Block Code", Reservoir."Field/Block Code");
                    CurrPage.Update(true);
                end;
            }
            action(RelatedReservoirs)
            {
                ApplicationArea = All;
                Caption = 'Reservoirs in this Field';
                RunObject = page "Reservoir List";
                RunPageLink = "Field/Block Code" = field("Field/Block Code");
            }
        }
    }
}
