"""Find shapes that collide on a slide.

I cannot render this deck here, so geometry is the only way to catch a text box
sitting on top of another one. Reports pairs whose rectangles intersect by more
than a hair, ignoring the deliberate case of a label placed inside its own card.
"""
import zipfile, re, sys
from xml.dom import minidom

EMU = 914400
z = zipfile.ZipFile('Curb-Cut.pptx')
slides = sorted((n for n in z.namelist() if re.match(r'ppt/slides/slide\d+\.xml$', n)),
                key=lambda s: int(re.findall(r'\d+', s)[0]))

only = set(int(a) for a in sys.argv[1:]) if len(sys.argv) > 1 else None
flags = 0

for si, name in enumerate(slides, 1):
    if only and si not in only:
        continue
    d = minidom.parseString(z.read(name))
    shapes = []
    for sp in d.getElementsByTagName('p:sp'):
        off = sp.getElementsByTagName('a:off')
        ext = sp.getElementsByTagName('a:ext')
        if not off or not ext:
            continue
        x = int(off[0].getAttribute('x'))/EMU
        y = int(off[0].getAttribute('y'))/EMU
        w = int(ext[0].getAttribute('cx'))/EMU
        h = int(ext[0].getAttribute('cy'))/EMU
        txt = ''.join(t.firstChild.nodeValue for t in sp.getElementsByTagName('a:t')
                      if t.firstChild)
        filled = bool(sp.getElementsByTagName('a:solidFill')) and not txt.strip()
        shapes.append((x, y, w, h, txt.strip(), filled))

    for i in range(len(shapes)):
        for j in range(i+1, len(shapes)):
            ax, ay, aw, ah, at, af = shapes[i]
            bx, by, bw, bh, bt, bf = shapes[j]
            # a filled shape is a card; text sitting inside it is intended
            if af or bf:
                continue
            if not at or not bt:
                continue
            ox = min(ax+aw, bx+bw) - max(ax, bx)
            oy = min(ay+ah, by+bh) - max(ay, by)
            if ox > 0.06 and oy > 0.06:
                area = ox*oy
                if area > 0.05:
                    print('  s%-2d overlap %.2f sq in :: "%s" x "%s"'
                          % (si, area, at[:34], bt[:34]))
                    flags += 1

print('overlap flags:', flags)
