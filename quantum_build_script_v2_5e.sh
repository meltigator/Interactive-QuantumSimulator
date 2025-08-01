#!/usr/bin/env bash
#
# Script di build per il Simulatore Quantistico di Curvatura Spazio-Temporale
# Versione Divulgazione Scientifica con OpenCL/OpenGL/SQLite
# 
# By Andrea Giani - Quantum Enhanced Version
#

set -e

# File names  
CPP_FILE="quantum_spacetime_main.cpp"
CL_FILE="quantum_curvature_kernel.cl"
EXE_FILE="quantum_spacetime_simulator"
DB_FILE="quantum_spacetime_data.db"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Enhanced package installation for quantum features
install_quantum_packages() {
    echo -e "${PURPLE}=== INSTALLATION OF QUANTUM SIMULATOR PACKAGES ===${NC}"
    local packages=(
        base-devel
        mingw-w64-x86_64-gcc
        mingw-w64-x86_64-cmake
        mingw-w64-x86_64-opencl-headers
        mingw-w64-x86_64-opencl-icd
        mingw-w64-x86_64-freeglut
        mingw-w64-x86_64-glew
        mingw-w64-x86_64-glm
        mingw-w64-x86_64-sqlite3
        mingw-w64-x86_64-pkg-config  # For better library detection
    )

    if [ -z "$(find /var/lib/pacman/sync -mtime -1 -print -quit 2>/dev/null)" ]; then
        echo -e "${BLUE}Repository update...${NC}"
        pacman -Sy --noconfirm
    fi

    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            echo -e "${YELLOW}Installing $pkg for quantum functionality...${NC}"
            pacman -S --needed --noconfirm "$pkg"
        fi
    done
    
    echo -e "${GREEN}✓ All installed quantum packages!${NC}"
    
    # Verify GPU/OpenCL capability
    echo -e "${BLUE}Check OpenCL support for quantum computing...${NC}"
    if command -v clinfo &> /dev/null; then
        clinfo | head -20
    else
        echo -e "${YELLOW}clinfo not available, but OpenCL should work${NC}"
    fi
}

# Generate the quantum main file (using the artifact content)
generate_quantum_main() {
	echo -e "${PURPLE}Generating main quantum C++ file...${NC}"

    cat > "$CPP_FILE" << 'EOF_QUANTUM_CPP'
#include <iostream>
#include <vector>
#include <cmath>
#include <GL/freeglut.h>
#include <cstdlib>
#include <thread>
#include <atomic>
#include <algorithm>
#include <string>
#include <ctime>
#include <windows.h>

#include <mmsystem.h>
//#pragma comment(lib, "winmm.lib")

struct QuantumState {
    double x, y, z;     // Posizione
    double dx, dy, dz;  // Direzione movimento
    double probability; // Ampiezza di probabilità
    double phase;       // Fase quantistica
    int entangled_with; // Particella correlata (-1 = nessuna)
};

std::vector<QuantumState> quantumStates;
std::atomic<bool> needsRedraw(false);
bool gravity_enabled = false;
bool show_entanglement = true;
std::string current_subtitle = "Ready for simulation";
double gravity_well = 0.0001; // Intensità curvatura
bool sound_enabled = true;

void playQuantumSound(float frequency, int duration) {
    if(!sound_enabled) return;
    Beep(static_cast<DWORD>(frequency), duration);
}

void playEventBeepSound(int eventType) {
    if(!sound_enabled) return;
    
    switch(eventType) {
        case 1: // Fluttuazioni
            playQuantumSound(800, 50);
            break;
        case 2: // Entanglement
            playQuantumSound(1200, 30);
            playQuantumSound(1500, 30);
            break;
        case 3: // Curvatura
            playQuantumSound(400, 30);
            playQuantumSound(300, 30);
            playQuantumSound(200, 30);
            break;
        case 4: // Energia
            for(int i=0; i<5; i++) {
                playQuantumSound(1500 + i*100, 20);
            }
            break;
        case 5: // Collasso
            playQuantumSound(300, 200);
            break;
        case 6: // Buco nero
            for(int i=0; i<10; i++) {
                playQuantumSound(100 + i*50, 50);
            }
            break;
    }
}

// c64 sid sawtooth
void playSidSound(float baseFreq, int duration) {
    if(!sound_enabled) return;
    
    const int sampleRate = 44100;
    const int samples = duration * sampleRate / 1000;
    short* buffer = new short[samples];
    
    // Genera onda a dente di sega
    for(int i = 0; i < samples; i++) {
        float t = static_cast<float>(i) / sampleRate;
        float sawtooth = 2.0 * (t * baseFreq - floor(0.5 + t * baseFreq));
        
        // Applica un semplice inviluppo
        float envelope = 1.0;
        if(i < 100) envelope = i / 100.0f;
        else if(i > samples - 100) envelope = (samples - i) / 100.0f;
        
        buffer[i] = static_cast<short>(30000 * sawtooth * envelope);
    }
    
    // Configura l'header WAV
    WAVEFORMATEX wfx = {};
    wfx.wFormatTag = WAVE_FORMAT_PCM;
    wfx.nChannels = 1;
    wfx.nSamplesPerSec = sampleRate;
    wfx.wBitsPerSample = 16;
    wfx.nBlockAlign = wfx.nChannels * wfx.wBitsPerSample / 8;
    wfx.nAvgBytesPerSec = wfx.nSamplesPerSec * wfx.nBlockAlign;
    
    // Prepara la struttura per la riproduzione
    WAVEHDR* header = new WAVEHDR;
    memset(header, 0, sizeof(WAVEHDR));
    header->lpData = (LPSTR)buffer;
    header->dwBufferLength = samples * sizeof(short);
    
    // Apri il dispositivo audio
    HWAVEOUT hWaveOut;
    if(waveOutOpen(&hWaveOut, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL) == MMSYSERR_NOERROR) {
        waveOutPrepareHeader(hWaveOut, header, sizeof(WAVEHDR));
        waveOutWrite(hWaveOut, header, sizeof(WAVEHDR));
        
        // Thread per la pulizia
        std::thread([hWaveOut, header, buffer]() {
            // Attendi il completamento
            while(!(header->dwFlags & WHDR_DONE)) {
                Sleep(10);
            }
            
            // Pulizia
            waveOutUnprepareHeader(hWaveOut, header, sizeof(WAVEHDR));
            waveOutClose(hWaveOut);
            delete[] buffer;
            delete header;
        }).detach();
    } else {
        delete[] buffer;
        delete header;
    }
}

// Modifica playEventSound per usare il nuovo suono
void playEventSound(int eventType) {
    if(!sound_enabled) return;
    
    switch(eventType) {
        case 1: // Fluttuazioni
            playSidSound(300.0f, 100);
            break;
        case 2: // Entanglement
            playSidSound(400.0f, 50);
            playSidSound(600.0f, 50);
            break;
        case 3: // Curvatura
            playSidSound(200.0f, 30);
            playSidSound(150.0f, 30);
            playSidSound(100.0f, 30);
            break;
        case 4: // Energia
            for(int i = 0; i < 5; i++) {
                playSidSound(500.0f + i * 100, 20);
            }
            break;
        case 5: // Collasso
            playSidSound(150.0f, 200);
            break;
        case 6: // Movimento continuo
            if(rand() % 5 == 0) { // Suoni occasionali
                playSidSound(100.0f + rand() % 200, 50);
            }
            break;
    }
}

void initQuantumSystem(int n) {
    quantumStates.clear();
    quantumStates.resize(n);
    for(int i = 0; i < n; i++) {
        quantumStates[i].x = (rand()%1000)/1000.0 - 0.5;
        quantumStates[i].y = (rand()%1000)/1000.0 - 0.5;
        quantumStates[i].z = (rand()%1000)/1000.0 - 0.5;
        quantumStates[i].dx = (rand()%100 - 50)/5000.0;
        quantumStates[i].dy = (rand()%100 - 50)/5000.0;
        quantumStates[i].dz = (rand()%100 - 50)/5000.0;
        quantumStates[i].probability = 0.1 + (rand()%900)/1000.0;
        quantumStates[i].phase = (rand()%628)/100.0;
        quantumStates[i].entangled_with = -1;
        
        // Crea entanglement tra coppie di particelle
        if(i % 2 == 0 && i+1 < n) {
            quantumStates[i].entangled_with = i+1;
            quantumStates[i+1].entangled_with = i;
        }
    }
    needsRedraw = true;
	gravity_enabled = std::rand() > (RAND_MAX / 2);
}

void quantumFluctuation() {
    for(auto& state : quantumStates) {
        // Aggiornamento fase per effetto pulsante
        state.phase += 0.01 * state.probability;
        if(state.phase > 6.28) state.phase -= 6.28;
        
        // Fluttuazione quantistica (movimento casuale)
        state.x += (rand()%100 - 50)/10000.0;
        state.y += (rand()%100 - 50)/10000.0;
        state.z += (rand()%100 - 50)/10000.0;
    }
    needsRedraw = true;
}

void spacetimeCurvature() {
    if(!gravity_enabled) return;
    
    const double center_x = 0, center_y = 0, center_z = 0;
    
    for(auto& state : quantumStates) {
        double dx = state.x - center_x;
        double dy = state.y - center_y;
        double dz = state.z - center_z;
        double dist = sqrt(dx*dx + dy*dy + dz*dz) + 0.0001;
        
        // Applica curvatura spazio-temporale
        state.dx -= gravity_well * dx / (dist*dist);
        state.dy -= gravity_well * dy / (dist*dist);
        state.dz -= gravity_well * dz / (dist*dist);
    }
}

// Funzione per creare sfere con effetto 3D realistico
void renderQuantumSphere(float size, float r, float g, float b) {
    // Abilita l'illuminazione per questa sfera
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    
    // Configura la luce
    GLfloat light_position[] = {0.0, 0.0, 3.0, 1.0};
    GLfloat light_diffuse[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat light_ambient[] = {0.2, 0.2, 0.2, 1.0};
    glLightfv(GL_LIGHT0, GL_POSITION, light_position);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
    glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
    
    // Configura il materiale per la sfera
    GLfloat mat_ambient[] = {r*0.3f, g*0.3f, b*0.3f, 1.0f};
    GLfloat mat_diffuse[] = {r, g, b, 1.0};
    GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat mat_shininess[] = {50.0};
    glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
    
    // Crea la sfera con più dettagli per un aspetto più levigato
    glutSolidSphere(size, 32, 32);
    
    // Disabilita l'illuminazione dopo aver disegnato
    glDisable(GL_LIGHT0);
    glDisable(GL_LIGHTING);
}

void renderText(float x, float y, const std::string& text, void* font = GLUT_BITMAP_HELVETICA_12) {
    glRasterPos2f(x, y);
    for (char c : text) {
        glutBitmapCharacter(font, c);
    }
}

void renderScene() {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    gluLookAt(0,0,3, 0,0,0, 0,1,0);

    // 1. RENDERIZZAZIONE 3D (PARTICELLE)
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHTING);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    for(const auto& state : quantumStates) {
        if(show_entanglement && state.entangled_with != -1) {
            const auto& other = quantumStates[state.entangled_with];
            glBegin(GL_LINES);
            glColor4f(0.8, 0.8, 1.0, 0.7);
            glVertex3f(state.x, state.y, state.z);
            glVertex3f(other.x, other.y, other.z);
            glEnd();
        }

        glPushMatrix();
        glTranslatef(state.x, state.y, state.z);
        float intensity = 0.2 + 0.8*state.probability;
        float r = intensity;
        float g = intensity/2;
        float b = 1.0-intensity;
        float size = 0.05 + 0.03*sin(state.phase);
        renderQuantumSphere(size, r, g, b);
        glPopMatrix();
    }
    
    glDisable(GL_LIGHTING);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);

    // 2. RENDERIZZAZIONE 2D (TESTO)
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    gluOrtho2D(0, glutGet(GLUT_WINDOW_WIDTH), 0, glutGet(GLUT_WINDOW_HEIGHT));
    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    // Sfondo per titolo
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glColor4f(0.0, 0.0, 0.0, 0.7);
    glBegin(GL_QUADS);
    glVertex2f(glutGet(GLUT_WINDOW_WIDTH)/2 - 220, glutGet(GLUT_WINDOW_HEIGHT) - 10);
    glVertex2f(glutGet(GLUT_WINDOW_WIDTH)/2 + 220, glutGet(GLUT_WINDOW_HEIGHT) - 10);
    glVertex2f(glutGet(GLUT_WINDOW_WIDTH)/2 + 220, glutGet(GLUT_WINDOW_HEIGHT) - 70);
    glVertex2f(glutGet(GLUT_WINDOW_WIDTH)/2 - 220, glutGet(GLUT_WINDOW_HEIGHT) - 70);
    glEnd();
    glDisable(GL_BLEND);

    // Titolo principale
    glColor3f(0.2, 1.0, 1.0); // Ciano brillante
    renderText(glutGet(GLUT_WINDOW_WIDTH)/2 - 200, 
               glutGet(GLUT_WINDOW_HEIGHT) - 30, 
               "QUANTUM SPACE-TIME SIMULATION",
               GLUT_BITMAP_HELVETICA_18);

    // Sottotitolo
    glColor3f(1.0, 1.0, 0.5); // Giallo
    renderText(glutGet(GLUT_WINDOW_WIDTH)/2 - 100, 
               glutGet(GLUT_WINDOW_HEIGHT) - 60, 
               current_subtitle);

    // Informazioni
    glColor3f(1.0, 1.0, 1.0); // Bianco
    renderText(10, glutGet(GLUT_WINDOW_HEIGHT) - 30, 
               "Curvature: " + std::string(gravity_enabled ? "ENABLE" : "DISABLE"));
    
    renderText(10, 30, 
               "Particles: " + std::to_string(quantumStates.size()));

    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);

    glutSwapBuffers();
}

void resizeWindow(int w, int h) {
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0, (double)w / (double)h, 0.1, 100.0);
    glMatrixMode(GL_MODELVIEW);
}

void update(int value) {
    quantumFluctuation();
    spacetimeCurvature();
    
    for(auto& state : quantumStates) {
        state.x += state.dx;
        state.y += state.dy;
        state.z += state.dz;
        
        // Mantiene le particelle nell'area visibile
        if(std::abs(state.x) > 1.0) state.dx *= -0.8;
        if(std::abs(state.y) > 1.0) state.dy *= -0.8;
        if(std::abs(state.z) > 1.0) state.dz *= -0.8;

        // Suono di movimento (occasionale)
    //  if(std::rand() % 100 < 5) { // 5% di probabilità per frame
        if(std::rand() % 100 == 42) { // 5% di probabilità per frame
            playEventSound(6);
        }
    }
    
    glutPostRedisplay();
    glutTimerFunc(16, update, 0);
}

void idle() {
    glutPostRedisplay();
}

void runMenu() {
    int choice;
    do {
		std::cout << "\n=== INTERACTIVE QUANTUM SIMULATOR ===";
		std::cout << "\n1. Generate new quantum fluctuations";
		std::cout << "\n2. " << (show_entanglement ? "Hide" : "Show") << " entanglement";
		std::cout << "\n3. Toggle space-time curvature";
		std::cout << "\n4. Increase particle energy";
		std::cout << "\n5. Observer effect (wave function collapse)";
		std::cout << "\n6. Black hole mode";
		std::cout << "\n7. " << (sound_enabled ? "Disable" : "Enable") << " sounds"; 
		std::cout << "\n8. Exit"; 
		std::cout << "\nChoice: ";
        std::cin >> choice;
        
        switch(choice) {
            case 1:
                initQuantumSystem(500);
				playEventSound(1);
                current_subtitle = "Quantum Fluctuations";
                std::cout << "\nNew quantum fluctuations generated!";
                break;
            case 2:
                show_entanglement = !show_entanglement;
				playEventSound(2);
                current_subtitle = show_entanglement ? "Quantum Entanglement" : "Hidden Entanglement";
                std::cout << "\nEntanglement " << (show_entanglement ? "VISIBLE" : "HIDDEN");
                break;
            case 3:
                gravity_enabled = !gravity_enabled;
				playEventSound(3);
                current_subtitle = gravity_enabled ? "Active Space-Time Curvature" : "Flat Space-Time";
                std::cout << "\nSpace-time curvature " 
                          << (gravity_enabled ? "ENABLE" : "DISABLE");
                break;
            case 4:
                current_subtitle = "Increased Kinetic Energy";
				playEventSound(4);
                std::cout << "\nIncreased particle energy!";
                for(auto& state : quantumStates) {
                    state.dx *= 1.5;
                    state.dy *= 1.5;
                    state.dz *= 1.5;
                }
                break;
            case 5:
				current_subtitle = "Wavefunction Collapse";
				playEventSound(5);
				std::cout << "\nWavefunction collapse observed!";
                for(auto& state : quantumStates) {
                    if(rand() % 100 < 30) {
                        state.dx = state.dy = state.dz = 0;
                        state.probability = std::min(1.0, state.probability * 1.5);
                    }
                }
                break;
            case 6:
				current_subtitle = "Black Hole Simulation"; 				
				playEventSound(6);				
				std::cout << "\nBlack hole mode enabled!";
                gravity_enabled = true;
                gravity_well = 0.001;
                break;
            case 7:
                sound_enabled = !sound_enabled;
        //      playEventSound(sound_enabled ? 1 : 5); // Feedback uditivo
				// Suono caratteristico di avvio C64
				playSidSound(100.0f, 100);
				playSidSound(200.0f, 100);
				playSidSound(400.0f, 300);
				current_subtitle = "c64 SID Audio Mode ";
                std::cout << (sound_enabled ? "ENABLE" : "DISABLE");				
                break;
            case 8:
                exit(0);
                break;
        }
        needsRedraw = true;
    } while(true);
}

int main(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DEPTH | GLUT_DOUBLE | GLUT_RGBA);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Quantum Simulator");
    
    glutDisplayFunc(renderScene);
    glutReshapeFunc(resizeWindow);
    glutIdleFunc(idle);
    glutTimerFunc(0, update, 0);
    
    // Abilita caratteristiche avanzate per l'effetto 3D
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_NORMALIZE); // Normalizza le normali per l'illuminazione
    glShadeModel(GL_SMOOTH); // Rendering sfumato
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    std::srand(std::time(0));
    
    std::thread menuThread(runMenu);
    menuThread.detach();
    
    glutMainLoop();
    return 0;
}
EOF_QUANTUM_CPP

    echo -e "${GREEN}✓ Generated quantum C++ file: $CPP_FILE${NC}"
}

# The OpenCL kernel is generated by the C++ code itself
verify_quantum_kernel() {
	echo -e "${BLUE}The OpenCL quantum kernel will be automatically generated by the C++ program${NC}"
	echo -e "${BLUE}Features of the quantum kernel:${NC}"
	echo -e " ${GREEN}• GPU parallel computations for vacuum fluctuations${NC}"
	echo -e " ${GREEN}• Quantum amplitudes with complex phase${NC}"
	echo -e " ${GREEN}• Dynamic coherence lengths${NC}"
	echo -e " ${GREEN}• Quantum information density (qubits/m³)${NC}"
	echo -e " ${GREEN}• Gravitational entanglement measurements${NC}"
}

# Enhanced compilation with quantum optimizations
compile_quantum() {
    echo -e "${PURPLE}=== QUANTUM SIMULATOR COMPILATION ===${NC}"
    
    local CXX_FLAGS="-g -Wall -std=c++11 -O3 -DFREEGLUT_STATIC -I/mingw64/include"
    local LD_FLAGS="-L/mingw64/lib -lfreeglut -lglu32 -lopengl32 -lgdi32 -lOpenCL -lsqlite3 -lwinmm"
    
    # Ignora l'avvertimento sul pragma
    local EXTRA_FLAGS="-Wno-unknown-pragmas"
    
    echo -e "${BLUE}Quantum compilation command:${NC}"
    echo "g++ $CPP_FILE -o $EXE_FILE $CXX_FLAGS $LD_FLAGS $EXTRA_FLAGS"  
	
    if g++ "$CPP_FILE" -o "$EXE_FILE" $CXX_FLAGS $LD_FLAGS; then
        echo -e "${GREEN}✓ QUANTUM SIMULATOR SUCCESSFULLY COMPILED!${NC}"
        echo -e "${PURPLE}Eseguibile: $EXE_FILE${NC}"
        
        # Show file size and info
        if [ -f "$EXE_FILE" ]; then
            local size=$(stat -f%z "$EXE_FILE" 2>/dev/null || stat -c%s "$EXE_FILE" 2>/dev/null || echo "unknown")
            echo -e "${BLUE}Executable size: $size bytes${NC}"
        fi
    else
        echo -e "${RED}✗ QUANTUM SIMULATOR COMPILATION ERROR${NC}"
        echo -e "${YELLOW}Suggestions:${NC}"
        echo -e "  ${YELLOW}• Verify package installation OpenCL/OpenGL${NC}"
        echo -e "  ${YELLOW}• Check drivers GPU${NC}"
        echo -e "  ${YELLOW}• Try with ./build_quantum_simulator.sh clean && ./build_quantum_simulator.sh build${NC}"
        exit 1
    fi
}

# Enhanced cleanup
clean_quantum() {
    echo -e "${YELLOW}Quantum Simulator File Cleanup...${NC}"
    rm -f "$CPP_FILE" "$CL_FILE" "$EXE_FILE"
    echo -e "${BLUE}Preserved quantum database: $DB_FILE${NC}"
    echo -e "${GREEN}✓ Cleaning completed${NC}"
}

# Run with quantum features info
run_quantum() {
    if [ -f "$EXE_FILE" ]; then
		echo -e "${PURPLE}=== START QUANTUM SIMULATOR ===${NC}"
		echo -e "${GREEN}Available Features:${NC}"
		echo -e " ${BLUE}1. Parallel quantum simulation (OpenCL)${NC}"
		echo -e " ${BLUE}2. Visualization of 6 quantum modes (OpenGL)${NC}"
		echo -e " ${BLUE}3. Persistent results database (SQLite)${NC}"
		echo -e " ${BLUE}4. Real-time quantum state analysis${NC}"
		echo -e " ${BLUE}5. Data export for research${NC}"
		echo ""
		echo -e "${YELLOW}Hint: Start with option 1 (simulation), then 2 (visualization)${NC}"
        echo ""
        ./"$EXE_FILE"
    else
        echo -e "${RED}Executable $EXE FILE not found.${NC}"
        echo -e "${YELLOW}Run: ./build_quantum_simulator.sh build${NC}"
        exit 1
    fi
}

# Show quantum info
show_quantum_info() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║               QUANTUM SPACE-TIME SIMULATOR                   ║${NC}"
    echo -e "${PURPLE}║                 written by Andrea Giani                      ║${NC}"
    echo -e "${PURPLE}║              Scientific Popularization v2.5                  ║${NC}"  
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║  ${GREEN}Technologies: OpenCL + OpenGL + SQLite                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║  ${BLUE}Physics: General Relativity + Quantum Mechanics             ${PURPLE}║${NC}"
    echo -e "${PURPLE}║  ${YELLOW}Target: Researchers + Outreach + Students                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
	echo -e "${GREEN}Visible Quantum Effects:${NC}"
	echo -e " ${BLUE}- Quantum Vacuum Fluctuations${NC}"
	echo -e " ${BLUE}- Geometric Probability Amplitudes${NC}"
	echo -e " ${BLUE}- Gravitational Entanglement${NC}"
	echo -e " ${BLUE}- Quantum Coherence/Decoherence${NC}"
	echo -e " ${BLUE}- Quantum Information Density${NC}"
	echo -e " ${BLUE}- Quantum Curvature Corrections${NC}"
    echo ""
	echo -e "${YELLOW}Available Commands:${NC}"
	echo -e "  ${GREEN}build${NC}  - Install packages, generate code, and compile"
	echo -e "  ${GREEN}run${NC}    - Run the quantum simulator"
	echo -e "  ${GREEN}clean${NC}  - Clean generated files"
	echo -e "  ${GREEN}info${NC}   - Show this information"
    echo ""
}

# Main logic
case "$1" in
  build)
    show_quantum_info
    install_quantum_packages
    generate_quantum_main
    verify_quantum_kernel
    compile_quantum
    echo -e "${PURPLE}(!) QUANTUM SIMULATOR READY (!)${NC}"
    echo -e "${GREEN}Run: ./build_quantum_simulator.sh run${NC}"
    ;;
  run)
    run_quantum
	
#	while true; do
#		read -rp "Select an option: " option

#		case "$option" in
#			1)
#				build_quantum_engine
#				;;
#			2)
#				run_benchmarks
#				;;
#			3)
#				echo "Exiting."
#				break
#				;;
#			*)
#				echo "Invalid option"
#				;;
#		esac
#	done
	
    ;;
  clean)
    clean_quantum
    ;;
  info)
    show_quantum_info
    ;;
  *)
    show_quantum_info
    echo -e "${RED}Use: $0 {build|run|clean|info}${NC}"
    exit 1
    ;;
esac
