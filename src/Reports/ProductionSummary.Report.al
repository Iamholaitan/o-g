// Production Summary (FR-28): RDLC presentation of SENT production sources.
// Raw quantities are subtotalled only within the same item/UOM. Cross-product
// totals use line BOE, never the header total repeated once per detail line.
report 70090 "Production Summary"
{
    Caption = 'Production Summary';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ProductionSummaryRDLC;

    dataset
    {
        dataitem(ProdHeader; "Production Entry Header")
        {
            DataItemTableView = sorting("Production Date", "Reservoir Code") where(Posted = const(true), Cancelled = const(false));
            RequestFilterFields = "Entity Code", "Production Date", "Field/Block Code", "Well Code", "Reservoir Code", "Document No.";
            PrintOnlyIfDetail = true;

            column(EntityCode; ProdHeader."Entity Code") { }
            column(IsReversal; ProdHeader."Record Kind" = ProdHeader."Record Kind"::Reversal) { }
            column(CompanyName; CompanyDisplayName) { }
            column(ReportFilters; ReportFilterText) { }
            column(DocumentNo; ProdHeader."Document No.") { }
            column(ProductionDate; ProdHeader."Production Date") { }
            column(ReservoirCode; ProdHeader."Reservoir Code") { }
            column(FieldBlockCode; ProdHeader."Field/Block Code") { }
            column(WellCode; ProdHeader."Well Code") { }
            column(CostCenterCode; ProdHeader."Cost Center Code") { }
            column(TotalBOE; ProdHeader."Total BOE") { }
            column(Posted; ProdHeader.Posted) { }

            dataitem(ProdLine; "Production Entry Line")
            {
                DataItemTableView = sorting("Document No.", "Line No.");
                DataItemLink = "Document No." = field("Document No.");
                DataItemLinkReference = ProdHeader;
                RequestFilterFields = "Item No.", "Unit of Measure Code", "Location Code";

                column(LineNo; ProdLine."Line No.") { }
                column(ItemNo; ProdLine."Item No.") { }
                column(ItemDescription; ProdLine."Item Description") { }
                column(Quantity; ProdLine.Quantity) { }
                column(UnitOfMeasureCode; ProdLine."Unit of Measure Code") { }
                column(BSWPercent; ProdLine."BS&W %") { }
                column(BSWQuantity; ProdLine.Quantity - ProdLine."Net Quantity") { }
                column(NetQuantity; ProdLine."Net Quantity") { }
                column(BOEQuantity; ProdLine."BOE Quantity") { }
                column(LocationCode; ProdLine."Location Code") { }
            }
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(ReportScope)
                {
                    Caption = 'Report Scope';
                    field(ScopeInformation; ScopeInformationLbl)
                    {
                        ApplicationArea = All;
                        Caption = 'Included Records';
                        Editable = false;
                        MultiLine = true;
                    }
                }
            }
        }
    }

    rendering
    {
        layout(ProductionSummaryRDLC)
        {
            Type = RDLC;
            LayoutFile = 'src/Reports/Layouts/ProductionSummary.rdlc';
            Caption = 'Production Summary (RDLC)';
            Summary = 'Landscape report by field/well, with detail, per-item/UOM quantities, BS&W losses, net volumes and BOE totals.';
        }
    }

    trigger OnPreReport()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyDisplayName := CompanyName();
        if CompanyInfo.Get() then
            if CompanyInfo.Name <> '' then
                CompanyDisplayName := CompanyInfo.Name;
        ReportFilterText := 'Sent production documents only';
        if ProdHeader.GetFilters() <> '' then
            ReportFilterText += ' | ' + ProdHeader.GetFilters();
        if ProdLine.GetFilters() <> '' then
            ReportFilterText += ' | ' + ProdLine.GetFilters();
    end;

    var
        CompanyDisplayName: Text[100];
        ReportFilterText: Text;
        ScopeInformationLbl: Label 'Includes production sources already sent to the item journal, not open drafts. Sending does not confirm Item Ledger/G/L posting. Quantities are subtotalled by item and unit; BOE is the cross-product total.';
}
