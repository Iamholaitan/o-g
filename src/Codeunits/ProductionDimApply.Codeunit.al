// Called only after the prepared audit/plan checkpoint has been committed.
// Boolean Codeunit.Run is therefore not invoked inside an outstanding write txn.
codeunit 70088 "Production Dim. Apply"
{
    TableNo = "Production Dim. Correction";
    trigger OnRun()
    var
        Mgt: Codeunit "Production Dimension Mgt.";
    begin
        Mgt.ApplyPrepared(Rec."Entry No.");
    end;
}
