#!/usr/bin/env python3
"""Generate songs/default-jingle.wav: a short, loopable, royalty-free bell melody (no samples, pure math)."""
import math, os, struct, wave

SR = 44100
BPM = 112
BEAT = 60.0 / BPM
OUT = os.path.join(os.path.dirname(__file__), "..", "songs", "default-jingle.wav")

def hz(n): return 440.0 * 2 ** ((n - 69) / 12)

def bell(freq, dur, amp):
    n = int(SR * dur); buf = []
    for i in range(n):
        t = i / SR
        v = (math.sin(2 * math.pi * freq * t) * math.exp(-2.6 * t)
             + 0.45 * math.sin(2 * math.pi * freq * 2 * t) * math.exp(-4.5 * t)
             + 0.18 * math.sin(2 * math.pi * freq * 3 * t) * math.exp(-7 * t))
        buf.append(amp * v * min(1.0, t * 400))   # tiny attack ramp avoids clicks
    return buf

def bass(freq, dur, amp):
    n = int(SR * dur); buf = []
    for i in range(n):
        t = i / SR
        env = math.exp(-1.2 * t) * min(1.0, t * 200)
        buf.append(amp * env * (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)))
    return buf

# (midi note or None, length in beats) — C major, 4 bars of 4/4
MELODY = [
    (76,.5),(79,.5),(81,.5),(79,.5),(76,.5),(74,.5),(72,1),
    (74,.5),(76,.5),(79,.5),(76,.5),(74,.5),(72,.5),(69,1),
    (72,.5),(76,.5),(79,.5),(84,.5),(81,.5),(79,.5),(76,.5),(79,.5),
    (81,.5),(79,.5),(76,.5),(74,.5),(72,2),
]
BASS = [(48,2),(43,2),(45,2),(52,2),(41,2),(43,2),(48,2),(48,2)]

total = sum(b for _, b in MELODY) * BEAT + 1.5   # leave room for the last note's tail
mix = [0.0] * int(SR * total)

def place(buf, start):
    s = int(start * SR)
    for i, v in enumerate(buf):
        if s + i < len(mix): mix[s + i] += v

t = 0.0
for note, beats in MELODY:
    if note is not None: place(bell(hz(note), beats * BEAT + 1.2, 0.55), t)
    t += beats * BEAT
t = 0.0
for note, beats in BASS:
    place(bass(hz(note), beats * BEAT, 0.35), t)
    t += beats * BEAT

peak = max(abs(v) for v in mix) or 1.0
fade = int(SR * 0.4)
for i in range(len(mix)):
    mix[i] = mix[i] / peak * 0.8
    if i > len(mix) - fade: mix[i] *= (len(mix) - i) / fade

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in mix))
print(f"wrote {OUT} ({len(mix)/SR:.1f} s)")
