// -----------------------------------------------------------------------------
// Reservoir Card (FR-04, FR-03, FR-05, FR-21)
// Reservoir master with product setup subpage, reserve estimation fields,
// revision history drill-down and depletion worksheet action.
// -----------------------------------------------------------------------------
page 70032 "Reservoir Card"
{
    PageType = Card;
    SourceTable = "Reservoir";
    Caption = 'Reservoir Card';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(General)
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(CostCenterCode; Rec."Cost Center Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Reserves)
            {
                Caption = 'Reserve Estimates (internally estimated - not third-party certified)';
                field(OriginalOilInPlace; Rec."Original Oil In Place (OOIP)")
                {
                    ApplicationArea = All;
                }
                field(Proved1P; Rec."Proved Reserves (1P)")
                {
                    ApplicationArea = All;
                }
                field(Probable2P; Rec."Probable Reserves (2P)")
                {
                    ApplicationArea = All;
                }
                field(Possible3P; Rec."Possible Reserves (3P)")
                {
                    ApplicationArea = All;
                }
                field(EstimatedBy; Rec."Estimated By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select an enabled Business Central user as the estimate preparer. New Reservoirs default to the signed-in user. Existing preparer names are preserved; no user account is deleted.';
                }
                field(EstimationMethodCode; Rec."Estimation Method Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select an unblocked method from your maintained Reserve Estimation Methods list. Use the Estimation Methods action to create or maintain choices.';
                }
                field(EstimationMethod; Rec."Estimation Method")
                {
                    ApplicationArea = All;
                    Caption = 'Method Details / Legacy Text';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Description captured when the method was selected. Existing free-text methods are retained here until a list method is explicitly chosen; later catalogue edits do not rewrite history.';
                }
                field(ReserveEstimateDate; Rec."Reserve Estimate Date")
                {
                    ApplicationArea = All;
                }
                field(CumulativeProduction; Rec."Cumulative Production BOE")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Automatically calculated from posted Production Entry documents - you never enter this (FR-19).';
                }
                field(RemainingReserves; Rec."Remaining Reserves BOE")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Proved Reserves (1P) minus Cumulative Production BOE - kept in sync automatically (FR-19, FR-20).';
                }
                field(RecoveryFactor; Rec."Recovery Factor %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Estimated ultimate recoverable oil / original oil in place x 100, on the same volume basis. For example, 3 million recoverable out of 10 million originally in place is 30%. This is not depletion or the percentage already produced and does not automatically set reserves or depletion.';
                }
            }
            group(Depletion)
            {
                Caption = 'Depletion (UOP)';
                field(FixedAssetNo; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fixed Asset that receives UOP depletion through the FA G/L Journal. The asset must have the selected depreciation book, an acquired cost and a valid FA Posting Group.';
                }
                field(DepreciationBookCode; Rec."Depreciation Book Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Book assigned to the linked Fixed Asset. Enable G/L Integration - Depreciation. Do not also run a separate automatic depreciation charge for the same UOP period.';
                }
                field(TotalCapitalisedCost; Rec."Total Capitalised Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Approved capitalised cost basis used by Depletion Suggest Lines. It is not automatically read from the linked Fixed Asset. If cost minus accumulated depletion is zero, no depletion expense is suggested.';
                }
                field(AccumulatedDepletion; Rec."Accumulated Depletion")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Automatically accumulated from posted Depletion Worksheet lines - you never enter this (FR-20, FR-21).';
                }
                field(DepletionRate; Rec."Depletion Rate per BOE")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Products)
            {
                Caption = 'Permitted Produced Items (FR-03)';
                part(ProductSetup; "Reservoir Product Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Permitted Produced Items';
                    SubPageLink = "Reservoir Code" = FIELD("Reservoir Code");
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EstimationMethods)
            {
                ApplicationArea = All;
                Caption = 'Estimation Methods';
                RunObject = page "Reserve Estimation Methods";
                ToolTip = 'Create or maintain the list of reserve-estimation methods. Used methods can be blocked instead of deleted.';
            }
            action(OpenDepletionWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Depletion Worksheet';
                ToolTip = 'Opens the Unit-of-Production depletion calculation worksheet (FR-21).';
                trigger OnAction()
                begin
                    Page.Run(Page::"Depletion Worksheet");
                end;
            }
            action(ShowRevisionHistory)
            {
                ApplicationArea = All;
                Caption = 'Reserve Revision History';
                ToolTip = 'Shows the audit trail of reserve estimate changes (FR-05). Filter by reservoir on the list.';
                trigger OnAction()
                begin
                    Page.Run(Page::"Reserve Revision History");
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        EstimationMgt: Codeunit "Reserve Estimation Mgt.";
    begin
        EstimationMgt.DefaultCurrentEstimator(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        // FlowFields are only shown once calculated.
        Rec.CalcFields("Cumulative Production BOE", "Accumulated Depletion");
    end;
}
