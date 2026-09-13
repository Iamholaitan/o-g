// -----------------------------------------------------------------------------
// O&G Setup (FR-01, FR-09)
// Single-record setup table for the O&G extension. All posting accounts,
// dimension codes and the accounting method are client-configurable here -
// nothing is hardcoded in the extension.
// -----------------------------------------------------------------------------
table 70000 "O&G Setup"
{
    Caption = 'O&G Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Default Royalty Rate %"; Decimal)
        {
            Caption = 'Default Royalty Rate %';
            DataClassification = ToBeClassified;
            Description = 'Default government/landowner royalty percentage, overridable per field (FR-01, FR-25).';
        }
        field(3; "Production Tax Rate %"; Decimal)
        {
            Caption = 'Production Tax Rate %';
            DataClassification = ToBeClassified;
            Description = 'Default production/petroleum profit tax rate (FR-01).';
        }
        field(4; "Default BOE UOM Code"; Code[10])
        {
            Caption = 'Default BOE UOM Code';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
            Description = 'The UOM code (e.g. BOE) that all produced items alternate UOM conversions target (FR-01, FR-02).';
        }
        field(5; "Accounting Method"; Option)
        {
            Caption = 'Accounting Method';
            DataClassification = ToBeClassified;
            OptionMembers = "Successful Efforts","Full Cost";
            Description = 'Elected policy: Successful Efforts or Full Cost (FR-09, FR-24).';
        }
        field(6; "Field/Block Dimension Code"; Code[20])
        {
            Caption = 'Field/Block Dimension Code';
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Description = 'Dimension code used for the Field/Block dimension (FR-07).';
        }
        field(7; "Well Dimension Code"; Code[20])
        {
            Caption = 'Well Dimension Code';
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Description = 'Dimension code used for the Well dimension (FR-07).';
        }
        field(8; "Reservoir Dimension Code"; Code[20])
        {
            Caption = 'Reservoir Dimension Code';
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Description = 'Dimension code used for the Reservoir dimension (FR-07).';
        }
        field(9; "Cost Center Dimension Code"; Code[20])
        {
            Caption = 'Cost Center Dimension Code';
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Description = 'Dimension code used for the Cost Center dimension (FR-07, FR-31).';
        }
        field(10; "JV Partner Dimension Code"; Code[20])
        {
            Caption = 'JV Partner Dimension Code';
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            Description = 'Dimension code used for the JV Partner dimension (FR-07, FR-27).';
        }
        field(11; "Depletion Expense Account"; Code[20])
        {
            Caption = 'Depletion Expense Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'G/L account debited on depletion posting (FR-22, Appendix A).';
        }
        field(12; "Royalty Expense Account"; Code[20])
        {
            Caption = 'Royalty Expense Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Default G/L account debited on royalty posting (FR-26, Appendix A).';
        }
        field(13; "Royalty Payable Account"; Code[20])
        {
            Caption = 'Royalty Payable Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Default G/L account credited for cash-settled royalty (FR-26, Appendix A).';
        }
        field(14; "JV Receivable Account"; Code[20])
        {
            Caption = 'JV Receivable Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Default G/L account debited for partner cost shares (FR-27, Appendix A).';
        }
        field(15; "Exploration Expense Account"; Code[20])
        {
            Caption = 'Exploration Expense Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'G/L account debited on Successful Efforts dry-hole write-off (FR-24, Appendix A).';
        }
        field(16; "Exploration Costs Account"; Code[20])
        {
            Caption = 'Exploration Costs Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Capitalised exploration cost account credited on write-off (FR-24, Appendix A).';
        }
        field(17; "Accumulated Depletion Account"; Code[20])
        {
            Caption = 'Accumulated Depletion Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'G/L account credited (contra-asset) on depletion posting (FR-22, Appendix A).';
        }
        field(18; "Gen. Journal Template Name"; Code[10])
        {
            Caption = 'Gen. Journal Template Name';
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
            Description = 'Journal template used for depletion, royalty, JV and write-off journal lines. Select the template in O&G Setup - nothing is hardcoded.';
        }
        field(19; "Item Journal Template Name"; Code[10])
        {
            Caption = 'Item Journal Template Name';
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Template";
            Description = 'Item Journal template used for production and in-kind royalty posting. Create the template in Business Central (Item Journal Templates) and select it here - nothing is hardcoded.';
        }
        field(20; "BS&W Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'BS&W Gen. Bus. Posting Group';
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Business Posting Group";
            Description = 'Used on production BS&W negative adjustments. General Posting Setup for this business group/product group supplies the Inventory Adjmt. Account for loss expense.';
        }
        field(21; "Production Nos."; Code[20])
        {
            Caption = 'Production Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            Description = 'Automatic numbers for production and reversal documents. Create the series in standard BC; enable Default Nos.';
        }
        field(22; "Royalty Gen. Bus. Post. Group"; Code[20])
        {
            Caption = 'Royalty Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";
            Description = 'In-kind royalty adjustment business group. Configure its Inventory Adjmt. Account as the royalty expense account for each product group.';
        }
        field(23; "FA G/L Journal Template"; Code[10])
        {
            Caption = 'FA G/L Journal Template';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Template".Name where(Type = const(Assets), Recurring = const(false));
            trigger OnValidate()
            var
                Mgt: Codeunit "FA Depletion Posting";
            begin
                if Rec."FA G/L Journal Template" <> '' then
                    Mgt.ValidateTemplate(Rec."FA G/L Journal Template");
            end;
        }
    }

    keys
    {
        key(PrimaryKey; "Primary Key")
        {
            Clustered = true;
        }
    }
}
