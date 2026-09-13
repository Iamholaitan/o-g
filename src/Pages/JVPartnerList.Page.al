// -----------------------------------------------------------------------------
// JV Partner List (FR-27)
// -----------------------------------------------------------------------------
page 70042 "JV Partner List"
{
    PageType = List;
    SourceTable = "JV Partner";
    Caption = 'JV Partners';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
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
                }
                field(JVReceivableAccount; Rec."JV Receivable Account")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
