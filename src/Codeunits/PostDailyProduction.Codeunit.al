// -----------------------------------------------------------------------------
// Post Daily Production (FR-14-19).
// Creates standard, validated Item Journal lines, then locks the source.
// No auto-posting to Item Ledger / G/L. Receipt less separate BS&W loss equals
// NET inventory: positive GROSS quantity; Negative Adjmt. with positive loss.
// -----------------------------------------------------------------------------
codeunit 70070 "Post Daily Production"
{
    var
        Helper: Codeunit "Production Entry Helper";
        DimHelper: Codeunit "Dimension Helper";
        JnlHelper: Codeunit "Journal Helper";

    procedure Post(ProductionHeader: Record "Production Entry Header")
    var
        ProdHeader: Record "Production Entry Header";
        ProdLine: Record "Production Entry Line";
        OGSetup: Record "O&G Setup";
        EntityMgt: Codeunit "O&G Entity Mgt.";
        Tracking: Codeunit "Production Posting Tracking";
        Reservoir: Record Reservoir;
        JournalLine: Record "Item Journal Line";
        BatchName: Code[10];
        LineNo: Integer;
        LossQuantity: Decimal;
    begin
        ProductionHeader.TestField("Document No.");
        ProdHeader.LockTable();
        ProdHeader.Get(ProductionHeader."Document No.");
        ProdHeader.TestOpen();
        ProdHeader.TestField("Production Date");
        ProdHeader.TestField("Reservoir Code");
        ProdHeader.TestField("Record Kind", ProdHeader."Record Kind"::Production);
        ValidateCorrectionSource(ProdHeader);
        EntityMgt.ValidateEntity(ProdHeader."Entity Code");
        Helper.GetSetup(OGSetup);
        OGSetup.TestField("Item Journal Template Name");
        OGSetup.TestField("Field/Block Dimension Code");
        OGSetup.TestField("Well Dimension Code");
        OGSetup.TestField("Reservoir Dimension Code");
        OGSetup.TestField("Cost Center Dimension Code");
        Reservoir.Get(ProdHeader."Reservoir Code");
        // Fill missing defaults on older open documents; preserve valid overrides.
        ProdHeader.SetReservoirDefaults(false);
        ProdHeader.TestField("Field/Block Code");
        ProdHeader."Item Journal Template Name" := OGSetup."Item Journal Template Name";
        ProdHeader."Dimension Set ID" := DimHelper.GetDimensionSetID(OGSetup, ProdHeader."Field/Block Code", ProdHeader."Well Code", ProdHeader."Reservoir Code", ProdHeader."Cost Center Code", '', ProdHeader."Entity Code");

        ProdLine.LockTable();
        ProdLine.SetRange("Document No.", ProdHeader."Document No.");
        if ProdLine.IsEmpty() then
            Error('Document %1 has no production lines.', ProdHeader."Document No.");
        BatchName := JnlHelper.MakeBatchName('PROD', ProdHeader."Production Date");
        JnlHelper.EnsureItemJournalBatch(BatchName, ProdHeader."Item Journal Template Name");
        // Serialize append within the complete template/batch key, not line 1
        // on every new document. A second send of the same source is blocked above.
        JournalLine.LockTable();
        LineNo := JnlHelper.NextItemJnlLineNo(ProdHeader."Item Journal Template Name", BatchName);

        if ProdLine.FindSet(true) then
            repeat
                ProdLine.TestField("Item No.");
                if ProdLine.Quantity <= 0 then
                    Error('Enter a positive gross quantity for item %1 on document %2, or remove the unused line.', ProdLine."Item No.", ProdHeader."Document No.");
                Helper.CalcLine(ProdLine, ProdHeader);
                ProdLine.TestField("Location Code");
                ProdLine.TestField("Unit of Measure Code");
                // Persist exactly the calculated lines used for journal generation.
                ProdLine.Modify(true);
                LossQuantity := Round(ProdLine.Quantity - ProdLine."Net Quantity", 0.001);
                if LossQuantity > 0 then
                    OGSetup.TestField("BS&W Gen. Bus. Posting Group");

                CreateJournalLine(ProdHeader, ProdLine, OGSetup, BatchName, LineNo, false, ProdLine.Quantity);
                LineNo += 10000;
                if LossQuantity > 0 then begin
                    CreateJournalLine(ProdHeader, ProdLine, OGSetup, BatchName, LineNo, true, LossQuantity);
                    LineNo += 10000;
                end;
            until ProdLine.Next() = 0;

        Helper.CalcHeaderTotals(ProdHeader);
        ProdHeader."Item Journal Batch Name" := BatchName;
        ProdHeader."Inventory Posting State" := ProdHeader."Inventory Posting State"::Pending;
        ProdHeader.Posted := true;
        ProdHeader.Modify(true);
        Helper.UpdateRemainingReserves(Reservoir);
        Reservoir.Modify(true);

        Message('Production %1 was sent to item journal template %2, batch %3. The source is now read-only. The accountant must review and post the journal separately.', ProdHeader."Document No.", ProdHeader."Item Journal Template Name", BatchName);
    end;

    local procedure CreateJournalLine(Header: Record "Production Entry Header"; ProdLine: Record "Production Entry Line"; OGSetup: Record "O&G Setup"; BatchName: Code[10]; LineNo: Integer; IsLoss: Boolean; JournalQuantity: Decimal)
    var
        JournalLine: Record "Item Journal Line";
        Template: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        GeneralPostingSetup: Record "General Posting Setup";
        Tracking: Codeunit "Production Posting Tracking";
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDs: array[10] of Integer;
        CombinedDimensionSetID: Integer;
    begin
        Template.Get(Header."Item Journal Template Name");
        Batch.Get(Header."Item Journal Template Name", BatchName);
        JournalLine.Init();
        JournalLine."Journal Template Name" := Header."Item Journal Template Name";
        JournalLine."Journal Batch Name" := BatchName;
        JournalLine."Line No." := LineNo;
        JournalLine."Source Code" := Template."Source Code";
        JournalLine."Reason Code" := Batch."Reason Code";
        JournalLine.Validate("Posting Date", Header."Production Date");
        JournalLine."Document No." := Header."Document No.";
        if IsLoss then
            JournalLine.Validate("Entry Type", JournalLine."Entry Type"::"Negative Adjmt.")
        else
            JournalLine.Validate("Entry Type", JournalLine."Entry Type"::"Positive Adjmt.");
        // Standard validation populates posting groups, unit cost, base quantity
        // and other BC fields; assigning only Quantity/Item No. is insufficient.
        JournalLine.Validate("Item No.", ProdLine."Item No.");
        JournalLine.Validate("Location Code", ProdLine."Location Code");
        JournalLine.Validate("Unit of Measure Code", ProdLine."Unit of Measure Code");
        if IsLoss then begin
            JournalLine.Validate("Gen. Bus. Posting Group", OGSetup."BS&W Gen. Bus. Posting Group");
            if not GeneralPostingSetup.Get(JournalLine."Gen. Bus. Posting Group", JournalLine."Gen. Prod. Posting Group") then
                Error('Create General Posting Setup for BS&W business group %1 and product group %2. Set its Inventory Adjmt. Account to the BS&W loss expense account.', JournalLine."Gen. Bus. Posting Group", JournalLine."Gen. Prod. Posting Group");
            GeneralPostingSetup.TestField("Inventory Adjmt. Account");
            JournalLine.Description := CopyStr('BS&W loss ' + Header."Document No." + ' / ' + ProdLine."Item No.", 1, MaxStrLen(JournalLine.Description));
        end else
            JournalLine.Description := CopyStr('Gross production ' + Header."Document No.", 1, MaxStrLen(JournalLine.Description));
        // Entry Type supplies the inventory sign. Both journal quantities are positive.
        JournalLine.Validate(Quantity, JournalQuantity);
        // Keep standard item/location default dimensions; explicit production
        // values have final precedence. Validate updates shortcut dimension fields.
        DimensionSetIDs[1] := JournalLine."Dimension Set ID";
        DimensionSetIDs[2] := Header."Dimension Set ID";
        CombinedDimensionSetID := DimMgt.GetCombinedDimensionSetID(DimensionSetIDs, JournalLine."Shortcut Dimension 1 Code", JournalLine."Shortcut Dimension 2 Code");
        JournalLine.Validate("Dimension Set ID", CombinedDimensionSetID);
        Tracking.RegisterJournalLine(JournalLine, Header."Document No.", ProdLine."Line No.", 0, 0);
        JournalLine.Insert(true);
        Tracking.CaptureSystemID(JournalLine);
    end;

    procedure PostAllOpen(FromDate: Date; ToDate: Date)
    var
        ProdHeader: Record "Production Entry Header";
        HeaderTemp: Record "Production Entry Header" temporary;
        Count: Integer;
    begin
        if (FromDate = 0D) or (ToDate = 0D) then
            Error('A valid from/to date range is required.');
        if FromDate > ToDate then
            Error('From Date must be before or equal to To Date.');
        ProdHeader.SetRange(Posted, false);
        ProdHeader.SetRange(Cancelled, false);
        ProdHeader.SetRange("Record Kind", ProdHeader."Record Kind"::Production);
        ProdHeader.SetRange("Production Date", FromDate, ToDate);
        if ProdHeader.FindSet() then
            repeat
                HeaderTemp.Init();
                HeaderTemp."Document No." := ProdHeader."Document No.";
                HeaderTemp.Insert(false);
            until ProdHeader.Next() = 0;
        if HeaderTemp.FindSet() then
            repeat
                if ProdHeader.Get(HeaderTemp."Document No.") then begin
                    Post(ProdHeader);
                    Count += 1;
                end;
            until HeaderTemp.Next() = 0;
        Message('%1 production document(s) sent to the item journal.', Count);
    end;
    local procedure ValidateCorrectionSource(Header: Record "Production Entry Header")
    var
        Original: Record "Production Entry Header";
        Reversal: Record "Production Entry Header";
        Tracking: Codeunit "Production Posting Tracking";
        OtherCorrection: Record "Production Entry Header";
    begin
        if Header."Corrects Document No." = '' then
            exit;
        OtherCorrection.SetRange("Corrects Document No.", Header."Corrects Document No.");
        OtherCorrection.SetRange(Cancelled, false);
        OtherCorrection.SetRange("Reversed By Document No.", '');
        OtherCorrection.SetFilter("Document No.", '<>%1', Header."Document No.");
        if OtherCorrection.FindFirst() then
            Error('Another active correction %1 already exists for the same source.', OtherCorrection."Document No.");
        Original.Get(Header."Corrects Document No.");
        if Original.Cancelled then
            exit;
        Original.TestField("Reversed By Document No.");
        Reversal.Get(Original."Reversed By Document No.");
        if Tracking.StateForDocument(Reversal."Document No.") <> "Production Posting State"::Posted then
            Error('Post the original source reversal before sending its corrected production.');
    end;
}
