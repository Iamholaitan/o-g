// Standard BC journal navigation. Opening a filtered, uninitialised Line record
// can lose the requested batch in the native page's startup logic. Use the native
// batch-entry method instead, after validating the template type and Page ID.
codeunit 70081 "O&G Item Journal Navigation"
{
    procedure ValidateTemplate(TemplateName: Code[10])
    var
        Template: Record "Item Journal Template";
    begin
        if TemplateName = '' then
            Error('Select an Item Journal Template Name in O&G Setup. Create the template in standard BC first; this extension does not create templates.');
        if not Template.Get(TemplateName) then
            Error('Item Journal template %1 does not exist. Create a non-recurring template of Type Item and select it in O&G Setup.', TemplateName);
        if Template.Type <> Template.Type::Item then
            Error('Template %1 has Type %2. O&G production uses the standard Item Journal with Type Item (positive/negative adjustments), not the Manufacturing Output Journal. Select an Item-type template in O&G Setup.', TemplateName, Template.Type);
        Template.TestField(Recurring, false);
        if Template."Page ID" <> Page::"Item Journal" then
            Error('Template %1 must open the standard Item Journal page %2. Its current Page ID is %3. Correct the template setup or select a standard Item-type template; existing journal data is not moved automatically.', TemplateName, Page::"Item Journal", Template."Page ID");
    end;

    procedure OpenBatch(TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20])
    var
        Batch: Record "Item Journal Batch";
        JournalLine: Record "Item Journal Line";
        ItemJnlMgt: Codeunit ItemJnlManagement;
    begin
        ValidateTemplate(TemplateName);
        if not Batch.Get(TemplateName, BatchName) then
            Error('Item journal batch %1 does not exist under template %2. No replacement batch was created.', BatchName, TemplateName);
        JournalLine.SetRange("Journal Template Name", TemplateName);
        JournalLine.SetRange("Journal Batch Name", BatchName);
        if DocumentNo <> '' then
            JournalLine.SetRange("Document No.", DocumentNo);
        if JournalLine.IsEmpty() then begin
            Message('No unposted item journal lines remain for document %1 in template %2, batch %3. They may have been posted or removed; check Item Ledger Entries separately. The production source remains read-only.', DocumentNo, TemplateName, BatchName);
            exit;
        end;
        // This opens the normal FULL batch on native page 40 / table 83, with the
        // native startup flags, batch selector, validation, dimensions and actions.
        // DocumentNo is an existence check, not a permanent partial-batch filter.
        ItemJnlMgt.TemplateSelectionFromBatch(Batch);
    end;
}
