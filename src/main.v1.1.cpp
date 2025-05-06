// --- 3D Rotation Functions ---
mat3 rotateY(float angle) {
    float s = sin(angle); float c = cos(angle);
    return mat3( c, 0, s, 0, 1, 0, -s, 0, c);
}
mat3 rotateX(float angle) {
    float s = sin(angle); float c = cos(angle);
    return mat3( 1, 0, 0, 0, c,-s, 0, s, c);
}

// --- Signed Distance Functions (SDFs) ---
// Box SDF
float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
// Sphere SDF
// p: point in space
// s: radius
float sdSphere( vec3 p, float s ) {
  return length(p)-s;
}


// --- Scene SDF ---
// Returns the distance to the closest object based on mouse position
// p: point in space
// angleY, angleX: rotation angles
// mouseNormX: normalized horizontal mouse position [0, 1]
float map(vec3 p, float angleY, float angleX, float mouseNormX) {
    vec3 boxSize = vec3(0.3);
    float sphereRadius = 0.4;

    // Rotate the point *before* checking distance
    mat3 rotMatrix = rotateY(angleY) * rotateX(angleX);
    vec3 rotated_p = rotMatrix * p;

    // Choose shape based on mouse X position
    if (mouseNormX < 0.5) { // Left side = Cube
        return sdBox(rotated_p, boxSize);
    } else { // Right side = Sphere
        return sdSphere(rotated_p, sphereRadius);
    }
}

// --- Calculate Normal ---
// Calculates the surface normal at a point p using the gradient of the SDF
// Needs mouseNormX to know which shape's SDF to use for gradient calculation
vec3 calcNormal( vec3 p, float angleY, float angleX, float mouseNormX ) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( p + e.xyy, angleY, angleX, mouseNormX ) +
                      e.yyx*map( p + e.yyx, angleY, angleX, mouseNormX ) +
                      e.yxy*map( p + e.yxy, angleY, angleX, mouseNormX ) +
                      e.xxx*map( p + e.xxx, angleY, angleX, mouseNormX ) );
}

// --- Raymarching Function ---
// Needs mouseNormX to pass to map() and calcNormal()
float rayMarch(vec3 ro, vec3 rd, float angleY, float angleX, float mouseNormX, out vec3 hitPos, out vec3 hitNormal) {
    float dO = 0.0;
    hitPos = ro;
    hitNormal = vec3(0.0);

    for(int i = 0; i < 100; i++) {
        hitPos = ro + rd * dO;
        // Pass mouseNormX to map
        float dS = map(hitPos, angleY, angleX, mouseNormX);
        dO += dS;
        if(dO > 20.0 || dS < 0.001) {
             if (dS < 0.001) {
                 // Pass mouseNormX to calcNormal
                 hitNormal = calcNormal(hitPos, angleY, angleX, mouseNormX);
             }
             break;
        }
    }
    return dO;
}

// --- Shadertoy-stijl hoofdfunctie ---
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv_norm = fragCoord / iResolution.xy;
    vec2 uv_centered = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Muis Input ---
    vec2 mouse_norm = iMouse.xy / iResolution.xy;
    float angleY = mouse_norm.x * 2.0 * 3.1415926535;
    float angleX = (mouse_norm.y - 0.5) * 3.1415926535;

    // --- Camera Setup ---
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(uv_centered, 1.0));

    // --- Raymarch ---
    vec3 hitPos;
    vec3 hitNormal;
    // Pass normalized mouse X to rayMarch
    float dist = rayMarch(ro, rd, angleY, angleX, mouse_norm.x, hitPos, hitNormal);

    // --- Kleur Bepalen / Shading ---
    vec3 col;

    if (dist < 20.0) { // We hit something (Cube or Sphere)
        vec3 lightPos = vec3(1.0, 1.5, -3.0);
        vec3 lightDir = normalize(lightPos - hitPos);
        float diffuse = max(dot(hitNormal, lightDir), 0.0);

        // Choose base color based on mouse X (optional, could be the same)
        vec3 baseColor;
        if (mouse_norm.x < 0.5) {
             baseColor = vec3(0.8, 0.6, 0.3); // Cube color (Oranje-achtig)
        } else {
             baseColor = vec3(0.3, 0.6, 0.8); // Sphere color (Blauw-achtig)
        }

        col = baseColor * diffuse + vec3(0.1) * diffuse;

    } else { // We hit the background
        vec3 gradient = vec3(uv_norm.x, uv_norm.y, 0.5);
        vec3 pulseColor = 0.5 + 0.5 * cos(iTime * 0.5 + uv_norm.xyx * 3.0 + vec3(0, 2, 4));
        col = mix(gradient, pulseColor, 0.6 + 0.3 * sin(iTime));
        col *= 0.5;
    }

    // Output de uiteindelijke kleur
    fragColor = vec4(col, 1.0);
}

// GEEN #version, out FragColor, uniforms, of main() hier - wordt door C++ toegevoegd.
