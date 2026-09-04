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

# A filled card is excluded from the pair test above, which means a card can run
# into the kicker without anything noticing. It did, twice. So find the kicker
# itself on each slide and test everything else against its actual rectangle,
# rather than against a guessed band: slides with no kicker must not be flagged.
z2 = zipfile.ZipFile('Curb-Cut.pptx')
for si, name in enumerate(slides, 1):
    if only and si not in only:
        continue
    d = minidom.parseString(z2.read(name))
    boxes = []
    for sp in d.getElementsByTagName('p:sp'):
        off = sp.getElementsByTagName('a:off'); ext = sp.getElementsByTagName('a:ext')
        if not off or not ext:
            continue
        boxes.append((
            int(off[0].getAttribute('x'))/EMU, int(off[0].getAttribute('y'))/EMU,
            int(ext[0].getAttribute('cx'))/EMU, int(ext[0].getAttribute('cy'))/EMU,
            ''.join(t.firstChild.nodeValue for t in sp.getElementsByTagName('a:t')
                    if t.firstChild).strip()))
    # the kicker is the wide italic line the deck puts at y=6.28
    kick = [b for b in boxes if abs(b[1] - 6.28) < 0.02 and b[2] > 11]
    if not kick:
        continue
    kx, ky, kw, kh, _ = kick[0]
    for x, y, w, h, txt in boxes:
        if (x, y, w, h) == (kx, ky, kw, kh):
            continue
        oy = min(y + h, ky + kh) - max(y, ky)
        ox = min(x + w, kx + kw) - max(x, kx)
        if oy > 0.04 and ox > 0.04:
            print('  s%-2d overlaps its kicker by %.2f" :: "%s"' % (si, oy, txt[:38]))
            flags += 1

print('overlap flags:', flags)
