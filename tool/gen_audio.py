"""Synthesize seamless, loopable ambient beds for The Nest.
Mono, 22.05 kHz, 16-bit WAV. Each track is crossfaded end-to-start so it loops
with no click. No external deps beyond numpy + the stdlib wave module."""
import numpy as np, wave, struct, os

SR = 22050
OUT = "assets/audio"
rng = np.random.default_rng(7)

def seamless(sig, xf=2.0):
    """Crossfade the tail into the head so the buffer loops seamlessly."""
    n = int(xf * SR)
    n = min(n, len(sig) // 2)
    head, tail = sig[:n].copy(), sig[-n:].copy()
    ramp = np.linspace(0, 1, n)
    blended = tail * (1 - ramp) + head * ramp
    body = sig[:-n].copy()
    body[:n] = blended
    return body

def norm(sig, peak=0.82):
    sig = sig - np.mean(sig)
    m = np.max(np.abs(sig)) or 1.0
    return sig / m * peak

def onepole_lp(x, a):
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y

def onepole_hp(x, a):
    return x - onepole_lp(x, a)

def save(name, sig):
    sig = norm(sig)
    data = (sig * 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"  {name:18s} {len(sig)/SR:4.1f}s  {os.path.getsize(path)//1024} KB")

def t(dur): return np.arange(int(dur*SR)) / SR

# ── Ocean waves: brown noise shaped by slow breathing swells ────────────────
def waves(dur=24):
    n = int(dur*SR)
    white = rng.standard_normal(n)
    brown = np.cumsum(white); brown = brown - onepole_lp(brown, 0.0008)  # remove drift
    brown = onepole_lp(brown, 0.05)                  # muffle to surf
    # two slow swells, whole cycles over the loop so the envelope is periodic
    env = (0.55 + 0.45*np.sin(2*np.pi*(2/dur)*t(dur) - 1.2))
    env *= (0.7 + 0.3*np.sin(2*np.pi*(3/dur)*t(dur)))
    surf = brown * env
    hiss = onepole_hp(rng.standard_normal(n), 0.4) * 0.04 * np.clip(env,0,1)
    return seamless(surf + hiss, xf=3.0)

# ── Rain: steady filtered hiss + sparse droplets ────────────────────────────
def rain(dur=20):
    n = int(dur*SR)
    bed = onepole_hp(rng.standard_normal(n), 0.22) * 0.5
    bed = onepole_lp(bed, 0.6)
    drops = np.zeros(n)
    for _ in range(int(dur*60)):                     # ~60 droplets/sec
        i = rng.integers(0, n)
        f = rng.uniform(1800, 5200); L = int(SR*0.012)
        if i+L < n:
            env = np.exp(-np.linspace(0,9,L))
            drops[i:i+L] += np.sin(2*np.pi*f*np.arange(L)/SR) * env * rng.uniform(0.2,0.6)
    return seamless(bed + drops*0.5, xf=1.5)

# ── Singing bowl: inharmonic partials, slow beating + shimmering re-strikes ─
def bowl(dur=24):
    n = int(dur*SR); x = t(dur); sig = np.zeros(n)
    base = 174.0  # a low, calming fundamental
    partials = [(1.0,1.0),(2.74,0.5),(5.41,0.28),(8.16,0.16),(11.0,0.09)]
    for mult, amp in partials:
        f = base*mult
        beat = 1 + 0.006*np.sin(2*np.pi*0.15*x)      # gentle shimmer/beating
        sig += amp*np.sin(2*np.pi*f*x*beat)
    # periodic swell envelope (whole cycles → seamless), plus a soft re-strike
    swell = 0.5 + 0.5*np.sin(2*np.pi*(2/dur)*x - 1.5)
    strike = np.exp(-((x % (dur/2))*1.1))
    sig *= (0.4 + 0.6*swell) * (0.6 + 0.4*strike)
    return seamless(sig, xf=3.0)

# ── Warm pad / drone for the Hold Me sanctuary ──────────────────────────────
def pad(dur=24):
    x = t(dur); sig = np.zeros(len(x))
    # a soft minor-ish stack, detuned for chorus warmth
    for f in [130.81, 196.0, 261.63, 392.0]:
        for det in (-0.3, 0.0, 0.3):
            sig += np.sin(2*np.pi*(f+det)*x) / 4
    sig += 0.25*np.sin(2*np.pi*65.4*x)               # sub warmth
    sig = onepole_lp(sig, 0.25)
    env = 0.6 + 0.4*np.sin(2*np.pi*(2/dur)*x)        # slow breathing
    return seamless(sig*env, xf=4.0)

if __name__ == "__main__":
    print("Synthesizing ambiences ->", OUT)
    save("ocean_waves.wav", waves())
    save("rain.wav", rain())
    save("singing_bowl.wav", bowl())
    save("warm_pad.wav", pad())
    print("done.")
