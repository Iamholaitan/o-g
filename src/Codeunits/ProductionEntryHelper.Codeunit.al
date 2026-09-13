// -----------------------------------------------------------------------------
// Production Entry Helper (FR-11, FR-12, FR-13, FR-19)
// Shared calculation routines for production documents.
// -----------------------------------------------------------------------------
codeunit 70078 "Production Entry Helper"
{
    var
        BOEConversion: Codeunit "O&G BOE Conversion";

    procedure GetSetup(var FmaSetup: Record "O&G Setup")
    begin
        if not FmaSetup.Get('DEFAULT') then
            Error('O&G Setup is not configured. Ask an administrator to complete it (O&G Setup page) before posting production.');
    end;

    // FR-12 / FR-13: calculates Net Quantity (BS&W) and BOE Quantity on a line.
    // BS&W is configured per reservoir/item in Reservoir Product Setup; nothing
    // is hardcoded to specific products.
    procedure CalcLine(var ProdLine: Record "Production Entry Line"; Header: Record "Production Entry Header")
    var
        FmaSetup: Record "O&G Setup";
        ReservoirProduct: Record "Reservoir Product Setup";
        Item: Record Item;
        BOEQuantity: Decimal;
    begin
        Header.TestOpen();
        Header.TestField("Reservoir Code");
        ProdLine.TestField("Item No.");
        if ProdLine.Quantity < 0 then
            Error('Gross production quantity cannot be negative on line %1.', ProdLine."Line No.");
        if (ProdLine."BS&W %" < 0) or (ProdLine."BS&W %" > 100) then
            Error('BS&W percentage must be between 0 and 100 on line %1.', ProdLine."Line No.");
        if not ReservoirProduct.Get(Header."Reservoir Code", ProdLine."Item No.") then
            Error('Item %1 is not permitted on reservoir %2. Add it under Reservoir Product Setup first.', ProdLine."Item No.", Header."Reservoir Code");
        ReservoirProduct.TestField(Blocked, false);
        Item.Get(ProdLine."Item No.");
        Item.TestField(Blocked, false);
        ProdLine."Item Description" := Item.Description;
        if ProdLine."Unit of Measure Code" = '' then
            ProdLine."Unit of Measure Code" := ReservoirProduct."Default Unit of Measure Code";
        if ProdLine."Location Code" = '' then
            ProdLine."Location Code" := ReservoirProduct."Location Code";
        if ReservoirProduct."BS&W Applicable" then
            ProdLine."Net Quantity" := Round(ProdLine.Quantity * (1 - ProdLine."BS&W %" / 100), 0.001)
        else begin
            ProdLine."BS&W %" := 0;
            ProdLine."Net Quantity" := ProdLine.Quantity;
        end;
        GetSetup(FmaSetup);
        FmaSetup.TestField("Default BOE UOM Code");
        BOEConversion.ConvertToBOE(ProdLine."Item No.", ProdLine."Net Quantity", ProdLine."Unit of Measure Code", FmaSetup."Default BOE UOM Code", BOEQuantity);
        ProdLine."BOE Quantity" := BOEQuantity;
    end;

    // FR-13: header-level BOE total.
    procedure CalcHeaderTotals(var Header: Record "Production Entry Header")
    var
        ProdLine: Record "Production Entry Line";
        TotalBOE: Decimal;
    begin
        ProdLine.SetRange("Document No.", Header."Document No.");
        if not ProdLine.FindSet() then begin
            Header."Total BOE" := 0;
            exit;
        end;

        TotalBOE := 0;
        repeat
            TotalBOE += ProdLine."BOE Quantity";
        until ProdLine.Next() = 0;

        Header."Total BOE" := TotalBOE;
    end;

    // FR-19: Remaining Reserves = 1P - Cumulative Production (never negative).
    // Cumulative Production is a FlowField - calculate it before reading.
    procedure UpdateRemainingReserves(var Reservoir: Record "Reservoir")
    begin
        Reservoir.CalcFields("Cumulative Production BOE");
        Reservoir."Remaining Reserves BOE" := Reservoir."Proved Reserves (1P)" - Reservoir."Cumulative Production BOE";
        if Reservoir."Remaining Reserves BOE" < 0 then
            Reservoir."Remaining Reserves BOE" := 0;
    end;

    // Next line number for a production document (10000, 20000, ...).
    procedure NextProductionLineNo(DocumentNo: Code[20]): Integer
    var
        ProdLine: Record "Production Entry Line";
    begin
        ProdLine.SetRange("Document No.", DocumentNo);
        if ProdLine.FindLast() then
            exit(ProdLine."Line No." + 10000)
        else
            exit(10000);
    end;

    // First day of the month of PostingDate - used as period start.
    procedure PeriodStartByMonth(PostingDate: Date): Date
    begin
        exit(DMY2Date(1, Date2DMY(PostingDate, 2), Date2DMY(PostingDate, 3)));
    end;

    // Last day of the month of PostingDate - used as period end.
    procedure PeriodEndByMonth(PostingDate: Date): Date
    begin
        exit(CalcDate('+1M-1D', PeriodStartByMonth(PostingDate)));
    end;
    procedure ShowProductionDimensions(Header: Record "Production Entry Header")
    var
        OGSetup: Record "O&G Setup";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimHelper: Codeunit "Dimension Helper";
        DimMgt: Codeunit DimensionManagement;
        EntityMgt: Codeunit "O&G Entity Mgt.";
    begin
        if Header.Posted then begin
            if Header."Dimension Set ID" = 0 then begin
                Message('This history entry has no recorded production dimension snapshot. Entries generated before v1.0.11 were not backfilled. Review their original journal or ledger dimensions instead.');
                exit;
            end;
            DimMgt.ShowDimensionSet(Header."Dimension Set ID", CopyStr('Production ' + Header."Document No.", 1, 250));
            exit;
        end;
        GetSetup(OGSetup);
        DimHelper.BuildDimensionBuffer(TempDimSetEntry, OGSetup, Header."Field/Block Code", Header."Well Code", Header."Reservoir Code", Header."Cost Center Code", '');
        EntityMgt.AddEntity(TempDimSetEntry, Header."Entity Code");
        if TempDimSetEntry.IsEmpty() then begin
            Message('Select a reservoir and dimension values on the open production document first.');
            exit;
        end;
        // A temporary record is passed to the standard read-only page. Previewing
        // dimensions does not create a persistent Dimension Set or post anything.
        Page.RunModal(Page::"Dimension Set Entries", TempDimSetEntry);
    end;

    procedure OpenReservoir(Header: Record "Production Entry Header")
    var
        Reservoir: Record Reservoir;
    begin
        Header.TestField("Reservoir Code");
        Reservoir.Get(Header."Reservoir Code");
        Page.Run(Page::"Reservoir Card", Reservoir);
    end;

    procedure OpenItemJournal(Header: Record "Production Entry Header")
    var
        JournalNavigation: Codeunit "O&G Item Journal Navigation";
    begin
        Header.TestField(Posted, true);
        if Header."Item Journal Template Name" = '' then
            Error('This entry predates template snapshots (v1.0.11). Locate its original item journal by document %1 and batch %2; the current setup template must not be assumed to be the historical template.', Header."Document No.", Header."Item Journal Batch Name");
        JournalNavigation.OpenBatch(Header."Item Journal Template Name", Header."Item Journal Batch Name", Header."Document No.");
    end;
}
