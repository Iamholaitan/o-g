// Keep the native FA G/L page and its accounting logic; expose core controls
// under the O&G profile's application-area settings, as for the Item Journal.
pageextension 70303 "O&G FA Journal Columns" extends "Fixed Asset G/L Journal"
{
    layout
    {
        modify(CurrentJnlBatchName)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Posting Date")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Document No.")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Account Type")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Account No.")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Depreciation Book Code")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("FA Posting Type")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("FA Posting Date")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify(Description)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify(Amount)
        {
            ApplicationArea = All;
            Visible = true;
        }
    }
}
