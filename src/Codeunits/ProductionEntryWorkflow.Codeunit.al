// Small user-facing workflow facade. Legacy evidence is verified inside the
// requested operation, not exposed as a compulsory separate bookkeeping step.
codeunit 70089 "Production Entry Workflow"
{
    var
        Tracking: Codeunit "Production Posting Tracking";
        ReversalMgt: Codeunit "Production Reversal Mgt.";

    procedure PrepareEvidence(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary; var LinkLegacy: Boolean): Boolean
    var
        Header: Record "Production Entry Header";
        Entry: Record "Item Ledger Entry";
        Journal: Record "Item Journal Line";
        Review: Page "Production Ledger Review";
        PeriodHelper: Page "Date Range";
        Result: Action;
        MatchError: Text;
    begin
        LinkLegacy := false;
        Selected.Reset();
        Selected.DeleteAll(false);
        Header.Get(DocumentNo);
        if not Header.Posted then
            exit(true);
        if Tracking.StateForDocument(DocumentNo) <> "Production Posting State"::Untracked then
            exit(true);
        Entry.SetRange("Document No.", DocumentNo);
        Entry.SetFilter("Entry Type", '%1|%2', Entry."Entry Type"::"Positive Adjmt.", Entry."Entry Type"::"Negative Adjmt.");
        Journal.SetRange("Journal Template Name", Header."Item Journal Template Name");
        Journal.SetRange("Journal Batch Name", Header."Item Journal Batch Name");
        Journal.SetRange("Document No.", DocumentNo);
        if Entry.IsEmpty() then begin
            if Journal.IsEmpty() then
                Error('No related pending journal or posted inventory was found for %1. Missing journal rows are not proof of posting. Review the original document reference before correction.', DocumentNo);
            exit(true); // pending rows will be exactly matched under the write lock
        end;
        if not Journal.IsEmpty() then
            Error('Older document %1 has both pending and posted rows without a complete source link. Review this partial posting before a full-document operation; unrelated rows will not be guessed.', DocumentNo);
        if Entry.FindSet() then
            repeat
                Selected := Entry;
                Selected.Insert(false);
            until Entry.Next() = 0;
        if not ReversalMgt.TryCheckLegacySelection(DocumentNo, Selected) then begin
            MatchError := GetLastErrorText();
            ClearLastError();
            Message('The related posting for %1 needs your selection because the automatic match is not unambiguous. Select the COMPLETE correct entries in the next window. Details: %2', DocumentNo, MatchError);
            Review.LoadCandidates(DocumentNo);
            Review.LookupMode(true);
            Result := Review.RunModal();
            if not PeriodHelper.IsConfirmed(Result) then
                exit(false);
            Review.GetSelection(Selected);
            if not ReversalMgt.TryCheckLegacySelection(DocumentNo, Selected) then
                Error('The selected posting does not match production %1: %2', DocumentNo, GetLastErrorText());
        end;
        LinkLegacy := true;
        exit(true);
    end;

    procedure EnsureEvidence(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary; LinkLegacy: Boolean)
    begin
        if Tracking.StateForDocument(DocumentNo) <> "Production Posting State"::Untracked then
            exit;
        if LinkLegacy then
            ReversalMgt.LinkLegacyLedger(DocumentNo, Selected, false)
        else
            ReversalMgt.EnsurePendingLinks(DocumentNo);
    end;

    procedure Reverse(DocumentNo: Code[20]; CorrectionDate: Date; Reason: Text[250]; var Selected: Record "Item Ledger Entry" temporary; LinkLegacy: Boolean): Code[20]
    var
        Corrections: Codeunit "Production Dimension Mgt.";
        State: Enum "Production Posting State";
    begin
        Corrections.CheckNoActiveCorrection(DocumentNo);
        EnsureEvidence(DocumentNo, Selected, LinkLegacy);
        State := Tracking.StateForDocument(DocumentNo);
        case State of
            State::Pending:
                begin
                    ReversalMgt.CancelPending(DocumentNo, Reason);
                    exit('');
                end;
            State::Posted:
                exit(ReversalMgt.ReversePosted(DocumentNo, CorrectionDate, Reason));
            else
                Error('Production %1 is not a complete pending or posted document. Complete/reconcile partial posting before reversal.', DocumentNo);
        end;
    end;

    procedure StatusText(Header: Record "Production Entry Header"): Text[50]
    var
        Reversal: Record "Production Entry Header";
        Correction: Record "Production Dim. Correction";
    begin
        Correction.SetRange("Document No.", Header."Document No.");
        Correction.SetFilter(State, '<>%1&<>%2', Correction.State::Completed, Correction.State::Cancelled);
        if Correction.FindLast() then begin
            if Correction.State = Correction.State::Failed then
                exit('Needs dimension review');
            exit('Correcting dimensions');
        end;
        if Header.Cancelled then
            exit('Cancelled');
        if Header."Reversed By Document No." <> '' then
            if Reversal.Get(Header."Reversed By Document No.") then
                if not Reversal.Cancelled then begin
                    if Reversal."Inventory Posting State" = Reversal."Inventory Posting State"::Posted then
                        exit('Reversed');
                    exit('Reversal ready to post');
                end;
        if not Header.Posted then
            exit('Open');
        case Header."Inventory Posting State" of
            Header."Inventory Posting State"::Posted:
                if Header."Record Kind" = Header."Record Kind"::Reversal then
                    exit('Reversal posted')
                else
                    exit('Posted to inventory');
            Header."Inventory Posting State"::Partial:
                exit('Partly posted - review');
            else
                if Header."Record Kind" = Header."Record Kind"::Reversal then
                    exit('Reversal ready to post')
                else
                    exit('Sent to journal');
        end;
    end;
}
