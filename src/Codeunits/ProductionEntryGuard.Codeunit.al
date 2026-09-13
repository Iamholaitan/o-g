// -----------------------------------------------------------------------------
// Production Entry Guard (FR-14).
// Database-event guards, not just disabled controls. Do not skip this subscriber
// when permissions are missing. Check stored state to catch stale pages and
// clearing Posted before Modify. Temporary batch-selection buffers are exempt.
// -----------------------------------------------------------------------------
codeunit 70080 "Production Entry Guard"
{
    [EventSubscriber(ObjectType::Table, Database::"Production Entry Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure HeaderBeforeInsert(var Rec: Record "Production Entry Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec.Posted then
            Error('A production history entry cannot be inserted manually. Use Post to Item Journal on an open production document.');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure HeaderBeforeModify(var Rec: Record "Production Entry Header"; var xRec: Record "Production Entry Header"; RunTrigger: Boolean)
    var
        JournalLine: Record "Item Journal Line";
        StoredHeader: Record "Production Entry Header";
    begin
        if Rec.IsTemporary() then
            exit;
        StoredHeader.LockTable();
        StoredHeader.Get(Rec."Document No.");
        if StoredHeader.Posted then begin
            ValidateSystemMetadata(Rec, StoredHeader);
            exit;
        end;
        CheckStoredHeaderOpen(Rec."Document No.");
        if Rec.Posted then begin
            Rec.TestField("Item Journal Template Name");
            Rec.TestField("Item Journal Batch Name");
            JournalLine.SetRange("Journal Template Name", Rec."Item Journal Template Name");
            JournalLine.SetRange("Journal Batch Name", Rec."Item Journal Batch Name");
            JournalLine.SetRange("Document No.", Rec."Document No.");
            if JournalLine.IsEmpty() then
                Error('Document %1 cannot be marked as sent: no generated item journal lines exist in its recorded template and batch.', Rec."Document No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure HeaderBeforeDelete(var Rec: Record "Production Entry Header"; RunTrigger: Boolean)
    var
        ProdLine: Record "Production Entry Line";
    begin
        if Rec.IsTemporary() then
            exit;
        CheckStoredHeaderOpen(Rec."Document No.");
        ProdLine.SetRange("Document No.", Rec."Document No.");
        ProdLine.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Header", 'OnBeforeRenameEvent', '', false, false)]
    local procedure HeaderBeforeRename(var Rec: Record "Production Entry Header"; var xRec: Record "Production Entry Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Error('Production document numbers cannot be renamed. Create a new open document instead; journal history references must not change.');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure LineBeforeInsert(var Rec: Record "Production Entry Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            CheckStoredHeaderOpen(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure LineBeforeModify(var Rec: Record "Production Entry Line"; var xRec: Record "Production Entry Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckStoredHeaderOpen(xRec."Document No.");
        if xRec."Document No." <> Rec."Document No." then
            CheckStoredHeaderOpen(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure LineBeforeDelete(var Rec: Record "Production Entry Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            CheckStoredHeaderOpen(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Entry Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure LineBeforeRename(var Rec: Record "Production Entry Line"; var xRec: Record "Production Entry Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        Error('Production line keys cannot be renamed. Add or remove lines only on an open production document.');
    end;

    // Sent quantities, dimensions and references remain immutable. Only verifiable
    // posting/cancellation/reversal metadata may change; no broad bypass switch.
    local procedure ValidateSystemMetadata(NewHeader: Record "Production Entry Header"; OldHeader: Record "Production Entry Header")
    var
        NewRef: RecordRef;
        OldRef: RecordRef;
        NewField: FieldRef;
        OldField: FieldRef;
        Related: Record "Production Entry Header";
        Tracking: Codeunit "Production Posting Tracking";
        DimensionCorrection: Codeunit "Production Dimension Mgt.";
        DimensionsChanged: Boolean;
        I: Integer;
    begin
        NewRef.GetTable(NewHeader);
        OldRef.GetTable(OldHeader);
        for I := 1 to NewRef.FieldCount() do begin
            NewField := NewRef.FieldIndex(I);
            if (NewField.Number() < 2000000000) and
               not (NewField.Number() in [17, 18, 19, 20, 21, 23]) and
               (NewField.Class() = FieldClass::Normal)
            then begin
                OldField := OldRef.Field(NewField.Number());
                if Format(NewField.Value(), 0, 9) <> Format(OldField.Value(), 0, 9) then
                    if NewField.Number() in [4, 5, 10, 11, 13, 25] then
                        DimensionsChanged := true
                    else
                        Error('Production document %1 has been sent to the item journal. Quantities, items, dates, reservoir and document identity cannot be edited or reopened. Use Correct Dimensions only for an audited classification change.', OldHeader."Document No.");
            end;
        end;
        if DimensionsChanged then
            DimensionCorrection.ValidateSourceChange(NewHeader, OldHeader);
        if NewHeader."Inventory Posting State" <> Tracking.StateForDocument(NewHeader."Document No.") then
            Error('Inventory posting state must match the linked journal/ledger evidence.');
        if OldHeader.Cancelled then begin
            if (not NewHeader.Cancelled) or (NewHeader."Cancellation Reason" <> OldHeader."Cancellation Reason") or
               (NewHeader."Cancelled At" <> OldHeader."Cancelled At") or (NewHeader."Cancelled By" <> OldHeader."Cancelled By") then
                Error('Cancelled production history cannot be reopened or its cancellation audit changed.');
        end else
            if NewHeader.Cancelled then begin
                NewHeader.TestField("Inventory Posting State", NewHeader."Inventory Posting State"::Cancelled);
                NewHeader.TestField("Cancellation Reason");
                NewHeader.TestField("Cancelled At");
                NewHeader.TestField("Cancelled By", UserSecurityId());
            end else
                if (NewHeader."Cancellation Reason" <> OldHeader."Cancellation Reason") or
                   (NewHeader."Cancelled At" <> OldHeader."Cancelled At") or (NewHeader."Cancelled By" <> OldHeader."Cancelled By") then
                    Error('Cancellation audit can only be recorded while cancelling all pending journal links.');
        if NewHeader."Reversed By Document No." <> OldHeader."Reversed By Document No." then begin
            if NewHeader."Reversed By Document No." = '' then begin
                Related.Get(OldHeader."Reversed By Document No.");
                Related.TestField(Cancelled, true);
            end else begin
                if OldHeader."Reversed By Document No." <> '' then begin
                    Related.Get(OldHeader."Reversed By Document No.");
                    Related.TestField(Cancelled, true);
                end;
                Related.Get(NewHeader."Reversed By Document No.");
                Related.TestField("Record Kind", Related."Record Kind"::Reversal);
                Related.TestField("Reverses Document No.", NewHeader."Document No.");
                Related.TestField(Posted, true);
                Related.TestField(Cancelled, false);
            end;
        end;
    end;

    local procedure CheckStoredHeaderOpen(DocumentNo: Code[20])
    var
        StoredHeader: Record "Production Entry Header";
    begin
        StoredHeader.LockTable();
        if not StoredHeader.Get(DocumentNo) then
            Error('Production document %1 does not exist.', DocumentNo);
        if StoredHeader.Posted then
            Error('Production document %1 has been sent to the item journal. Its header and lines cannot be modified, deleted, or reopened.', DocumentNo);
    end;
}
