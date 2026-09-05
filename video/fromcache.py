#!/usr/bin/env python3
"""voice.py hands one narration line on stdin and an output path in $OUT.
This looks for an ElevenLabs take already generated for that exact line
(named by the md5 of the text) and converts it to the WAV voice.py expects."""
import sys, os, hashlib, subprocess
text=sys.stdin.read().strip(); out=os.environ['OUT']
SP='/private/tmp/claude-501/-Users-drashtipathak-Downloads/1de67fe8-25b2-4540-996c-f3f60771df45/scratchpad'
src=os.path.join(SP,'static','in',hashlib.md5(text.encode()).hexdigest()+'.mp3')
if not os.path.exists(src): sys.exit('no take for: '+text[:60])
subprocess.run(['ffmpeg','-y','-loglevel','error','-i',src,'-ar','48000','-ac','2',out],check=True)
