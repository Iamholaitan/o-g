// -----------------------------------------------------------------------------
// Reserve Estimate & Revision History (FR-32)
// For a selected reservoir: every recorded reserve estimate and revision with
// preparer, method/basis and date - the client-facing evidence trail for
// internally estimated (non-certified) figures.
// -----------------------------------------------------------------------------
report 70094 "Reserve Revision History"
{
    Caption = 'Reserve Estimate & Revision History';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Revision; "Reserve Revision History")
        {
            column(EntryNo; Revision."Entry No.")
            {
            }
            column(ReservoirCode; Revision."Reservoir Code")
            {
            }
            column(RevisionDate; Revision."Revision Date")
            {
            }
            column(PreviousReserves; Revision."Previous Reserves (BOE)")
            {
            }
            column(RevisedReserves; Revision."Revised Reserves (BOE)")
            {
            }
            column(PreparedBy; Revision."Prepared By")
            {
            }
            column(EstimationBasis; Revision."Estimation Basis")
            {
            }
        }
    }
}
