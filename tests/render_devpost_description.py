#!/usr/bin/env python3
"""Renders submission/devpost/Q0-project-description.txt to the HTML that is PUT to Devpost: h3 headings with icons, the six doors as a list, and images served from the public repo. Run: python3 tests/render_devpost_description.py > out.html"""
import re, html, sys, os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R='https://raw.githubusercontent.com/parthsevak2/curb-cut/main/submission/images/'
ALT={'one-in-four': 'One in four adults has a disability. About three in a hundred have told their employer. The people in between manage quietly. Curb Cut was built for them.', 'ask-no-login': 'The ask page: one box, no login, no name, and the words you never have to say why.', 'console-refusal': 'The console refusing to say what is wrong with her. There is no field for a diagnosis anywhere in this system, so nobody can be asked.', 'slack-live': 'A real Slack direct message, 5 September 2026: the app says it is automated and that Slack belongs to the employer, then lists three lighting options with usual costs, and refuses to send anything from Slack.', 'on-a-phone': 'The same conversation by text, on a basic phone with no internet: options in her own words, and a number to reply with.'}
ICON={'PROBLEM TO SOLVE': '🧱 ', 'OUR SOLUTION': '🌱 ', 'WHAT HAPPENS AFTER YOU PRESS SEND': '✔ ', 'WHAT WE CAN SHOW, NOT JUST SAY': '🔎 ', 'WHAT WE GOT WRONG, AND FIXED IN THE OPEN': '💛 ', "WHAT ISN'T DONE": '⚠ ', 'WHO THIS IS FOR': '🤍 '}
DOORS={'Web, no login': '🌐 ', 'Text CURB CUT': '📱 ', 'Voice on the same': '📞 ', 'Email.': '✉️ ', 'Slack, private': '💬 ', 'Any assistant': '🤝 '}

def render():
    src=open(os.path.join(ROOT,'submission/devpost/Q0-project-description.txt')).read().strip()
    blocks=[b.strip() for b in re.split(r'\n\s*\n',src) if b.strip()]
    out=[]
    for i,b in enumerate(blocks):
        lines=b.split('\n')
        if i==0:
            rest=re.sub(r'^Curb Cut:\s*','',b); out.append('<h3>Project Name</h3><p><strong>Curb Cut</strong> · '+html.escape(rest)+'</p>'); continue
        m=re.match(r'^\[image: ([a-z-]+)\]$',b)
        if m: out.append('<p><img src="%s%s.png" alt="%s"></p>'%(R,m.group(1),html.escape(ALT[m.group(1)],quote=True))); continue
        if b.isupper() and len(b)<60: out.append('<h3>'+ICON.get(b,'')+html.escape(b.capitalize())+'</h3>'); continue
        if any(l.startswith('- ') for l in lines):
            intro=' '.join(l.strip() for l in lines if not l.startswith('- '))
            if intro: out.append('<p>🚪 '+html.escape(intro)+'</p>')
            lis=[]
            for l in lines:
                if not l.startswith('- '): continue
                t=l[2:].strip(); pre=next((v for k,v in DOORS.items() if t.startswith(k)),'')
                lis.append('<li>'+pre+html.escape(t)+'</li>')
            out.append('<ul>'+''.join(lis)+'</ul>'); continue
        p=' '.join(l.strip() for l in lines)
        if p.startswith("There's no field for a diagnosis"): out.append('<p>🔒 '+html.escape(p)+'</p>'); continue
        if p.startswith('Watch the three-minute cut'): out.append('<p>▶ <a href="https://drive.google.com/file/d/1Loqum6Kbk1noQazJDKrrVEnHzoU3biMD/view">Watch the three-minute cut</a> · <a href="https://youtu.be/yleHLiwWRKA">The full film, 4:59, every channel live</a></p>'); continue
        if p.startswith('Try it, no login:'): out.append('<p>✿ Try it, no login: <a href="https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask">orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask</a></p>'); continue
        if p.startswith('Everything else'): out.append('<p>📖 Everything else, evidence included: <a href="https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/docs">orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/docs</a>. Code, MIT: <a href="https://github.com/parthsevak2/curb-cut">github.com/parthsevak2/curb-cut</a></p>'); continue
        out.append('<p>'+html.escape(p)+'</p>')
    return ''.join(out)
if __name__=='__main__': sys.stdout.write(render())
