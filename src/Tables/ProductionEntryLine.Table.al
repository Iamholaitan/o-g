// -----------------------------------------------------------------------------
// Production Entry Line (FR-11-16). Validation belongs on the table so every
// entry surface uses the same reservoir defaults and calculations.
// Posted-source immutability is also enforced by Production Entry Guard.
// -----------------------------------------------------------------------------
table 70005 "Production Entry Line"
{
    Caption = 'Production Entry Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
            TableRelation = "Production Entry Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
            TableRelation = Item;
            trigger OnValidate()
            var
                Item: Record Item;
            begin
                GetOpenHeader();
                if Rec."Item No." = '' then begin
                    Rec."Item Description" := '';
                    Rec."Unit of Measure Code" := '';
                    Rec."Net Quantity" := 0;
                    Rec."BOE Quantity" := 0;
                    exit;
                end;
                Item.Get(Rec."Item No.");
                Item.TestField(Blocked, false);
                Rec."Item Description" := Item.Description;
                if Rec."Item No." <> xRec."Item No." then begin
                    Rec."Unit of Measure Code" := '';
                    Rec."Location Code" := '';
                    Rec."BS&W %" := 0;
                end;
                Helper.CalcLine(Rec, Header);
            end;
        }
        field(4; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Gross Quantity';
            DataClassification = ToBeClassified;
            MinValue = 0;
            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = ToBeClassified;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(7; "BS&W %"; Decimal)
        {
            Caption = 'BS&W %';
            DataClassification = ToBeClassified;
            MinValue = 0;
            MaxValue = 100;
            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(8; "Net Quantity"; Decimal)
        {
            Caption = 'Net Quantity';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(9; "BOE Quantity"; Decimal)
        {
            Caption = 'BOE Quantity';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
            TableRelation = Location;
            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
    }

    keys
    {
        key(PrimaryKey; "Document No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "BOE Quantity";
        }
    }

    trigger OnInsert()
    begin
        GetOpenHeader();
        Rec.TestField("Item No.");
        if Rec."Line No." = 0 then
            Rec."Line No." := Helper.NextProductionLineNo(Rec."Document No.");
        Helper.CalcLine(Rec, Header);
    end;

    trigger OnModify()
    begin
        Recalculate();
    end;

    var
        Header: Record "Production Entry Header";
        Helper: Codeunit "Production Entry Helper";

    local procedure GetOpenHeader()
    begin
        Rec.TestField("Document No.");
        Header.Get(Rec."Document No.");
        Header.TestOpen();
        Header.TestField("Reservoir Code");
    end;

    local procedure Recalculate()
    begin
        GetOpenHeader();
        Rec.TestField("Item No.");
        Helper.CalcLine(Rec, Header);
    end;
}
