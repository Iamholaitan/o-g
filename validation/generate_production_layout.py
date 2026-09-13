#!/usr/bin/env python3
"""Generate the delivered RDLC. Requires lxml; no external images/fonts/scripts."""
from pathlib import Path
from decimal import Decimal
from lxml import etree as E

ROOT = Path(__file__).resolve().parents[1]
NS = 'http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition'
RD = 'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner'
def el(parent, name, text=None, **attrs):
    n = E.SubElement(parent, '{'+NS+'}'+name, **attrs)
    if text is not None: n.text = str(text)
    return n

def style(parent, *, bg=None, color='#243649', bold=False, size='8pt', align='Left', fmt=None, border=True):
    s = el(parent, 'Style')
    if border:
        b = el(s, 'BottomBorder');el(b, 'Color', '#D8E2EA');el(b, 'Style', 'Solid');el(b, 'Width', '0.4pt')
    if bg: el(s, 'BackgroundColor', bg)
    el(s, 'VerticalAlign', 'Middle')
    el(s, 'PaddingLeft', '3pt');el(s, 'PaddingRight', '3pt')
    el(s, 'PaddingTop', '3pt');el(s, 'PaddingBottom', '3pt')
    if fmt: el(s, 'Format', fmt)
    return s

counter = 0
def textbox(parent, value, *, name=None, bg=None, color='#243649', bold=False, size='8pt', align='Left', fmt=None, border=True):
    global counter
    counter += 1
    tb = el(parent, 'Textbox', Name=name or f'Textbox{counter}')
    el(tb, 'CanGrow', 'true');el(tb, 'KeepTogether', 'true')
    paragraphs = el(tb, 'Paragraphs');p = el(paragraphs, 'Paragraph');runs = el(p, 'TextRuns');run = el(runs, 'TextRun')
    el(run, 'Value', value)
    rs = el(run, 'Style');el(rs, 'FontFamily', 'Segoe UI');el(rs, 'FontSize', size);el(rs, 'Color', color)
    if bold: el(rs, 'FontWeight', 'Bold')
    if fmt: el(rs, 'Format', fmt)
    ps = el(p, 'Style');el(ps, 'TextAlign', align)
    style(tb, bg=bg, color=color, bold=bold, size=size, align=align, fmt=fmt, border=border)
    return tb

def box(items, value, name, top, left, width, height, **opts):
    tb = textbox(items, value, name=name, **opts)
    el(tb, 'Top', top);el(tb, 'Left', left);el(tb, 'Height', height);el(tb, 'Width', width)
    return tb

report = E.Element('{'+NS+'}Report', nsmap={None:NS, 'rd':RD})
el(report, 'AutoRefresh', 0)
sources = el(report, 'DataSources');source = el(sources, 'DataSource', Name='DataSource')
conn = el(source, 'ConnectionProperties');el(conn, 'DataProvider', 'SQL');el(conn, 'ConnectString', '')
E.SubElement(source, '{'+RD+'}DataSourceID').text = 'c00e083b-746c-45b9-97f3-bfe50f4f6f7b'
sets = el(report, 'DataSets');dataset = el(sets, 'DataSet', Name='DataSet_Result');fields = el(dataset, 'Fields')
fieldtypes = {
    'EntityCode':'String', 'IsReversal':'Boolean', 'CompanyName':'String', 'ReportFilters':'String', 'DocumentNo':'String', 'ProductionDate':'DateTime',
    'ReservoirCode':'String', 'FieldBlockCode':'String', 'WellCode':'String', 'CostCenterCode':'String',
    'TotalBOE':'Decimal', 'Posted':'Boolean', 'LineNo':'Int32', 'ItemNo':'String', 'ItemDescription':'String',
    'Quantity':'Decimal', 'UnitOfMeasureCode':'String', 'BSWPercent':'Decimal', 'BSWQuantity':'Decimal',
    'NetQuantity':'Decimal', 'BOEQuantity':'Decimal', 'LocationCode':'String'
}
for name, typ in fieldtypes.items():
    f = el(fields, 'Field', Name=name);el(f, 'DataField', name)
    E.SubElement(f, '{'+RD+'}TypeName').text = 'System.'+typ
query = el(dataset, 'Query');el(query, 'DataSourceName', 'DataSource');el(query, 'CommandText', '')

body = el(report, 'Body');items = el(body, 'ReportItems')
box(items, '=First(Fields!ReportFilters.Value, "DataSet_Result")', 'AppliedFilters', '0cm', '0cm', '26.5cm', '0.7cm', size='8pt', border=False, bg='#F0F4F7')

# Eleven columns. Field/Well are group headers rather than repeated on every row.
columns = [
 ('Date','ProductionDate','1.9',False,'dd/MM/yyyy'),
 ('Document No.','DocumentNo','3.6',False,None),
 ('Reservoir','ReservoirCode','2.4',False,None),
 ('Item','ItemNo','3.0',False,None),
 ('Description','ItemDescription','4.2',False,None),
 ('UOM','UnitOfMeasureCode','1.2',False,None),
 ('Gross','Quantity','2.2',True,'#,##0.###'),
 ('BS&W %','BSWPercent','1.5',True,'0.##'),
 ('BS&W Qty.','BSWQuantity','2.1',True,'#,##0.###'),
 ('Net','NetQuantity','2.2',True,'#,##0.###'),
 ('BOE','BOEQuantity','2.2',True,'#,##0.###')
]
assert sum(Decimal(c[2]) for c in columns) == Decimal('26.5')
tablix = el(items, 'Tablix', Name='ProductionTable')
tb = el(tablix, 'TablixBody');cols = el(tb, 'TablixColumns')
for c in columns: el(el(cols, 'TablixColumn'), 'Width', c[2]+'cm')
rows = el(tb, 'TablixRows')

def row(height, cells):
    r = el(rows, 'TablixRow');el(r, 'Height', height);tc = el(r, 'TablixCells')
    for value, span, options in cells:
        cell = el(tc, 'TablixCell');content = el(cell, 'CellContents')
        textbox(content, value, **options)
        if span > 1:
            el(content, 'ColSpan', span)
            # RDLC requires one cell node per physical column. Spanned columns
            # have empty TablixCell placeholders, not additional CellContents.
            for _ in range(span - 1): el(tc, 'TablixCell')
    return r

row('0.7cm', [(c[0],1,dict(bg='#DFE8F0', color='#12314D', bold=True, align='Right' if c[3] else 'Left')) for c in columns])
row('0.7cm', [('="ENTITY  " & Fields!EntityCode.Value & "     |     FIELD  " & Fields!FieldBlockCode.Value & "     |     WELL  " & Fields!WellCode.Value',11,dict(bg='#173B56',color='#FFFFFF',bold=True,size='10pt'))])
row('0.62cm', [('=Fields!'+c[1]+'.Value',1,dict(bg='=IIF(RowNumber(Nothing) Mod 2 = 0, "#F5F8FA", "#FFFFFF")',align='Right' if c[3] else 'Left',fmt=c[4])) for c in columns])
sub = [('="Subtotal: " & Fields!ItemNo.Value & " / " & Fields!UnitOfMeasureCode.Value',6,dict(bg='#EDF2F6',bold=True))]
for name in ['Quantity',None,'BSWQuantity','NetQuantity','BOEQuantity']:
    sub.append(('=Sum(Fields!'+name+'.Value, "ItemUOMGroup")' if name else '',1,dict(bg='#EDF2F6',bold=True,align='Right',fmt='#,##0.###')))
row('0.67cm', sub)
row('0.72cm', [('Field / Well total — BOE only (raw quantities are not mixed)',10,dict(bg='#DDEAF1',bold=True)),('=Sum(Fields!BOEQuantity.Value, "FieldWellGroup")',1,dict(bg='#DDEAF1',bold=True,align='Right',fmt='#,##0.###'))])
row('0.85cm', [('TOTAL PRODUCED — BOE',10,dict(bg='#12314D',color='#FFFFFF',bold=True,size='10pt')),('=Sum(Fields!BOEQuantity.Value, "DataSet_Result")',1,dict(bg='#12314D',color='#FFFFFF',bold=True,size='10pt',align='Right',fmt='#,##0.###'))])

ch = el(tablix, 'TablixColumnHierarchy');cm = el(ch, 'TablixMembers')
for _ in columns: el(cm, 'TablixMember')
rh = el(tablix, 'TablixRowHierarchy');rm = el(rh, 'TablixMembers')
head = el(rm, 'TablixMember');el(head, 'KeepWithGroup', 'After');el(head, 'RepeatOnNewPage', 'true');el(head, 'FixedData', 'true')
fieldmember = el(rm, 'TablixMember');group = el(fieldmember, 'Group', Name='FieldWellGroup');gx = el(group, 'GroupExpressions')
for f in ['EntityCode','FieldBlockCode','WellCode']: el(gx, 'GroupExpression', '=Fields!'+f+'.Value')
sorts = el(fieldmember, 'SortExpressions')
for f in ['EntityCode','FieldBlockCode','WellCode']: el(el(sorts, 'SortExpression'), 'Value', '=Fields!'+f+'.Value')
fm = el(fieldmember, 'TablixMembers')
fh = el(fm, 'TablixMember');el(fh, 'KeepWithGroup', 'After');el(fh, 'RepeatOnNewPage', 'true')
itemmember = el(fm, 'TablixMember');igroup = el(itemmember, 'Group', Name='ItemUOMGroup');igx = el(igroup, 'GroupExpressions')
for f in ['ItemNo','UnitOfMeasureCode']: el(igx, 'GroupExpression', '=Fields!'+f+'.Value')
isorts = el(itemmember, 'SortExpressions')
for f in ['ItemNo','UnitOfMeasureCode']: el(el(isorts, 'SortExpression'), 'Value', '=Fields!'+f+'.Value')
im = el(itemmember, 'TablixMembers');detail = el(im, 'TablixMember');el(detail, 'Group', Name='ProductionDetails')
dsorts = el(detail, 'SortExpressions')
for f in ['ProductionDate','DocumentNo','ReservoirCode','LineNo']: el(el(dsorts, 'SortExpression'), 'Value', '=Fields!'+f+'.Value')
isub = el(im, 'TablixMember');el(isub, 'KeepWithGroup', 'Before')
fsub = el(fm, 'TablixMember');el(fsub, 'KeepWithGroup', 'Before')
el(rm, 'TablixMember')
el(tablix, 'DataSetName', 'DataSet_Result')
el(tablix, 'NoRowsMessage', 'No sent production entries match the selected filters.')
el(tablix, 'Top', '0.9cm');el(tablix, 'Left', '0cm');el(tablix, 'Height', '4.26cm');el(tablix, 'Width', '26.5cm')
el(tablix, 'Style')
box(items, 'Gross, BS&W and net quantities are subtotalled only within each item/UOM. BOE is based on net production; items without a BOE conversion contribute zero BOE.',
    'VolumeBasisNote','5.36cm','0cm','26.5cm','0.65cm',size='7.5pt',border=False,color='#586B7B')
el(body, 'Height', '6.2cm');el(body, 'Style');el(report, 'Width', '26.5cm')

page = el(report, 'Page');ph = el(page, 'PageHeader');el(ph, 'Height', '2.0cm');el(ph, 'PrintOnFirstPage', 'true');el(ph, 'PrintOnLastPage', 'true');hi = el(ph, 'ReportItems')
box(hi, '=First(Fields!CompanyName.Value, "DataSet_Result")','CompanyHeading','0cm','0cm','20cm','0.56cm',size='10pt',bold=True,border=False,color='#34566E')
box(hi, 'PRODUCTION SUMMARY','ReportHeading','0.60cm','0cm','20cm','0.85cm',size='18pt',bold=True,border=False,color='#12314D')
box(hi, 'ENTITY / FIELD / WELL / PRODUCT','ReportSubtitle','1.43cm','0cm','20cm','0.43cm',size='8pt',border=False,color='#586B7B')
box(hi, '=Globals!ExecutionTime','RunTimestamp','0.12cm','20cm','6.5cm','0.5cm',size='8pt',align='Right',fmt='dd MMM yyyy HH:mm',border=False,color='#586B7B')
box(hi, 'O&G  |  OPERATIONS','ModuleName','0.76cm','20cm','6.5cm','0.7cm',size='10pt',align='Right',bold=True,border=False,color='#1A7D98')
el(ph, 'Style')
pf = el(page, 'PageFooter');el(pf, 'Height', '0.8cm');el(pf, 'PrintOnFirstPage', 'true');el(pf, 'PrintOnLastPage', 'true');fi = el(pf, 'ReportItems')
box(fi, 'Sent-to-journal production history. This report does not confirm Item Ledger or G/L posting.', 'StatusNote','0.1cm','0cm','22cm','0.52cm',size='7.2pt',border=False,color='#586B7B')
box(fi, '="Page " & Globals!PageNumber & " of " & Globals!TotalPages','PageCount','0.1cm','22cm','4.5cm','0.52cm',size='7.5pt',align='Right',border=False,color='#586B7B')
el(pf, 'Style')
for name,value in [('PageHeight','21cm'),('PageWidth','29.7cm'),('LeftMargin','1.5cm'),('RightMargin','1.5cm'),('TopMargin','0.8cm'),('BottomMargin','0.8cm')]: el(page,name,value)
el(page, 'Style');el(report,'Language','en-GB');el(report,'ConsumeContainerWhitespace','true')
E.SubElement(report,'{'+RD+'}ReportUnitType').text='Cm'
E.SubElement(report,'{'+RD+'}ReportID').text='47b0f305-04bb-4c5a-978e-143d826a14ec'
path = ROOT/'src/Reports/Layouts/ProductionSummary.rdlc';path.parent.mkdir(parents=True,exist_ok=True)
path.write_bytes(E.tostring(report,xml_declaration=True,encoding='utf-8',pretty_print=True))
print(path)
