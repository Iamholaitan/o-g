// Input-only period dialog. No SourceTable, database writes or temporary-record
// readback assumptions. Existing table 70015 is retained for schema compatibility.
page 70049 "Date Range"
{
    PageType = StandardDialog;
    Caption = 'Calculation Date Range';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Period)
            {
                field(FromDate; FromDateValue)
                {
                    ApplicationArea = All;
                    Caption = 'From Date';
                    ShowMandatory = true;
                    ToolTip = 'First Production Date to include. This filters the production document date, not merely the Item Journal posting date.';
                }
                field(ToDate; ToDateValue)
                {
                    ApplicationArea = All;
                    Caption = 'To Date';
                    ShowMandatory = true;
                    ToolTip = 'Last Production Date to include. For financial worksheets this is also the suggested posting date.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateDates();
        exit(true);
    end;

    var
        FromDateValue: Date;
        ToDateValue: Date;

    procedure SetDates(FromDate: Date; ToDate: Date)
    begin
        FromDateValue := FromDate;
        ToDateValue := ToDate;
    end;

    procedure GetDates(var FromDate: Date; var ToDate: Date)
    begin
        ValidateDates();
        FromDate := FromDateValue;
        ToDate := ToDateValue;
    end;

    procedure IsConfirmed(Result: Action): Boolean
    begin
        case Result of
            Action::OK, Action::LookupOK:
                exit(true);
            Action::Cancel, Action::LookupCancel:
                exit(false);
            else
                Error('Unexpected date-dialog result %1. No calculation was started. Please report this result.', Format(Result));
        end;
    end;

    local procedure ValidateDates()
    begin
        if (FromDateValue = 0D) or (ToDateValue = 0D) then
            Error('Enter both From Date and To Date.');
        if FromDateValue > ToDateValue then
            Error('From Date must not be after To Date.');
    end;
}
