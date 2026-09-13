// -----------------------------------------------------------------------------
// Reserve Revision Logger (FR-05, FR-32)
// Fires on modification of a Reservoir Master reserve figure (called from the
// table OnModify trigger) and writes a Reserve Revision History record with
// previous value, revised value, date, preparer and estimation basis.
// -----------------------------------------------------------------------------
codeunit 70074 "Reserve Revision Logger"
{
    Permissions = tabledata "Reserve Revision History" = I;

    procedure Log(var Reservoir: Record "Reservoir"; var OldReservoir: Record "Reservoir")
    var
        Revision: Record "Reserve Revision History";
    begin
        Revision.Init();
        Revision."Reservoir Code" := Reservoir."Reservoir Code";
        Revision."Revision Date" := Today();
        Revision."Previous Reserves (BOE)" := OldReservoir."Proved Reserves (1P)";
        Revision."Revised Reserves (BOE)" := Reservoir."Proved Reserves (1P)";
        Revision."Estimation Basis" := Reservoir."Estimation Method";
        Revision."Prepared By" := Reservoir."Estimated By";
        Revision."Estimator User Security ID" := Reservoir."Estimated By User Security ID";
        Revision."Estimation Method Code" := Reservoir."Estimation Method Code";
        Revision."Changed By User Security ID" := UserSecurityId();
        Revision."Changed By" := CopyStr(UserId(), 1, MaxStrLen(Revision."Changed By"));
        Revision."Changed At" := CurrentDateTime();
        Revision.Insert(true);
    end;
}
