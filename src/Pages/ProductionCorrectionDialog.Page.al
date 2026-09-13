page 70059 "Production Correction Dialog"
{
    PageType = StandardDialog;
    Caption = 'Production Correction';
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(Details)
            {
                field(SourceDocument; SourceDocument) { ApplicationArea = All; Caption = 'Source Document'; Editable = false; }
                field(CorrectionDate; CorrectionDate) { ApplicationArea = All; Caption = 'Correction Posting Date'; }
                field(Reason; Reason) { ApplicationArea = All; Caption = 'Reason'; MultiLine = true; ShowMandatory = true; }
                field(Notice; NoticeLbl) { ApplicationArea = All; Caption = 'Important'; Editable = false; MultiLine = true; }
            }
        }
    }
    var
        SourceDocument: Code[20];
        CorrectionDate: Date;
        Reason: Text[250];
        NoticeLbl: Label 'The original stays read-only. Pending source lines are cancelled without inventory posting. Posted production creates a separate reversal journal for accountant review/posting. Royalty, depletion, JV and management-fee accounting are NOT silently reversed.';
    procedure SetSource(DocumentNo: Code[20])
    begin
        SourceDocument := DocumentNo;
        CorrectionDate := WorkDate();
    end;
    procedure GetValues(var PostingDate: Date; var ReasonText: Text[250])
    begin
        if CorrectionDate = 0D then
            Error('A correction date is required.');
        if Reason = '' then
            Error('A correction reason is required.');
        PostingDate := CorrectionDate;
        ReasonText := Reason;
    end;
}
