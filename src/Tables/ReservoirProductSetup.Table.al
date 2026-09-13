// -----------------------------------------------------------------------------
// Reservoir Product Setup (FR-03, FR-06, FR-12)
// Configurable per-reservoir list of producible items - the produced-item mix
// varies by reservoir and over time without a code change. The BS&W indicator
// also lives here (per reservoir/item), so nothing is hardcoded to products.
// -----------------------------------------------------------------------------
table 70002 "Reservoir Product Setup"
{
    Caption = 'Reservoir Product Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Reservoir Code"; Code[20])
        {
            Caption = 'Reservoir Code';
            DataClassification = ToBeClassified;
            TableRelation = "Reservoir";
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            TableRelation = Item;
            Description = 'A producible item (crude grade, gas, condensate, or any other finished product), FR-03/FR-06.';
        }
        field(3; "Default Unit of Measure Code"; Code[10])
        {
            Caption = 'Default Unit of Measure Code';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
            Description = 'Default entry UOM for this item on this reservoir production lines (FR-11).';
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
            TableRelation = Location;
            Description = 'Default location (Wellhead / Flow Station / Tank Farm / ...) for posting, FR-08.';
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = ToBeClassified;
            Description = 'Removes the item from selection on new production lines without deleting history.';
        }
        field(6; "BS&W Applicable"; Boolean)
        {
            Caption = 'BS&W Applicable';
            DataClassification = ToBeClassified;
            Description = 'Set by the client where this item on this reservoir requires Basic Sediment & Water treatment: Net Quantity = Gross x (1 - BS&W%) (FR-12).';
        }
    }

    keys
    {
        key(PrimaryKey; "Reservoir Code", "Item No.")
        {
            Clustered = true;
        }
    }
}
