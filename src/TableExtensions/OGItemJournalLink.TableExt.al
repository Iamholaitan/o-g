tableextension 70300 "O&G Item Journal Link" extends "Item Journal Line"
{
    fields
    {
        field(73000; "O&G Production Link No."; Integer)
        {
            Caption = 'O&G Production Link No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Posting Link";
        }
    }
}
