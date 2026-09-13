page 70065 "JV Ownership Partners"
{
    PageType = ListPart;
    SourceTable = "JV Ownership Partner";
    Caption = 'JV Ownership Partners';
    ApplicationArea = All;
    Editable = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(PartnerCode; Rec."Partner Code") { ApplicationArea = All; }
                field(WorkingInterest; Rec."Working Interest %") { ApplicationArea = All; }
            }
        }
    }
}
