#!/usr/bin/env python3
"""Regenerates force-app/main/default/pages/docs.page from the repository's
markdown so the public site carries the same documents judges are sent.
Headings are renormalised per document (the section title is h2, the
document's own levels follow without skipping), relative links become plain
text, tables keep their semantics inside a scrolling wrapper."""
import re, html, os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def inline(t):
    t=html.escape(t, quote=False)
    t=re.sub(r'!\[([^\]]*)\]\((https?://[^)]+)\)', r'<img src="\2" alt="\1" loading="lazy">', t)
    t=re.sub(r'&lt;(https?://[^&]+)&gt;', r'<a href="\1">\1</a>', t)
    t=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)', r'<a href="\2">\1</a>', t)
    t=re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', t)
    t=re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t=re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t=re.sub(r'(?<![\w*])\*([^*]+)\*(?![\w*])', r'<em>\1</em>', t)
    return t
def md(src, title):
    lines=src.split('\n')
    heads=[(len(m.group(1)),m.group(2).strip()) for l in lines for m in [re.match(r'^(#{1,6})\s+(.*)',l)] if m]
    drop_first = bool(heads) and heads[0][1].strip('#').strip().lower()==title.lower()
    levels=sorted({h[0] for h in (heads[1:] if drop_first else heads)})
    lvlmap={L:min(6,3+i) for i,L in enumerate(levels)}
    out=[]; i=0; para=[]; inlist=None; first_heading=True
    def flush():
        nonlocal para
        if para: out.append('<p>'+inline(' '.join(para))+'</p>'); para=[]
    def close_list():
        nonlocal inlist
        if inlist: out.append('</%s>'%inlist); inlist=None
    while i<len(lines):
        l=lines[i]
        if l.startswith('```'):
            flush(); close_list(); j=i+1; buf=[]
            while j<len(lines) and not lines[j].startswith('```'): buf.append(lines[j]); j+=1
            out.append('<pre>'+html.escape('\n'.join(buf), quote=False)+'</pre>'); i=j+1; continue
        m=re.match(r'^(#{1,6})\s+(.*)',l)
        if m:
            flush(); close_list(); txt=m.group(2).strip()
            if first_heading and drop_first: first_heading=False; i+=1; continue
            first_heading=False
            lvl=lvlmap.get(len(m.group(1)),3); out.append('<h%d>%s</h%d>'%(lvl,inline(txt),lvl)); i+=1; continue
        if l.strip()=='---': flush(); close_list(); out.append('<hr/>'); i+=1; continue
        if l.startswith('|'):
            flush(); close_list(); rows=[]
            while i<len(lines) and lines[i].startswith('|'): rows.append(lines[i]); i+=1
            cells=[[c.strip() for c in r.strip().strip('|').split('|')] for r in rows if not re.match(r'^\|[\s:|-]+\|$',r.strip())]
            if cells: out.append('<div class="tbl"><table><thead><tr>'+''.join('<th scope="col">'+inline(c)+'</th>' for c in cells[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+inline(c)+'</td>' for c in r)+'</tr>' for r in cells[1:])+'</tbody></table></div>')
            continue
        m=re.match(r'^\s*[-*]\s+(.*)',l)
        if m:
            flush()
            if inlist!='ul': close_list(); out.append('<ul>'); inlist='ul'
            out.append('<li>'+inline(m.group(1))+'</li>'); i+=1; continue
        m=re.match(r'^\s*\d+\.\s+(.*)',l)
        if m:
            flush()
            if inlist!='ol': close_list(); out.append('<ol>'); inlist='ol'
            out.append('<li>'+inline(m.group(1))+'</li>'); i+=1; continue
        if l.startswith('> '):
            flush(); close_list(); buf=[]
            while i<len(lines) and lines[i].startswith('>'): buf.append(lines[i][1:].strip()); i+=1
            out.append('<blockquote><p>'+inline(' '.join(buf))+'</p></blockquote>'); continue
        if not l.strip(): flush(); close_list(); i+=1; continue
        if inlist and (l.startswith('  ') or l.startswith('\t')):
            out[-1]=out[-1][:-5]+' '+inline(l.strip())+'</li>'; i+=1; continue
        close_list(); para.append(l.strip()); i+=1
    flush(); close_list(); return '\n'.join(out)
DOCS=[('README','README.md','What this is, what is live, how to verify it'),
      ('Test it yourself','submission/JUDGE-TEST-GUIDE.md','Every channel, end to end, with what came back'),
      ('What a screen reader is handed','docs/SCREEN-READER-WALK.md','A scripted walk of the ask page, step by step, and what it cannot tell you'),
      ('Technical design','submission/TECHNICAL-DESIGN.md','How it fits together, verified against the org'),
      ('Evidence','docs/EVIDENCE.md','Every public figure, its source, its denominator and its caveat'),
      ('Who this is for','docs/AUDIENCE.md','Audience and market'),
      ('Accessibility audit','docs/A11Y-SA11Y-REPORT.md','Salesforce Sa11y findings'),
      ('Decisions','docs/DECISIONS.md','Every significant call and why')]
def main():
    parts=[]; toc=[]
    for k,(title,path,blurb) in enumerate(DOCS):
        src=open(os.path.join(ROOT,path)).read(); sid='doc-%d'%k
        if path.endswith('TECHNICAL-DESIGN.md'):
            chunks=re.split(r'\n─+\n(\d+\. [^\n]+)\n─+\n', src)
            body='<pre class="tdd">'+html.escape(chunks[0].strip(),quote=False)+'</pre>'
            for a in range(1,len(chunks),2):
                body+='<h3>'+html.escape(chunks[a].strip())+'</h3><pre class="tdd">'+html.escape(chunks[a+1].strip(),quote=False)+'</pre>'
        else: body=md(src,title)
        parts.append('<section aria-labelledby="%s"><h2 id="%s">%s</h2><p class="mute">%s. Source: <code>%s</code></p>%s</section>'%(sid,sid,html.escape(title),html.escape(blurb),path,body))
        toc.append('<li><a href="#%s">%s</a></li>'%(sid,html.escape(title)))
    content=('<nav aria-label="Documents on this page"><ol>'+''.join(toc)+'</ol></nav>'+'\n'.join(parts)).replace('{!','{&#33;')
    p=os.path.join(ROOT,'force-app/main/default/pages/docs.page'); s=open(p).read()
    i=s.index('<div class="docs">')+len('<div class="docs">'); j=s.index('</div>\n</c:CurbCutShell>')
    open(p,'w').write(s[:i]+'\n'+content+'\n'+s[j:]); print('docs.page regenerated')
if __name__=='__main__': main()
