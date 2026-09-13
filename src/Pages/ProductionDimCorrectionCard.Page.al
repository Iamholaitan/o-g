page 70068 "Production Dim. Change Card"
{
    PageType = Card;
    SourceTable = "Production Dim. Correction";
    Caption = 'Production Dimension Correction';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(Audit)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(DocumentNo; Rec."Document No.") { ApplicationArea = All; }
                field(State; Rec."State") { ApplicationArea = All; }
                field(Reason; Rec."Reason") { ApplicationArea = All; }
                field(CreatedAt; Rec."Created At") { ApplicationArea = All; }
                field(CreatedBy; Rec."Created By") { ApplicationArea = All; }
                field(LastRunAt; Rec."Last Run At") { ApplicationArea = All; }
                field(LastRunBy; Rec."Last Run By") { ApplicationArea = All; }
                field(CompletedAt; Rec."Completed At") { ApplicationArea = All; }
                field(OldEntityCode; Rec."Old Entity Code") { ApplicationArea = All; }
                field(NewEntityCode; Rec."New Entity Code") { ApplicationArea = All; }
                field(OldFieldCode; Rec."Old Field Code") { ApplicationArea = All; }
                field(NewFieldCode; Rec."New Field Code") { ApplicationArea = All; }
                field(OldWellCode; Rec."Old Well Code") { ApplicationArea = All; }
                field(NewWellCode; Rec."New Well Code") { ApplicationArea = All; }
                field(OldCostCenterCode; Rec."Old Cost Center Code") { ApplicationArea = All; }
                field(NewCostCenterCode; Rec."New Cost Center Code") { ApplicationArea = All; }
                field(GLCorrectionEntryNo; Rec."G/L Correction Entry No.") { ApplicationArea = All; }
                field(GLEntryCount; Rec."G/L Entry Count") { ApplicationArea = All; }
                field(ItemEntryCount; Rec."Item Entry Count") { ApplicationArea = All; }
                field(ValueEntryCount; Rec."Value Entry Count") { ApplicationArea = All; }
                field(JournalLineCount; Rec."Journal Line Count") { ApplicationArea = All; }
                field(ErrorText; Rec."Error Text") { ApplicationArea = All; }
            }
            part(Changes; "Production Dimension Changes")
            {
                ApplicationArea = All;
                SubPageLink = "Correction Entry No." = field("Entry No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ResumeCorrection)
            {
                ApplicationArea = All;
                Caption = 'Resume Correction';
                AccessByPermission = codeunit "Production Dimension Mgt." = X;
                trigger OnAction()
                var
                    Mgt: Codeunit "Production Dimension Mgt.";
                begin
                    if not Confirm('Resume this audited correction after resolving its error? Stop concurrent posting/cost adjustment for the source.', false) then
                        exit;
                    Mgt.RunPrepared(Rec."Entry No.");
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(OpenNativeCorrection)
            {
                ApplicationArea = All;
                Caption = 'G/L Dimension Correction';
                AccessByPermission = codeunit "Production Dimension Mgt." = X;
                trigger OnAction()
                var
                    Native: Record "Dimension Correction";
                begin
                    Rec.TestField("G/L Correction Entry No.");
                    Native.Get(Rec."G/L Correction Entry No.");
                    if Native.Completed then
                        Page.Run(Page::"Dimension Correction", Native)
                    else
                        Page.Run(Page::"Dimension Correction Draft", Native);
                end;
            }
            action(CancelUnfinished)
            {
                ApplicationArea = All;
                Caption = 'Cancel Unfinished Request';
                AccessByPermission = codeunit "Production Dimension Mgt." = X;
                trigger OnAction()
                var
                    Mgt: Codeunit "Production Dimension Mgt.";
                begin
                    if not Confirm('Cancel this request only if no source/inventory changes occurred and any native G/L changes have been undone?', false) then
                        exit;
                    Mgt.CancelUnfinished(Rec."Entry No.");
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
