// Tracks the exact native journal/ledger rows. Untagged standard BC journals
// are not changed. All updates take part in the native posting transaction.
codeunit 70084 "Production Posting Tracking"
{
    InherentPermissions = X;
    Permissions = tabledata "Production Posting Link" = RIMD,
                  tabledata "Production Ledger Link" = RIMD,
                  tabledata "Production Entry Header" = RM;

    procedure RegisterJournalLine(var JournalLine: Record "Item Journal Line"; DocumentNo: Code[20]; ProductionLineNo: Integer; ReversesLedgerEntryNo: Integer; ApplyToLinkNo: Integer): Integer
    var
        Link: Record "Production Posting Link";
    begin
        Link.Init();
        Link."Entry No." := 0;
        Link."Document No." := DocumentNo;
        Link."Production Line No." := ProductionLineNo;
        Link."Journal Template Name" := JournalLine."Journal Template Name";
        Link."Journal Batch Name" := JournalLine."Journal Batch Name";
        Link."Journal Line No." := JournalLine."Line No.";
        Link."Item No." := JournalLine."Item No.";
        Link."Location Code" := JournalLine."Location Code";
        Link."Unit of Measure Code" := JournalLine."Unit of Measure Code";
        Link."Entry Type" := JournalLine."Entry Type";
        Link.Quantity := JournalLine.Quantity;
        Link."Quantity Base" := JournalLine."Quantity (Base)";
        CapturePostingValues(Link, JournalLine);
        Link.State := Link.State::Pending;
        Link."Reverses Ledger Entry No." := ReversesLedgerEntryNo;
        Link."Apply To Link No." := ApplyToLinkNo;
        Link."Created At" := CurrentDateTime();
        Link."Created By" := UserSecurityId();
        Link.Insert(true);
        JournalLine."O&G Production Link No." := Link."Entry No.";
        exit(Link."Entry No.");
    end;

    procedure CaptureSystemID(JournalLine: Record "Item Journal Line")
    var
        Link: Record "Production Posting Link";
    begin
        Link.Get(JournalLine."O&G Production Link No.");
        Link."Journal Line System ID" := JournalLine.SystemId;
        Link.Modify();
    end;

    procedure StateForDocument(DocumentNo: Code[20]): Enum "Production Posting State"
    var
        Link: Record "Production Posting Link";
        Pending: Integer;
        Posted: Integer;
        Cancelled: Integer;
        Partial: Integer;
    begin
        Link.SetRange("Document No.", DocumentNo);
        if not Link.FindSet() then
            exit("Production Posting State"::Untracked);
        repeat
            case Link.State of
                Link.State::Pending: Pending += 1;
                Link.State::Posted: Posted += 1;
                Link.State::Cancelled: Cancelled += 1;
                else Partial += 1;
            end;
        until Link.Next() = 0;
        if (Pending = 0) and (Posted = 0) and (Partial = 0) then
            exit("Production Posting State"::Cancelled);
        if (Posted > 0) and (Pending = 0) and (Partial = 0) and (Cancelled = 0) then
            exit("Production Posting State"::Posted);
        if (Pending > 0) and (Posted = 0) and (Partial = 0) and (Cancelled = 0) then
            exit("Production Posting State"::Pending);
        exit("Production Posting State"::Partial);
    end;

    procedure RefreshHeader(DocumentNo: Code[20])
    var
        Header: Record "Production Entry Header";
        NewState: Enum "Production Posting State";
    begin
        Header.LockTable();
        Header.Get(DocumentNo);
        if not Header.Posted then
            exit;
        NewState := StateForDocument(DocumentNo);
        if Header."Inventory Posting State" <> NewState then begin
            Header."Inventory Posting State" := NewState;
            Header.Modify(false);
        end;
    end;

    procedure RecordLedger(LinkNo: Integer; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Link: Record "Production Posting Link";
        LedgerLink: Record "Production Ledger Link";
        SumLink: Record "Production Ledger Link";
        SignedQuantity: Decimal;
        Expected: Decimal;
    begin
        Link.LockTable();
        Link.Get(LinkNo);
        if LedgerLink.Get(ItemLedgerEntry."Entry No.") then begin
            LedgerLink.TestField("Posting Link No.", LinkNo);
            exit;
        end;
        LedgerLink.Init();
        LedgerLink."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        LedgerLink."Posting Link No." := LinkNo;
        LedgerLink."Document No." := Link."Document No.";
        LedgerLink."Production Line No." := Link."Production Line No.";
        LedgerLink."Quantity Base" := ItemLedgerEntry.Quantity;
        LedgerLink."Item No." := ItemLedgerEntry."Item No.";
        LedgerLink."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        LedgerLink."Posting Date" := ItemLedgerEntry."Posting Date";
        LedgerLink."Reverses Ledger Entry No." := Link."Reverses Ledger Entry No.";
        LedgerLink.Insert(true);
        SumLink.SetRange("Posting Link No.", LinkNo);
        if SumLink.FindSet() then
            repeat
                SignedQuantity += SumLink."Quantity Base";
            until SumLink.Next() = 0;
        Expected := Link."Quantity Base";
        if Link."Entry Type" = Link."Entry Type"::"Negative Adjmt." then
            Expected := -Expected;
        if Abs(SignedQuantity - Expected) < 0.00001 then
            Link.State := Link.State::Posted
        else
            Link.State := Link.State::Partial;
        Link.Modify();
        RefreshHeader(Link."Document No.");
    end;

    procedure ValidateMovement(JournalLine: Record "Item Journal Line"; Link: Record "Production Posting Link")
    begin
        JournalLine.TestField("Journal Template Name", Link."Journal Template Name");
        JournalLine.TestField("Journal Batch Name", Link."Journal Batch Name");
        JournalLine.TestField("Line No.", Link."Journal Line No.");
        JournalLine.TestField("Document No.", Link."Document No.");
        JournalLine.TestField("Item No.", Link."Item No.");
        JournalLine.TestField("Location Code", Link."Location Code");
        JournalLine.TestField("Unit of Measure Code", Link."Unit of Measure Code");
        JournalLine.TestField("Entry Type", Link."Entry Type");
        JournalLine.TestField(Quantity, Link.Quantity);
        if Abs(JournalLine."Quantity (Base)" - Link."Quantity Base") >= 0.00001 then
            Error('The base quantity of production journal line %1 changed. Cancel the source and create a corrected production document.', Link."Entry No.");
    end;

    local procedure CapturePostingValues(var Link: Record "Production Posting Link"; JournalLine: Record "Item Journal Line")
    begin
        Link."Posting Date" := JournalLine."Posting Date";
        Link."Dimension Set ID" := JournalLine."Dimension Set ID";
        Link."Gen. Bus. Posting Group" := JournalLine."Gen. Bus. Posting Group";
        Link."Gen. Prod. Posting Group" := JournalLine."Gen. Prod. Posting Group";
        Link."Inventory Posting Group" := JournalLine."Inventory Posting Group";
        Link."Unit Amount" := JournalLine."Unit Amount";
        Link."Unit Cost" := JournalLine."Unit Cost";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeRunWithCheck', '', false, false)]
    local procedure BeforeNativePosting(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; CalledFromApplicationWorksheet: Boolean; PostponeReservationHandling: Boolean; var IsHandled: Boolean)
    var
        Link: Record "Production Posting Link";
        Header: Record "Production Entry Header";
        LedgerLink: Record "Production Ledger Link";
        RequiredDim: Record "Dimension Set Entry";
        ActualDim: Record "Dimension Set Entry";
        DimensionCorrection: Codeunit "Production Dimension Mgt.";
    begin
        if ItemJournalLine."O&G Production Link No." = 0 then
            exit;
        Link.Get(ItemJournalLine."O&G Production Link No.");
        if Link.State in [Link.State::Cancelled, Link.State::Posted] then
            Error('Production journal link %1 is already posted or cancelled.', Link."Entry No.");
        Header.Get(Link."Document No.");
        DimensionCorrection.CheckNoActiveCorrection(Header."Document No.");
        Header.TestField(Posted, true);
        Header.TestField(Cancelled, false);
        ValidateMovement(ItemJournalLine, Link);
        if Header."Record Kind" = Header."Record Kind"::Reversal then
            ItemJournalLine.TestField("Dimension Set ID", Link."Dimension Set ID")
        else begin
            RequiredDim.SetRange("Dimension Set ID", Header."Dimension Set ID");
            if RequiredDim.FindSet() then
                repeat
                    if not ActualDim.Get(ItemJournalLine."Dimension Set ID", RequiredDim."Dimension Code") then
                        Error('Production dimension %1 is missing from the journal.', RequiredDim."Dimension Code");
                    ActualDim.TestField("Dimension Value Code", RequiredDim."Dimension Value Code");
                until RequiredDim.Next() = 0;
        end;
        if Link."Apply To Link No." <> 0 then begin
            LedgerLink.SetRange("Posting Link No.", Link."Apply To Link No.");
            if LedgerLink.Count() <> 1 then
                Error('Post the full reversal in generated line order. Its preceding BS&W restoration line must be posted first.');
            LedgerLink.FindFirst();
            ItemJournalLine.Validate("Applies-to Entry", LedgerLink."Item Ledger Entry No.");
        end;
        CapturePostingValues(Link, ItemJournalLine);
        Link.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', false, false)]
    local procedure AfterNativeLedger(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if ItemJournalLine."O&G Production Link No." <> 0 then
            RecordLedger(ItemJournalLine."O&G Production Link No.", ItemLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeJournalDelete(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    var
        Link: Record "Production Posting Link";
    begin
        if Rec.IsTemporary() or (Rec."O&G Production Link No." = 0) then
            exit;
        Link.Get(Rec."O&G Production Link No.");
        if not (Link.State in [Link.State::Posted, Link.State::Cancelled]) then
            Error('Use Cancel Pending Journal on production document %1 instead of deleting its linked journal lines.', Link."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeJournalModify(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; RunTrigger: Boolean)
    var
        Link: Record "Production Posting Link";
    begin
        if Rec.IsTemporary() then
            exit;
        if xRec."O&G Production Link No." <> Rec."O&G Production Link No." then
            if xRec."O&G Production Link No." <> 0 then
                Error('The production source link cannot be changed.');
        if Rec."O&G Production Link No." = 0 then
            exit;
        Link.Get(Rec."O&G Production Link No.");
        if Link.State = Link.State::Pending then
            ValidateMovement(Rec, Link);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeJournalRename(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if (not Rec.IsTemporary()) and (xRec."O&G Production Link No." <> 0) then
            Error('Linked production journal lines cannot be moved or renumbered. Cancel the source and create a correction.');
    end;
}
