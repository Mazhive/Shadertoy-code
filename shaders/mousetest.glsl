// Shadertoy-stijl hoofdfunctie
// Uniforms iResolution, iTime, iMouse worden verwacht vanuit de C++ wrapper
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normaliseer coördinaten [0, 1]
    vec2 uv = fragCoord.xy / iResolution.xy;

    // --- Muis Input ---
    vec2 currentMousePos = iMouse.xy; // Huidige positie
    vec2 clickPos = iMouse.zw;        // Positie waar klik begon (of negatief als knop los)
    bool isMouseButtonDown = (iMouse.z >= 0.0); // Check of knop ingedrukt is via teken van Z

    // --- Achtergrond ---
    // Verander achtergrondkleur op basis van huidige muispositie
    vec3 backgroundColor = vec3(uv.x, uv.y, 0.5 + 0.5 * sin(iTime * 0.2));

    // --- Vorm Tekenen ---
    vec3 shapeColor = backgroundColor; // Begin met achtergrondkleur
    float shapeSize = 50.0; // Grootte van de vorm in pixels

    if (isMouseButtonDown) {
        // Knop is ingedrukt: teken witte cirkel op klikpositie
        float distToClick = length(fragCoord - clickPos); // Afstand tot klikpositie
        if (distToClick < shapeSize / 2.0) {
            shapeColor = vec3(1.0); // Wit
            // Optioneel: maak rand zachter
            // shapeColor = vec3(smoothstep(shapeSize / 2.0, shapeSize / 2.0 - 2.0, distToClick));
        }
    } else {
        // Knop is los: teken rood vierkant op *laatste* klikpositie
        // Gebruik absolute waarde omdat Z/W negatief kunnen zijn als knop los is
        vec2 lastClickPos = abs(clickPos);
        // Controleer of we binnen het vierkant vallen rond de laatste klik
        if (abs(fragCoord.x - lastClickPos.x) < shapeSize / 2.0 &&
            abs(fragCoord.y - lastClickPos.y) < shapeSize / 2.0)
        {
             // Alleen tekenen als er ooit geklikt is (positie is niet de initiële -1,-1)
             if(clickPos.x != -1.0 || clickPos.y != -1.0) {
                shapeColor = vec3(1.0, 0.0, 0.0); // Rood
             }
        }
    }

    // Output de uiteindelijke kleur
    fragColor = vec4(shapeColor, 1.0);
}

// GEEN #version, out FragColor, uniforms, of main() hier - wordt door C++ toegevoegd.

