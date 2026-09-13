enum 70403 "Prod. Dim. Correction State"
{
    Extensible = false;
    value(0; Prepared) { Caption = 'Prepared'; }
    value(1; "G/L Correction") { Caption = 'Correcting G/L'; }
    value(2; "Applying Source") { Caption = 'Correcting Source and Inventory'; }
    value(3; Completed) { Caption = 'Completed'; }
    value(4; Failed) { Caption = 'Needs Review / Resume'; }
    value(5; Cancelled) { Caption = 'Cancelled Before Changes'; }
}
