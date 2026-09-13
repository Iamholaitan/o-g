import re
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
