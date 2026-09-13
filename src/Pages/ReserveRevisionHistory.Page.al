// -----------------------------------------------------------------------------
// Reserve Revision History (FR-05, FR-32)
// Read-only audit trail of reserve estimate changes.
// -----------------------------------------------------------------------------
page 70034 "Reserve Revision History"
{
    PageType = List;
    SourceTable = "Reserve Revision History";
    Caption = 'Reserve Estimate & Revision History';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(EntryNo; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                }
                field(RevisionDate; Rec."Revision Date")
                {
                    ApplicationArea = All;
                }
                field(PreviousReserves; Rec."Previous Reserves (BOE)")
                {
                    ApplicationArea = All;
                }
                field(RevisedReserves; Rec."Revised Reserves (BOE)")
                {
                    ApplicationArea = All;
                }
                field(EstimationMethodCode; Rec."Estimation Method Code")
                {
                    ApplicationArea = All;
                }
                field(ChangedBy; Rec."Changed By")
                {
                    ApplicationArea = All;
                }
                field(ChangedAt; Rec."Changed At")
                {
                    ApplicationArea = All;
                }
                field(PreparedBy; Rec."Prepared By")
                {
                    ApplicationArea = All;
                }
                field(EstimationBasis; Rec."Estimation Basis")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
