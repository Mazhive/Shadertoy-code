// src/mainV1.cpp
// Broncode voor de C++ Shadertoy Viewer
// AANGEPAST voor OpenGL 4.6 Context & GLSL 4.60 Injectie

#include <glad/glad.h> // MOET ALTIJD EERST! (Nu de 4.6 versie)
#include <GLFW/glfw3.h>
#include "tinyfiledialogs.h" // Include voor bestandsdialoog

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cmath>
#include <filesystem> // Voor pad manipulatie (C++17)

// --- Instellingen ---
const unsigned int INITIAL_SCR_WIDTH = 800;
const unsigned int INITIAL_SCR_HEIGHT = 600;
const char* vertexShaderPath = "shaders/shader.vert"; // Vaste vertex shader
const char* defaultFragmentShaderPath = "shaders/default.frag";

// --- Functie Prototypes ---
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);
bool loadNewFragmentShader(const char* fragmentPath);
std::string loadShaderFromFile(const char* path);
GLuint compileShader(GLenum type, const char* source, const char* shaderName = "");
GLuint compileAndLinkProgram(const char* vPath, const std::string& fragmentSource); // Aangepast voor 4.6 injectie

// --- Globale Variabelen ---
float currentWindowWidth = INITIAL_SCR_WIDTH;
float currentWindowHeight = INITIAL_SCR_HEIGHT;
GLuint currentShaderProgram = 0;
GLint iResolutionLocation = -1;
GLint iTimeLocation = -1;
GLint iMouseLocation = -1;
double mouseX = 0.0, mouseY = 0.0;

// --- Hoofdfunctie ---
int main()
{
    std::cout << "Starting Shadertoy Viewer (OpenGL 4.6 Mode)..." << std::endl;
    std::cout << "Requesting OpenGL 4.6 Context." << std::endl;
    std::cout << "Injecting GLSL 4.60 header and common uniforms." << std::endl;
    std::cout << "Press 'O' to open a fragment shader file (.frag, .glsl)." << std::endl;

    // --- 1. Initialisatie GLFW ---
    if (!glfwInit()) { std::cerr << "Failed to initialize GLFW" << std::endl; return -1; }

    // --- VRAAG NU EEN OPENGL 4.6 CORE CONTEXT AAN ---
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4); // <-- GEWIJZIGD
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6); // <-- GEWIJZIGD
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // <-- Belangrijk: Core Profile
    #ifdef __APPLE__
        // Op macOS is Core Profile > 4.1 vaak lastig, dit deel blijft voor compatibiliteit
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    #endif
    glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE); // Handig voor debuggen (vereist KHR_debug in GLAD)


    // --- 2. Maak venster ---
    GLFWwindow* window = glfwCreateWindow(INITIAL_SCR_WIDTH, INITIAL_SCR_HEIGHT, "C++ Shadertoy Viewer (OpenGL 4.6)", NULL, NULL);
    // --- CONTROLEER OF HET MAKEN VAN HET 4.6 VENSTER LUKTE! ---
    if (window == NULL) {
        std::cerr << "Failed to create GLFW window." << std::endl;
        std::cerr << "!!! Mogelijk ondersteunen je videokaart/drivers geen OpenGL 4.6 Core Profile !!!" << std::endl;
        glfwTerminate();
        return -1;
    }
    // --- 3. Maak OpenGL context huidig ---
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // --- 4. Initialiseer GLAD (voor OpenGL 4.6 functies) ---
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cerr << "Failed to initialize GLAD (for OpenGL 4.6)." << std::endl;
        glfwTerminate();
        return -1;
    }
    // --- PRINT DE VERKREGEN OPENGL VERSIE ---
    std::cout << "OpenGL Renderer: " << glGetString(GL_RENDERER) << std::endl;
    std::cout << "OpenGL Version Initialized: " << glGetString(GL_VERSION) << std::endl; // Controleer of hier echt 4.6 staat!


    // --- 5. Probeer een initiële shader te laden ---
    std::cout << "\n--- Loading Initial Shader (optional) ---" << std::endl;
    if (std::filesystem::exists(defaultFragmentShaderPath)) {
        loadNewFragmentShader(defaultFragmentShaderPath); // Deze gebruikt nu 4.6 injectie
    } else {
        std::cout << "Default fragment shader not found, starting empty." << std::endl;
    }
    std::cout << "--- End Initial Shader Load ---\n" << std::endl;

    // --- 6. Setup VBO/VAO (blijft hetzelfde) ---
    float vertices[] = { -1.0f, 1.0f, -1.0f, -1.0f, 1.0f, -1.0f, -1.0f, 1.0f, 1.0f, -1.0f, 1.0f, 1.0f };
    unsigned int quadVAO, quadVBO;
    glGenVertexArrays(1, &quadVAO); glGenBuffers(1, &quadVBO); glBindVertexArray(quadVAO);
    glBindBuffer(GL_ARRAY_BUFFER, quadVBO); glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0); glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0); glBindVertexArray(0);

    // --- 7. Render Loop ---
    std::cout << "Entering main render loop..." << std::endl;
    while (!glfwWindowShouldClose(window)) {
        processInput(window);
        glfwGetCursorPos(window, &mouseX, &mouseY);
        float glMouseY = currentWindowHeight - (float)mouseY;

        if (currentShaderProgram != 0) {
            glUseProgram(currentShaderProgram);
            if (iTimeLocation != -1) glUniform1f(iTimeLocation, (float)glfwGetTime());
            if (iResolutionLocation != -1) glUniform2f(iResolutionLocation, currentWindowWidth, currentWindowHeight);
            if (iMouseLocation != -1) glUniform4f(iMouseLocation, (float)mouseX, glMouseY, 0.0f, 0.0f);
            glBindVertexArray(quadVAO);
            glDrawArrays(GL_TRIANGLES, 0, 6);
            glBindVertexArray(0);
        } else {
            glClearColor(0.15f, 0.15f, 0.15f, 1.0f); // Donkergrijs
            glClear(GL_COLOR_BUFFER_BIT);
        }
        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    std::cout << "Exited render loop." << std::endl;

    // --- 8. Cleanup ---
    glDeleteVertexArrays(1, &quadVAO); glDeleteBuffers(1, &quadVBO);
    if (currentShaderProgram != 0) { glDeleteProgram(currentShaderProgram); }
    glfwDestroyWindow(window); glfwTerminate();
    std::cout << "GLFW terminated. Exiting program." << std::endl;
    return 0;
}

// --- Implementaties van Helper Functies ---

// Functie om een nieuwe fragment shader te laden
bool loadNewFragmentShader(const char* fragmentPath) {
    std::cout << "Attempting to load fragment shader: " << fragmentPath << std::endl;
    std::string fragmentCode = loadShaderFromFile(fragmentPath);
    if (fragmentCode.empty()) {
        tinyfd_messageBox("Error", "Could not read shader file.", "ok", "error", 1);
        return false;
    }
    // Compileer en link met 4.6 injectie
    GLuint newProgram = compileAndLinkProgram(vertexShaderPath, fragmentCode);
    if (newProgram == 0) {
        tinyfd_messageBox("Shader Error", "Failed to compile or link the shader program. Check console output.", "ok", "error", 1);
        return false;
    }
    // Succes
    if (currentShaderProgram != 0) { glDeleteProgram(currentShaderProgram); }
    currentShaderProgram = newProgram;
    iResolutionLocation = glGetUniformLocation(currentShaderProgram, "iResolution");
    iTimeLocation = glGetUniformLocation(currentShaderProgram, "iTime");
    iMouseLocation = glGetUniformLocation(currentShaderProgram, "iMouse");
    std::cout << "Successfully processed shader: " << fragmentPath << std::endl;
    if (GLFWwindow* currentWindow = glfwGetCurrentContext()) {
        std::filesystem::path p(fragmentPath); std::string title = "Shadertoy Viewer (4.6) - " + p.filename().string() + " (Press O)";
        glfwSetWindowTitle(currentWindow, title.c_str());
    }
    return true;
}

// AANGEPASTE Functie: Compileert & Linkt + Injecteert 4.6 Header
GLuint compileAndLinkProgram(const char* vPath, const std::string& originalFragmentSource) {
    std::string vertexCode = loadShaderFromFile(vPath);
     if (vertexCode.empty()) { std::cerr << "FATAL: Could not load fixed vertex shader!" << std::endl; return 0; }

    // --- Injectie van de 4.6 header ---
    std::string injectedHeader =
        "#version 460 core\n"             // <-- GEWIJZIGD naar 460 core
        "out vec4 FragColor;\n"
        "uniform vec2 iResolution;\n"
        "uniform float iTime;\n"
        "uniform vec4 iMouse;\n"
        "#define gl_FragColor FragColor\n"
        "#line 1\n"; // Reset lijnnummer

    std::string finalFragmentCode = injectedHeader + originalFragmentSource;

    // Compileer shaders
    GLuint vertexShader = compileShader(GL_VERTEX_SHADER, vertexCode.c_str(), "Vertex");
    GLuint fragmentShader = compileShader(GL_FRAGMENT_SHADER, finalFragmentCode.c_str(), "Fragment");

    // Link programma
    if (vertexShader == 0 || fragmentShader == 0) { /* cleanup */ if(vertexShader) glDeleteShader(vertexShader); if(fragmentShader) glDeleteShader(fragmentShader); return 0; }
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader); glAttachShader(program, fragmentShader); glLinkProgram(program);
    glDeleteShader(vertexShader); glDeleteShader(fragmentShader);
    int success; char infoLog[1024]; glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) { glGetProgramInfoLog(program, 1024, NULL, infoLog); std::cerr << "ERROR::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl; glDeleteProgram(program); return 0; }
    std::cout << "Shader program compiled and linked successfully (with GLSL 4.60 injections)." << std::endl;
    return program;
}

// Verwerk input, inclusief 'O' toets
void processInput(GLFWwindow *window) { /* ... (zelfde als vorige versie) ... */
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) { glfwSetWindowShouldClose(window, true); }
    static bool o_key_pressed = false;
    if (glfwGetKey(window, GLFW_KEY_O) == GLFW_PRESS && !o_key_pressed) {
        o_key_pressed = true; std::cout << "'O' key pressed, opening file dialog..." << std::endl;
        char const * lFilterPatterns[2] = { "*.frag", "*.glsl" };
        char const * selectedFilePath = tinyfd_openFileDialog("Open Fragment Shader File", "", 2, lFilterPatterns, "Fragment Shader Files (.frag, .glsl)", 0 );
        if (selectedFilePath != NULL) { std::cout << "File selected: " << selectedFilePath << std::endl; loadNewFragmentShader(selectedFilePath); }
        else { std::cout << "File selection cancelled." << std::endl; }
    }
    if (glfwGetKey(window, GLFW_KEY_O) == GLFW_RELEASE) { o_key_pressed = false; }
}

// Callback functie voor venstergrootte
void framebuffer_size_callback(GLFWwindow* /*window*/, int width, int height) { glViewport(0, 0, width, height); currentWindowWidth = (float)width; currentWindowHeight = (float)height; }
// Helper functie: lees shader uit bestand
std::string loadShaderFromFile(const char* path) { /* ... (zelfde als vorige versie) ... */
    std::string code; std::ifstream shaderFile; shaderFile.exceptions(std::ifstream::failbit | std::ifstream::badbit);
    try { shaderFile.open(path); std::stringstream shaderStream; shaderStream << shaderFile.rdbuf(); shaderFile.close(); code = shaderStream.str();
    } catch (std::ifstream::failure& e) { std::cerr << "ERROR::SHADER::FILE_NOT_SUCCESSFULLY_READ: " << path << " (" << e.what() << ")" << std::endl; return ""; }
    return code;
}
// Helper functie: compileer een shader
GLuint compileShader(GLenum type, const char* source, const char* shaderName) { /* ... (zelfde als vorige versie) ... */
     GLuint shader = glCreateShader(type); glShaderSource(shader, 1, &source, NULL); glCompileShader(shader);
     int success; char infoLog[1024]; glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
     if (!success) { glGetShaderInfoLog(shader, 1024, NULL, infoLog); std::cerr << "ERROR::SHADER::" << (shaderName ? shaderName : "") << "::COMPILATION_FAILED\n" << infoLog << std::endl; glDeleteShader(shader); return 0; }
     return shader;
}
