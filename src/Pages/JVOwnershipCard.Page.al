page 70064 "JV Ownership Card"
{
    PageType = Card;
    SourceTable = "JV Ownership";
    Caption = 'JV Ownership';
    ApplicationArea = All;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Entity; Rec."Entity Code") { ApplicationArea = All; }
                field(StartingDate; Rec."Starting Date") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(OperatorInterest; Rec."Operator Interest %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Explicit equity/working interest only. Currently zero when the operator earns only a management fee. A fee is NOT an ownership share.';
                }
                field(OperatorCostEntity; Rec."Operator Cost Entity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Required if the operator acquires an ownership interest: retained cost is reclassified to this Operator Entity. No reclassification occurs at zero interest.';
                }
            }
            part(Partners; "JV Ownership Partners")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Code" = field("Entity Code"), "Starting Date" = field("Starting Date");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(LoadPartners)
            {
                ApplicationArea = All;
                Caption = 'Load Existing JV Partners';
                ToolTip = 'Reuse the existing partner master and copy its default percentages. Review the actual interests; the total including operator ownership must be exactly 100%.';
                trigger OnAction()
                var
                    Mgt: Codeunit "JV Ownership Mgt.";
                begin
                    CurrPage.SaveRecord();
                    Mgt.LoadPartnerDefaults(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CheckOwnership)
            {
                ApplicationArea = All;
                Caption = 'Check Total Ownership';
                trigger OnAction()
                var
                    Mgt: Codeunit "JV Ownership Mgt.";
                begin
                    CurrPage.SaveRecord();
                    Mgt.ValidateOwnership(Rec);
                    Message('Ownership totals 100%. Management fees are accounted for separately.');
                end;
            }
        }
    }
}
