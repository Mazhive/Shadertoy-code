#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURFACE_DIST 0.001

// Signed Distance Function voor een doos
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Rotatiefuncties
mat3 rotateY(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}

mat3 rotateX(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(vec3(1, 0, 0), vec3(0, c, -s), vec3(0, s, c));
}

// Struct voor informatie over een hit
struct HitInfo {
    float dist;
    vec3 pos;
    vec3 localP;
    mat3 rotation;
    bool hit;
};

// Scene met bewegende kubussen in een liggende S-beweging
HitInfo sceneHit(vec3 p) {
    float minDist = MAX_DIST;
    vec3 bestLocalP = vec3(0);
    vec3 bestPos = vec3(0);
    mat3 bestRotation = mat3(1.0);
    bool anyHit = false;

    int gridY = 5;  // Verticaal (boven naar beneden)
    int gridZ = 20; // Horizontaal (links naar rechts)

    for (int y = 0; y < gridY; y++) {
        for (int z = 0; z < gridZ; z++) {

            // Faseverschuiving per kubus voor S-beweging
            float phase = float(y) * 0.3 + float(z) * 0.15;
            vec3 offset = vec3(
                sin(iTime + phase) * 1.0,
                sin(iTime * 0.7 + phase) * 0.5,
                cos(iTime * 0.4 + phase) * 1.0
            );

            // Positie van de kubus met compacte spreiding
            vec3 pos = vec3(
                float(z - gridZ / 2) * 0.4,
                float(y - gridY / 2) * 0.4,
                0.0
            ) + offset;

            // Rotatie
            float angle = iTime + float(y + z) * 0.15;
            mat3 rotation = rotateY(angle) * rotateX(angle * 0.3);

            // Local space
            vec3 localP = (p - pos) * rotation;
            float d = sdBox(localP, vec3(0.1));

            if (d < minDist) {
                minDist = d;
                bestLocalP = localP;
                bestPos = pos;
                bestRotation = rotation;
                anyHit = true;
            }
        }
    }

    return HitInfo(minDist, bestPos, bestLocalP, bestRotation, anyHit);
}

// Normaalberekening
vec3 calcNormal(vec3 p) {
    const float h = 0.001;
    const vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * sceneHit(p + k.xyy * h).dist +
        k.yyx * sceneHit(p + k.yyx * h).dist +
        k.yxy * sceneHit(p + k.yxy * h).dist +
        k.xxx * sceneHit(p + k.xxx * h).dist
    );
}

// Raymarching
HitInfo raymarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        HitInfo h = sceneHit(p);
        if (h.dist < SURFACE_DIST) {
            h.pos = p;
            h.dist = dO;
            h.hit = true;
            return h;
        }
        if (dO > MAX_DIST) break;
        dO += h.dist;
    }
    return HitInfo(MAX_DIST, vec3(0), vec3(0), mat3(1.0), false);
}

// Hoofdfunctie
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 ro = vec3(-1.0, 2.0, -10.0);  // Camera positie
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.5));

    HitInfo hit = raymarch(ro, rd);
    vec3 col = vec3(0.1, 0.1, 0.2); // Achtergrondkleur

    if (hit.hit) {
        vec3 normal = calcNormal(hit.pos);
        vec3 localNormal = transpose(hit.rotation) * normal;

        // Kleur per vlak
        vec3 objectColor = vec3(1.0);
        if (localNormal.x > 0.5)       objectColor = vec3(0.0, 0.0, 0.3);
        else if (localNormal.x < -0.5) objectColor = vec3(1.0, 0.0, 0.0);
        else if (localNormal.y > 0.5)  objectColor = vec3(0.0, 1.0, 0.0);
        else if (localNormal.y < -0.5) objectColor = vec3(1.0, 1.0, 0.0);
        else if (localNormal.z > 0.5)  objectColor = vec3(1.0, 0.5, 0.0);
        else if (localNormal.z < -0.5) objectColor = vec3(0.5, 0.0, 0.5);

        // Licht
        vec3 lightPos = vec3(10.0, 10.0, -5.0);
        vec3 lightDir = normalize(lightPos - hit.pos);
        float ambient = 1.5;
        float diffuse = 0.8 * max(dot(normal, lightDir), 0.0);
        vec3 viewDir = normalize(ro - hit.pos);
        vec3 reflectDir = reflect(-lightDir, normal);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
        vec3 specular = vec3(0.6) * spec;

        col = (ambient + diffuse) * objectColor + specular;

        // Mist
        col = mix(col, vec3(0.1, 0.1, 0.2), 1.0 - exp(-0.01 * hit.dist * hit.dist));
    }

    fragColor = vec4(col, 1.0);
}
