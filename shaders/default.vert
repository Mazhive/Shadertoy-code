#version 330 core

// Input vertex attribuut: Positie van het vertex.
// 'location = 0' komt overeen met glVertexAttribPointer(0, ...) in de C++ code.
// We verwachten 2D posities (x, y) voor de fullscreen quad.
layout (location = 0) in vec2 aPos;

// Standaard GLSL entry point die OpenGL aanroept voor elk vertex
void main()
{
    // Geef de 2D positie direct door als clip space coördinaat.
    // De input aPos wordt verwacht in Normalized Device Coordinates (NDC),
    // die lopen van -1.0 tot 1.0.
    // We zetten z op 0.0 (geen diepte nodig voor 2D quad) en w op 1.0 (standaard).
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
}
