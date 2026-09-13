page 70069 "Production Dimension Changes"
{
    PageType = ListPart;
    SourceTable = "Production Dim. Change";
    Caption = 'Audited Dimension Changes';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Changes)
            {
                field(TableID; Rec."Table ID") { ApplicationArea = All; }
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(Description; Rec."Description") { ApplicationArea = All; }
                field(OldDimensionSetID; Rec."Old Dimension Set ID") { ApplicationArea = All; }
                field(NewDimensionSetID; Rec."New Dimension Set ID") { ApplicationArea = All; }
                field(QuantitySnapshot; Rec."Quantity Snapshot") { ApplicationArea = All; }
                field(AmountSnapshot; Rec."Amount Snapshot") { ApplicationArea = All; }
                field(Applied; Rec."Applied") { ApplicationArea = All; }
            }
        }
    }
}
