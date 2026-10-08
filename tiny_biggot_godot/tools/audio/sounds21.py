"""21.3 THE SOUND OF EACH PLACE (his word, 8 Oct: "make game more alive"): every sound here is
made from scratch by this script (noise, filters and sine waves), so all of it is the game's own.
Writes assets/audio/amb/amb_<world>.wav (seamless loops) and assets/audio/se/cc_step_<floor>.wav
(footsteps). 22050 Hz mono 16 bit; Godot imports them compressed (QOA), the loops set to repeat.
Run from the project folder:  python3 tools/audio/sounds21.py
"""
import math, os, random, struct, wave

SR = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
AMB = os.path.join(ROOT, "assets", "audio", "amb")
SE = os.path.join(ROOT, "assets", "audio", "se")


# ---------- building blocks ----------
def zeros(n):
    return [0.0] * n


def white(n, rnd):
    return [rnd.uniform(-1.0, 1.0) for _ in range(n)]


def brown(n, rnd, leak=0.995):
    out, v = [], 0.0
    for _ in range(n):
        v = v * leak + rnd.uniform(-1.0, 1.0) * 0.06
        out.append(v)
    return norm(out, 1.0)


def lowpass(x, f):
    a = 1.0 - math.exp(-2.0 * math.pi * f / SR)
    out, y = [], 0.0
    for v in x:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(x, f):
    lp = lowpass(x, f)
    return [a - b for a, b in zip(x, lp)]


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def resonant(x, f_of_t, q=6.0):
    """A two-pole band-pass whose centre moves (f_of_t: sample index -> Hz)."""
    out, y1, y2 = [], 0.0, 0.0
    for i, v in enumerate(x):
        f = f_of_t(i)
        w = 2.0 * math.pi * f / SR
        r = 1.0 - w / (2.0 * q)
        y = v * (1.0 - r) + 2.0 * r * math.cos(w) * y1 - r * r * y2
        y2, y1 = y1, y
        out.append(y)
    return norm(out, 1.0)


def norm(x, peak):
    m = max(1e-9, max(abs(v) for v in x))
    return [v * peak / m for v in x]


def mix(dst, src, at=0, gain=1.0):
    n = len(dst)
    for i, v in enumerate(src):
        j = at + i
        if j >= n:
            j -= n   # wrap round: events near the end carry over into the start (a seamless loop)
        dst[j] += v * gain


def env(n, attack, decay):
    a = max(1, int(attack * SR))
    return [(i / a if i < a else math.exp(-(i - a) / (decay * SR))) for i in range(n)]


def tone(freqs, dur, decay, glide=0.0, rnd=None):
    n = int(dur * SR)
    out = zeros(n)
    for k, f in enumerate(freqs):
        ph = rnd.random() * 6.28 if rnd else 0.0
        for i in range(n):
            ff = f * (1.0 + glide * i / n)
            ph += 2.0 * math.pi * ff / SR
            out[i] += math.sin(ph) * math.exp(-i / (decay * SR)) / (k + 1)
    return fade(out)


def fade(x, a=0.0015, r=0.004):
    """A sound starts and stops without a click: a quick ramp in and out."""
    n = len(x)
    ai, ri = max(1, int(a * SR)), max(1, int(r * SR))
    return [v * min(1.0, i / ai, (n - 1 - i) / ri) for i, v in enumerate(x)]


def burst(n, rnd, lo, hi, attack, decay):
    e = env(n, attack, decay)
    return [v * g for v, g in zip(bandpass(white(n, rnd), lo, hi), e)]


def lfo(n, rate, depth, base=1.0, phase=0.0):
    return [base + depth * math.sin(2 * math.pi * rate * i / SR + phase) for i in range(n)]


def loop_fit(x, rate):
    """Round a rate so it repeats a whole number of times in the loop (no seam)."""
    secs = len(x) / SR
    return max(1, round(rate * secs)) / secs


def seam(x):
    """Make a noise bed loop without a click: blend it with itself shifted by half its length,
    each half weighted to vanish where its own ends meet (equal power, so it sounds the same)."""
    n = len(x)
    h = n // 2
    return [x[i] * math.sin(math.pi * i / n) + x[(i + h) % n] * abs(math.cos(math.pi * i / n)) for i in range(n)]


def write(path, x, peak=0.6, rms=None):
    if rms is not None:   # the loops are matched by loudness, not by their loudest moment
        r = math.sqrt(sum(v * v for v in x) / len(x))
        x = [v * rms / max(r, 1e-9) for v in x]
        m = max(abs(v) for v in x)
        if m > 0.95:
            x = [v * 0.95 / m for v in x]
    else:
        x = norm(x, peak)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in x))
    print("wrote", os.path.relpath(path, ROOT), "%.1fs" % (len(x) / SR))


# ---------- the places ----------
L = 8.0
N = int(L * SR)


def drip(rnd):
    d = tone([rnd.uniform(1300, 1900)], 0.18, 0.05, glide=-0.35, rnd=rnd)
    echo = zeros(len(d) + int(0.17 * SR))
    mix(echo, d)
    mix(echo, d, int(0.17 * SR), 0.3)
    return echo


def crackle(rnd, n_per_sec, gain):
    out = zeros(N)
    for _ in range(int(n_per_sec * L)):
        c = burst(int(0.012 * SR), rnd, 900, 5000, 0.0005, 0.003)
        mix(out, c, rnd.randrange(N), gain * rnd.uniform(0.3, 1.0))
    return out


def crickets(rnd, pitch, gain):
    out = zeros(N)
    t = rnd.uniform(0, 0.5)
    while t < L:
        for k in range(3):   # a chirp: three quick pulses
            pulse = tone([pitch], 0.012, 0.006, rnd=rnd)
            mix(out, pulse, int((t + k * 0.03) * SR), gain)
        t += rnd.uniform(0.55, 1.3)
    return out


def bell(rnd, base, gain):
    return [v * gain for v in tone([base, base * 2.01, base * 2.98, base * 4.13], 2.2, 0.7, rnd=rnd)]


def crypt(rnd):
    out = [v * 0.5 for v in seam(lowpass(brown(N, rnd), 180))]
    t = 0.4
    while t < L:
        mix(out, drip(rnd), int(t * SR), 0.5)
        t += rnd.uniform(0.9, 2.4)
    return out


def grotto(rnd):
    w = resonant(white(N, rnd), lambda i: 520 + 180 * math.sin(2 * math.pi * loop_fit(range(N), 0.12) * i / SR), 3.0)
    out = [v * 0.35 for v in seam(w)]
    mix(out, crickets(rnd, 4300, 0.5))
    mix(out, crickets(rnd, 3700, 0.35))
    return out


def rain(rnd):
    out = [v * 0.5 for v in seam(highpass(white(N, rnd), 1800))]
    for _ in range(int(40 * L)):
        mix(out, burst(int(0.01 * SR), rnd, 2500, 7000, 0.0005, 0.002), rnd.randrange(N), rnd.uniform(0.2, 0.7))
    thunder = [v * g for v, g in zip(lowpass(brown(int(3.0 * SR), rnd), 90), env(int(3.0 * SR), 0.4, 0.9))]
    mix(out, thunder, int(2.5 * SR), 1.6)
    return out


def water(rnd):
    lap = seam(bandpass(brown(N, rnd), 120, 520))
    a = lfo(N, loop_fit(lap, 0.35), 0.5, 0.6)
    out = [v * g * 0.6 for v, g in zip(lap, a)]
    t = 0.8
    while t < L:
        mix(out, drip(rnd), int(t * SR), 0.35)
        t += rnd.uniform(1.5, 3.0)
    return out


def forge(rnd):
    out = [v * 0.7 for v in seam(lowpass(brown(N, rnd), 110))]
    mix(out, crackle(rnd, 9, 0.5))
    for t in (1.1, 4.6):   # a far-off hammer on an anvil
        clang = tone([520, 1340, 2210], 0.6, 0.18, rnd=rnd)
        mix(out, clang, int(t * SR), 0.18)
    return out


def wind(rnd, chimes=True):
    f = loop_fit(range(N), 0.09)
    out = resonant(white(N, rnd), lambda i: 600 + 260 * math.sin(2 * math.pi * f * i / SR) + 120 * math.sin(2 * math.pi * f * 3 * i / SR), 5.0)
    out = seam(out)
    gust = lfo(N, loop_fit(out, 0.25), 0.4, 0.6)
    out = [v * g * 0.6 for v, g in zip(out, gust)]
    if chimes:
        mix(out, bell(rnd, 1180, 0.08), int(3.0 * SR))
    return out


def eclipse(rnd):
    out = zeros(N)
    for f in (55.0, 55.6, 82.4, 110.3):
        ff = loop_fit(range(N), f)
        for i in range(N):
            out[i] += math.sin(2 * math.pi * ff * i / SR) * 0.25
    beat = lfo(N, loop_fit(out, 0.25), 0.3, 0.7)
    out = [v * g for v, g in zip(out, beat)]
    mix(out, [v * 0.25 for v in seam(lowpass(brown(N, rnd), 300))])
    return out


def ink(rnd):
    out = [v * 0.3 for v in seam(lowpass(brown(N, rnd), 250))]
    for _ in range(int(3 * L)):
        blub = tone([rnd.uniform(110, 260)], 0.12, 0.04, glide=0.9, rnd=rnd)
        mix(out, blub, rnd.randrange(N), rnd.uniform(0.3, 0.6))
    for _ in range(3):   # paper stirring
        mix(out, burst(int(0.25 * SR), rnd, 2500, 8000, 0.05, 0.08), rnd.randrange(N), 0.15)
    return out


def library(rnd):
    out = [v * 0.2 for v in seam(bandpass(white(N, rnd), 200, 900))]
    for k in range(int(L)):   # a slow clock
        tick = tone([1900, 2600], 0.04, 0.008, rnd=rnd)
        mix(out, tick, int((k + 0.05) * SR), 0.22 if k % 2 == 0 else 0.15)
    for _ in range(2):   # a page turned somewhere
        mix(out, burst(int(0.35 * SR), rnd, 1800, 7000, 0.08, 0.1), rnd.randrange(N), 0.25)
    return out


def hearth(rnd):
    roar = seam(lowpass(brown(N, rnd), 320))
    a = lfo(N, loop_fit(roar, 0.5), 0.25, 0.75)
    out = [v * g * 0.8 for v, g in zip(roar, a)]
    mix(out, crackle(rnd, 22, 0.8))
    return out


def camp(rnd):
    out = [v * 0.2 for v in seam(lowpass(brown(N, rnd), 260))]
    mix(out, crackle(rnd, 10, 0.45))
    mix(out, crickets(rnd, 4100, 0.4))
    mix(out, crickets(rnd, 3500, 0.3))
    return out


PLACES = { "crypt": crypt, "grotto": grotto, "rain": rain, "water": water, "forge": forge, "wind": wind,
	"eclipse": eclipse, "ink": ink, "library": library, "hearth": hearth, "camp": camp }


# ---------- footsteps ----------
def step(kind, rnd):
    n = int(0.09 * SR)
    out = zeros(n)
    if kind == "stone":
        mix(out, burst(n, rnd, 900, 3500, 0.001, 0.012))
        mix(out, tone([120], 0.06, 0.02, rnd=rnd), 0, 0.6)
    elif kind == "wood":
        mix(out, tone([210, 430], 0.08, 0.025, rnd=rnd))
        mix(out, burst(n, rnd, 600, 2500, 0.001, 0.01), 0, 0.4)
    elif kind == "grass":
        mix(out, burst(n, rnd, 2000, 7000, 0.012, 0.03))
    elif kind == "snow":
        for k in range(6):
            mix(out, burst(int(0.015 * SR), rnd, 500, 2500, 0.001, 0.004), int(k * 0.011 * SR), rnd.uniform(0.5, 1.0))
    elif kind == "water":
        mix(out, burst(n, rnd, 400, 1600, 0.004, 0.035))
        mix(out, tone([rnd.uniform(500, 700)], 0.05, 0.015, glide=0.8, rnd=rnd), int(0.02 * SR), 0.3)
    elif kind == "paper":
        mix(out, burst(n, rnd, 2500, 9000, 0.005, 0.02))
        mix(out, burst(int(0.03 * SR), rnd, 3000, 9000, 0.002, 0.01), int(0.04 * SR), 0.5)
    elif kind == "metal":
        mix(out, tone([900, 2310, 3170], 0.09, 0.03, rnd=rnd))
    return fade(out)


STEPS = ["stone", "wood", "grass", "snow", "water", "paper", "metal"]


def main():
    os.makedirs(AMB, exist_ok=True)
    for i, (name, fn) in enumerate(PLACES.items()):
        rnd = random.Random(2100 + i)
        write(os.path.join(AMB, "amb_%s.wav" % name), fn(rnd), rms=0.12)
    for i, kind in enumerate(STEPS):
        rnd = random.Random(3100 + i)
        write(os.path.join(SE, "cc_step_%s.wav" % kind), step(kind, rnd), 0.7)


if __name__ == "__main__":
    main()
