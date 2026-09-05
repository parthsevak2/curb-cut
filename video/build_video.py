import subprocess, os, json, script
FPS, W, H, GROUND = 30, 1920, 1080, '0xF2F3F4'

def clip(src, secs, mobile, out):
    d = int(secs * FPS)
    if src.endswith('.mp4'):
        # a real recording: no loop, no zoom, just conform it to the frame and
        # hold its last frame if the scene runs longer than the footage
        vf = (f"scale={W}:{H}:force_original_aspect_ratio=decrease,"
              f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:{GROUND},fps={FPS},tpad=stop_mode=clone:stop_duration={secs}")
        subprocess.run(['ffmpeg','-y','-loglevel','error','-i',src,'-vf',vf,
                        '-t',str(secs),'-r',str(FPS),'-an','-c:v','libx264','-pix_fmt','yuv420p',
                        '-crf','18',out], check=True)
        return
    base = (f"scale=-2:{H-80},pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:{GROUND}" if mobile else
            f"scale={W}:{H}:force_original_aspect_ratio=decrease,"
            f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:{GROUND}")
    vf = base + f",zoompan=z='min(zoom+0.00035,1.05)':d={d}:s={W}x{H}:fps={FPS}"
    subprocess.run(['ffmpeg','-y','-loglevel','error','-loop','1','-i',src,'-vf',vf,
                    '-t',str(secs),'-r',str(FPS),'-c:v','libx264','-pix_fmt','yuv420p',
                    '-crf','18',out], check=True)

os.makedirs('clips', exist_ok=True)
paths=[]
for i,(src,secs,mob,_,_) in enumerate(script.SCENES):
    out=f'clips/{i:02d}.mp4'; clip(src,secs,mob,out); paths.append((out,secs))

args=[]
for p,_ in paths: args += ['-i',p]
chain=[]; prev='[0:v]'; off=paths[0][1]-script.XF
for i in range(1,len(paths)):
    lbl=f'[x{i}]'
    chain.append(f'{prev}[{i}:v]xfade=transition=fade:duration={script.XF}:offset={off:.2f}{lbl}')
    prev=lbl
    if i < len(paths)-1: off += paths[i][1]-script.XF
subprocess.run(['ffmpeg','-y','-loglevel','error',*args,'-filter_complex',';'.join(chain),
                '-map',prev,'-c:v','libx264','-pix_fmt','yuv420p','-crf','19',
                '-movflags','+faststart','curb-cut-demo.mp4'], check=True)

r=subprocess.run(['ffprobe','-v','quiet','-print_format','json','-show_format','-show_streams',
                  'curb-cut-demo.mp4'],capture_output=True,text=True)
d=json.loads(r.stdout); v=[s for s in d['streams'] if s['codec_type']=='video'][0]
dur=float(d['format']['duration'])
print('duration : %d:%02d   (script says %d:%02d)' % (dur//60,dur%60,script.total()//60,script.total()%60))
print('picture  : %dx%d, %d KB' % (v['width'],v['height'],os.path.getsize('curb-cut-demo.mp4')//1024))
