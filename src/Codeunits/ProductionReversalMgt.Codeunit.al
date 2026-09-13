// Full-document corrections. Never deletes ledger entries or unlocks the source.
// Posted reversals are generated journals, not silently posted transactions.
codeunit 70085 "Production Reversal Mgt."
{
    Permissions = tabledata "Production Posting Link" = RIMD,
                  tabledata "Production Ledger Link" = RIMD,
                  tabledata "Production Entry Header" = RIMD,
                  tabledata "Production Entry Line" = RIMD;

    var
        Tracking: Codeunit "Production Posting Tracking";
        Helper: Codeunit "Production Entry Helper";
        JnlHelper: Codeunit "Journal Helper";

    procedure CancelPending(DocumentNo: Code[20]; Reason: Text[250])
    var
        Header: Record "Production Entry Header";
        Original: Record "Production Entry Header";
        Link: Record "Production Posting Link";
        JournalLine: Record "Item Journal Line";
        Ledger: Record "Production Ledger Link";
    begin
        if Reason = '' then
            Error('A cancellation reason is required.');
        Header.LockTable();
        Header.Get(DocumentNo);
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        if Header."Reversed By Document No." <> '' then
            Error('This source already has a reversal. Work with reversal document %1.', Header."Reversed By Document No.");
        if Tracking.StateForDocument(DocumentNo) = "Production Posting State"::Untracked then begin
            AdoptPending(Header);
            Header.Get(DocumentNo);
        end;
        if Tracking.StateForDocument(DocumentNo) <> "Production Posting State"::Pending then
            Error('Only a fully unposted document can be cancelled. This source is partially or fully inventory-posted; do not delete its remaining journal rows.');
        Ledger.SetRange("Document No.", DocumentNo);
        if not Ledger.IsEmpty() then
            Error('Ledger entries already exist for this source. Use the posted-reversal workflow.');
        Link.LockTable();
        JournalLine.LockTable();
        Link.SetRange("Document No.", DocumentNo);
        if Link.FindSet(true) then
            repeat
                JournalLine.Get(Link."Journal Template Name", Link."Journal Batch Name", Link."Journal Line No.");
                JournalLine.TestField("O&G Production Link No.", Link."Entry No.");
                Tracking.ValidateMovement(JournalLine, Link);
                Link."Posting Date" := JournalLine."Posting Date";
                Link."Dimension Set ID" := JournalLine."Dimension Set ID";
                Link."Gen. Bus. Posting Group" := JournalLine."Gen. Bus. Posting Group";
                Link."Gen. Prod. Posting Group" := JournalLine."Gen. Prod. Posting Group";
                Link."Inventory Posting Group" := JournalLine."Inventory Posting Group";
                Link."Unit Amount" := JournalLine."Unit Amount";
                Link."Unit Cost" := JournalLine."Unit Cost";
                Link.State := Link.State::Cancelled;
                Link.Modify();
                JournalLine.Delete(true);
            until Link.Next() = 0;
        Header.Cancelled := true;
        Header."Cancellation Reason" := Reason;
        Header."Cancelled At" := CurrentDateTime();
        Header."Cancelled By" := UserSecurityId();
        Header."Inventory Posting State" := Header."Inventory Posting State"::Cancelled;
        Header.Modify(false);
        if Header."Record Kind" = Header."Record Kind"::Reversal then begin
            Original.Get(Header."Reverses Document No.");
            Original."Reversed By Document No." := '';
            Original.Modify(false);
        end;
        RefreshReserves(Header."Reservoir Code");
        Message('Production %1 is cancelled. Only its verified pending journal rows were removed; the source remains read-only. Re-run any unposted financial calculations and review existing royalty/depletion/JV accounting separately.', DocumentNo);
    end;

    procedure ReversePosted(DocumentNo: Code[20]; PostingDate: Date; Reason: Text[250]): Code[20]
    var
        Original: Record "Production Entry Header";
        Reversal: Record "Production Entry Header";
        CheckTotal: Record "Production Entry Header";
        OriginalLine: Record "Production Entry Line";
        ReverseLine: Record "Production Entry Line";
        LedgerLink: Record "Production Ledger Link";
        OtherLink: Record "Production Ledger Link";
        Entry: Record "Item Ledger Entry";
        SourceLink: Record "Production Posting Link";
        RestoreLink: Record "Production Posting Link";
        Application: Record "Item Application Entry";
        OGSetup: Record "O&G Setup";
        JournalLock: Record "Item Journal Line";
        Batch: Code[10];
        LineNo: Integer;
        Consumed: Decimal;
    begin
        if (PostingDate = 0D) or (Reason = '') then
            Error('A reversal date and reason are required.');
        Original.LockTable();
        Original.Get(DocumentNo);
        Original.TestField(Posted, true);
        Original.TestField(Cancelled, false);
        Original.TestField("Record Kind", Original."Record Kind"::Production);
        Original.TestField("Reversed By Document No.", '');
        if Tracking.StateForDocument(DocumentNo) <> "Production Posting State"::Posted then
            Error('The source must be fully linked and inventory-posted. For a legacy source, use Review/Link Existing Ledger Entries first. Partially posted documents must be resolved before reversal.');
        CheckTotal := Original;
        Helper.CalcHeaderTotals(CheckTotal);
        if Abs(CheckTotal."Total BOE" - Original."Total BOE") > 0.00001 then
            Error('The stored source total does not match its lines. Reconcile this legacy source before reversing it; BOE must not be guessed from current conversion setup.');
        LedgerLink.SetRange("Document No.", DocumentNo);
        if not LedgerLink.FindSet() then
            Error('No linked item ledger entries exist.');
        // Validate the entire document before creating any reversal journal rows.
        repeat
            Entry.Get(LedgerLink."Item Ledger Entry No.");
            CheckLedgerReversible(Entry, DocumentNo);
            if PostingDate < Entry."Posting Date" then
                Error('The reversal date cannot precede original ledger entry %1 posting date %2.', Entry."Entry No.", Entry."Posting Date");
        until LedgerLink.Next() = 0;
        Helper.GetSetup(OGSetup);
        Reversal.Init();
        Reversal."Document No." := '';
        Reversal."Production Date" := PostingDate;
        Reversal."Record Kind" := Reversal."Record Kind"::Reversal;
        Reversal."Reverses Document No." := Original."Document No.";
        Reversal."Correction Reason" := Reason;
        Reversal.Insert(true); // automatic No. Series, no number assigned during the dialog
        Reversal."Reservoir Code" := Original."Reservoir Code";
        Reversal."Field/Block Code" := Original."Field/Block Code";
        Reversal."Well Code" := Original."Well Code";
        Reversal."Cost Center Code" := Original."Cost Center Code";
        Reversal."Entity Code" := Original."Entity Code";
        Reversal."Dimension Set ID" := Original."Dimension Set ID";
        Reversal."Item Journal Template Name" := OGSetup."Item Journal Template Name";
        Reversal.Modify(true);
        OriginalLine.SetRange("Document No.", DocumentNo);
        if OriginalLine.FindSet() then
            repeat
                ReverseLine := OriginalLine;
                ReverseLine."Document No." := Reversal."Document No.";
                ReverseLine.Quantity := -OriginalLine.Quantity;
                ReverseLine."Net Quantity" := -OriginalLine."Net Quantity";
                ReverseLine."BOE Quantity" := -OriginalLine."BOE Quantity";
                // Intentional signed, read-only correction history; do not run the
                // positive-production capture validator on these internal rows.
                ReverseLine.Insert(false);
            until OriginalLine.Next() = 0;
        Batch := JnlHelper.MakeBatchName('REV', PostingDate);
        JnlHelper.EnsureItemJournalBatch(Batch, Reversal."Item Journal Template Name");
        JournalLock.LockTable();
        LineNo := JnlHelper.NextItemJnlLineNo(Reversal."Item Journal Template Name", Batch);
        // Restore original BS&W losses FIRST. Fixed cost applications use the
        // actual original outbound ledger entries, not current item default cost.
        LedgerLink.FindSet();
        repeat
            Entry.Get(LedgerLink."Item Ledger Entry No.");
            if Entry.Quantity < 0 then begin
                SourceLink.Get(LedgerLink."Posting Link No.");
                CreateReverseJournal(Reversal, Entry, SourceLink, Batch, LineNo, Abs(Entry.Quantity), 0, 0);
                LineNo += 10000;
            end;
        until LedgerLink.Next() = 0;
        // Remove the original receipts. If own BS&W consumed part of a receipt,
        // split removal between the original remaining receipt and its restored
        // BS&W layer, rather than removing unrelated inventory through FIFO.
        LedgerLink.FindSet();
        repeat
            Entry.Get(LedgerLink."Item Ledger Entry No.");
            if Entry.Quantity > 0 then begin
                SourceLink.Get(LedgerLink."Posting Link No.");
                if Entry."Remaining Quantity" > 0 then begin
                    CreateReverseJournal(Reversal, Entry, SourceLink, Batch, LineNo, Entry."Remaining Quantity", Entry."Entry No.", 0);
                    LineNo += 10000;
                end;
                Consumed := 0;
                Application.Reset();
                Application.SetRange("Inbound Item Entry No.", Entry."Entry No.");
                Application.SetFilter("Outbound Item Entry No.", '<>0');
                Application.SetFilter(Quantity, '<>0');
                if Application.FindSet() then
                    repeat
                        OtherLink.Get(Application."Outbound Item Entry No.");
                        OtherLink.TestField("Document No.", DocumentNo);
                        RestoreLink.Reset();
                        RestoreLink.SetRange("Document No.", Reversal."Document No.");
                        RestoreLink.SetRange("Reverses Ledger Entry No.", Application."Outbound Item Entry No.");
                        RestoreLink.SetRange("Entry Type", RestoreLink."Entry Type"::"Positive Adjmt.");
                        if not RestoreLink.FindFirst() then
                            Error('A required BS&W restoration link is missing.');
                        CreateReverseJournal(Reversal, Entry, SourceLink, Batch, LineNo, Abs(Application.Quantity), 0, RestoreLink."Entry No.");
                        LineNo += 10000;
                        Consumed += Abs(Application.Quantity);
                    until Application.Next() = 0;
                if Abs(Entry.Quantity - Entry."Remaining Quantity" - Consumed) > 0.00001 then
                    Error('Receipt applications changed while preparing the reversal. Refresh and try again.');
            end;
        until LedgerLink.Next() = 0;
        Reversal."Total BOE" := -Original."Total BOE";
        Reversal."Item Journal Batch Name" := Batch;
        Reversal."Inventory Posting State" := Reversal."Inventory Posting State"::Pending;
        Reversal.Posted := true;
        Reversal.Modify(true);
        Original."Reversed By Document No." := Reversal."Document No.";
        Original.Modify(false);
        RefreshReserves(Original."Reservoir Code");
        Message('Reversal %1 was prepared in %2 / %3. Review and post the FULL reversal in generated order using standard BC. Original %4 remains read-only. No royalty, depletion, JV or management-fee journal was automatically reversed.', Reversal."Document No.", Reversal."Item Journal Template Name", Batch, Original."Document No.");
        exit(Reversal."Document No.");
    end;

    local procedure CreateReverseJournal(Header: Record "Production Entry Header"; OriginalEntry: Record "Item Ledger Entry"; OriginalLink: Record "Production Posting Link"; Batch: Code[10]; LineNo: Integer; BaseQuantity: Decimal; ApplyToEntry: Integer; ApplyToLink: Integer)
    var
        JournalLine: Record "Item Journal Line";
        Item: Record Item;
        Template: Record "Item Journal Template";
    begin
        Item.Get(OriginalEntry."Item No.");
        Template.Get(Header."Item Journal Template Name");
        JournalLine.Init();
        JournalLine."Journal Template Name" := Header."Item Journal Template Name";
        JournalLine."Journal Batch Name" := Batch;
        JournalLine."Line No." := LineNo;
        JournalLine."Source Code" := Template."Source Code";
        JournalLine.Validate("Posting Date", Header."Production Date");
        JournalLine."Document No." := Header."Document No.";
        if OriginalEntry.Quantity < 0 then
            JournalLine.Validate("Entry Type", JournalLine."Entry Type"::"Positive Adjmt.")
        else
            JournalLine.Validate("Entry Type", JournalLine."Entry Type"::"Negative Adjmt.");
        JournalLine.Validate("Item No.", OriginalEntry."Item No.");
        JournalLine.Validate("Location Code", OriginalEntry."Location Code");
        JournalLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        JournalLine.Validate("Gen. Bus. Posting Group", OriginalLink."Gen. Bus. Posting Group");
        JournalLine.Validate("Gen. Prod. Posting Group", OriginalLink."Gen. Prod. Posting Group");
        JournalLine.Validate("Inventory Posting Group", OriginalLink."Inventory Posting Group");
        JournalLine.Validate(Quantity, BaseQuantity);
        if OriginalEntry.Quantity < 0 then
            JournalLine.Validate("Applies-from Entry", OriginalEntry."Entry No.")
        else
            if ApplyToEntry <> 0 then
                JournalLine.Validate("Applies-to Entry", ApplyToEntry);
        JournalLine.Validate("Dimension Set ID", OriginalEntry."Dimension Set ID");
        JournalLine.Description := CopyStr(StrSubstNo('Reverse %1 / ILE %2', Header."Reverses Document No.", OriginalEntry."Entry No."), 1, MaxStrLen(JournalLine.Description));
        Tracking.RegisterJournalLine(JournalLine, Header."Document No.", OriginalLink."Production Line No.", OriginalEntry."Entry No.", ApplyToLink);
        JournalLine.Insert(true);
        Tracking.CaptureSystemID(JournalLine);
    end;

    local procedure CheckLedgerReversible(var Entry: Record "Item Ledger Entry"; DocumentNo: Code[20])
    var
        Item: Record Item;
        Location: Record Location;
        App: Record "Item Application Entry";
        OutboundLink: Record "Production Ledger Link";
        ReversalLink: Record "Production Ledger Link";
        OwnConsumption: Decimal;
    begin
        Entry.TestField(Correction, false);
        if not (Entry."Entry Type" in [Entry."Entry Type"::"Positive Adjmt.", Entry."Entry Type"::"Negative Adjmt."]) then
            Error('Only production adjustment entries can be reversed by this action.');
        Item.Get(Entry."Item No.");
        Item.TestField(Blocked, false);
        if (Item."Item Tracking Code" <> '') or (Entry."Lot No." <> '') or (Entry."Serial No." <> '') or (Entry."Variant Code" <> '') then
            Error('Entry %1 uses tracking/variants. Use a controlled standard BC tracking/warehouse correction; this bulk-production reversal will not guess lot/serial applications.', Entry."Entry No.");
        if Location.Get(Entry."Location Code") then
            if Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
                Error('Location %1 requires a warehouse/bin correction. Do not bypass warehouse controls with a production reversal.', Location.Code);
        Entry.CalcFields("Reserved Quantity");
        if Entry."Reserved Quantity" <> 0 then
            Error('Entry %1 has reservations. Resolve them before reversal.', Entry."Entry No.");
        ReversalLink.SetRange("Reverses Ledger Entry No.", Entry."Entry No.");
        if not ReversalLink.IsEmpty() then
            Error('Ledger entry %1 already has posted reversal links.', Entry."Entry No.");
        if Entry.Quantity < 0 then begin
            if Abs(Entry."Shipped Qty. Not Returned" - Entry.Quantity) > 0.00001 then
                Error('Outbound entry %1 has already been returned/corrected. Reconcile it before reversal.', Entry."Entry No.");
            exit;
        end;
        if (Entry.Quantity <= 0) or (Entry."Remaining Quantity" < 0) then
            Error('Invalid receipt quantities on entry %1.', Entry."Entry No.");
        App.SetRange("Inbound Item Entry No.", Entry."Entry No.");
        App.SetFilter("Outbound Item Entry No.", '<>0');
        App.SetFilter(Quantity, '<>0');
        if App.FindSet() then
            repeat
                if not OutboundLink.Get(App."Outbound Item Entry No.") then
                    Error('Receipt %1 has been consumed, sold or transferred by another transaction. Reverse/unapply the downstream transaction through BC first.', Entry."Entry No.");
                if (OutboundLink."Document No." <> DocumentNo) or (OutboundLink."Quantity Base" >= 0) then
                    Error('Receipt %1 has downstream use outside this production document. Resolve that use first.', Entry."Entry No.");
                OwnConsumption += Abs(App.Quantity);
            until App.Next() = 0;
        if Abs(Entry.Quantity - Entry."Remaining Quantity" - OwnConsumption) > 0.00001 then
            Error('Receipt %1 has unreconciled applications. Manual BC review is required before reversal.', Entry."Entry No.");
    end;

    procedure CreateCorrectionCopy(DocumentNo: Code[20]): Code[20]
    var
        Original: Record "Production Entry Header";
        ReverseHeader: Record "Production Entry Header";
        NewHeader: Record "Production Entry Header";
        ExistingCorrection: Record "Production Entry Header";
        OldLine: Record "Production Entry Line";
        NewLine: Record "Production Entry Line";
    begin
        Original.Get(DocumentNo);
        Original.TestField("Record Kind", Original."Record Kind"::Production);
        ExistingCorrection.SetRange("Corrects Document No.", DocumentNo);
        ExistingCorrection.SetRange(Cancelled, false);
        ExistingCorrection.SetRange("Reversed By Document No.", '');
        if ExistingCorrection.FindFirst() then
            Error('Correction %1 already exists for this source. Open that document instead of creating a duplicate.', ExistingCorrection."Document No.");
        if not Original.Cancelled then begin
            Original.TestField("Reversed By Document No.");
            ReverseHeader.Get(Original."Reversed By Document No.");
            if Tracking.StateForDocument(ReverseHeader."Document No.") <> "Production Posting State"::Posted then
                Error('Post the full reversal before creating/sending a corrected production document.');
        end;
        NewHeader.Init();
        NewHeader."Document No." := '';
        NewHeader."Production Date" := Original."Production Date";
        NewHeader.Insert(true);
        NewHeader.Validate("Reservoir Code", Original."Reservoir Code");
        NewHeader.Validate("Field/Block Code", Original."Field/Block Code");
        NewHeader.Validate("Well Code", Original."Well Code");
        NewHeader.Validate("Cost Center Code", Original."Cost Center Code");
        if Original."Entity Code" <> '' then
            NewHeader.Validate("Entity Code", Original."Entity Code");
        NewHeader."Corrects Document No." := Original."Document No.";
        NewHeader.Modify(true);
        OldLine.SetRange("Document No.", DocumentNo);
        if OldLine.FindSet() then
            repeat
                NewLine := OldLine;
                NewLine."Document No." := NewHeader."Document No.";
                NewLine.Insert(true);
            until OldLine.Next() = 0;
        exit(NewHeader."Document No.");
    end;

    local procedure AdoptPending(Header: Record "Production Entry Header")
    var
        Line: Record "Production Entry Line";
        Entry: Record "Item Ledger Entry";
        JournalLine: Record "Item Journal Line";
        Matched: Integer;
        Expected: Integer;
    begin
        Header.TestField("Item Journal Template Name");
        Entry.SetRange("Document No.", Header."Document No.");
        if not Entry.IsEmpty() then
            Error('Legacy ledger entries exist for this document number. Do not infer that its journal is wholly unposted. Review/link the actual ledger entries first.');
        Line.SetRange("Document No.", Header."Document No.");
        if Line.FindSet() then
            repeat
                AdoptOnePending(Header, Line, false, Line.Quantity);
                Expected += 1;
                if Line.Quantity - Line."Net Quantity" > 0 then begin
                    AdoptOnePending(Header, Line, true, Line.Quantity - Line."Net Quantity");
                    Expected += 1;
                end;
            until Line.Next() = 0;
        JournalLine.SetRange("Journal Template Name", Header."Item Journal Template Name");
        JournalLine.SetRange("Journal Batch Name", Header."Item Journal Batch Name");
        JournalLine.SetRange("Document No.", Header."Document No.");
        Matched := JournalLine.Count();
        if (Expected = 0) or (Expected <> Matched) then
            Error('Legacy journal rows do not exactly match the source. No rows were cancelled; reconcile the journal first.');
        Tracking.RefreshHeader(Header."Document No.");
    end;

    local procedure AdoptOnePending(Header: Record "Production Entry Header"; SourceLine: Record "Production Entry Line"; IsLoss: Boolean; Quantity: Decimal)
    var
        JournalLine: Record "Item Journal Line";
    begin
        JournalLine.SetRange("Journal Template Name", Header."Item Journal Template Name");
        JournalLine.SetRange("Journal Batch Name", Header."Item Journal Batch Name");
        JournalLine.SetRange("Document No.", Header."Document No.");
        JournalLine.SetRange("Item No.", SourceLine."Item No.");
        JournalLine.SetRange("Location Code", SourceLine."Location Code");
        JournalLine.SetRange("Unit of Measure Code", SourceLine."Unit of Measure Code");
        JournalLine.SetRange(Quantity, Quantity);
        JournalLine.SetRange("O&G Production Link No.", 0);
        if IsLoss then
            JournalLine.SetRange("Entry Type", JournalLine."Entry Type"::"Negative Adjmt.")
        else
            JournalLine.SetRange("Entry Type", JournalLine."Entry Type"::"Positive Adjmt.");
        if JournalLine.Count() <> 1 then
            Error('Cannot unambiguously match a legacy journal row for source item %1. No guessing or broad deletion is allowed.', SourceLine."Item No.");
        JournalLine.FindFirst();
        Tracking.RegisterJournalLine(JournalLine, Header."Document No.", SourceLine."Line No.", 0, 0);
        JournalLine.Modify(false);
        Tracking.CaptureSystemID(JournalLine);
    end;

    procedure LinkLegacyLedger(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary)
    begin
        LinkLegacyLedger(DocumentNo, Selected, true);
    end;

    procedure LinkLegacyLedger(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary; ShowMessage: Boolean)
    var
        Header: Record "Production Entry Header";
        SourceLine: Record "Production Entry Line";
        Existing: Record "Production Ledger Link";
        Link: Record "Production Posting Link";
        Entry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        Journal: Record "Item Journal Line";
        PositiveTotal: Decimal;
        NegativeTotal: Decimal;
        Factor: Decimal;
    begin
        Header.LockTable();
        Header.Get(DocumentNo);
        CheckLegacySelection(DocumentNo, Selected);
        Selected.FindSet();
        repeat
            Entry.Get(Selected."Entry No.");
            SourceLine.Reset();
            SourceLine.SetRange("Document No.", DocumentNo);
            SourceLine.SetRange("Item No.", Entry."Item No.");
            SourceLine.SetRange("Location Code", Entry."Location Code");
            SourceLine.SetRange("Unit of Measure Code", Entry."Unit of Measure Code");
            SourceLine.FindFirst();
            ValueEntry.Reset();
            ValueEntry.SetRange("Item Ledger Entry No.", Entry."Entry No.");
            ValueEntry.SetRange(Adjustment, false);
            if not ValueEntry.FindFirst() then
                Error('No original value-entry evidence exists for ledger entry %1.', Entry."Entry No.");
            Link.Init();
            Link."Entry No." := 0;
            Link."Document No." := DocumentNo;
            Link."Production Line No." := SourceLine."Line No.";
            Link."Journal Template Name" := Header."Item Journal Template Name";
            Link."Journal Batch Name" := Header."Item Journal Batch Name";
            Link."Item No." := Entry."Item No.";
            Link."Location Code" := Entry."Location Code";
            Link."Unit of Measure Code" := Entry."Unit of Measure Code";
            Link."Entry Type" := Entry."Entry Type";
            Link.Quantity := Abs(Entry.Quantity) / Entry."Qty. per Unit of Measure";
            Link."Quantity Base" := Abs(Entry.Quantity);
            Link."Dimension Set ID" := Entry."Dimension Set ID";
            Link."Posting Date" := Entry."Posting Date";
            Link."Gen. Bus. Posting Group" := ValueEntry."Gen. Bus. Posting Group";
            Link."Gen. Prod. Posting Group" := ValueEntry."Gen. Prod. Posting Group";
            Link."Inventory Posting Group" := ValueEntry."Inventory Posting Group";
            Link.State := Link.State::Pending;
            Link."Legacy Link" := true;
            Link."Created At" := CurrentDateTime();
            Link."Created By" := UserSecurityId();
            Link.Insert(true);
            Tracking.RecordLedger(Link."Entry No.", Entry);
        until Selected.Next() = 0;
        Tracking.RefreshHeader(DocumentNo);
        if ShowMessage then
            Message('Selected legacy ledger entries linked to %1 after quantity verification. Linking did not reverse or repost any inventory.', DocumentNo);
    end;

    // Read-only: safe to call before the user confirms a correction/reversal.
    [TryFunction]
    procedure TryCheckLegacySelection(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary)
    begin
        CheckLegacySelection(DocumentNo, Selected);
    end;

    local procedure CheckLegacySelection(DocumentNo: Code[20]; var Selected: Record "Item Ledger Entry" temporary)
    var
        Header: Record "Production Entry Header";
        SourceLine: Record "Production Entry Line";
        Existing: Record "Production Ledger Link";
        Entry: Record "Item Ledger Entry";
        Journal: Record "Item Journal Line";
        PositiveTotal: Decimal;
        NegativeTotal: Decimal;
        Factor: Decimal;
    begin
        Header.Get(DocumentNo);
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        if Tracking.StateForDocument(DocumentNo) <> "Production Posting State"::Untracked then
            Error('This source already has posting links. Existing links are not overwritten.');
        Journal.SetRange("Journal Template Name", Header."Item Journal Template Name");
        Journal.SetRange("Journal Batch Name", Header."Item Journal Batch Name");
        Journal.SetRange("Document No.", DocumentNo);
        if not Journal.IsEmpty() then
            Error('Pending journal rows remain for this source. Complete/reconcile partial posting first.');
        if not Selected.FindSet() then
            Error('Select the complete set of actual ledger entries for this production document.');
        // Require a one-to-one source item/location/UOM group, with exact gross
        // receipt and BS&W-loss totals. Ambiguous historical mappings are rejected.
        repeat
            Entry.Get(Selected."Entry No.");
            Entry.TestField("Document No.", DocumentNo);
            if Existing.Get(Entry."Entry No.") then
                Error('Ledger entry %1 is already linked to source %2.', Entry."Entry No.", Existing."Document No.");
            SourceLine.Reset();
            SourceLine.SetRange("Document No.", DocumentNo);
            SourceLine.SetRange("Item No.", Entry."Item No.");
            SourceLine.SetRange("Location Code", Entry."Location Code");
            SourceLine.SetRange("Unit of Measure Code", Entry."Unit of Measure Code");
            if SourceLine.Count() <> 1 then
                Error('Ledger entry %1 cannot be unambiguously matched to one source item/location/UOM line.', Entry."Entry No.");
            if not (Entry."Entry Type" in [Entry."Entry Type"::"Positive Adjmt.", Entry."Entry Type"::"Negative Adjmt."]) then
                Error('Only adjustment entries may be linked.');
            if ((Entry."Entry Type" = Entry."Entry Type"::"Positive Adjmt.") and (Entry.Quantity <= 0)) or
               ((Entry."Entry Type" = Entry."Entry Type"::"Negative Adjmt.") and (Entry.Quantity >= 0)) then
                Error('Ledger entry %1 has an unexpected quantity sign. Reconcile the historical posting rather than inferring a source link.', Entry."Entry No.");
        until Selected.Next() = 0;
        SourceLine.Reset();
        SourceLine.SetRange("Document No.", DocumentNo);
        if SourceLine.FindSet() then
            repeat
                PositiveTotal := 0;
                NegativeTotal := 0;
                Selected.FindSet();
                repeat
                    if (Selected."Item No." = SourceLine."Item No.") and (Selected."Location Code" = SourceLine."Location Code") and
                       (Selected."Unit of Measure Code" = SourceLine."Unit of Measure Code") then begin
                        Factor := Selected."Qty. per Unit of Measure";
                        if Factor = 0 then
                            Error('Ledger entry %1 has no recorded UOM factor.', Selected."Entry No.");
                        if Selected.Quantity > 0 then
                            PositiveTotal += Selected.Quantity / Factor
                        else
                            NegativeTotal += -Selected.Quantity / Factor;
                    end;
                until Selected.Next() = 0;
                if (Abs(PositiveTotal - SourceLine.Quantity) > 0.00001) or
                   (Abs(NegativeTotal - (SourceLine.Quantity - SourceLine."Net Quantity")) > 0.00001) then
                    Error('Selected ledger quantities do not match gross and BS&W for item %1. Linking is stopped.', SourceLine."Item No.");
            until SourceLine.Next() = 0;
    end;

    procedure EnsurePendingLinks(DocumentNo: Code[20])
    var
        Header: Record "Production Entry Header";
    begin
        Header.LockTable();
        Header.Get(DocumentNo);
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        if Tracking.StateForDocument(DocumentNo) = "Production Posting State"::Untracked then
            AdoptPending(Header);
    end;

    local procedure RefreshReserves(ReservoirCode: Code[20])
    var
        Reservoir: Record Reservoir;
    begin
        if Reservoir.Get(ReservoirCode) then begin
            Helper.UpdateRemainingReserves(Reservoir);
            Reservoir.Modify(true);
        end;
    end;
}
