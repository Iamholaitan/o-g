// Restore the native Item Journal controls; no replacement journal or custom
// journal table. All standard validation and posting actions remain native.
// ApplicationArea=All keeps the core fields visible under the O&G profiles even
// when Basic/Suite visibility differs from the standard accountant profile.
pageextension 70058 "O&G Item Journal Columns" extends "Item Journal"
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
        modify(EntryType)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Document No.")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Item No.")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify(Description)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Location Code")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify(Quantity)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Unit of Measure Code")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Unit Amount")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify(Amount)
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Gen. Bus. Posting Group")
        {
            ApplicationArea = All;
            Visible = true;
        }
        modify("Gen. Prod. Posting Group")
        {
            ApplicationArea = All;
            Visible = true;
        }
        // Keep the standard proxy EntryType field, not two Entry Type columns.
        modify("Entry Type")
        {
            Visible = false;
        }
        addafter("Unit Amount")
        {
            field(OGUnitCost; Rec."Unit Cost")
            {
                Caption = 'Unit Cost';
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Standard BC item journal unit cost. Costing and posting remain controlled by BC item and posting setup.';
            }
        }
    }

    actions
    {
        modify(Post)
        {
            ApplicationArea = All;
        }
        modify(PreviewPosting)
        {
            ApplicationArea = All;
        }
        modify("Test Report")
        {
            ApplicationArea = All;
        }
    }
}
