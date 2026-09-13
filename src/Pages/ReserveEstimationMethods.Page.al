page 70056 "Reserve Estimation Methods"
{
    PageType = List;
    SourceTable = "Reserve Estimation Method";
    Caption = 'Reserve Estimation Methods';
    ApplicationArea = All;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Methods)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Enter your own unique code for this reserve-estimation method.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Name or description of the method, for example a client-defined volumetric, decline-curve or simulation method. No list is hardcoded.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Prevent new selections without removing the method or changing historical descriptions.';
                }
            }
        }
    }
}
