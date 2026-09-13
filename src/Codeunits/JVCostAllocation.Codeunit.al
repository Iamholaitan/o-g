// Entity is the activity/cost bucket. JV Partner remains the actual party.
// Explicit effective-dated interests total 100%; management fees are not equity.
codeunit 70076 "JV Cost Allocation"
{
    var
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        JnlHelper: Codeunit "Journal Helper";

    procedure Post(var JVHeader: Record "JV Cost Allocation Header")
    var
        Line: Record "JV Cost Allocation Line";
        Partner: Record "JV Partner";
        Member: Record "JV Ownership Partner";
        Ownership: Record "JV Ownership";
        OwnershipMgt: Codeunit "JV Ownership Mgt.";
        Setup: Record "O&G Setup";
        GLSetup: Record "General Ledger Setup";
        Journal: Record "Gen. Journal Line";
        Batch: Code[10];
        ReceivableAccount: Code[20];
        DimID: Integer;
        OperatorDimID: Integer;
        LineNo: Integer;
        Position: Integer;
        Members: Integer;
        OperatorAmount: Decimal;
        PartnerTarget: Decimal;
        Allocated: Decimal;
        Share: Decimal;
        Total: Decimal;
    begin
        JVHeader.LockTable();
        JVHeader.Get(JVHeader."Document No.");
        JVHeader.TestField(Posted, false);
        JVHeader.TestField("Posting Date");
        OwnershipMgt.GetForDate(JVHeader."Entity Code", JVHeader."Posting Date", Ownership);
        Helper.GetSetup(Setup);
        GLSetup.Get();
        Line.SetRange("Document No.", JVHeader."Document No.");
        if not Line.FindSet() then
            Error('The JV allocation has no cost lines.');
        Member.SetRange("Entity Code", Ownership."Entity Code");
        Member.SetRange("Starting Date", Ownership."Starting Date");
        Member.SetFilter("Working Interest %", '>0');
        Members := Member.Count();
        Batch := JnlHelper.MakeBatchName('JV', JVHeader."Posting Date");
        JnlHelper.EnsureGenJournalBatch(Batch, Setup."Gen. Journal Template Name");
        Journal.LockTable();
        repeat
            Line.TestField("G/L Account No.");
            Total += Line.Amount;
            OperatorAmount := Round(Line.Amount * Ownership."Operator Interest %" / 100, GLSetup."Amount Rounding Precision");
            PartnerTarget := Line.Amount - OperatorAmount;
            Allocated := 0;
            Position := 0;
            if Member.FindSet() then
                repeat
                    Position += 1;
                    // Allocate rounding to the last configured partner, never to
                    // an assumed operator interest or management-fee account.
                    if Position = Members then
                        Share := PartnerTarget - Allocated
                    else
                        Share := Round(Line.Amount * Member."Working Interest %" / 100, GLSetup."Amount Rounding Precision");
                    Allocated += Share;
                    if Share <> 0 then begin
                        Partner.Get(Member."Partner Code");
                        ReceivableAccount := Partner."JV Receivable Account";
                        if ReceivableAccount = '' then
                            ReceivableAccount := Setup."JV Receivable Account";
                        DimID := DimHelper.GetDimensionSetID(Setup, JVHeader."Field/Block Code", '', '', '', Partner."Partner Code", JVHeader."Entity Code");
                        LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                        JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, JVHeader."Posting Date", JVHeader."Document No.", ReceivableAccount, Share, 0, 'JV share ' + Partner."Partner Code", DimID);
                        LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                        JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, JVHeader."Posting Date", JVHeader."Document No.", Line."G/L Account No.", 0, Share, 'JV share ' + Partner."Partner Code", DimID);
                    end;
                until Member.Next() = 0;
            if Abs(PartnerTarget - Allocated) > GLSetup."Amount Rounding Precision" / 2 then
                Error('Partner allocation did not reconcile. Check the ownership setup.');
            if OperatorAmount <> 0 then begin
                // Future equity participation only. At today's 0% this creates
                // NO operator cost entry. Management fee revenue is separate.
                DimID := DimHelper.GetDimensionSetID(Setup, JVHeader."Field/Block Code", '', '', '', '', JVHeader."Entity Code");
                OperatorDimID := DimHelper.GetDimensionSetID(Setup, JVHeader."Field/Block Code", '', '', '', '', Ownership."Operator Cost Entity");
                LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, JVHeader."Posting Date", JVHeader."Document No.", Line."G/L Account No.", 0, OperatorAmount, 'Operator equity cost reclass', DimID);
                LineNo := JnlHelper.NextGenJnlLineNo(Setup."Gen. Journal Template Name", Batch);
                JnlHelper.CreateGenJournalLine(Setup."Gen. Journal Template Name", Batch, LineNo, JVHeader."Posting Date", JVHeader."Document No.", Line."G/L Account No.", OperatorAmount, 0, 'Operator equity cost reclass', OperatorDimID);
            end;
        until Line.Next() = 0;
        JVHeader."Total Amount" := Total;
        JVHeader."Ownership Starting Date" := Ownership."Starting Date";
        JVHeader."Operator Interest %" := Ownership."Operator Interest %";
        JVHeader."Operator Cost Entity" := Ownership."Operator Cost Entity";
        JVHeader."Journal Batch Name" := Batch;
        JVHeader.Posted := true;
        JVHeader.Modify(true);
        Message('Allocation sent to %1 / %2 using ownership effective %3. Operator equity is %4%; management fees are not allocated as an ownership share. The accountant must post the journal separately.', Setup."Gen. Journal Template Name", Batch, Ownership."Starting Date", Ownership."Operator Interest %");
    end;

    procedure NextCostLineNo(DocumentNo: Code[20]): Integer
    var
        Line: Record "JV Cost Allocation Line";
    begin
        Line.SetRange("Document No.", DocumentNo);
        if Line.FindLast() then
            exit(Line."Line No." + 10000);
        exit(10000);
    end;
}
