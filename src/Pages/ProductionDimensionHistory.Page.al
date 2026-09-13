page 70067 "Production Dimension History"
{
    PageType = List;
    SourceTable = "Production Dim. Correction";
    Caption = 'Production Dimension History';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    CardPageId = "Production Dim. Change Card";
    layout
    {
        area(Content)
        {
            repeater(History)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(DocumentNo; Rec."Document No.") { ApplicationArea = All; }
                field(State; Rec."State") { ApplicationArea = All; }
                field(Reason; Rec."Reason") { ApplicationArea = All; }
                field(CreatedAt; Rec."Created At") { ApplicationArea = All; }
                field(CompletedAt; Rec."Completed At") { ApplicationArea = All; }
                field(OldEntityCode; Rec."Old Entity Code") { ApplicationArea = All; }
                field(NewEntityCode; Rec."New Entity Code") { ApplicationArea = All; }
                field(GLCorrectionEntryNo; Rec."G/L Correction Entry No.") { ApplicationArea = All; }
                field(ErrorText; Rec."Error Text") { ApplicationArea = All; }
            }
        }
    }
}
