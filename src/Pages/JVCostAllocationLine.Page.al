// -----------------------------------------------------------------------------
// JV Cost Allocation Line (FR-27)
// Subpage: cost lines (G/L expense accounts) to allocate to JV partners.
// -----------------------------------------------------------------------------
page 70046 "JV Cost Allocation Line"
{
    PageType = ListPart;
    SourceTable = "JV Cost Allocation Line";
    Caption = 'Cost Lines';
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(LineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(GLAccountNo; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Lifting/operating cost account to be shared with partners (FR-27).';
                    trigger OnValidate()
                    var
                        GLAccount: Record "G/L Account";
                    begin
                        Rec."Account Name" := '';
                        if Rec."G/L Account No." <> '' then
                            if GLAccount.Get(Rec."G/L Account No.") then
                                Rec."Account Name" := GLAccount.Name;
                    end;
                }
                field(AccountName; Rec."Account Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Allocator: Codeunit "JV Cost Allocation";
    begin
        if Rec."Document No." <> '' then
            Rec."Line No." := Allocator.NextCostLineNo(Rec."Document No.")
        else
            Rec."Line No." := 0;
    end;
}
