// -----------------------------------------------------------------------------
// Reservoir List (FR-04)
// -----------------------------------------------------------------------------
page 70031 "Reservoir List"
{
    PageType = List;
    SourceTable = "Reservoir";
    CardPageId = "Reservoir Card";
    Caption = 'Reservoirs';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = false;

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
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                }
                field(WellCode; Rec."Well Code")
                {
                    ApplicationArea = All;
                }
                field(CostCenterCode; Rec."Cost Center Code")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(Proved1P; Rec."Proved Reserves (1P)")
                {
                    ApplicationArea = All;
                }
                field(CumulativeProduction; Rec."Cumulative Production BOE")
                {
                    ApplicationArea = All;
                }
                field(RemainingReserves; Rec."Remaining Reserves BOE")
                {
                    ApplicationArea = All;
                }
                field(DepletionRate; Rec."Depletion Rate per BOE")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
