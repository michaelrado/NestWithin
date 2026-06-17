#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

// A living "soul": a fake-3D sphere lit from the top-left, with swirling inner
// energy (fbm flow), a glowing fresnel rim, and a soft outer aura. Driven by
// breath (size + brightness) and time (the swirl).
uniform vec2 uSize;
uniform float uTime;
uniform float uBreath;   // 0..1  contracted -> expanded
uniform vec3 uColorA;    // inner core colour
uniform vec3 uColorB;    // energy / rim colour
out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * vnoise(p);
    p *= 2.02;
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - 0.5 * uSize) / uSize.y;
  float dist = length(uv);

  float R = 0.24 + uBreath * 0.08;          // sphere pulses with the breath
  vec3 col = vec3(0.0);
  float alpha = 0.0;

  // outer aura (kept well inside the paint rect so no square shows)
  float glow = smoothstep(R * 1.9, R, dist);
  glow = pow(glow, 1.7) * (0.30 + 0.28 * uBreath);

  if (dist < R) {
    // reconstruct a sphere normal so the disc reads as a 3D ball
    float z = sqrt(max(R * R - dist * dist, 0.0));
    vec3 n = normalize(vec3(uv, z));
    vec3 L = normalize(vec3(-0.4, -0.6, 0.8));
    float diff = clamp(dot(n, L), 0.0, 1.0);
    float fres = pow(1.0 - n.z, 2.2);

    // swirling inner soul energy
    float ang = atan(uv.y, uv.x);
    vec2 flow = vec2(cos(uTime * 0.25), sin(uTime * 0.20));
    float s1 = fbm(uv * 3.2 + flow + ang * 0.25 + uTime * 0.12);
    float s2 = fbm(uv * 6.0 - flow * 1.5 - uTime * 0.18);
    float energy = mix(s1, s2, 0.5);

    vec3 core = mix(uColorA, uColorB, energy);
    core *= (0.45 + 0.85 * diff);             // volumetric shading
    core += uColorB * fres * 0.9;             // glowing rim
    core += uColorB * pow(energy, 3.0) * 0.6; // bright wisps

    float edge = smoothstep(R, R * 0.92, dist);
    col = core;
    alpha = edge;
  }

  col += uColorB * glow;
  alpha = max(alpha, glow);
  // confine everything to a disc so the square paint rect never shows
  alpha *= smoothstep(0.5, 0.34, dist);
  col *= (0.90 + 0.20 * uBreath);

  // premultiplied output
  fragColor = vec4(col, 1.0) * alpha;
}
