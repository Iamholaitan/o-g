// -----------------------------------------------------------------------------
// Product Inventory Position (FR-30)
// Quantity and value by location and item, as of a selected date.
// Ties to standard BC Item Ledger data; custom layout only. Filter on the
// request page by Item, Location Code and Posting Date to get the position.
// -----------------------------------------------------------------------------
report 70092 "Product Inventory Position"
{
    Caption = 'Product Inventory Position';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            column(PostingDate; ItemLedgerEntry."Posting Date")
            {
            }
            column(ItemNo; ItemLedgerEntry."Item No.")
            {
            }
            column(LocationCode; ItemLedgerEntry."Location Code")
            {
            }
            column(EntryType; ItemLedgerEntry."Entry Type")
            {
            }
            column(Quantity; ItemLedgerEntry.Quantity)
            {
            }
            column(UnitOfMeasureCode; ItemLedgerEntry."Unit of Measure Code")
            {
            }
            column(CostAmountActual; ItemLedgerEntry."Cost Amount (Actual)")
            {
            }
        }
    }
}
