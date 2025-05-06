// ---- Standaard C++ Headers ----
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <chrono>
#include <filesystem> // Nodig voor bestands- en mapoperaties

// ---- Bibliotheek Headers (met aangepaste paden) ----

// GLAD (in 'include/glad/')
#include "glad/glad.h" // Gebruik "..." voor project-specifieke includes

// GLFW (Aanname: systeembibliotheek of apart pad)
#include <GLFW/glfw3.h>

// GLM is niet nodig

// ImGui (in 'include/imgui/')
#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_glfw.h"
#include "imgui/backends/imgui_impl_opengl3.h"

// Tiny File Dialogs (in 'include/tinyfiledialogs/')
#include "tinyfiledialogs/tinyfiledialogs.h"

// ---- Einde Includes ----

// --- Simpele struct om vec2 te vervangen ---
struct Vec2D {
    float x = 0.0f;
    float y = 0.0f;
};

// --- Globale Variabelen ---
unsigned int shaderProgram = 0;
unsigned int vertexShader = 0; // Start als 0 (ongeldig)
GLint timeLocation = -1;
GLint resolutionLocation = -1;
GLint mouseLocation = -1;
std::string currentShaderPath = "";

// --- Functie Declaraties ---
bool loadAndCompileShaders(const std::string& fragmentShaderPath);
void triggerFileDialogAndLoad();
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);
std::string readFile(const std::string& filePath);
std::string prepareShadertoyFragmentShader(const std::string& shadertoyFilePath);
unsigned int compileShader(GLenum type, const std::string& source, const std::string& shaderName = "Shader");
unsigned int linkShaderProgram(unsigned int vertShader, unsigned int fragShader);
void ensureDefaultVertexShaderExists(const std::string& dirPath, const std::string& filePath);

// --- Instellingen ---
const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;
const char * shaderDir = "shaders/"; // Relatief pad voor de shaders map
const char * defaultVertexShaderFilename = "default.vert"; // Alleen bestandsnaam
const char * defaultFragmentShader = "default.frag";

// --- Standaard Vertex Shader Inhoud ---
const std::string DEFAULT_VERTEX_SHADER_CONTENT = R"GLSL(
#version 330 core
layout (location = 0) in vec2 aPos;
void main()
{
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
}
)GLSL";

int main()
{
    // --- Initialisatie (GLFW, Window, GLAD) ---
    if (!glfwInit()) { std::cerr << "Failed to initialize GLFW" << std::endl; return -1; }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif
    const char* glsl_version = "#version 330";

    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Shadertoy Viewer (Menu/O=Open, Esc=Close)", NULL, NULL);
    if (window == NULL) { std::cerr << "Failed to create GLFW window" << std::endl; glfwTerminate(); return -1; }
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) { std::cerr << "Failed to initialize GLAD" << std::endl; glfwTerminate(); return -1; }

    // --- ImGui Initialisatie ---
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    // --- Zorg ervoor dat de default vertex shader bestaat ---
    std::string vertexShaderFullPath = std::string(shaderDir) + defaultVertexShaderFilename;
    ensureDefaultVertexShaderExists(shaderDir, vertexShaderFullPath);

    // --- Vertex Shader Bouwen ---
    std::string vertexShaderSource = readFile(vertexShaderFullPath);
    if (!vertexShaderSource.empty()) {
        vertexShader = compileShader(GL_VERTEX_SHADER, vertexShaderSource, "Vertex Shader");
    } else {
        std::cerr << "ERROR: Vertex shader source file could not be read (even after attempting to create it): " << vertexShaderFullPath << std::endl;
    }

    if (vertexShader == 0) {
        std::cerr << "CRITICAL ERROR: Default vertex shader (" << vertexShaderFullPath << ") could not be compiled. Application cannot run shaders." << std::endl;
        currentShaderPath = "CRITICAL: Vertex Shader Failed";
    }


    // --- Initiële Fragment Shader Laden ---
    std::string initialFragmentPath = std::string(shaderDir) + defaultFragmentShader;
    if (vertexShader != 0) {
        if (!loadAndCompileShaders(initialFragmentPath)) {
            std::cerr << "WARNING: Failed to load initial fragment shader: " << initialFragmentPath << ". Continuing without a loaded shader." << std::endl;
        }
    } else {
         // currentShaderPath is al gezet
    }


    // --- Geometrie opzetten (Fullscreen Quad) ---
     float quadVertices[] = { -1.0f, 1.0f, -1.0f, -1.0f, 1.0f, -1.0f, 1.0f, 1.0f };
     unsigned int quadIndices[] = { 0, 1, 2, 0, 2, 3 };
     unsigned int quadVAO, quadVBO, quadEBO;
     glGenVertexArrays(1, &quadVAO); glGenBuffers(1, &quadVBO); glGenBuffers(1, &quadEBO);
     glBindVertexArray(quadVAO); glBindBuffer(GL_ARRAY_BUFFER, quadVBO); glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), quadVertices, GL_STATIC_DRAW);
     glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quadEBO); glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(quadIndices), quadIndices, GL_STATIC_DRAW);
     glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0); glEnableVertexAttribArray(0);
     glBindVertexArray(0); glBindBuffer(GL_ARRAY_BUFFER, 0);

    // --- Render Loop ---
    auto startTime = std::chrono::high_resolution_clock::now();
    static Vec2D clickStartPos = {-1.0f, -1.0f};
    static bool mouseButtonDown = false;

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        if (ImGui::BeginMainMenuBar()) {
            if (ImGui::BeginMenu("File")) {
                if (ImGui::MenuItem("Open File...", "O")) {
                    triggerFileDialogAndLoad();
                }
                ImGui::Separator();
                if (ImGui::MenuItem("Close App", "Esc")) {
                    glfwSetWindowShouldClose(window, true);
                }
                ImGui::EndMenu();
            }
            ImGui::Separator();
            ImGui::Text("Shader: %s", currentShaderPath.c_str());
            ImGui::EndMainMenuBar();
        }

        processInput(window);

        auto currentTime = std::chrono::high_resolution_clock::now();
        float time = std::chrono::duration<float, std::chrono::seconds::period>(currentTime - startTime).count();

        double mouseX, mouseY;
        glfwGetCursorPos(window, &mouseX, &mouseY);
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        float glMouseY = (float)display_h - (float)mouseY;

        bool currentlyPressed = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS;
        if (currentlyPressed && !mouseButtonDown && !io.WantCaptureMouse) {
             clickStartPos.x = (float)mouseX; clickStartPos.y = glMouseY; mouseButtonDown = true;
        } else if (!currentlyPressed && mouseButtonDown) {
            mouseButtonDown = false;
        } else if (!currentlyPressed) {
             clickStartPos = {-1.0f, -1.0f};
        }

        glViewport(0, 0, display_w, display_h);
        glClearColor(0.1f, 0.1f, 0.15f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        if (shaderProgram != 0 && vertexShader != 0) {
            glUseProgram(shaderProgram);
            if (resolutionLocation != -1) { glUniform2f(resolutionLocation, (float)display_w, (float)display_h); }
            if (timeLocation != -1) { glUniform1f(timeLocation, time); }
            if (mouseLocation != -1) {
                float clickZ = mouseButtonDown ? clickStartPos.x : -abs(clickStartPos.x);
                float clickW = mouseButtonDown ? clickStartPos.y : -abs(clickStartPos.y);
                if (clickStartPos.x < 0.0f) clickZ = clickStartPos.x;
                if (clickStartPos.y < 0.0f) clickW = clickStartPos.y;
                glUniform4f(mouseLocation, (float)mouseX, glMouseY, clickZ, clickW);
            }
            glBindVertexArray(quadVAO);
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
            glBindVertexArray(0);
        }

        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        glfwSwapBuffers(window);
    }

    // --- Opruimen ---
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glDeleteVertexArrays(1, &quadVAO); glDeleteBuffers(1, &quadVBO); glDeleteBuffers(1, &quadEBO);
    if (shaderProgram != 0) { glDeleteProgram(shaderProgram); }
    if (vertexShader != 0) { glDeleteShader(vertexShader); }
    glfwDestroyWindow(window); glfwTerminate();
    return 0;
}

// --- Functie Definities ---

void ensureDefaultVertexShaderExists(const std::string& dirPathStr, const std::string& filePathStr) {
    std::filesystem::path dir(dirPathStr);
    std::filesystem::path file(filePathStr);

    if (!std::filesystem::exists(dir)) {
        std::cout << "Shader directory '" << dir << "' does not exist. Attempting to create it." << std::endl;
        try {
            if (std::filesystem::create_directories(dir)) {
                std::cout << "Shader directory created successfully." << std::endl;
            } else {
                std::cerr << "Failed to create shader directory '" << dir << "'." << std::endl;
            }
        } catch (const std::filesystem::filesystem_error& e) {
            std::cerr << "Filesystem error creating directory '" << dir << "': " << e.what() << std::endl;
            return;
        }
    } else if (!std::filesystem::is_directory(dir)) {
         std::cerr << "ERROR: Path '" << dir << "' exists but is not a directory. Cannot create default vertex shader." << std::endl;
         return;
    }

    if (!std::filesystem::exists(file)) {
        std::cout << "Default vertex shader '" << file << "' not found. Attempting to create it." << std::endl;
        std::ofstream outFile(file);
        if (outFile.is_open()) {
            outFile << DEFAULT_VERTEX_SHADER_CONTENT;
            outFile.close();
            std::cout << "Default vertex shader created successfully: " << file << std::endl;
        } else {
            std::cerr << "Failed to create or open default vertex shader file for writing: " << file << std::endl;
        }
    }
}


void triggerFileDialogAndLoad() {
    std::cout << "Triggering file dialog..." << std::endl;
    // TOEGEVOEGD: "*.*" filter om alle bestanden te tonen, en aantal filters verhoogd naar 3.
    char const * lFilterPatterns[3] = { "*.glsl", "*.frag", "*.*" };
    char const * startDir = nullptr;
    try {
        if (std::filesystem::exists(shaderDir) && std::filesystem::is_directory(shaderDir)) {
             startDir = shaderDir;
        }
    } catch (const std::filesystem::filesystem_error& e) {
        std::cerr << "Filesystem error checking shader directory: " << e.what() << std::endl;
    }

    char const * selection = tinyfd_openFileDialog(
        "Select Shadertoy Fragment Shader", // Titel
        startDir,                           // Startmap
        3,                                  // Aantal filterpatronen <-- GEWIJZIGD
        lFilterPatterns,                    // Filterpatronen array
        "Shader Files (*.glsl, *.frag) or All Files (*.*)", // Filter beschrijving <-- GEWIJZIGD
        0                                   // Meerdere selecties (0=nee)
    );

    if (selection != NULL) {
        std::string selectedPath = selection;
        std::cout << "File selected: " << selectedPath << std::endl;
        bool success = loadAndCompileShaders(selectedPath);
        if (!success) {
            if (vertexShader != 0) {
                 tinyfd_messageBox("Fragment Shader Load Error",
                                   "Failed to load or compile selected fragment shader. Check console for details.",
                                   "ok", "error", 1);
            }
        }
    } else {
        std::cout << "File dialog cancelled." << std::endl;
    }
}

bool loadAndCompileShaders(const std::string& fragmentShaderPath) {
    if (vertexShader == 0) {
        std::cerr << "ERROR: Cannot load fragment shader, vertex shader is not available or compiled." << std::endl;
        try {
            std::filesystem::path p(fragmentShaderPath);
            currentShaderPath = "Failed: " + p.filename().string() + " (Vertex Shader Missing)";
        } catch (...) {
            currentShaderPath = "Failed to load (Vertex Shader Missing)";
        }
        return false;
    }
    std::cout << "Attempting to load fragment shader: " << fragmentShaderPath << std::endl;

    std::string fragmentShaderSourcePrepared = prepareShadertoyFragmentShader(fragmentShaderPath);
    if (fragmentShaderSourcePrepared.empty()) {
        try { std::filesystem::path p(fragmentShaderPath); currentShaderPath = "Failed: " + p.filename().string() + " (File empty/unreadable)"; }
        catch (...) { currentShaderPath = "Failed to load (File empty/unreadable)"; }
        return false;
    }

    unsigned int newFragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSourcePrepared, "Fragment Shader (Shadertoy)");
    if (newFragmentShader == 0) {
         try { std::filesystem::path p(fragmentShaderPath); currentShaderPath = "Failed: " + p.filename().string() + " (Compilation Error)"; }
         catch (...) { currentShaderPath = "Failed to load (Compilation Error)"; }
        return false;
    }

    unsigned int newShaderProgram = linkShaderProgram(vertexShader, newFragmentShader);
    glDeleteShader(newFragmentShader);

    if (newShaderProgram == 0) {
        try { std::filesystem::path p(fragmentShaderPath); currentShaderPath = "Failed: " + p.filename().string() + " (Linking Error)"; }
        catch (...) { currentShaderPath = "Failed to load (Linking Error)"; }
        return false;
    }

    if (shaderProgram != 0) {
        glDeleteProgram(shaderProgram);
    }
    shaderProgram = newShaderProgram;

    timeLocation = glGetUniformLocation(shaderProgram, "iTime");
    resolutionLocation = glGetUniformLocation(shaderProgram, "iResolution");
    mouseLocation = glGetUniformLocation(shaderProgram, "iMouse");

    try { std::filesystem::path p(fragmentShaderPath); currentShaderPath = p.filename().string(); }
    catch(...) { currentShaderPath = fragmentShaderPath; }

    if (timeLocation == -1) std::cerr << "Warning: Uniform 'iTime' not found in new shader." << std::endl;
    if (resolutionLocation == -1) std::cerr << "Warning: Uniform 'iResolution' not found in new shader." << std::endl;
    if (mouseLocation == -1) std::cerr << "Warning: Uniform 'iMouse' not found in new shader." << std::endl;

    std::cout << "Shader loaded and compiled successfully: " << fragmentShaderPath << std::endl;
    return true;
}

void processInput(GLFWwindow *window) {
    ImGuiIO& io = ImGui::GetIO();
    if (!io.WantCaptureKeyboard) {
        if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
            glfwSetWindowShouldClose(window, true);
        }
        static bool o_key_pressed_shortcut = false;
        if (glfwGetKey(window, GLFW_KEY_O) == GLFW_PRESS && !o_key_pressed_shortcut) {
             o_key_pressed_shortcut = true; triggerFileDialogAndLoad();
        } else if (glfwGetKey(window, GLFW_KEY_O) == GLFW_RELEASE) {
            o_key_pressed_shortcut = false;
        }
    }
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    glViewport(0, 0, width, height);
}

std::string readFile(const std::string& filePath) {
    std::ifstream fileStream(filePath, std::ios::in | std::ios::binary);
    if (!fileStream.is_open()) {
        std::cerr << "ERROR::FILE::COULD_NOT_OPEN: " << filePath << std::endl;
        return "";
    }
    fileStream.seekg(0, std::ios::end);
    std::streamsize size = fileStream.tellg();
    fileStream.seekg(0, std::ios::beg);
    if (size <= 0) {
         if (size == 0) std::cerr << "Warning: File is empty: " << filePath << std::endl;
         else std::cerr << "ERROR::FILE::SIZE_ERROR: " << filePath << std::endl;
         return "";
    }
    std::vector<char> buffer(static_cast<size_t>(size));
    if (!fileStream.read(buffer.data(), size)) {
         std::cerr << "ERROR::FILE::READ_FAILED: " << filePath << std::endl;
         return "";
    }
    fileStream.close();
    if (size >= 3 && static_cast<unsigned char>(buffer[0]) == 0xEF &&
                     static_cast<unsigned char>(buffer[1]) == 0xBB &&
                     static_cast<unsigned char>(buffer[2]) == 0xBF) {
        return std::string(buffer.begin() + 3, buffer.end());
    } else {
        return std::string(buffer.begin(), buffer.end());
    }
}

std::string prepareShadertoyFragmentShader(const std::string& shadertoyFilePath) {
    std::string shadertoyCode = readFile(shadertoyFilePath);
    if (shadertoyCode.empty()) { return ""; }
    if (shadertoyCode.find_first_not_of(" \t\n\r\f\v") == std::string::npos) {
        std::cerr << "ERROR: Shader file is empty or contains only whitespace: " << shadertoyFilePath << std::endl;
        return "";
    }
    std::stringstream fullShaderSource;
    fullShaderSource << "#version 330 core\n\n";
    fullShaderSource << "out vec4 FragColor;\n\n";
    fullShaderSource << "uniform vec2 iResolution;\n";
    fullShaderSource << "uniform float iTime;\n";
    fullShaderSource << "uniform float iTimeDelta;\n";
    fullShaderSource << "uniform int iFrame;\n";
    fullShaderSource << "uniform float iFrameRate;\n";
    fullShaderSource << "uniform vec4 iMouse;\n";
    fullShaderSource << "uniform sampler2D iChannel0;\n";
    fullShaderSource << "uniform sampler2D iChannel1;\n";
    fullShaderSource << "uniform sampler2D iChannel2;\n";
    fullShaderSource << "uniform sampler2D iChannel3;\n";
    fullShaderSource << "uniform vec3 iChannelResolution[4];\n";
    fullShaderSource << "uniform float iChannelTime[4];\n\n";
    fullShaderSource << "// --- Begin User Shadertoy Code ---\n";
    fullShaderSource << shadertoyCode << "\n";
    fullShaderSource << "// --- End User Shadertoy Code ---\n\n";
    fullShaderSource << "// GLSL main entry point calling Shadertoy's mainImage\n";
    fullShaderSource << "void main()\n";
    fullShaderSource << "{\n";
    fullShaderSource << "    mainImage(FragColor, gl_FragCoord.xy);\n";
    fullShaderSource << "}\n";
    return fullShaderSource.str();
}

unsigned int compileShader(GLenum type, const std::string& source, const std::string& shaderName) {
    unsigned int shader = glCreateShader(type);
    const char* src = source.c_str();
    if(source.empty()) { std::cerr << "ERROR::SHADER::" << shaderName << "::SOURCE_IS_EMPTY" << std::endl; glDeleteShader(shader); return 0; }
    glShaderSource(shader, 1, &src, NULL);
    glCompileShader(shader);
    int success;
    char infoLog[1024];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 1024, NULL, infoLog);
        std::cerr << "ERROR::SHADER::" << shaderName << "::COMPILATION_FAILED\n" << infoLog << std::endl;
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

unsigned int linkShaderProgram(unsigned int vertShader, unsigned int fragShader) {
     if (vertShader == 0 || fragShader == 0) { std::cerr << "ERROR::PROGRAM::LINKING_FAILED - Invalid shader ID provided." << std::endl; return 0; }
    unsigned int program = glCreateProgram();
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    glLinkProgram(program);
    int success;
    char infoLog[1024];
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(program, 1024, NULL, infoLog);
        std::cerr << "ERROR::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
        glDetachShader(program, vertShader);
        glDetachShader(program, fragShader);
        glDeleteProgram(program);
        return 0;
    }
    return program;
}
