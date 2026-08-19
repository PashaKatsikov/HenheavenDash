#!/usr/bin/env python3
"""Renders the game's looping background track.

The art/audio bundle the game shipped with only contained short SFX clips, so
this generates the cozy farm loop that plays under the menus and levels:
plucked (Karplus-Strong) nylon-string arpeggios over a soft pad and bass,
with a simple marimba melody on top.

The loop is seamless: the arrangement is rendered three times over and only
the middle pass is kept, so the exported audio already has the previous
pass's reverb and pad tails bleeding into it and matches what follows it.
Nothing swells or dips where the track repeats.

Usage:  python3 tool/generate_bgm.py
Output: assets/sounds/bgm_cozy_farm.m4a  (via macOS `afconvert`)

Replacing the track with a licensed one is just a matter of dropping a file
with the same name into assets/sounds/.
"""

import os
import struct
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
BPM = 88.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 8
LOOP = BARS * BAR
PASSES = 3  # render this many identical passes; keep the middle one

RNG = np.random.default_rng(20260819)


def note(name: str) -> float:
    """MIDI-style note name ('A3', 'C#5') to frequency in Hz."""
    steps = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    semitone = steps[name[0]]
    idx = 1
    if len(name) > 1 and name[1] in "#b":
        semitone += 1 if name[1] == "#" else -1
        idx = 2
    midi = semitone + 12 * (int(name[idx:]) + 1)
    return 440.0 * 2 ** ((midi - 69) / 12)


def buffer() -> np.ndarray:
    return np.zeros(int(PASSES * LOOP * SR) + 4 * SR, dtype=np.float64)


def mix(dst: np.ndarray, src: np.ndarray, at: float, gain: float = 1.0) -> None:
    start = int(at * SR)
    dst[start : start + len(src)] += src * gain


def pluck(freq: float, dur: float, damping: float = 0.9955) -> np.ndarray:
    """Karplus-Strong string - warm and nylon-like rather than twangy."""
    period = max(2, int(SR / freq))
    ring = RNG.uniform(-1.0, 1.0, period)
    ring = np.convolve(ring, np.ones(6) / 6, mode="same")  # soften the attack
    n = int(dur * SR)
    out = np.empty(n)
    idx = 0
    prev = 0.0
    for i in range(n):
        cur = ring[idx]
        out[i] = cur
        ring[idx] = damping * 0.5 * (cur + prev)
        prev = cur
        idx = (idx + 1) % period
    fade = min(n, int(0.02 * SR))
    out[-fade:] *= np.linspace(1.0, 0.0, fade)
    return out


def bell(freq: float, dur: float, decay: float = 4.5) -> np.ndarray:
    """Marimba-ish melody voice: a sine with a quick, wooden decay."""
    t = np.arange(int(dur * SR)) / SR
    env = np.exp(-decay * t)
    tone = np.sin(2 * np.pi * freq * t)
    tone += 0.22 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-decay * 3 * t)
    attack = min(len(t), int(0.006 * SR))
    env[:attack] *= np.linspace(0.0, 1.0, attack)
    return tone * env


def pad(freqs, dur: float) -> np.ndarray:
    """Slow-breathing chord bed under everything."""
    t = np.arange(int(dur * SR)) / SR
    out = np.zeros_like(t)
    for i, f in enumerate(freqs):
        for detune in (-0.12, 0.12):
            out += np.sin(2 * np.pi * (f + detune) * t + i) / (1.6 + i)
    env = np.ones_like(t)
    rise = int(0.35 * SR)
    fall = int(0.5 * SR)
    env[:rise] = np.linspace(0.0, 1.0, rise) ** 2
    env[-fall:] = np.linspace(1.0, 0.0, fall) ** 2
    return out * env / len(freqs)


def bass(freq: float, dur: float) -> np.ndarray:
    t = np.arange(int(dur * SR)) / SR
    tone = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    env = np.exp(-1.6 * t)
    attack = int(0.012 * SR)
    env[:attack] *= np.linspace(0.0, 1.0, attack)
    return tone * env


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    """One-pole lowpass - takes the digital edge off the plucks."""
    a = np.exp(-2 * np.pi * cutoff / SR)
    out = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        out[i] = acc
    return out


def dc_block(x: np.ndarray) -> np.ndarray:
    """Removes the sub-audible offset the lowpass leaves behind, which would
    otherwise eat headroom and click at the loop point."""
    out = np.empty_like(x)
    prev_in = 0.0
    prev_out = 0.0
    for i, v in enumerate(x):
        prev_out = v - prev_in + 0.9995 * prev_out
        prev_in = v
        out[i] = prev_out
    return out


def reverb(x: np.ndarray) -> np.ndarray:
    """Cheap Schroeder-style room: a few decaying taps, gently smeared."""
    out = x.copy()
    for delay_ms, gain in ((37, 0.28), (61, 0.22), (97, 0.16), (139, 0.11)):
        d = int(SR * delay_ms / 1000)
        out[d:] += x[:-d] * gain
    return out


# ── Arrangement ──────────────────────────────────────────────────────────────

# One chord per bar. Ending on C makes the wrap back to bar 1 seamless.
PROGRESSION = [
    ("C3", ["C4", "E4", "G4", "C5"]),
    ("G2", ["B3", "D4", "G4", "B4"]),
    ("A2", ["A3", "C4", "E4", "A4"]),
    ("F2", ["F3", "A3", "C4", "F4"]),
    ("C3", ["C4", "E4", "G4", "C5"]),
    ("G2", ["B3", "D4", "G4", "B4"]),
    ("F2", ["F3", "A3", "C4", "F4"]),
    ("G2", ["G3", "B3", "D4", "G4"]),
]

# Eighth-note arpeggio pattern, as indices into each bar's chord tones.
ARP = [0, 1, 2, 3, 2, 1, 2, 3]

# Simple singable melody: (bar, beat offset, note, length in beats).
MELODY = [
    (0, 0.0, "G4", 1.5), (0, 1.5, "E4", 0.5), (0, 2.0, "G4", 2.0),
    (1, 0.0, "D4", 1.0), (1, 1.0, "G4", 1.0), (1, 2.0, "B4", 2.0),
    (2, 0.0, "A4", 1.5), (2, 1.5, "G4", 0.5), (2, 2.0, "E4", 2.0),
    (3, 0.0, "F4", 1.0), (3, 1.0, "A4", 1.0), (3, 2.0, "C5", 2.0),
    (4, 0.0, "E5", 1.5), (4, 1.5, "C5", 0.5), (4, 2.0, "G4", 2.0),
    (5, 0.0, "D5", 1.0), (5, 1.0, "B4", 1.0), (5, 2.0, "G4", 2.0),
    (6, 0.0, "A4", 1.5), (6, 1.5, "C5", 0.5), (6, 2.0, "F4", 2.0),
    (7, 0.0, "B4", 1.0), (7, 1.0, "D5", 1.0), (7, 2.0, "G4", 2.0),
]


def render() -> np.ndarray:
    strings = buffer()
    pads = buffer()
    lows = buffer()
    lead = buffer()

    # Humanised timing/dynamics are drawn once for the 8-bar pattern and then
    # reused by every pass, so all passes are identical and the middle one can
    # be cut out as a perfect loop.
    feel = [
        [(RNG.normal(0.0, 0.006), max(0.2, 0.5 + 0.16 * (s % 2 == 0) + RNG.normal(0.0, 0.04)))
         for s in range(len(ARP))]
        for _ in PROGRESSION
    ]
    voices = {n: pluck(note(n), BEAT * 1.9) for _, chord in PROGRESSION for n in chord}

    for p in range(PASSES):
        for bar, (root, chord) in enumerate(PROGRESSION):
            at = (p * BARS + bar) * BAR
            mix(pads, pad([note(n) for n in chord[:3]], BAR + 0.4), at, 0.30)
            mix(lows, bass(note(root), BAR), at, 0.55)
            mix(lows, bass(note(root) * 1.5, BEAT * 1.5), at + 2 * BEAT, 0.22)
            for step, tone in enumerate(ARP):
                jitter, level = feel[bar][step]
                mix(strings, voices[chord[tone]], at + step * BEAT / 2 + jitter, level)

        for bar, beat, name, length in MELODY:
            at = (p * BARS + bar) * BAR + beat * BEAT
            mix(lead, bell(note(name), length * BEAT + 0.3), at, 0.42)

    track = (
        lowpass(strings, 3200) * 0.55
        + lowpass(pads, 1400) * 0.85
        + lowpass(lows, 700) * 0.9
        + lowpass(lead, 4200) * 0.5
    )
    track = dc_block(reverb(track))

    # Keep the middle pass: it has the previous pass bleeding into it and is
    # followed by an identical one, so its two ends already line up.
    loop_n = int(LOOP * SR)
    body = track[loop_n : 2 * loop_n].copy()

    peak = np.max(np.abs(body))
    return body / peak * 0.72 if peak > 0 else body


def write_wav(path: str, mono: np.ndarray) -> None:
    data = np.clip(mono, -1.0, 1.0)
    pcm = (data * 32767).astype(np.int16)
    stereo = np.repeat(pcm[:, None], 2, axis=1).flatten()
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(struct.pack(f"<{len(stereo)}h", *stereo))


def main() -> int:
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sounds")
    target = os.path.join(out_dir, "bgm_cozy_farm.m4a")
    audio = render()

    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "bgm.wav")
        write_wav(wav, audio)
        result = subprocess.run(
            ["afconvert", "-f", "m4af", "-d", "aac", "-b", "112000", wav, target],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(result.stderr, file=sys.stderr)
            return result.returncode

    print(f"wrote {target} ({os.path.getsize(target) / 1024:.0f} KB, {LOOP:.1f}s loop)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
