#!/usr/bin/env python3
"""
Put a voice on the film.

Reads the same scene table that cuts the picture, speaks each narration line
with the Mac's own speech engine, places each line at the second its scene
starts, and mixes the result into one track under the film. The picture is
untouched; a second file is written with the voice on it.

This is a placeholder voice and says so in its own filename. A human reading
submission/VIDEO-NARRATION.md in one unhurried take will sound like a person,
which this does not. If you have a key for a hosted voice service, set
CURBCUT_TTS_CMD to a command that takes text on stdin and writes a WAV to the
path in $OUT, and this will use it instead.

    python3 voice.py                      # Samantha, or $CURBCUT_VOICE
    say -v '?'                            # to see what voices this Mac has
"""
import os, subprocess, json, sys, shutil
import script

VOICE = os.environ.get('CURBCUT_VOICE', 'Samantha')
RATE  = int(os.environ.get('CURBCUT_RATE', '150'))     # words per minute; 175 is the default and too fast for this
FILM  = os.environ.get('CURBCUT_FILM', 'curb-cut-demo.mp4')
OUT   = os.environ.get('CURBCUT_VOICED', 'curb-cut-demo-voiced.mp4')
WORK  = 'voice'
os.makedirs(WORK, exist_ok=True)

def speak(text, path):
    """One line to one WAV. The pause markers give the sentences room."""
    custom = os.environ.get('CURBCUT_TTS_CMD')
    if custom:
        subprocess.run(custom, shell=True, input=text.encode(), env={**os.environ, 'OUT': path}, check=True)
        return
    aiff = path.replace('.wav', '.aiff')
    spoken = text.replace('. ', '. [[slnc 350]] ').replace(', ', ', [[slnc 120]] ')
    subprocess.run(['say', '-v', VOICE, '-r', str(RATE), '-o', aiff, spoken], check=True)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', aiff, '-ar', '48000', '-ac', '2', path], check=True)

def length(path):
    r = subprocess.run(['ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_format', path],
                       capture_output=True, text=True)
    return float(json.loads(r.stdout)['format']['duration'])

clips = []          # (path, start_seconds)
t = 0.0
tight = []
for i, (src, secs, _, line, _) in enumerate(script.SCENES):
    if line:
        path = os.path.join(WORK, f'{i:02d}.wav')
        speak(line, path)
        dur = length(path)
        start = t + 0.6     # a beat after the cut lands
        if dur > secs - 0.8:
            tight.append((i, src, round(dur, 1), secs))
        clips.append((path, start))
    t += secs - script.XF
total = t + script.XF

# lay every clip at its start and mix them; the film has no other audio
inputs = []; filters = []; labels = []
for n, (path, start) in enumerate(clips):
    inputs += ['-i', path]
    filters.append(f'[{n}:a]adelay={int(start*1000)}|{int(start*1000)}[a{n}]')
    labels.append(f'[a{n}]')
filters.append(''.join(labels) + f'amix=inputs={len(clips)}:normalize=0,volume=1.0,apad=whole_dur={total:.2f}[mix]')
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', *inputs, '-filter_complex', ';'.join(filters),
                '-map', '[mix]', '-t', f'{total:.2f}', os.path.join(WORK, 'narration.wav')], check=True)

# mux under the picture without re-encoding the picture
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', FILM, '-i', os.path.join(WORK, 'narration.wav'),
                '-map', '0:v', '-map', '1:a', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k', '-shortest', OUT], check=True)

print(f'voice     : {VOICE} at {RATE} wpm, {len(clips)} lines')
print(f'film      : {FILM} -> {OUT}  ({length(OUT):.1f}s, picture {total:.1f}s)')
if tight:
    print('lines that run close to or past their hold at this rate (slow the rate, or lengthen the hold in script.py):')
    for i, src, dur, secs in tight:
        print(f'  scene {i:02d} {src}: spoken {dur}s, hold {secs}s')
else:
    print('every line finishes inside its hold')
