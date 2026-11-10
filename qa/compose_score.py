"""Original 16-bar adventure cue, rendered as sample-aligned adaptive stems.

No downloaded samples: plucked strings, marimba, bass and percussion are
synthesized from deterministic partials/noise. All stems loop on the same bar.
"""
import wave
from pathlib import Path
import numpy as np

RATE = 22050
BPM = 120
BEAT = 60 / BPM
SECONDS = 16 * 4 * BEAT
N = round(SECONDS * RATE)
rng = np.random.default_rng(2026)
stems = {name: np.zeros((N, 2), np.float64) for name in ['base', 'rhythm', 'drive']}

def note_hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)

def add(stem, when, signal, gain=1, pan=0):
    at = round(when * RATE)
    end = min(N, at + len(signal))
    if at < 0 or at >= N:
        return
    signal = signal[:end-at] * gain
    left, right = np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)
    stems[stem][at:end, 0] += signal * left
    stems[stem][at:end, 1] += signal * right

def pluck(midi, length=0.48, kind='marimba'):
    t = np.arange(round(length * RATE)) / RATE
    hz = note_hz(midi)
    if kind == 'bass':
        wave_ = np.sin(2*np.pi*hz*t) + .25*np.sin(4*np.pi*hz*t) + .09*np.sin(6*np.pi*hz*t)
        env = np.exp(-t*5) * np.minimum(t*180, 1)
    elif kind == 'string':
        wave_ = sum(np.sin(2*np.pi*hz*k*t + .03*k) * np.exp(-t*(4+k*2)) / k for k in range(1, 7))
        env = np.minimum(t*140, 1)
    else:
        wave_ = np.sin(2*np.pi*hz*t)*np.exp(-t*7) + .28*np.sin(2*np.pi*hz*3.99*t)*np.exp(-t*18) + .12*np.sin(2*np.pi*hz*9.98*t)*np.exp(-t*30)
        env = np.minimum(t*500, 1)
    return wave_ * env * np.minimum((length-t)*30, 1)

chords = [(53,57,60), (50,53,57), (46,50,53), (48,52,55)]
melodies = [
    [(0,77),(.75,76),(1,74),(1.5,72),(2.5,69),(3,72),(3.5,74)],
    [(0,77),(.5,74),(1.5,72),(2,69),(3,65),(3.5,69)],
    [(0,70),(.75,74),(1,77),(2,74),(2.5,72),(3.5,70)],
    [(0,72),(.5,76),(1,79),(2,77),(2.5,76),(3,74),(3.5,72)],
]
for bar in range(16):
    chord = chords[bar % 4]
    start = bar * 4 * BEAT
    for beat in range(4):
        bass = chord[0] - 12 + (7 if beat == 2 else 0)
        add('base', start+beat*BEAT, pluck(bass,.44,'bass'), .22)
        if beat in (1,3):
            for k,note in enumerate(chord):
                add('base', start+beat*BEAT+k*.012, pluck(note+12,.36,'string'), .065, -.35)
    for timing, note in melodies[bar % 4]:
        # The second half answers the first; occasional rests keep the cue breathing.
        if bar in (7,15) and timing > 2.5:
            continue
        if bar >= 8 and timing in (0,2):
            note += 12 if bar % 4 == 0 else 0
        add('base', start+timing*BEAT, pluck(note,.52), .145, .22)
    for beat in range(4):
        # Soft hand drum, not a loud synthetic dance kick.
        t=np.arange(round(.19*RATE))/RATE
        drum=np.sin(2*np.pi*(82*t-85*t*t))*np.exp(-t*23)*np.minimum(t*350,1)
        add('rhythm',start+beat*BEAT,drum,.21 if beat%2==0 else .08,-.12)
        if beat%2:
            t=np.arange(round(.11*RATE))/RATE
            noise=rng.normal(0,1,len(t)); noise=np.convolve(noise,[.25,.5,.25],mode='same')
            add('rhythm',start+beat*BEAT,noise*np.exp(-t*42)*np.minimum(t*500,1),.12,.18)
    for eighth in range(8):
        t=np.arange(round(.055*RATE))/RATE
        noise=rng.normal(0,1,len(t)); noise=np.r_[0,np.diff(noise)]
        add('rhythm',start+(eighth*.5+.035*(eighth%2))*BEAT,noise*np.exp(-t*80)*np.minimum(t*600,1),.025,-.5 if eighth%2 else .5)
    for beat in (0.5,1.75,2.5,3.5):
        n=chord[int(beat)%3]+24
        add('drive',start+beat*BEAT,pluck(n,.22,'string'),.075,-.25)
    if bar%4==3:
        for beat in (3,3.25,3.5,3.75):
            add('drive',start+beat*BEAT,pluck(77+int((beat-3)*4),.11),.07,.35)

peak=max(np.max(np.abs(sum(stems.values()))),1e-6)
gain=min(1,.82/peak)
out=Path(__file__).resolve().parents[1]/'assets/runner/music'
out.mkdir(parents=True,exist_ok=True)
for name,audio in stems.items():
    # Very short edge fade prevents a discontinuity at the bar-aligned loop boundary.
    fade=round(.008*RATE)
    audio[:fade]*=np.linspace(0,1,fade)[:,None]
    audio[-fade:]*=np.linspace(1,0,fade)[:,None]
    data=(np.clip(audio*gain,-1,1)*32767).astype('<i2')
    with wave.open(str(out/f'{name}.wav'),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(data.tobytes())
    print(name, '32s / 16 bars / 120 BPM',data.shape)
