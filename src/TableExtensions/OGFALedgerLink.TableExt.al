tableextension 70302 "O&G FA Ledger Link" extends "FA Ledger Entry"
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
