// Selection only: no user-account administration actions or writes.
page 70057 "Reserve Estimator Users"
{
    PageType = List;
    SourceTable = User;
    SourceTableView = where(State = const(Enabled));
    Caption = 'Select Estimate Preparer';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(EnabledUsers)
            {
                field(UserName; Rec."User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Business Central account to record as the estimate preparer.';
                }
                field(FullName; Rec."Full Name")
                {
                    ApplicationArea = All;
                }
                field(State; Rec.State)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
