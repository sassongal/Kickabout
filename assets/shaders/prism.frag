#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uAlpha;

out vec4 fragColor;

// Constants from the original shader
const float uHeight = 3.5;
const float uBaseHalf = 2.75; // baseWidth 5.5 / 2
const float uGlow = 2.5; // BOOSTED GLOW FOR VISIBILITY
const float uNoise = 0.5;
const float uSaturation = 1.5; // transparent ? 1.5 : 1
const float uScale = 3.6;
const float uHueShift = 0.0;
const float uColorFreq = 1.0;
const float uBloom = 1.0;
const float uTimeScale = 0.5;


// Helpers
vec4 tanh4(vec4 x) {
    vec4 e2x = exp(2.0 * x);
    return (e2x - 1.0) / (e2x + 1.0);
}

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
}

float sdOctaAnisoInv(vec3 p) {
    float uInvBaseHalf = 1.0 / uBaseHalf;
    float uInvHeight = 1.0 / uHeight;
    float uMinAxis = min(uBaseHalf, uHeight);
    
    vec3 q = vec3(abs(p.x) * uInvBaseHalf, abs(p.y) * uInvHeight, abs(p.z) * uInvBaseHalf);
    float m = q.x + q.y + q.z - 1.0;
    return m * uMinAxis * 0.5773502691896258;
}

float sdPyramidUpInv(vec3 p) {
    float oct = sdOctaAnisoInv(p);
    float halfSpace = -p.y;
    return max(oct, halfSpace);
}

mat3 hueRotation(float a) {
    float c = cos(a), s = sin(a);
    mat3 W = mat3(
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114
    );
    mat3 U = mat3(
        0.701, -0.587, -0.114,
        -0.299, 0.413, -0.114,
        -0.300, -0.588, 0.886
    );
    mat3 V = mat3(
        0.168, -0.331, 0.500,
        0.328, 0.035, -0.500,
        -0.497, 0.296, 0.201
    );
    return W + U * c + V * s;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    vec2 p = (FlutterFragCoord().xy - 0.5 * uResolution.xy) / min(uResolution.y, uResolution.x);
    
    // Time-based animations
    float t = uTime * 0.2;
    
    // 1. SWEEPING GOLD SHINE (The "Prism" sweep)
    // We create a diagonal sweep that moves from top-left to bottom-right
    float sweepPos = fract(t * 0.2);
    float sweep = smoothstep(0.1, 0.0, abs((uv.x + uv.y) * 0.5 - sweepPos * 1.5 + 0.25));
    
    // 2. METALLIC NOISE & GRAIN (For that premium feel)
    float n = rand(uv + fract(t));
    float grain = (n - 0.5) * 0.05;
    
    // 3. GOLD COLOR MAPPING
    // Luxury Gold Colors
    vec3 goldDark  = vec3(0.25, 0.15, 0.05); // Deep Bronze
    vec3 goldMid   = vec3(0.85, 0.65, 0.2);  // Rich Gold
    vec3 goldLight = vec3(1.0, 0.95, 0.7);   // Sparkling Highlight
    
    // Base Gold Gradient Background
    vec3 baseGold = mix(goldDark, goldMid, uv.y + 0.2 * sin(uv.x * 3.0 + t));
    
    // Adding highlights based on position and time
    float sparkle = pow(max(0.0, sin(p.x * 4.0 + p.y * 2.0 + t)), 10.0) * 0.3;
    
    // Combine everything
    vec3 finalColor = baseGold;
    finalColor += goldLight * sweep * 0.8; // The sweep
    finalColor += goldLight * sparkle;      // The sparkles
    finalColor += grain;                    // Texture
    
    // Ensure vibrancy
    finalColor = clamp(finalColor, 0.0, 1.0);
    
    // 4. ALPHA LOGIC
    // We want it to be translucent enough to see the card content, but gold enough to pop.
    // The sweep and sparkles should be more opaque.
    float finalAlpha = uAlpha * (0.3 + sweep * 0.4 + sparkle * 0.3);
    
    fragColor = vec4(finalColor, finalAlpha);
}


