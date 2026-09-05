import script
def ts(x):
    h=int(x//3600); m=int(x%3600//60); s=int(x%60); ms=int(round((x-int(x))*1000))
    return '%02d:%02d:%02d,%03d' % (h,m,s,ms)
t=0.0; n=0; out=[]
for src,secs,_,line,_ in script.SCENES:
    if line:
        n+=1; a=t+0.4; b=min(t+secs-0.3, a+max(2.5, len(line.split())/140*60+1.2))
        out.append('%d\n%s --> %s\n%s\n' % (n, ts(a), ts(b), line))
    t += secs - script.XF
open('curb-cut-demo.srt','w').write('\n'.join(out))
print('srt: %d cues, last ends %s' % (n, ts(b)))
