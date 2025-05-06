// Shadertoy-stijl hoofdfunctie voor kleurcalculatie per pixel
// Input: fragCoord = pixel coördinaat (van gl_FragCoord.xy)
// Output: fragColor = berekende kleur voor de pixel
// Uniforms (iResolution, iTime) worden verwacht vanuit de C++ wrapper.
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normaliseer de pixel coördinaten naar een bereik van [0.0, 1.0]
    // iResolution en iTime worden als beschikbaar verondersteld (toegevoegd door C++ wrapper)
    vec2 uv = fragCoord / iResolution.xy;

    // Maak een simpele visualisatie:
    // Een kleurverloop gebaseerd op de x/y positie,
    // gemengd met een langzaam pulserende kleur gebaseerd op tijd.
    vec3 gradientColor = vec3(uv.x, uv.y, 0.5 + 0.5 * sin(iTime * 0.5)); // Rood/Groen verloop, Blauw pulseert langzaam

    // Meng de kleur met een sinusgolf voor een zachte puls
    float pulse = 0.75 + 0.25 * cos(iTime * 2.0 + uv.x * 5.0); // Sneller pulserende helderheid
    vec3 finalColor = gradientColor * pulse;

    // Zet de uiteindelijke kleur (RGB) en alpha (A=1.0 = ondoorzichtig)
    fragColor = vec4(finalColor, 1.0);
}

// GEEN #version hier
// GEEN out FragColor hier (wordt door wrapper toegevoegd)
// GEEN uniforms hier (worden door wrapper toegevoegd)
// GEEN main() hier (wordt door wrapper toegevoegd)
