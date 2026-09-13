enum 70401 "Production Posting State"
{
    Extensible = false;
    value(0; "Untracked") { Caption = 'Untracked / Legacy'; }
    value(1; "Pending") { Caption = 'Pending Journal Posting'; }
    value(2; "Partial") { Caption = 'Partially Posted'; }
    value(3; "Posted") { Caption = 'Inventory Posted'; }
    value(4; "Cancelled") { Caption = 'Cancelled Before Posting'; }
}
