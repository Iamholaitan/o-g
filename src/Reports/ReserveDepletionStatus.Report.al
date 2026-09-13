// -----------------------------------------------------------------------------
// Reserve Depletion Status (FR-29)
// Original reserves, cumulative production, remaining reserves, depletion %
// and net book value by reservoir as of a selected date.
// -----------------------------------------------------------------------------
report 70091 "Reserve Depletion Status"
{
    Caption = 'Reserve Depletion Status';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Reservoir; "Reservoir")
        {
            column(ReservoirCode; Reservoir."Reservoir Code")
            {
            }
            column(Description; Reservoir.Description)
            {
            }
            column(FieldBlockCode; Reservoir."Field/Block Code")
            {
            }
            column(WellCode; Reservoir."Well Code")
            {
            }
            column(Status; Reservoir.Status)
            {
            }
            column(OriginalOilInPlace; Reservoir."Original Oil In Place (OOIP)")
            {
            }
            column(Proved1P; Reservoir."Proved Reserves (1P)")
            {
            }
            column(Probable2P; Reservoir."Probable Reserves (2P)")
            {
            }
            column(Possible3P; Reservoir."Possible Reserves (3P)")
            {
            }
            column(CumulativeProduction; Reservoir."Cumulative Production BOE")
            {
            }
            column(RemainingReserves; Reservoir."Remaining Reserves BOE")
            {
            }
            column(RecoveryFactor; Reservoir."Recovery Factor %")
            {
            }
            column(TotalCapitalisedCost; Reservoir."Total Capitalised Cost")
            {
            }
            column(AccumulatedDepletion; Reservoir."Accumulated Depletion")
            {
            }
            column(NetBookValue; Reservoir."Total Capitalised Cost" - Reservoir."Accumulated Depletion")
            {
            }
            column(DepletionRate; Reservoir."Depletion Rate per BOE")
            {
            }
            column(ReserveEstimateDate; Reservoir."Reserve Estimate Date")
            {
            }
            column(EstimatedBy; Reservoir."Estimated By")
            {
            }
        }
    }
}
