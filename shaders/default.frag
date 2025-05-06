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
float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdSphere( vec3 p, float s ) {
  return length(p)-s;
}

// --- Scene SDF ---
// p: point in space
// angleY, angleX: rotation angles
// useCube: boolean indicating whether to render the cube or sphere
// Returns distance and applies rotation internally
float map(vec3 p, float angleY, float angleX, bool useCube, out mat3 rotMat) { // Added rotMat output
    vec3 boxSize = vec3(0.3);
    float sphereRadius = 0.4;

    rotMat = rotateY(angleY) * rotateX(angleX); // Calculate rotation matrix
    vec3 rotated_p = rotMat * p; // Rotate the point

    if (useCube) {
        return sdBox(rotated_p, boxSize);
    } else {
        return sdSphere(rotated_p, sphereRadius);
    }
}

// --- Calculate Normal ---
// Calculates normal based on rotated space
vec3 calcNormal( vec3 p, float angleY, float angleX, bool useCube, mat3 rotMat ) { // Pass rotMat
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    // We need map to return distance based on the *same* rotation matrix
    // So we pass rotMat implicitly via the map calls here.
    // Note: map recalculates rotMat inside, slightly inefficient but works.
    // A cleaner way would be to pass rotMat into map as well.
    // Let's modify map to output rotMat and pass it here.

    // Re-calculate map with small offsets in world space
    // The map function applies the rotation internally
    mat3 unusedRotMat; // Dummy output for map calls inside normal calc
    return normalize( e.xyy*map( p + e.xyy, angleY, angleX, useCube, unusedRotMat ) +
                      e.yyx*map( p + e.yyx, angleY, angleX, useCube, unusedRotMat ) +
                      e.yxy*map( p + e.yxy, angleY, angleX, useCube, unusedRotMat ) +
                      e.xxx*map( p + e.xxx, angleY, angleX, useCube, unusedRotMat ) );
    // The resulting normal is in world space
}


// --- Raymarching Function ---
float rayMarch(vec3 ro, vec3 rd, float angleY, float angleX, bool useCube, out vec3 hitPos, out vec3 hitNormal, out mat3 hitRotMat) { // Added hitRotMat output
    float dO = 0.0;
    hitPos = ro;
    hitNormal = vec3(0.0);
    mat3 currentHitRotMat; // Rotation matrix at the potential hit point

    for(int i = 0; i < 100; i++) {
        hitPos = ro + rd * dO;
        // Get distance and the rotation used for this check
        float dS = map(hitPos, angleY, angleX, useCube, currentHitRotMat);
        dO += dS;
        if(dO > 20.0 || dS < 0.001) {
             if (dS < 0.001) {
                 // Calculate normal using the same rotation
                 hitNormal = calcNormal(hitPos, angleY, angleX, useCube, currentHitRotMat);
                 hitRotMat = currentHitRotMat; // Store the rotation matrix at hit
             } else {
                 hitRotMat = mat3(1.0); // No hit, return identity matrix
             }
             break;
        }
    }
     if (dO >= 20.0) hitRotMat = mat3(1.0); // Ensure identity if no hit
    return dO;
}

// --- Sphere Checkerboard Pattern (Triplanar using LOCAL position) ---
// localP: hit position in the object's local space (unrotated)
// normal: world space normal (still useful for blending)
vec3 checkerboardSphereTriplanar(vec3 localP, vec3 normal) {
    vec3 blendWeights = abs(normal);
    blendWeights = blendWeights / (blendWeights.x + blendWeights.y + blendWeights.z + 1e-5); // Add epsilon

    float scale = 5.0;
    // Use LOCAL position for UVs
    vec2 uv_xy = localP.xy * scale;
    vec2 uv_yz = localP.yz * scale;
    vec2 uv_xz = localP.xz * scale;

    float checker_xy = mod(floor(uv_xy.x) + floor(uv_xy.y), 2.0);
    float checker_yz = mod(floor(uv_yz.x) + floor(uv_yz.y), 2.0);
    float checker_xz = mod(floor(uv_xz.x) + floor(uv_xz.y), 2.0);

    vec3 color_xy = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), checker_xy);
    vec3 color_yz = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), checker_yz);
    vec3 color_xz = mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), checker_xz);

    return color_xy * blendWeights.z + color_yz * blendWeights.x + color_xz * blendWeights.y;
}

// --- UI Button Drawing ---
bool drawButton(vec2 coord_px, vec2 buttonCenter_px, float buttonSize_px, vec3 buttonColor, out vec3 outColor) {
    vec2 diff = coord_px - buttonCenter_px;
    bool inside = max(abs(diff.x), abs(diff.y)) < buttonSize_px / 2.0;
    if (inside) {
        outColor = buttonColor;
    }
    float border = buttonSize_px / 2.0 + 2.0;
    if (max(abs(diff.x), abs(diff.y)) < border && !inside) {
         outColor = vec3(0.8);
    }
    return inside;
}

// --- Shadertoy-stijl hoofdfunctie ---
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv_norm = fragCoord / iResolution.xy;
    vec2 uv_centered = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Muis Input ---
    vec2 mouse_pos_px = iMouse.xy;
    vec2 mouse_pos_norm = mouse_pos_px / iResolution.xy;

    float clickStateX = iMouse.z;
    float clickStateY = iMouse.w;
    vec2 lastClickPos_px = abs(iMouse.zw);
    bool isClickValid = !(clickStateX == -1.0 && clickStateY == -1.0);

    // --- UI Button Definitions ---
    float buttonSize = 50.0;
    float buttonMargin = 15.0;
    vec2 cubeButtonPos = vec2(buttonMargin + buttonSize / 2.0, iResolution.y - buttonMargin - buttonSize / 2.0);
    vec2 sphereButtonPos = vec2(buttonMargin + buttonSize / 2.0, iResolution.y - buttonMargin * 2.0 - buttonSize * 1.5);
    vec3 cubeButtonColor = vec3(0.8, 0.6, 0.3);
    vec3 sphereButtonColor = vec3(0.3, 0.6, 0.8);

    // --- Determine Selected Shape ---
    bool showCube = true;
    if (isClickValid) {
         if (max(abs(lastClickPos_px.x - sphereButtonPos.x), abs(lastClickPos_px.y - sphereButtonPos.y)) < buttonSize / 2.0) {
             showCube = false;
         } else {
             showCube = true; // Default to cube if click outside sphere button or on cube button
         }
    }

    // --- Rotation Angles based on current mouse position ---
    float angleY = mouse_pos_norm.x * 2.0 * 3.1415926535;
    float angleX = (mouse_pos_norm.y - 0.5) * 3.1415926535;

    // --- Camera Setup ---
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(uv_centered, 1.0));

    // --- Raymarch for the main shape ---
    vec3 hitPos; // World space hit position
    vec3 hitNormal; // World space normal
    mat3 hitRotMat; // Rotation matrix used at hit point
    float dist = rayMarch(ro, rd, angleY, angleX, showCube, hitPos, hitNormal, hitRotMat);

    // --- Background Color ---
    vec3 finalColor;
    vec3 gradient = vec3(uv_norm.x, uv_norm.y, 0.5);
    vec3 pulseColor = 0.5 + 0.5 * cos(iTime * 0.5 + uv_norm.xyx * 3.0 + vec3(0, 2, 4));
    finalColor = mix(gradient, pulseColor, 0.6 + 0.3 * sin(iTime));
    finalColor *= 0.5;


    // --- Render Main Shape ---
    if (dist < 20.0) { // We hit the main shape
        vec3 lightPos = vec3(1.0, 1.5, -3.0);
        vec3 lightDir = normalize(lightPos - hitPos);
        float diffuse = max(dot(hitNormal, lightDir), 0.0);

        vec3 baseColor;
        if (showCube) {
             baseColor = vec3(0.8, 0.6, 0.3); // Cube color
        } else {
             // Calculate local position for sphere pattern <-- NIEUW
             // Inverse rotation is the transpose of the rotation matrix
             vec3 localHitPos = transpose(hitRotMat) * hitPos;
             // Use local position for triplanar checkerboard
             baseColor = checkerboardSphereTriplanar(localHitPos, hitNormal);
        }
        // Overwrite background with shaded shape color
        finalColor = baseColor * diffuse + vec3(0.1) * diffuse;
    }

    // --- Render UI Buttons (on top) ---
    vec3 buttonPixelColor = finalColor;
    bool insideCubeBtn = drawButton(fragCoord, cubeButtonPos, buttonSize, cubeButtonColor, buttonPixelColor);
    bool insideSphereBtn = drawButton(fragCoord, sphereButtonPos, buttonSize, sphereButtonColor, buttonPixelColor);

    if (insideCubeBtn || insideSphereBtn) {
        finalColor = buttonPixelColor;
    }

    // Highlight selected button
    if (showCube && insideCubeBtn) {
        finalColor = mix(finalColor, vec3(1.0), 0.3);
    } else if (!showCube && insideSphereBtn) {
        finalColor = mix(finalColor, vec3(1.0), 0.3);
    }


    // Output de uiteindelijke kleur
    fragColor = vec4(finalColor, 1.0);
}

// GEEN #version, out FragColor, uniforms, of main() hier - wordt door C++ toegevoegd.

