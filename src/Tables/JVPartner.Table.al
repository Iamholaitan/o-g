// -----------------------------------------------------------------------------
// JV Partner (FR-27)
// Joint venture partner master with working interest share.
// -----------------------------------------------------------------------------
table 70009 "JV Partner"
{
    Caption = 'JV Partner';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Partner Code"; Code[20])
        {
            Caption = 'Partner Code';
            DataClassification = ToBeClassified;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = ToBeClassified;
        }
        field(3; "Working Interest %"; Decimal)
        {
            Caption = 'Working Interest %';
            DataClassification = ToBeClassified;
            Description = 'Partner working interest share of joint costs (FR-27). The operator retains the remainder.';
        }
        field(4; "JV Receivable Account"; Code[20])
        {
            Caption = 'JV Receivable Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account";
            Description = 'Overrides the O&G Setup default JV receivable account for this partner (FR-27).';
        }
    }

    keys
    {
        key(PrimaryKey; "Partner Code")
        {
            Clustered = true;
        }
    }
}
