codeunit 70086 "JV Ownership Mgt."
{
    procedure GetForDate(EntityCode: Code[20]; PostingDate: Date; var Ownership: Record "JV Ownership")
    var
        Entity: Record "O&G Entity";
        EntityMgt: Codeunit "O&G Entity Mgt.";
    begin
        EntityMgt.ValidateEntity(EntityCode);
        Entity.Get(EntityCode);
        Entity.TestField(Type, Entity.Type::"Joint Operation");
        Ownership.Reset();
        Ownership.SetRange("Entity Code", EntityCode);
        Ownership.SetFilter("Starting Date", '..%1', PostingDate);
        if not Ownership.FindLast() then
            Error('Define a JV Ownership version for Entity %1 starting on or before %2.', EntityCode, PostingDate);
        ValidateOwnership(Ownership);
    end;

    procedure ValidateOwnership(Ownership: Record "JV Ownership")
    var
        Member: Record "JV Ownership Partner";
        Partner: Record "JV Partner";
        OperatorEntity: Record "O&G Entity";
        Total: Decimal;
    begin
        Total := Ownership."Operator Interest %";
        Member.SetRange("Entity Code", Ownership."Entity Code");
        Member.SetRange("Starting Date", Ownership."Starting Date");
        if Member.FindSet() then
            repeat
                Partner.Get(Member."Partner Code");
                if (Member."Working Interest %" < 0) or (Member."Working Interest %" > 100) then
                    Error('Partner %1 has an invalid working interest.', Member."Partner Code");
                Total += Member."Working Interest %";
            until Member.Next() = 0;
        if Abs(Total - 100) > 0.00001 then
            Error('JV ownership must total 100%. Current total is %1% including explicit operator ownership %2%. An unexplained remainder is NOT an operator share or management fee.', Total, Ownership."Operator Interest %");
        if Ownership."Operator Interest %" > 0 then begin
            Ownership.TestField("Operator Cost Entity");
            OperatorEntity.Get(Ownership."Operator Cost Entity");
            OperatorEntity.TestField(Type, OperatorEntity.Type::Operator);
            OperatorEntity.TestField(Blocked, false);
        end;
    end;

    procedure LoadPartnerDefaults(Ownership: Record "JV Ownership")
    var
        Partner: Record "JV Partner";
        Member: Record "JV Ownership Partner";
    begin
        Ownership.CheckUnused();
        if Partner.FindSet() then
            repeat
                if not Member.Get(Ownership."Entity Code", Ownership."Starting Date", Partner."Partner Code") then begin
                    Member.Init();
                    Member."Entity Code" := Ownership."Entity Code";
                    Member."Starting Date" := Ownership."Starting Date";
                    Member."Partner Code" := Partner."Partner Code";
                    Member."Working Interest %" := Partner."Working Interest %";
                    Member.Insert(true);
                end;
            until Partner.Next() = 0;
    end;
}
