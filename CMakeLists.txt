cmake_minimum_required(VERSION 3.10) # Of nieuwer
project(ShaderToyViewer LANGUAGES CXX C) # Voeg C toe voor glad.c, tinyfiledialogs.c

# Vind benodigde pakketten (GLFW, OpenGL)
find_package(glfw3 REQUIRED)
find_package(OpenGL REQUIRED)
# find_package(Threads REQUIRED) # Vaak nodig op Linux

# Stel C++ standaard in (optioneel maar aanbevolen)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# --- Definieer Bronbestanden ---
# Hoofdbestand en andere C-bestanden
set(APP_SOURCES
    src/main.cpp
    src/glad/glad.c                 # Compileer glad.c
    src/tinyfiledialogs/tinyfiledialogs.c # Compileer tinyfiledialogs.c
)

# Voeg ImGui Kern Bronbestanden toe
list(APPEND APP_SOURCES
    src/imgui/imgui.cpp
    src/imgui/imgui_draw.cpp
    src/imgui/imgui_tables.cpp
    src/imgui/imgui_widgets.cpp
    # Voeg eventueel imgui_demo.cpp toe als je de demo gebruikt
)

# Voeg ImGui Backend Bronbestanden toe
list(APPEND APP_SOURCES
    src/imgui/backends/imgui_impl_glfw.cpp
    src/imgui/backends/imgui_impl_opengl3.cpp
)

# --- Maak de Executable ---
add_executable(shadertoy_viewer ${APP_SOURCES})

# --- Stel Include Directories in (belangrijk!) ---
# Vertel CMake waar de headers te vinden zijn
target_include_directories(shadertoy_viewer PRIVATE
    include        # Voor "glad/glad.h", "tinyfiledialogs/tinyfiledialogs.h" etc.
                   # en voor "imgui/backends/..." vanuit main.cpp
    include/imgui
    include/tinyfiledialogs   # Zodat ImGui's interne #include "imgui.h", "imconfig.h" etc. werkt
)

# --- Link Bibliotheken ---
target_link_libraries(shadertoy_viewer PRIVATE
    glfw            # Link met GLFW
    OpenGL::GL      # Link met OpenGL (moderne CMake manier)
    # Threads::Threads # Vaak nodig op Linux voor GLFW/OpenGL
    # Als je op Linux extra libs nodig hebt (zelden met moderne CMake):
    # $<TARGET_OBJECTS:m> $<TARGET_OBJECTS:dl> $<TARGET_OBJECTS:pthread>
)

# Optioneel: Voeg compile definitie toe als ImGui dat vereist (zelden nodig)
# target_compile_definitions(shadertoy_viewer PRIVATE IMGUI_IMPL_OPENGL_LOADER_GLAD)
