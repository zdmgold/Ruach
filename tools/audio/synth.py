#!/usr/bin/env python3
"""Synthesises every Ruach sound effect and the music loop from code.

Original sounds, no samples and no licences. Run from the repo root:

    python3 tools/audio/synth.py

Writes app/assets/audio/<effect>.ogg (names match SoundEffect in
core/ports/device_ports.dart) and music.ogg. Needs numpy and ffmpeg.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'app', 'assets', 'audio')
RNG = np.random.default_rng(11)


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.005, release=0.1, curve=2.0):
    """Quick attack, exponential-ish release."""
    e = np.ones(n)
    a = max(1, int(SR * attack))
    e[:a] = np.linspace(0, 1, a)
    r = max(1, int(SR * release))
    r = min(r, n)
    e[-r:] *= np.linspace(1, 0, r) ** curve
    return e


def tone(freq, seconds, kind='sine', attack=0.005, release=0.15, vol=1.0):
    x = t(seconds)
    ph = 2 * np.pi * freq * x
    if kind == 'sine':
        w = np.sin(ph)
    elif kind == 'tri':
        w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == 'square':
        w = np.sign(np.sin(ph)) * 0.6
    elif kind == 'saw':
        w = 2 * (freq * x % 1) - 1
    elif kind == 'bell':
        w = (np.sin(ph) + 0.5 * np.sin(2.76 * ph) * np.exp(-x * 9)
             + 0.3 * np.sin(5.4 * ph) * np.exp(-x * 14))
        w *= np.exp(-x * 3.2)
    elif kind == 'pluck':
        w = (np.sin(ph) + 0.4 * np.sin(2 * ph) + 0.2 * np.sin(3 * ph)) * np.exp(-x * 7)
    else:
        raise ValueError(kind)
    return w * env(len(x), attack, release) * vol


def mix(parts, length=None):
    """parts: list of (start_seconds, samples)."""
    n = length or max(int(SR * s) + len(a) for s, a in parts)
    out = np.zeros(n)
    for s, a in parts:
        i = int(SR * s)
        out[i:i + len(a)] += a[:max(0, n - i)]
    return out


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    prev = 0.0
    for i, v in enumerate(x):
        prev = (1 - a) * v + a * prev
        y[i] = prev
    return y


def noise(seconds):
    return RNG.uniform(-1, 1, int(SR * seconds))


def save(name, x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    x[:8] *= np.linspace(0, 1, 8)
    x[-8:] *= np.linspace(1, 0, 8)
    pcm = (x * 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as d:
        wav = os.path.join(d, 'a.wav')
        with wave.open(wav, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        os.makedirs(OUT, exist_ok=True)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis',
                        '-q:a', '3', os.path.join(OUT, name + '.ogg')], check=True)


NOTE = {'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.0, 'A4': 440.0,
        'B4': 493.88, 'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46, 'G5': 783.99,
        'A5': 880.0, 'B5': 987.77, 'C6': 1046.5, 'E6': 1318.5, 'G6': 1568.0, 'C3': 130.81,
        'G3': 196.0, 'F3': 174.61, 'A3': 220.0, 'E3': 164.81}


def effects():
    save('tap', tone(880, 0.07, 'sine', release=0.05))
    save('countdownTick', tone(660, 0.16, 'tri', release=0.12))
    save('go', mix([(i * 0.09, tone(f, 0.35, 'tri', release=0.3))
                    for i, f in enumerate([NOTE['C5'], NOTE['E5'], NOTE['G5'], NOTE['C6']])]
                   + [(0.27, tone(NOTE['C6'] * 2, 0.5, 'bell', vol=0.4))]))
    n = int(SR * 0.7)
    sweep = lowpass(noise(0.7), 3000) * np.linspace(0.2, 1, n) * env(n, 0.05, 0.35)
    rise = np.sin(2 * np.pi * np.cumsum(np.linspace(300, 1100, n)) / SR) * env(n, 0.05, 0.4) * 0.5
    save('boost', sweep + rise)
    thud = tone(110, 0.3, 'sine', attack=0.002, release=0.28) * np.exp(-t(0.3) * 9)
    crack = lowpass(noise(0.18), 2200) * env(int(SR * 0.18), 0.001, 0.16)
    save('collision', mix([(0, thud * 1.2), (0, crack * 0.8)]))
    save('lap', mix([(0, tone(NOTE['G5'], 0.6, 'bell')), (0.14, tone(NOTE['C6'], 0.9, 'bell'))]))
    win = [('C5', 0), ('E5', .12), ('G5', .24), ('C6', .36), ('G5', .6), ('C6', .72), ('E6', .9)]
    save('finishWin', mix([(s, tone(NOTE[n], 0.7, 'tri', release=0.5)) for n, s in win]
                          + [(s, tone(NOTE[n], 1.2, 'bell', vol=0.5)) for n, s in win[3:]]
                          + [(0.9, tone(NOTE['C4'], 1.2, 'tri', release=1.0, vol=0.6))]))
    pod = [('E5', 0), ('G5', .15), ('C6', .3)]
    save('finishPodium', mix([(s, tone(NOTE[n], 0.6, 'tri', release=0.45)) for n, s in pod]
                             + [(.3, tone(NOTE['C6'], 0.9, 'bell', vol=0.5))]))
    oth = [('G4', 0), ('C5', .16), ('E5', .32)]
    save('finishOther', mix([(s, tone(NOTE[n], 0.5, 'tri', release=0.4, vol=0.8)) for n, s in oth]))
    save('star', mix([(0, tone(1320, 0.5, 'bell')), (0.06, tone(1760, 0.4, 'bell', vol=0.6))]))
    save('gift', mix([(0, tone(988, 0.12, 'square', release=0.1, vol=0.5)),
                      (0.09, tone(1319, 0.3, 'square', release=0.25, vol=0.5))]))
    up = ['C5', 'E5', 'G5', 'C6']
    save('upgrade', mix([(i * 0.08, tone(NOTE[n], 0.5, 'pluck')) for i, n in enumerate(up)]
                        + [(0.3, tone(NOTE['C6'] * 2, 0.8, 'bell', vol=0.4))]))


def music():
    """A bright 16-second loop: bass, chords, a pentatonic tune and a shaker."""
    bpm = 120
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    n = int(SR * total)
    out = np.zeros(n)

    def put(start, samples, vol=1.0):
        i = int(SR * start)
        end = min(n, i + len(samples))
        out[i:end] += samples[:end - i] * vol

    prog = [('C3', ['C4', 'E4', 'G4']), ('G3', ['B4', 'D5', 'G4']),
            ('A3', ['C5', 'E4', 'A4']), ('F3', ['C5', 'F4', 'A4'])] * 2
    for bar, (bass, chord) in enumerate(prog):
        b0 = bar * 4 * beat
        for k in range(4):
            put(b0 + k * beat, tone(NOTE[bass] * (2 if k % 2 else 1), beat * 0.9, 'tri',
                                    release=0.12), 0.5)
        for k in range(8):
            c = chord[k % 3]
            put(b0 + k * beat / 2, tone(NOTE[c], beat / 2, 'pluck', release=0.2), 0.22)
    tune = ['E5', 'G5', 'A5', 'G5', 'E5', 'D5', 'C5', 'D5',
            'E5', 'G5', 'C6', 'A5', 'G5', 'E5', 'D5', 'C5',
            'A4', 'C5', 'E5', 'D5', 'C5', 'E5', 'G5', 'E5',
            'F5', 'A5', 'G5', 'E5', 'D5', 'E5', 'C5', 'C5']
    for i, nme in enumerate(tune):
        put(i * 2 * beat, tone(NOTE[nme], beat * 1.8, 'square', attack=0.01, release=0.25), 0.16)
        put(i * 2 * beat, tone(NOTE[nme], beat * 1.8, 'sine', attack=0.01, release=0.3), 0.18)
    for k in range(bars * 8):
        hit = lowpass(noise(0.05), 9000) * env(int(SR * 0.05), 0.001, 0.045)
        put(k * beat / 2 + beat / 4, hit, 0.12 if k % 2 else 0.07)
    for k in range(bars * 4):
        thump = tone(70, 0.12, 'sine', attack=0.002, release=0.1) * np.exp(-t(0.12) * 14)
        put(k * beat, thump, 0.5)
    save('music', out, peak=0.7)


if __name__ == '__main__':
    effects()
    music()
    print('written to', os.path.abspath(OUT))
