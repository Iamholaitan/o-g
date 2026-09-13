page 70062 "O&G Entities"
{
    PageType = List;
    SourceTable = "O&G Entity";
    Caption = 'O&G Entities';
    ApplicationArea = All;
    Editable = true;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntityCode; Rec."Entity Code") { ApplicationArea = All; }
                field(Description; Rec."Description") { ApplicationArea = All; }
                field(Type; Rec."Type") { ApplicationArea = All; }
                field(Blocked; Rec."Blocked") { ApplicationArea = All; }
            }
        }
    }
}
