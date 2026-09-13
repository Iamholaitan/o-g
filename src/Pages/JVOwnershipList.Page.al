page 70063 "JV Ownership List"
{
    PageType = List;
    SourceTable = "JV Ownership";
    Caption = 'JV Ownership List';
    ApplicationArea = All;
    Editable = false;
    UsageCategory = Administration;
    CardPageId = "JV Ownership Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntityCode; Rec."Entity Code") { ApplicationArea = All; }
                field(StartingDate; Rec."Starting Date") { ApplicationArea = All; }
                field(Description; Rec."Description") { ApplicationArea = All; }
                field(OperatorInterest; Rec."Operator Interest %") { ApplicationArea = All; }
                field(OperatorCostEntity; Rec."Operator Cost Entity") { ApplicationArea = All; }
            }
        }
    }
}
