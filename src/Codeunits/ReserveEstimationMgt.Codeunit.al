// Links the preparer to an enabled BC user while preserving the stored name
// for audit history. Never inserts, modifies or deletes a User/Employee record.
codeunit 70082 "Reserve Estimation Mgt."
{
    procedure LookupEstimatedBy(var Reservoir: Record Reservoir)
    var
        Estimator: Record User;
        CurrentEstimator: Record User;
        EstimatorUsers: Page "Reserve Estimator Users";
    begin
        Estimator.SetRange(State, Estimator.State::Enabled);
        EstimatorUsers.SetTableView(Estimator);
        if not IsNullGuid(Reservoir."Estimated By User Security ID") then
            if CurrentEstimator.Get(Reservoir."Estimated By User Security ID") then
                if CurrentEstimator.State = CurrentEstimator.State::Enabled then
                    EstimatorUsers.SetRecord(CurrentEstimator);
        EstimatorUsers.LookupMode(true);
        if EstimatorUsers.RunModal() <> Action::LookupOK then
            exit;
        EstimatorUsers.GetRecord(Estimator);
        Reservoir.Validate("Estimated By", Estimator."User Name");
    end;

    procedure ValidateEstimatedBy(var Reservoir: Record Reservoir)
    var
        Estimator: Record User;
    begin
        if Reservoir."Estimated By" = '' then begin
            Clear(Reservoir."Estimated By User Security ID");
            exit;
        end;
        Estimator.SetRange("User Name", Reservoir."Estimated By");
        Estimator.SetRange(State, Estimator.State::Enabled);
        if not Estimator.FindFirst() then
            Error('Select an enabled Business Central user for Estimated By. User %1 was not found or is disabled. Existing historical preparer names are not changed automatically.', Reservoir."Estimated By");
        Reservoir."Estimated By" := CopyStr(Estimator."User Name", 1, MaxStrLen(Reservoir."Estimated By"));
        Reservoir."Estimated By User Security ID" := Estimator."User Security ID";
    end;

    procedure DefaultCurrentEstimator(var Reservoir: Record Reservoir)
    var
        Estimator: Record User;
    begin
        if Reservoir."Estimated By" <> '' then
            exit;
        if Estimator.Get(UserSecurityId()) then
            if Estimator.State = Estimator.State::Enabled then
                Reservoir.Validate("Estimated By", Estimator."User Name");
    end;
}
