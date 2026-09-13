// -----------------------------------------------------------------------------
// O&G BOE Conversion (FR-02, FR-13)
// Converts a production line quantity to the Default BOE Unit of Measure by
// calling the standards-based conversion against the item's Item Units of
// Measure setup. No custom conversion factor table is used.
// -----------------------------------------------------------------------------
codeunit 70071 "O&G BOE Conversion"
{

    procedure ConvertToBOE(ItemNo: Code[20]; Quantity: Decimal; FromUnitOfMeasure: Code[10]; DefaultBOEUnitOfMeasure: Code[10]; var BOEQuantity: Decimal): Boolean
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        BasePerFromUOM: Decimal;
        BasePerBOEUOM: Decimal;
        BaseQuantity: Decimal;
    begin
        if Quantity = 0 then begin
            BOEQuantity := 0;
            exit(false);
        end;

        if not Item.Get(ItemNo) then
            Error('Item %1 does not exist.', ItemNo);

        // Quantity of base UOM units represented by the line quantity.
        if FromUnitOfMeasure = Item."Base Unit of Measure" then
            BasePerFromUOM := 1
        else begin
            if not ItemUnitOfMeasure.Get(ItemNo, FromUnitOfMeasure) then
                Error('Unit of measure %1 is not defined on item %2.', FromUnitOfMeasure, ItemNo);
            BasePerFromUOM := ItemUnitOfMeasure."Qty. per Unit of Measure";
        end;
        BaseQuantity := Quantity * BasePerFromUOM;

        // Quantity of base UOM units that make up one BOE (alternate UOM factor).
        if DefaultBOEUnitOfMeasure = Item."Base Unit of Measure" then
            BasePerBOEUOM := 1
        else begin
            if not ItemUnitOfMeasure.Get(ItemNo, DefaultBOEUnitOfMeasure) then begin
                // No BOE UOM on this item (e.g. produced water): it contributes 0 BOE
                // instead of stopping the whole posting.
                BOEQuantity := 0;
                exit(false);
            end;
            BasePerBOEUOM := ItemUnitOfMeasure."Qty. per Unit of Measure";
        end;

        BOEQuantity := Round(BaseQuantity / BasePerBOEUOM, 0.001);
        exit(true);
    end;
}
