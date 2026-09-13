// -----------------------------------------------------------------------------
// JV Partner Card (FR-27)
// -----------------------------------------------------------------------------
page 70043 "JV Partner Card"
{
    PageType = Card;
    SourceTable = "JV Partner";
    Caption = 'JV Partner Card';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(PartnerCode; Rec."Partner Code")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(WorkingInterest; Rec."Working Interest %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Partner working interest share of joint costs. The operator retains the remainder (FR-27).';
                }
                field(JVReceivableAccount; Rec."JV Receivable Account")
                {
                    ApplicationArea = All;
                    ToolTip = 'Overrides the O&G Setup default JV receivable account for this partner.';
                }
            }
        }
    }
}
