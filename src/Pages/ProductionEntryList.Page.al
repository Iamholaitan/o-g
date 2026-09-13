// Read-only history: journal generation, not confirmation of ledger posting.
page 70035 "Production Entry List"
{
    PageType = List;
    SourceTable = "Production Entry Header";
    SourceTableView = where(Posted = const(true));
    CardPageId = "Posted Production Card";
    Caption = 'Production Entries';
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(DocumentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(Entity; Rec."Entity Code") { ApplicationArea = All; }
                field(Status; DisplayStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                }
                field(ProductionDate; Rec."Production Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
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
                field(RecordKind; Rec."Record Kind") { ApplicationArea = All; Visible = ShowPostingDetails; }
                field(InventoryState; Rec."Inventory Posting State") { ApplicationArea = All; Visible = ShowPostingDetails; }
                field(Cancelled; Rec.Cancelled) { ApplicationArea = All; Visible = ShowPostingDetails; }
                field(ReversesDocument; Rec."Reverses Document No.") { ApplicationArea = All; Visible = ShowPostingDetails; }
                field(ReversedByDocument; Rec."Reversed By Document No.") { ApplicationArea = All; Visible = ShowPostingDetails; }
                field(TotalBOE; Rec."Total BOE")
                {
                    ApplicationArea = All;
                }
                field(TemplateName; Rec."Item Journal Template Name")
                {
                    ApplicationArea = All;
                    Visible = ShowPostingDetails;
                }
                field(BatchName; Rec."Item Journal Batch Name")
                {
                    ApplicationArea = All;
                    Visible = ShowPostingDetails;
                }
                field(SentToJournal; Rec.Posted)
                {
                    ApplicationArea = All;
                    Visible = ShowPostingDetails;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReverseProduction)
            {
                ApplicationArea = All;
                Caption = 'Reverse';
                Image = ReverseRegister;
                Promoted = true;
                PromotedCategory = Process;
                AccessByPermission = codeunit "Production Reversal Mgt." = X;
                ToolTip = 'Cancel verified pending rows or prepare a posted-production reversal for review. Original posting evidence is found automatically when unambiguous.';
                trigger OnAction()
                var
                    Workflow: Codeunit "Production Entry Workflow";
                    Dialog: Page "Production Correction Dialog";
                    DateHelper: Page "Date Range";
                    Selected: Record "Item Ledger Entry" temporary;
                    Reversal: Record "Production Entry Header";
                    LinkLegacy: Boolean;
                    Date: Date;
                    Reason: Text[250];
                    NewNo: Code[20];
                begin
                    if not Workflow.PrepareEvidence(Rec."Document No.", Selected, LinkLegacy) then
                        exit;
                    Dialog.SetSource(Rec."Document No.");
                    if not DateHelper.IsConfirmed(Dialog.RunModal()) then
                        exit;
                    Dialog.GetValues(Date, Reason);
                    if not Confirm('Reverse production %1? Pending rows will be cancelled; posted inventory will create an opposite journal for your review and posting. Related financial calculations are not silently reversed.', false, Rec."Document No.") then
                        exit;
                    NewNo := Workflow.Reverse(Rec."Document No.", Date, Reason, Selected, LinkLegacy);
                    Rec.Get(Rec."Document No.");
                    CurrPage.Update(false);
                    if NewNo <> '' then begin
                        Reversal.Get(NewNo);
                        Page.Run(Page::"Posted Production Card", Reversal);
                    end;
                end;
            }
            action(CorrectDimensions)
            {
                ApplicationArea = All;
                Caption = 'Correct Dimensions';
                Image = ChangeDimensions;
                Promoted = true;
                PromotedCategory = Process;
                AccessByPermission = codeunit "Production Dimension Mgt." = X;
                ToolTip = 'Audited correction of Entity and selected dimensions on this source and verified related postings. Does not change quantities, values or posting dates.';
                trigger OnAction()
                var
                    Workflow: Codeunit "Production Entry Workflow";
                    Dialog: Page "Correct Production Dimensions";
                    DateHelper: Page "Date Range";
                    Mgt: Codeunit "Production Dimension Mgt.";
                    Selected: Record "Item Ledger Entry" temporary;
                    LinkLegacy: Boolean;
                    CorrectionNo: Integer;
                begin
                    Mgt.CheckNoActiveCorrection(Rec."Document No.");
                    if not Workflow.PrepareEvidence(Rec."Document No.", Selected, LinkLegacy) then
                        exit;
                    Dialog.SetSource(Rec);
                    if not DateHelper.IsConfirmed(Dialog.RunModal()) then
                        exit;
                    if not Confirm('Correct dimensions for %1 and its verified related postings? Quantities/amounts stay unchanged. G/L correction uses standard BC and keeps an audit trail. Do not run inventory posting or cost adjustment concurrently.', false, Rec."Document No.") then
                        exit;
                    Workflow.EnsureEvidence(Rec."Document No.", Selected, LinkLegacy);
                    CorrectionNo := Dialog.PrepareCorrection();
                    Mgt.RunPrepared(CorrectionNo);
                    Rec.Get(Rec."Document No.");
                    CurrPage.Update(false);
                end;
            }
            action(CorrectedCopy)
            {
                ApplicationArea = All;
                Caption = 'Create Corrected Production';
                AccessByPermission = codeunit "Production Reversal Mgt." = X;
                Image = CopyDocument;
                trigger OnAction()
                var
                    Mgt: Codeunit "Production Reversal Mgt.";
                    Draft: Record "Production Entry Header";
                    NewNo: Code[20];
                begin
                    NewNo := Mgt.CreateCorrectionCopy(Rec."Document No.");
                    Draft.Get(NewNo);
                    Page.Run(Page::"Production Entry Card", Draft);
                end;
            }
            action(PostingEvidence)
            {
                ApplicationArea = All;
                Caption = 'Posting Details';
                Visible = ShowPostingDetails;
                RunObject = page "Production Posting Links";
                RunPageLink = "Document No." = field("Document No.");
            }
            action(DimensionHistory)
            {
                ApplicationArea = All;
                Caption = 'Dimension History';
                Image = History;
                RunObject = page "Production Dimension History";
                RunPageLink = "Document No." = field("Document No.");
            }
            action(ToggleDetails)
            {
                ApplicationArea = All;
                Caption = 'Show/Hide Posting Details';
                trigger OnAction()
                begin
                    ShowPostingDetails := not ShowPostingDetails;
                    CurrPage.Update(false);
                end;
            }
            action(ShowDimensions)
            {
                ApplicationArea = All;
                Caption = 'Production Dimensions';
                ToolTip = 'View the production dimensions recorded when this document was sent to the item journal.';
                trigger OnAction()
                begin
                    Helper.ShowProductionDimensions(Rec);
                end;
            }
            action(OpenReservoir)
            {
                ApplicationArea = All;
                Caption = 'Reservoir Card';
                trigger OnAction()
                begin
                    Helper.OpenReservoir(Rec);
                end;
            }
            action(OpenItemJournal)
            {
                ApplicationArea = All;
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Open Standard Item Journal';
                AccessByPermission = codeunit "Post Daily Production" = X;
                ToolTip = 'Open the standard BC Item Journal and full recorded batch, with native item, quantity, UOM, cost, amount and posting controls.';
                trigger OnAction()
                begin
                    Helper.OpenItemJournal(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Workflow: Codeunit "Production Entry Workflow";
    begin
        DisplayStatus := Workflow.StatusText(Rec);
    end;

    var
        ShowPostingDetails: Boolean;
        DisplayStatus: Text[50];
        Helper: Codeunit "Production Entry Helper";
}
