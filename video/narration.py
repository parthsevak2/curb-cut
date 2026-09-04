import script
def ts(x): return '%d:%02d' % (int(x)//60, int(x)%60)
t=0.0; rows=[]
for src,secs,_,line,note in script.SCENES:
    rows.append((t,t+secs,src,line,note)); t += secs - script.XF
total = t + script.XF
L=[]
L.append('# Curb Cut, demo film. Narration script')
L.append('')
L.append('Run time **%s**. Picture is locked, and these timings are generated from the' % ts(total))
L.append('same table that cuts the film, so they cannot drift apart from it.')
L.append('')
L.append('**The film already carries its own captions and works in silence.** That is a')
L.append('choice, not a shortcut: a film about access should not assume you can hear it.')
L.append('If you do record a voice over it, keep it low and unhurried. The pictures are')
L.append('making the argument already, and a narrator pushing the feeling will undo it.')
L.append('')
L.append('Every line below fits its hold at 140 words per minute with two seconds of air.')
L.append('Where a card already carries its sentence, the direction is silence: reading a')
L.append('slide aloud to somebody who is reading it is how a film loses them.')
L.append('')
L.append('| In | Out | | Line |')
L.append('|---|---|---|---|')
for a,b,src,line,note in rows:
    kind = 'card' if src.startswith('cards/') else 'screen'
    L.append('| %s | %s | %s | %s |' % (ts(a), ts(b), kind,
             (line.replace('|','\\|') if line else '_silence_')))
L.append('')
L.append('---')
L.append('')
for a,b,src,line,note in rows:
    L.append('### %s  %s' % (ts(a), src.split('/')[-1]))
    L.append('')
    if line:
        L.append('> %s' % line)
        L.append('')
        L.append('%d words, %.0fs hold.' % (len(line.split()), b-a))
    else:
        L.append('Silence.')
    if note: L.append('')
    if note: L.append('**Direction.** %s' % note)
    L.append('')
w=sum(len(l.split()) for _,_,_,l,_ in rows)
L.append('---')
L.append('')
L.append('%d words across %s, which is %d words per minute counting the silences.'
         % (w, ts(total), w/(total/60)))
open('VIDEO-NARRATION.md','w').write('\n'.join(L)+'\n')
print('narration written,', w, 'words')
