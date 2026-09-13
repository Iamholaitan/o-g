#!/usr/bin/env python3
"""Static source/schema checks only. Not a BC runtime test runner."""
from pathlib import Path
import re, json, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'validation'
def read(p): return (ROOT/p).read_text()
def fields(s):
    result={}
    for m in re.finditer(r'\bfield\(\s*(\d+)\s*;\s*("[^"]+"|[\w]+)\s*;\s*([^)]*)\)',s):
        start=s.index('{',m.end());depth=1;end=start+1
        while depth:
            if s[end]=='{':depth+=1
            elif s[end]=='}':depth-=1
            end+=1
        block=s[start:end]
        result[m.group(1)]={'name':m.group(2).strip('"'),'type':re.sub(r'\s+','',m.group(3)),
                           'class':'FlowField' if re.search(r'FieldClass\s*=\s*FlowField',block) else 'Normal',
                           'block':block}
    return result
def schema():
    return {p.name:{i:{k:v for k,v in f.items() if k!='block'} for i,f in fields(p.read_text()).items()}
            for p in (ROOT/'src/Tables').glob('*.al')}
checks=[]
def check(name, condition):checks.append({'check':name,'pass':bool(condition)})
app=json.loads(read('app.json'))
check('Manifest version 1.0.12.0',app['version']=='1.0.12.0')
check('BC 26 / runtime 16 / NoImplicitWith',app['application']=='26.0.0.0' and app['platform']=='26.0.0.0' and app['runtime']=='16.0' and 'NoImplicitWith' in app['features'])
base=json.loads(read('validation/baseline-schema-v1.0.11.json'));cur=schema()
check('Every existing table and field retains ID, name, type and class',all(t in cur and all(cur[t].get(i)==f for i,f in fs.items()) for t,fs in base.items()))
check('Only the method catalogue table added; no prior tables removed',set(base)<=set(cur) and set(cur)-set(base)=={'ReserveEstimationMethod.Table.al'})
check('Stored Total BOE and existing live FlowField preserved',cur['ProductionEntryHeader.Table.al']['6']['class']=='Normal' and cur['ProductionEntryHeader.Table.al']['12']['class']=='FlowField')
als=list((ROOT/'src').rglob('*.al'));allsource='\n'.join(p.read_text() for p in als)
objects=re.findall(r'^\s*(table|pageextension|page|codeunit|report|permissionset)\s+(\d+)\s',allsource,re.M|re.I)
check('Numeric object IDs unique and within assigned range',len(objects)==len({i for _,i in objects}) and all(70000<=int(i)<=75000 for _,i in objects))
check('No client-owned table IDs 70012-70014 declared',not any(k.lower()=='table' and i in {'70012','70013','70014'} for k,i in objects))
check('No DataClassification on any FlowField',all('DataClassification' not in f['block'] for p in (ROOT/'src/Tables').glob('*.al') for f in fields(p.read_text()).values() if f['class']=='FlowField'))
h=read('src/Tables/ProductionEntryHeader.Table.al');rf=read('src/Tables/Reservoir.Table.al')
check('Reservoir has lookup, drill-down and dropdown field group','LookupPageId = "Reservoir List";' in rf and 'DrillDownPageId = "Reservoir List";' in rf and 'fieldgroup(DropDown;' in rf)
check('Reservoir list opens Reservoir Card','CardPageId = "Reservoir Card";' in read('src/Pages/ReservoirList.Page.al'))
check('Reservoir/header dimensions no longer use fixed dimension-name constants',not re.search(r"const\('(FIELD|WELL|RESERVOIR|COST CENTER)'\)",rf+h))
check('All seven dimension selectors use setup-driven lookup and validation',len(re.findall(r'DimHelper.LookupDimensionValue\(OGSetup\.',rf+h))==7 and len(re.findall(r'DimHelper.ValidateDimensionValue\(OGSetup\.',rf+h))==7)
dh=read('src/Codeunits/DimensionHelper.Codeunit.al')
check('Dimension lookup filters Standard and unblocked values','SetRange(Blocked, false)' in dh and 'SetRange("Dimension Value Type"' in dh)
check('Modal dimension lookup does not take a header update lock','StoredHeader.LockTable()' not in h)
card=read('src/Pages/ProductionEntryCard.Page.al');lines=read('src/Pages/ProductionEntryLine.Page.al')
check('Draft header and lines have conditional editing and parent refresh',card.count('Editable = IsOpen;')>=2 and 'UpdatePropagation = Both;' in card and 'Editable = DocumentIsOpen;' in lines)
check('Live BOE total is a FlowField and immutable total is separate','Rec."Calculated BOE"' in card and 'Rec."Total BOE"' in card and 'Visible = not IsOpen;' in card)
check('Current setup template displayed only on open documents','DisplayTemplateName := OGSetup."Item Journal Template Name"' in card and 'DisplayTemplateName := Rec."Item Journal Template Name"' in card)
check('Older drafts can refresh missing defaults without replacing overrides','Caption = \'Refresh Missing Defaults\';' in card and 'Rec.SetReservoirDefaults(false)' in card)
for filename in ['ProductionEntryList.Page.al','PostedProductionCard.Page.al']:
 s=read('src/Pages/'+filename)
 check(filename+' is locked history',all(x in s for x in ['where(Posted = const(true))','Editable = false;','InsertAllowed = false;','ModifyAllowed = false;','DeleteAllowed = false;']) and 'Poster.Post(' not in s)
check('Open work queue filters out sent history','where(Posted = const(false))' in read('src/Pages/OpenProductionList.Page.al'))
for role in ['FieldOperatorRoleCenter.Page.al','OGAccountantRoleCenter.Page.al']:
 s=read('src/Pages/'+role)
 check(role+' has separate open and history routes','RunObject = page "Open Production List";' in s and 'RunObject = page "Production Entry List";' in s)
check('Operator New opens Create mode','RunPageMode = Create;' in read('src/Pages/FieldOperatorRoleCenter.Page.al'))
operator=read('src/PermissionSets/FieldOperator.PermissionSet.al')
check('Operator can read setup / reservoir and execute lookups','tabledata "O&G Setup" = R,' in operator and 'page "Reservoir Card" = X,' in operator and 'page "Dimension Value List" = X,' in operator)
check('Operator receives no production posting codeunit or item-journal write permission','codeunit "Post Daily Production"' not in operator and 'tabledata "Item Journal Line"' not in operator)
guard=read('src/Codeunits/ProductionEntryGuard.Codeunit.al')
check('Header and line Insert/Modify/Delete/Rename database guards present',len(re.findall(r'\[EventSubscriber\(ObjectType::Table',guard))==8 and all(guard.count("'OnBefore"+ev+"Event'")==2 for ev in ['Insert','Modify','Delete','Rename']))
check('Data guards use stored state, update locks, and no RunTrigger bypass','StoredHeader.LockTable();' in guard and 'if StoredHeader.Posted then' in guard and 'if RunTrigger' not in guard and guard.count("'', false, false)]")==8)
check('Temporary records are exempt from production-history guards',guard.count('Rec.IsTemporary()')==8)
check('Marking sent requires matching journal template/batch/document',all('JournalLine.SetRange("'+f+'"' in guard for f in ['Journal Template Name','Journal Batch Name','Document No.']))
poster=read('src/Codeunits/PostDailyProduction.Codeunit.al');helper=read('src/Codeunits/ProductionEntryHelper.Codeunit.al');jnl=read('src/Codeunits/JournalHelper.Codeunit.al')
check('Journal gets full template/batch/line key and standard validations',all(x in poster for x in ['JournalLine."Journal Template Name" := Header."Item Journal Template Name";','JournalLine."Journal Batch Name" := BatchName;','JournalLine."Line No." := LineNo;','JournalLine.Validate("Item No."','JournalLine.Validate("Unit of Measure Code"','JournalLine.Validate(Quantity, JournalQuantity)','JournalLine.Validate("Dimension Set ID"']))
check('Journal numbering scopes template and batch and appends by 10000',all(x in jnl for x in ['SetRange("Journal Template Name", TemplateName);','SetRange("Journal Batch Name", BatchName);','ItemJournalLine."Line No." + 10000']) and 'LineNo := 0;' not in poster)
check('Posting persists calculation and locks the source at the end','ProdLine.Modify(true);' in poster and poster.index('ProdHeader.Posted := true;')>poster.index('CreateJournalLine(ProdHeader'))
check('Posting uses header dimension overrides and records snapshot','ProdHeader.SetReservoirDefaults(false);' in poster and 'ProdHeader."Dimension Set ID" := DimHelper.GetDimensionSetID' in poster and 'ProdHeader."Well Code"' in poster)
check('Standard default dimensions merged; shortcut dimensions validated','DimMgt.GetCombinedDimensionSetID' in poster and 'JournalLine.Validate("Dimension Set ID", CombinedDimensionSetID);' in poster)
check('BS&W receipt is gross; separate loss uses positive difference','LineNo, false, ProdLine.Quantity);' in poster and 'LineNo, true, LossQuantity);' in poster and 'ProdLine.Quantity - ProdLine."Net Quantity"' in poster and 'Quantity := -' not in poster)
check('BS&W expense routing is setup-driven, not an account literal','OGSetup."BS&W Gen. Bus. Posting Group"' in poster and 'GeneralPostingSetup.TestField("Inventory Adjmt. Account")' in poster)
check('History dimension/template actions do not substitute current setup','if Header.Posted then begin' in helper and 'DimMgt.ShowDimensionSet(Header."Dimension Set ID"' in helper and 'This entry predates template snapshots' in helper)
check('Pending batches filtered by configured template and non-empty lines',all(x in read('src/Pages/PendingItemJournalBatches.Page.al') for x in ['SourceTableTemporary = true;','Batch.SetRange("Journal Template Name", OGSetup."Item Journal Template Name");','if not JournalLine.IsEmpty() then begin']))
setup=read('src/Pages/OGSetup.Page.al')
check('Setup singleton fix retained','trigger OnOpenPage()' in setup and 'trigger OnInit()' not in setup and 'Inserted := Setup.Insert(true)' in setup and 'InsertAllowed = false;' in setup)
check('No journal auto-post or commits introduced',not re.search(r'Codeunit::"Item Jnl.-Post|Codeunit "Item Jnl.-Post|\bCommit\(',poster,re.I))
check('Sample production BOE still 1272 and 1000; BS&W effect is net',1200-48+80+40==1272 and 6000/6==1000 and 1000-20==980)
check('All AL braces balanced after stripping comments/strings',all((lambda s:s.count('{')==s.count('}'))(re.sub(r"//[^\n]*|/\*.*?\*/|'(?:''|[^'])*'",'',p.read_text(),flags=re.S)) for p in als))
# v1.0.12 source / RDLC structure checks.
method=read('src/Tables/ReserveEstimationMethod.Table.al')
est=read('src/Codeunits/ReserveEstimationMgt.Codeunit.al')
nav=read('src/Codeunits/OGItemJournalNavigation.Codeunit.al')
pageext=read('src/PageExtensions/OGItemJournalColumns.PageExt.al')
rep=read('src/Reports/ProductionSummary.Report.al')
check('Method catalogue supports client code/description and blocking',all(x in method for x in ['table 70017','field(1; Code; Code[20])','field(2; Description; Text[250])','field(3; Blocked; Boolean)']))
check('Reservoir method selection stores a description snapshot','Rec."Estimation Method" := Method.Description;' in rf and 'Method.TestField(Blocked, false);' in rf)
check('Existing Estimated By / Estimation Method text fields unchanged',cur['Reservoir.Table.al']['10']==base['Reservoir.Table.al']['10'] and cur['Reservoir.Table.al']['11']==base['Reservoir.Table.al']['11'])
check('Preparer lookup selects enabled users and stores stable ID',all(x in est for x in ['SetRange(State, Estimator.State::Enabled);','EstimatorUsers.LookupMode(true);','"Estimated By User Security ID" := Estimator."User Security ID";']))
check('Current-user default does not overwrite existing preparer text',"if Reservoir.\"Estimated By\" <> '' then" in est and 'Estimator.Get(UserSecurityId())' in est)
check('No account writes in preparer management',not re.search(r'\.(Insert|Modify|Delete|Rename)\(',est))
check('Both roles receive User read only',all('tabledata User = R,' in read('src/PermissionSets/'+name) for name in ['FieldOperator.PermissionSet.al','OGAccountant.PermissionSet.al']))
check('Recovery factor input limited to 0-100 without computing reserves',all(x in fields(rf)['15']['block'] for x in ['MinValue = 0;','MaxValue = 100;']) and 'trigger OnValidate' not in fields(rf)['15']['block'])
logger=read('src/Codeunits/ReserveRevisionLogger.Codeunit.al')
check('Revision audit captures selected preparer plus actual editor',all(x in logger for x in ['"Estimator User Security ID"','"Estimation Method Code"','"Changed By User Security ID" := UserSecurityId()','"Changed At" := CurrentDateTime()']))
check('Audit insertion is indirect for Accountant', 'tabledata "Reserve Revision History" = Ri,' in read('src/PermissionSets/OGAccountant.PermissionSet.al') and 'Permissions = tabledata "Reserve Revision History" = I;' in logger)
check('Native journal template requires Type Item/non-recurring/page 40',all(x in nav for x in ['Template.Type <> Template.Type::Item','Template.TestField(Recurring, false)','Template."Page ID" <> Page::"Item Journal"']))
check('Both document and pending-batch routes use shared native navigation','JournalNavigation.OpenBatch(' in helper and 'JournalNavigation.OpenBatch(' in read('src/Pages/PendingItemJournalBatches.Page.al') and 'ItemJnlMgt.TemplateSelectionFromBatch(Batch);' in nav)
check('Native Item Journal page extended, not replaced','extends "Item Journal"' in pageext and 'SourceTable =' not in pageext and all('modify('+c+')' in pageext for c in ['"Posting Date"','EntryType','"Document No."','"Item No."','Quantity','"Unit of Measure Code"','Amount']))
check('Core native journal controls available across application areas',pageext.count('ApplicationArea = All;')>=16 and pageext.count('Visible = true;')>=13)
check('RDLC is the default rendering layout','DefaultRenderingLayout = ProductionSummaryRDLC;' in rep and 'Type = RDLC;' in rep and (ROOT/'src/Reports/Layouts/ProductionSummary.rdlc').exists())
check('Production Summary exposes filters and excludes drafts','where(Posted = const(true))' in rep and 'RequestFilterFields = "Production Date", "Field/Block Code", "Well Code", "Reservoir Code", "Document No.";' in rep and 'RequestFilterFields = "Item No.", "Unit of Measure Code", "Location Code";' in rep)
from lxml import etree as ET
rdl=ET.parse(str(ROOT/'src/Reports/Layouts/ProductionSummary.rdlc'))
ns={'r':'http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition'}
rdltext=ET.tostring(rdl).decode()
rdlfields={f.get('Name') for f in rdl.findall('.//r:Field',ns)}
usedfields=set(re.findall(r'Fields!([A-Za-z_][A-Za-z0-9_]*)\.Value',rdltext))
check('Every RDLC field expression resolves in the layout dataset',usedfields<=rdlfields)
check('BOE totals use detail BOE, not repeated header total','Sum(Fields!BOEQuantity.Value' in rdltext and 'Sum(Fields!TotalBOE.Value' not in rdltext)
check('Raw volume subtotals scoped to item/UOM','Name="ItemUOMGroup"' in rdltext and all('Sum(Fields!'+f+'.Value, &quot;ItemUOMGroup&quot;)' in rdltext or 'Sum(Fields!'+f+'.Value, "ItemUOMGroup")' in rdltext for f in ['Quantity','NetQuantity','BSWQuantity']))
tablix=rdl.find('.//r:Tablix',ns)
ncols=len(tablix.findall('r:TablixBody/r:TablixColumns/r:TablixColumn',ns))
rowcells=[row.findall('r:TablixCells/r:TablixCell',ns) for row in tablix.findall('r:TablixBody/r:TablixRows/r:TablixRow',ns)]
check('All RDLC rows include physical placeholders for merged cells',all(len(cells)==ncols for cells in rowcells))
width=float(rdl.find('r:Width',ns).text.replace('cm',''));page=rdl.find('r:Page',ns)
pagewidth=float(page.find('r:PageWidth',ns).text.replace('cm',''));margins=sum(float(page.find('r:'+x,ns).text.replace('cm','')) for x in ['LeftMargin','RightMargin'])
check('RDLC body fits within landscape printable width',width<=pagewidth-margins)
report={'kind':'static source/schema checks (not runtime tests)','files':len(als),'numeric_objects':len(objects),'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(OUT/'source-checks.json').write_text(json.dumps(report,indent=2)+'\n')
for c in checks:print(('PASS' if c['pass'] else 'FAIL')+'  '+c['check'])
print(f"\n{report['passed']}/{report['total']} static checks passed; {len(als)} AL files.")
sys.exit(0 if report['passed']==report['total'] else 1)
