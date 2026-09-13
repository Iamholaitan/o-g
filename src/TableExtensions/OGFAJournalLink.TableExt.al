tableextension 70301 "O&G FA Journal Link" extends "Gen. Journal Line"
{
    fields
    {
        field(73001; "O&G Depletion Entry No."; Integer)
        {
            Caption = 'O&G Depletion Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Depletion Worksheet";
        }
    }
}
