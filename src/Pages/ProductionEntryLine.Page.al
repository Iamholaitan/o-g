// -----------------------------------------------------------------------------
// Production line input. Business validation/calculation is on the table.
// Parent UpdatePropagation=Both refreshes the live header FlowField after edits.
// -----------------------------------------------------------------------------
page 70037 "Production Entry Line"
{
    PageType = ListPart;
    SourceTable = "Production Entry Line";
    Caption = 'Production Lines';
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = DocumentIsOpen;
                field(LineNo; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'An item permitted and unblocked on this Reservoir Product Setup.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(ItemDescription; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Gross reading in the selected unit of measure. Net and BOE quantities are calculated.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(UnitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(BSWPercent; Rec."BS&W %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Basic Sediment & Water percentage. Applied only where configured for this reservoir/item.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(BSWQuantity; LossQuantity)
                {
                    Caption = 'BS&W Quantity';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Gross less net quantity, in this line unit of measure. A separate negative adjustment records this loss.';
                }
                field(NetQuantity; Rec."Net Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(BOEQuantity; Rec."BOE Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(LocationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting location, defaulted from Reservoir Product Setup.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateEditability();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditability();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateEditability();
    end;

    var
        DocumentIsOpen: Boolean;
        LossQuantity: Decimal;

    procedure SaveCurrentLine()
    begin
        if Rec."Item No." <> '' then
            CurrPage.SaveRecord();
    end;

    local procedure UpdateEditability()
    var
        Header: Record "Production Entry Header";
    begin
        LossQuantity := Round(Rec.Quantity - Rec."Net Quantity", 0.001);
        DocumentIsOpen := false;
        if Header.Get(Rec."Document No.") then
            DocumentIsOpen := not Header.Posted;
    end;
}
