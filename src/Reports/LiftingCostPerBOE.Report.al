// -----------------------------------------------------------------------------
// Lifting Cost per BOE (FR-31)
// Total lifting (operating) cost divided by net production volume for the
// selected period. Uses standard BC G/L data (filter the request page by
// Posting Date and G/L account range, e.g. the Cost Center dimension), plus
// posted production volumes. The running period ratio is shown per row.
// -----------------------------------------------------------------------------
report 70093 "Lifting Cost per BOE"
{
    Caption = 'Lifting Cost per BOE';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GLEntry; "G/L Entry")
        {
            column(PostingDate; GLEntry."Posting Date")
            {
            }
            column(AccountNo; GLEntry."G/L Account No.")
            {
            }
            column(Description; GLEntry.Description)
            {
            }
            column(Amount; GLEntry.Amount)
            {
            }
            column(RunningLiftingCost; TotalLiftingCost)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TotalLiftingCost += GLEntry.Amount;
            end;
        }

        dataitem(ProdHeader; "Production Entry Header")
        {
            column(ProductionDate; ProdHeader."Production Date")
            {
            }
            column(FieldBlockCode; ProdHeader."Field/Block Code")
            {
            }
            column(ReservoirCode; ProdHeader."Reservoir Code")
            {
            }
            column(TotalBOE; ProdHeader."Total BOE")
            {
            }
            column(RunningTotalBOE; TotalProductionBOE)
            {
            }
            column(RunningLiftingCostValue; TotalLiftingCost)
            {
            }
            column(CostPerBOE; CostPerBOERunning)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TotalProductionBOE += ProdHeader."Total BOE";
                if TotalProductionBOE = 0 then
                    CostPerBOERunning := 0
                else
                    CostPerBOERunning := Round(TotalLiftingCost / TotalProductionBOE, 0.0001);
            end;
        }
    }

    trigger OnPreReport()
    begin
        TotalLiftingCost := 0;
        TotalProductionBOE := 0;
        CostPerBOERunning := 0;
    end;

    var
        TotalLiftingCost: Decimal;
        TotalProductionBOE: Decimal;
        CostPerBOERunning: Decimal;
}
