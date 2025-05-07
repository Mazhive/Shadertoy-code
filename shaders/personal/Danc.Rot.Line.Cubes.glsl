// Shadertoy Shader: Dancing & Rotating Line Cubes with FIXED Face Colors + Edge Darkening
// Version 17.1: Complete code with all function bodies restored.

// --- Primitives / Helpers ---

// Signed distance function for a Box
float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Rotation matrix around Y axis
mat3 rotY(float a) {
    float s = sin(a); float c = cos(a);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

// Rotation matrix around X axis
mat3 rotX(float a) {
    float s = sin(a); float c = cos(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

// Rotation matrix around Z axis
mat3 rotZ(float a) {
    float s = sin(a); float c = cos(a);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

// Helper to calculate normal directly from sdBox in local space
vec3 calcBoxLocalNormal(vec3 p_local, vec3 boxSize) {
    vec2 e = vec2(boxSize.x * 0.01, 0.0);
     if (e.x == 0.0) e.x = 0.0001; // Prevent zero epsilon if CUBE_SIZE is zero
    return normalize(vec3(
        sdBox(p_local + e.xyy, boxSize) - sdBox(p_local - e.xyy, boxSize),
        sdBox(p_local + e.yxy, boxSize) - sdBox(p_local - e.yxy, boxSize),
        sdBox(p_local + e.yyx, boxSize) - sdBox(p_local - e.yyx, boxSize)
    ));
}


// --- Scene Definition ---
// Constants
const int NUM_STEPS_CURVE = 25;
const float CURVE_LENGTH = 9.0;
const vec3 CUBE_SIZE = vec3(0.04);
const int GRID_DIM = 3;
const float GRID_SPACING = CUBE_SIZE.x * 6.5;
const float DANCE_AMPLITUDE = 0.108;
const float DANCE_FREQUENCY = 1.2;
const float ROTATION_FREQUENCY = 0.8;
const float MOVE_SPEED = 0.6;
const float MOVE_RANGE = 4.0;

// Function defining the 3D path of the CENTERLINE
vec3 getCurvePoint(float t) {
    float horizontalOffset = sin(iTime * MOVE_SPEED) * (MOVE_RANGE / 2.0);
    vec3 p;
    p.x = t + horizontalOffset;
    p.y = 0.0;
    p.z = 0.0;
    return p;
}

// Signed Distance Function for the entire scene
float map(vec3 p) {
    float minDist = 1e10;
    const float max_magnitude = max(0.0, (GRID_SPACING - 2.0 * CUBE_SIZE.x) / 2.0);
    const int gridHalf = GRID_DIM / 2;

    for(int i = 0; i < NUM_STEPS_CURVE; ++i) {
        float t = (float(i) / float(NUM_STEPS_CURVE - 1)) * CURVE_LENGTH - CURVE_LENGTH * 0.5;
        vec3 curveCenter = getCurvePoint(t);

        for (int x = -gridHalf; x <= gridHalf; ++x) {
            for (int y = -gridHalf; y <= gridHalf; ++y) {
                // Note: Using vec3(0.0, float(x), float(y)) assumes the line is along X
                // If the curve changes, gridRight/gridUp calculation needed again
                vec3 offset = vec3(0.0, float(x), float(y)) * GRID_SPACING;
                vec3 baseCubePos = curveCenter + offset;
                float phase_seed = float(i) * 5.37 + float(x) * 8.13 + float(y) * 6.79;

                // Dance Translation (Clamped)
                float timePhaseDance = iTime * DANCE_FREQUENCY;
                vec3 danceOffset;
                danceOffset.x = sin(timePhaseDance * 0.9 + phase_seed * 1.1) * DANCE_AMPLITUDE;
                danceOffset.y = cos(timePhaseDance * 1.1 + phase_seed * 0.8) * DANCE_AMPLITUDE * 0.7;
                danceOffset.z = sin(timePhaseDance + phase_seed * 1.3) * DANCE_AMPLITUDE;
                float current_magnitude = length(danceOffset);
                if (current_magnitude > max_magnitude && current_magnitude > 0.0) {
                    danceOffset *= max_magnitude / current_magnitude;
                }
                vec3 cubePos = baseCubePos + danceOffset;

                // Rotation
                float timePhaseRotate = iTime * ROTATION_FREQUENCY;
                float angleY = timePhaseRotate + phase_seed * 1.4;
                float angleZ = timePhaseRotate * 0.8 + phase_seed * 1.9;
                mat3 rotationMatrix = rotY(angleY) * rotZ(angleZ);
                mat3 invRotationMatrix = transpose(rotationMatrix); // Built-in transpose

                // SDF Calculation
                vec3 p_local_rotated = invRotationMatrix * (p - cubePos);
                float dist = sdBox(p_local_rotated, CUBE_SIZE);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

// Calculate the world normal vector
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Simple Ambient Occlusion calculation
float calcAO(vec3 p, vec3 n) {
    float occ = 0.0; float sca = 1.0; const int ITERATIONS = 5;
    for(int i = 0; i < ITERATIONS; i++) {
        float h = 0.01 + 0.1 * float(i + 1) / float(ITERATIONS);
        float d = map(p + n * h);
        occ += max(0.0, (h - d)) * sca; sca *= 0.9; if (occ > 0.7) break;
    }
    return clamp(1.0 - 1.5 * occ, 0.0, 1.0);
}


// --- Raymarching & Rendering ---

const int MAX_STEPS = 90;
const float MAX_DIST = 100.0;
const float SURF_DIST = 0.001;

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0.0, 0.5, 0.75);
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 upDir = vec3(0.0, 1.0, 0.0);
    vec3 forward = normalize(target - ro);
    vec3 camRight = normalize(cross(upDir, forward));
    vec3 camUp = normalize(cross(forward, camRight));
    vec3 rd = normalize(forward + camRight * uv.x + camUp * uv.y);

    float d = 0.0;
    vec3 p = ro;
    bool hit = false;
    for(int i = 0; i < MAX_STEPS; i++) {
        p = ro + rd * d;
        float dist = map(p);
        float hitPrecision = SURF_DIST * max(1.0, d * 0.5);
        if(dist < hitPrecision) {
            hit = true;
            p -= rd * hitPrecision * 0.5; // Step back slightly onto surface
            break;
        }
        d += max(dist * 0.7, hitPrecision * 2.0);
        if(d >= MAX_DIST) break;
    }

    vec3 col = vec3(0.01, 0.01, 0.02); // Dark background

    if(hit) {
        vec3 worldNormal = calcNormal(p); // World normal for lighting

        // --- Determine Face Color & Edge Factor ---
        vec3 objectColor = vec3(0.15, 0.55, 0.9); // Default color if loop fails
        float minFoundDist = 1e9;
        float edgeFactor = 1.0; // Default to no darkening

        const float max_magnitude = max(0.0, (GRID_SPACING - 2.0 * CUBE_SIZE.x) / 2.0);
        const int gridHalf = GRID_DIM / 2;
        for(int i = 0; i < NUM_STEPS_CURVE; ++i) {
             // Check only a subset around expected t? Optimization possible but complex.
            float t = (float(i) / float(NUM_STEPS_CURVE - 1)) * CURVE_LENGTH - CURVE_LENGTH * 0.5;
            vec3 curveCenter = getCurvePoint(t);

            // Optimization potential: Check if curveCenter is too far from hit point p first.
            // if (distance(p, curveCenter) > some_threshold) continue;

            for (int x = -gridHalf; x <= gridHalf; ++x) {
                for (int y = -gridHalf; y <= gridHalf; ++y) {
                    // Recalculate properties for this specific cube
                    vec3 offset = vec3(0.0, float(x), float(y)) * GRID_SPACING;
                    vec3 baseCubePos = curveCenter + offset;
                    float phase_seed = float(i) * 5.37 + float(x) * 8.13 + float(y) * 6.79;

                    // Dance offset (clamped)
                    float timePhaseDance = iTime * DANCE_FREQUENCY;
                    vec3 danceOffset;
                    danceOffset.x = sin(timePhaseDance * 0.9 + phase_seed * 1.1) * DANCE_AMPLITUDE;
                    danceOffset.y = cos(timePhaseDance * 1.1 + phase_seed * 0.8) * DANCE_AMPLITUDE * 0.7;
                    danceOffset.z = sin(timePhaseDance + phase_seed * 1.3) * DANCE_AMPLITUDE;
                    float current_magnitude = length(danceOffset);
                    if (current_magnitude > max_magnitude && current_magnitude > 0.0) {
                        danceOffset *= max_magnitude / current_magnitude;
                    }
                    vec3 cubePos = baseCubePos + danceOffset;

                    // Rotation
                    float timePhaseRotate = iTime * ROTATION_FREQUENCY;
                    float angleY = timePhaseRotate + phase_seed * 1.4;
                    float angleZ = timePhaseRotate * 0.8 + phase_seed * 1.9;
                    mat3 rotationMatrix = rotY(angleY) * rotZ(angleZ);
                    mat3 invRotationMatrix = transpose(rotationMatrix); // Use built-in

                    // Calculate distance from hit point p to this specific cube's surface
                    vec3 p_local = invRotationMatrix * (p - cubePos); // p in cube's local frame
                    float currentDist = sdBox(p_local, CUBE_SIZE);

                    // Check if this cube is the closest one found so far near the hit point
                    // Compare squared distances potentially faster? But currentDist needed anyway.
                    // Threshold check helps ignore cubes clearly not the hit one.
                    if (currentDist < minFoundDist && currentDist < SURF_DIST * 50.0) { // Increased threshold tolerance
                        minFoundDist = currentDist;

                        // Calculate TRUE local normal using gradient of sdBox
                        vec3 trueLocalNormal = calcBoxLocalNormal(p_local, CUBE_SIZE);

                        // Determine FIXED face color based on trueLocalNormal
                        vec3 faceColor = vec3(1.0); // Default White
                        if      (trueLocalNormal.x >  0.9) faceColor = vec3(0.0, 0.0, 0.3); // +X = Dark Blue
                        else if (trueLocalNormal.x < -0.9) faceColor = vec3(1.0, 0.0, 0.0); // -X = Red
                        else if (trueLocalNormal.y >  0.9) faceColor = vec3(0.0, 1.0, 0.0); // +Y = Green
                        else if (trueLocalNormal.y < -0.9) faceColor = vec3(1.0, 1.0, 0.0); // -Y = Yellow
                        else if (trueLocalNormal.z >  0.9) faceColor = vec3(1.0, 0.5, 0.0); // +Z = Orange
                        else if (trueLocalNormal.z < -0.9) faceColor = vec3(0.5, 0.0, 0.5); // -Z = Purple

                        // Calculate Edge Darkening Factor based on true local normal purity
                        float max_comp = max(abs(trueLocalNormal.x), max(abs(trueLocalNormal.y), abs(trueLocalNormal.z)));
                        edgeFactor = smoothstep(0.90, 0.98, max_comp); // Store edge factor

                        // Apply Edge Darkening to Face Color
                        objectColor = faceColor * edgeFactor; // Store final color for shading
                    }
                }
            }
        }
        // --- End Determine Face Color & Edge Factor ---


        // --- Standard Shading using worldNormal and final objectColor ---
        float ao = calcAO(p, worldNormal);
        vec3 lightPos = vec3(4.0, 5.0, 6.0);
        vec3 lightDir = normalize(lightPos - p);
        float diffuse = max(dot(worldNormal, lightDir), 0.0);
        float shadow = 1.0; // Basic shadowing disabled
        float ambient = 0.15;

        // Use the potentially darkened objectColor here
        col = objectColor * (ambient * ao + diffuse * shadow * 1.0);

        float rim = pow(1.0 - max(dot(worldNormal, -rd), 0.0), 3.0);
        // Rim light applied additively
        col += vec3(0.5, 0.7, 1.0) * rim * 0.3 * diffuse * shadow;

        // Fog
        col = mix(col, vec3(0.01, 0.01, 0.02), 1.0 - exp(-0.01 * d * d));
    }

    // Post-processing
    col = pow(col, vec3(0.8)); // Gamma correction
    fragColor = vec4(col, 1.0);
}
