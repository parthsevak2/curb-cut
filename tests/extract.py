import re, sys, os, json
BOX = re.compile(r'[│╭╰╮╯─┤├]')
def dedupe(name):
    t=open(f"transcripts/{name}.txt",encoding='utf-8',errors='replace').read()
    lines=[BOX.sub('',l).strip() for l in t.split('\n')]
    drop=('Start typing','New session','Starting session','UTTERANCES','...','')
    lines=[l for l in lines if l and not any(l.startswith(d) for d in drop if d)]
    out=[]
    for l in lines:
        if not out or out[-1]!=l: out.append(l)
    return out
if __name__=="__main__":
    print('\n'.join(dedupe(sys.argv[1])))
