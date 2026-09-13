// -----------------------------------------------------------------------------
// Daily Production Entry: editable input until sent to the item journal.
// History is exposed separately through Production Entry List / Posted Card.
// -----------------------------------------------------------------------------
page 70036 "Production Entry Card"
{
    PageType = Card;
    SourceTable = "Production Entry Header";
    Caption = 'Daily Production Entry';
    UsageCategory = Documents;
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = IsOpen;
                field(DocumentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Assigned automatically from Production Nos. in O&G Setup when the document is first saved.';
                }
                field(ProductionDate; Rec."Production Date")
                {
                    ApplicationArea = All;
                }
                field(ReservoirCode; Rec."Reservoir Code")
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    ToolTip = 'Choose a Reservoir master record. Field/Block, Well and Cost Center default from it. Use the assist button or Reservoir Card action to view the master.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Helper.OpenReservoir(Rec);
                    end;
                }
                field(EntityCode; Rec."Entity Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Global Dimension 1 Entity: Joint Operation or Operator activity. This classifies the transaction; it does not allocate ownership or management fees.';
                }
                field(FieldBlockCode; Rec."Field/Block Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Defaults from the Reservoir. While open, select another valid value of the Field/Block dimension configured in O&G Setup.';
                }
                field(WellCode; Rec."Well Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Defaults from the Reservoir. While open, select another valid value of the Well dimension configured in O&G Setup.';
                }
                field(CostCenterCode; Rec."Cost Center Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Defaults from the Reservoir; lookup uses the Cost Center dimension code in O&G Setup.';
                }
            }
            group(TotalsAndJournal)
            {
                Caption = 'Production Totals';
                field(OpenTotalBOE; Rec."Calculated BOE")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = IsOpen;
                    ToolTip = 'Calculated from the saved production lines in the common BOE unit. Quantities in unlike units are not simply added together.';
                }
                field(SentTotalBOE; Rec."Total BOE")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not IsOpen;
                    ToolTip = 'The frozen BOE total recorded when this document was sent to the item journal.';
                }
                field(ItemJournalTemplateName; DisplayTemplateName)
                {
                    Caption = 'Item Journal Template Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'While open, shows the current Item Journal Template Name from O&G Setup. Once sent, shows the template actually used, preserved on the document.';
                }
                field(Status; DisplayStatus) { ApplicationArea = All; Caption = 'Status'; Editable = false; }
                field(InventoryPostingState; Rec."Inventory Posting State") { ApplicationArea = All; Editable = false; Visible = ShowPostingDetails; }
                field(CorrectsDocument; Rec."Corrects Document No.") { ApplicationArea = All; Editable = false; Visible = ShowPostingDetails; }
                field(ItemJournalBatchName; Rec."Item Journal Batch Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'The monthly batch populated when sent. Use Open Item Journal to review any unposted lines.';
                }
                field(SentToItemJournal; Rec.Posted)
                {
                    ApplicationArea = All;
                    Visible = ShowPostingDetails;
                    Editable = false;
                    ToolTip = 'The source is locked after journal generation. This does not confirm inventory or G/L posting.';
                }
            }
            part(ProductionLines; "Production Entry Line")
            {
                ApplicationArea = All;
                Caption = 'Production Lines';
                SubPageLink = "Document No." = field("Document No.");
                Editable = IsOpen;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CalcNetVolumes)
            {
                ApplicationArea = All;
                Caption = 'Calculate Net Volumes';
                Enabled = IsOpen;
                ToolTip = 'Recalculates net quantities and BOE for this open document. The total is also refreshed automatically from saved lines.';
                trigger OnAction()
                var
                    ProdLine: Record "Production Entry Line";
                begin
                    CurrPage.SaveRecord();
                    CurrPage.ProductionLines.Page.SaveCurrentLine();
                    Rec.Get(Rec."Document No.");
                    Rec.TestOpen();
                    ProdLine.SetRange("Document No.", Rec."Document No.");
                    if ProdLine.FindSet(true) then
                        repeat
                            ProdLine.Modify(true);
                        until ProdLine.Next() = 0;
                    Helper.CalcHeaderTotals(Rec);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(PostToItemJournal)
            {
                ApplicationArea = All;
                Caption = 'Post to Item Journal';
                Enabled = IsOpen;
                AccessByPermission = codeunit "Post Daily Production" = X;
                ToolTip = 'Accountant action: creates item journal lines in the template selected in O&G Setup, then locks this source document. It does not post the journal to inventory.';
                trigger OnAction()
                var
                    Poster: Codeunit "Post Daily Production";
                begin
                    CurrPage.SaveRecord();
                    CurrPage.ProductionLines.Page.SaveCurrentLine();
                    Poster.Post(Rec);
                    Rec.Get(Rec."Document No.");
                    UpdateControlState();
                    CurrPage.Update(false);
                end;
            }
            action(RefreshDefaults)
            {
                ApplicationArea = All;
                Caption = 'Refresh Missing Defaults';
                Enabled = IsOpen;
                ToolTip = 'For an older open document, fill missing Field/Block, Well and Cost Center values from the Reservoir and refresh the setup template. Existing dimension overrides are preserved; sent history cannot be changed.';
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Rec.Get(Rec."Document No.");
                    Rec.TestOpen();
                    Rec.SetReservoirDefaults(false);
                    Rec.InitializeOpenDefaults();
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(ReverseProduction)
            {
                ApplicationArea = All;
                Caption = 'Reverse';
                Enabled = not IsOpen;
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
                Enabled = not IsOpen;
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
                ToolTip = 'View the configured dimension codes and selected values; on a sent document, view the recorded production dimension snapshot.';
                trigger OnAction()
                begin
                    Helper.ShowProductionDimensions(Rec);
                end;
            }
            action(OpenReservoirCard)
            {
                ApplicationArea = All;
                Caption = 'Reservoir Card';
                ToolTip = 'Open the selected Reservoir master and its permitted production items. Field Operator access is read-only.';
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
                Enabled = not IsOpen;
                AccessByPermission = codeunit "Post Daily Production" = X;
                ToolTip = 'Open the standard BC Item Journal for the recorded template and full monthly batch. This is not the Production Dimensions viewer.';
                trigger OnAction()
                begin
                    Helper.OpenItemJournal(Rec);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Posted := false;
        Rec.InitializeOpenDefaults();
        UpdateControlState();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControlState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControlState();
    end;

    var
        Helper: Codeunit "Production Entry Helper";
        IsOpen: Boolean;
        DisplayTemplateName: Code[10];
        DisplayStatus: Text[50];
        ShowPostingDetails: Boolean;

    local procedure UpdateControlState()
    var
        OGSetup: Record "O&G Setup";
        Workflow: Codeunit "Production Entry Workflow";
    begin
        DisplayStatus := Workflow.StatusText(Rec);
        IsOpen := (not Rec.Posted) and (not Rec.Cancelled);
        if IsOpen then begin
            Rec.CalcFields("Calculated BOE");
            Helper.GetSetup(OGSetup);
            DisplayTemplateName := OGSetup."Item Journal Template Name";
        end else
            DisplayTemplateName := Rec."Item Journal Template Name";
    end;
}
