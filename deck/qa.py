import zipfile, re
from xml.dom import minidom
z = zipfile.ZipFile('Curb-Cut.pptx'); EMU = 914400
slides = sorted((n for n in z.namelist() if re.match(r'ppt/slides/slide\d+\.xml$', n)),
                key=lambda s: int(re.findall(r'\d+', s)[0]))
issues = 0
for si, s in enumerate(slides, 1):
    d = minidom.parseString(z.read(s))
    for sp in d.getElementsByTagName('p:sp'):
        off = sp.getElementsByTagName('a:off'); ext = sp.getElementsByTagName('a:ext')
        if not off or not ext: continue
        x = int(off[0].getAttribute('x'))/EMU; y = int(off[0].getAttribute('y'))/EMU
        w = int(ext[0].getAttribute('cx'))/EMU; h = int(ext[0].getAttribute('cy'))/EMU
        txt = ''.join(t.firstChild.nodeValue for t in sp.getElementsByTagName('a:t') if t.firstChild)
        if not txt.strip(): continue
        szs = [int(r.getAttribute('sz'))/100 for r in sp.getElementsByTagName('a:rPr') if r.getAttribute('sz')]
        pt = max(szs) if szs else 18
        cpl = max(1, int((w*72)/(pt*0.5)))
        lines = max(1, -(-len(txt)//cpl))
        need = lines*pt*1.25/72
        if x < 0 or y < 0 or x+w > 13.35 or y+h > 7.55:
            print('  s%d: OFF-SLIDE x=%.2f y=%.2f w=%.2f h=%.2f :: %s' % (si,x,y,w,h,txt[:46])); issues += 1
        elif need > h*1.35:
            print('  s%d: OVERFLOW? h=%.2f" need~%.2f" @%gpt :: %s' % (si,h,need,pt,txt[:56])); issues += 1
print('slides: %d | flags: %d' % (len(slides), issues))
