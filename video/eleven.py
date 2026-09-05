#!/usr/bin/env python3
"""
One line of narration to one WAV, spoken by an ElevenLabs voice.

voice.py hands this the text on stdin and the output path in $OUT. The API key
is read from channels/.env (ELEVENLABS_API_KEY=...), which is gitignored; it is
never taken from the command line, an argument, or this file. The voice is the
one the owner chose: calm, soft and close.

    CURBCUT_TTS_CMD="python3 eleven.py" python3 voice.py
"""
import os, sys, json, subprocess, urllib.request

VOICE_ID = os.environ.get('ELEVEN_VOICE_ID', 'uIZsnBL0YK1S5j69bAih')
MODEL    = os.environ.get('ELEVEN_MODEL', 'eleven_multilingual_v2')
HERE     = os.path.dirname(os.path.abspath(__file__))
ENV      = os.path.join(HERE, '..', 'channels', '.env')

def key():
    k = os.environ.get('ELEVENLABS_API_KEY')
    if k: return k.strip()
    try:
        for line in open(ENV):
            line = line.strip()
            if line.startswith('ELEVENLABS_API_KEY=') and len(line) > 20:
                return line.split('=', 1)[1].strip().strip('"').strip("'")
    except OSError:
        pass
    sys.exit('no ELEVENLABS_API_KEY in channels/.env; add one line there and run again')

text = sys.stdin.read().strip()
out  = os.environ['OUT']
mp3  = out.replace('.wav', '.mp3')

req = urllib.request.Request(
    f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=mp3_44100_128',
    data=json.dumps({
        'text': text,
        'model_id': MODEL,
        # steady, close, a little expressive; not theatrical
        'voice_settings': {'stability': 0.55, 'similarity_boost': 0.8, 'style': 0.3, 'use_speaker_boost': True},
    }).encode(),
    headers={'xi-api-key': key(), 'content-type': 'application/json', 'accept': 'audio/mpeg'})
with urllib.request.urlopen(req, timeout=120) as r:
    open(mp3, 'wb').write(r.read())
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', mp3, '-ar', '48000', '-ac', '2', out], check=True)
