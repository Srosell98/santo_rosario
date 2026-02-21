
//
//  ContentView.swift
//  RosarioApp
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: RosarioViewModel
    @StateObject private var editorViewModel: EditorViewModel
    @State private var selectedTab: Int = 0
    
    let mysteryToday: MysteryGroup
    
    init() {
        // 1. Calcular misterio de hoy
        let calendar = Calendar.current
        let today = Date()
        let dayOfWeek = calendar.component(.weekday, from: today)
        let day = DayOfWeek(rawValue: dayOfWeek) ?? .sunday
        let mystery = day.mysteryGroup
        
        // 2. Crear configuración por defecto
        let defaultConfig = RosarioConfiguration(
            includeInitialPrayers: false,
            includeCredo: true,
            includeVisita: false,
            includeTrinity: true,
            includeLitanies: true,
            includeFinalPrayers: false,
            includePetitions: true
        )
        
        // 3. Crear secuencia inicial basada en config + misterio
        let initialSequence = buildRosarioSequence(config: defaultConfig, mysteryGroup: mystery)
        
        // 4. Inicializar ViewModels
        let vm = RosarioViewModel(sequence: initialSequence)
        let editorVM = EditorViewModel(initialConfig: defaultConfig, mysteryGroup: mystery)
        
        // 5. Asignar a StateObjects
        _viewModel = StateObject(wrappedValue: vm)
        _editorViewModel = StateObject(wrappedValue: editorVM)
        
        self.mysteryToday = mystery
    }
    
    var body: some View {
        ZStack {
            WoodBackground()
            
            TabView(selection: $selectedTab) {
                // Tab 1: Inicio/Hoy
                HomeTabView(
                    mysteryToday: mysteryToday,
                    onPlayComplete: { isResponsorial in
                        viewModel.isResponsorial = isResponsorial
                        viewModel.startRosario()
                        selectedTab = 1
                    }
                )
                .tag(0)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Hoy")
                }
                
                // Tab 2: Reproductor
                PlayerView(viewModel: viewModel)
                    .tag(1)
                    .tabItem {
                        Image(systemName: "play.circle.fill")
                        Text("Rezar")
                    }
                
                // Tab 3: Editor (ACTUALIZADO)
                EditorView(editorViewModel: editorViewModel, onSave: { newSequence in
                    viewModel.updateSequence(newSequence)
                })
                .tag(2)
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Editar")
                }
                
                // Tab 4: Configuración
                SettingsView()
                    .tag(3)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Ajustes")
                    }
            }
        }
        .preferredColorScheme(.none)
    }
}

// MARK: - Home Tab
struct HomeTabView: View {
    let mysteryToday: MysteryGroup
    let onPlayComplete: (Bool) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView { // ScrollView añadido para pantallas pequeñas
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Hoy es")
                            .font(.caption)
                            .foregroundColor(.brown)
                        
                        Text(mysteryToday.rawValue)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.brown)
                        
                        Text("Misterios para hoy")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(12)
                    
                    // Lista de misterios
                    VStack(spacing: 12) {
                        let mysteries = getMysteries(for: mysteryToday)
                        ForEach(mysteries) { mystery in
                            HStack {
                                Text("\(mystery.number).")
                                    .fontWeight(.bold)
                                    .foregroundColor(.brown)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mystery.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brown)
                                    
                                    Text(mystery.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Botones de acción
                    VStack(spacing: 12) {
                        Button(action: { onPlayComplete(false) }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Modo Completo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.62, green: 0.42, blue: 0.25))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { onPlayComplete(true) }) {
                            HStack {
                                Image(systemName: "waveform.circle")
                                Text("Modo Responsorial")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.72, green: 0.52, blue: 0.35))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Rosario")
        }
    }
}
// MARK: - Player View
struct PlayerView: View {
    @ObservedObject var viewModel: RosarioViewModel
    
    private func isCurrentSection(_ sectionIndex: Int) -> Bool {
        return viewModel.currentSegmentIndex >= sectionIndex &&
               viewModel.currentSegmentIndex < (sectionIndex + 20)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. Progreso visual (cuentas) - ARRIBA
                RosaryBeadProgress(
                    current: viewModel.currentSegmentIndex,
                    total: viewModel.currentSequence.enabledSegments().count
                )
                
                // 2. Texto de la oración actual - MEDIO SUPERIOR
                VStack(spacing: 12) {
                    Text(viewModel.currentText)
                        .font(.title2) // Un poco más grande para leer mejor
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                // 3. IMAGEN DINÁMICA - JUSTO DEBAJO DEL TEXTO
                // ----------------------------------------------------
                Image(viewModel.currentImageName) // Usa el nombre calculado
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280) // Ajusta altura máxima para que quepa bien
                    .cornerRadius(16)
                    .shadow(radius: 8) // Sombra suave para darle profundidad
                    .padding(.horizontal)
                    .id(viewModel.currentImageName) // ID para animar el cambio
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                // ----------------------------------------------------
                
                Spacer()
                
                // 4. Controles de reproducción - ABAJO
                VStack(spacing: 16) {
                    HStack(spacing: 40) {
                        Button(action: { viewModel.previousSegment() }) {
                            Image(systemName: "backward.fill")
                                .font(.largeTitle)
                                .foregroundColor(.brown)
                        }
                        
                        Button(action: {
                            if viewModel.isPlaying {
                                viewModel.pauseRosario()
                            } else {
                                viewModel.resumeRosario()
                            }
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.brown)
                        }
                        
                        Button(action: { viewModel.nextSegment() }) {
                            Image(systemName: "forward.fill")
                                .font(.largeTitle)
                                .foregroundColor(.brown)
                        }
                    }
                    .padding()
                    
                    // Toggles
                    HStack(spacing: 20) {
                        Toggle("Responsorial", isOn: $viewModel.isResponsorial)
                            .toggleStyle(.switch)
                            .tint(Color(red: 0.62, green: 0.42, blue: 0.25))
                            .labelsHidden()
                        Text("Responsorial")
                            .font(.caption)
                            .foregroundColor(.brown)
                        
                        if viewModel.isResponsorial {
                            Spacer().frame(width: 20)
                            Toggle("Voz responde", isOn: $viewModel.voiceResponds)
                                .toggleStyle(.switch)
                                .tint(Color(red: 0.62, green: 0.42, blue: 0.25))
                                .labelsHidden()
                            Text("Voz Auto")
                                .font(.caption)
                                .foregroundColor(.brown)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.4))
                    .cornerRadius(20)
                }
                .padding(.bottom, 30)
            }
            .padding(.top)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { // .automatic o .primaryAction para iOS/macOS
                    Menu {
                        Text("Ir a sección:")
                        ForEach(viewModel.navigationPoints, id: \.id) { point in
                            Button {
                                viewModel.jumpTo(index: point.index)
                            } label: {
                                if isCurrentSection(point.index) {
                                    Label(point.title, systemImage: "checkmark")
                                } else {
                                    Text(point.title)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brown)
                    }
                }
            }
        }
    }
}

// MARK: - Editor View (COMPLETAMENTE NUEVO)

struct EditorView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var showResetConfirm = false
    let onSave: (RosarioSequence) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección Inicial
                Section(header: Text("Parte Inicial").font(.headline).foregroundColor(.brown)) {
                    Toggle("Credo", isOn: $editorViewModel.config.includeCredo)
                    
                    Toggle("La Visita", isOn: $editorViewModel.config.includeVisita)
                    if editorViewModel.config.includeVisita {
                        Text("Incluye: Oración, 3x(PN, Ave, Gloria) y Comunión Espiritual")
                            .font(.caption).foregroundColor(.gray)
                    }
                    
                    Toggle("Rezos Iniciales (Extendidos)", isOn: $editorViewModel.config.includeInitialPrayers)
                    Toggle("Oraciones Introductorias", isOn: $editorViewModel.config.includeIntroPrayers)
                    if editorViewModel.config.includeIntroPrayers {
                        Text("Incluye: Padre Nuestro, 3 Avemarías y Gloria antes del primer misterio")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                
                // Sección Central (Informativa)
                Section(header: Text("Parte Central").font(.headline).foregroundColor(.brown)) {
                    HStack {
                        Image(systemName: "lock.fill").foregroundColor(.gray)
                        Text("5 Misterios del día")
                        Spacer()
                        Text("Fijo").foregroundColor(.secondary)
                    }
                }
                
                // Sección Final
                Section(header: Text("Parte Final").font(.headline).foregroundColor(.brown)) {
                    Toggle("Trinidad (3 Avemarías)", isOn: $editorViewModel.config.includeTrinity)
                    
                    Toggle("Letanías Lauretanas", isOn: $editorViewModel.config.includeLitanies)
                    
                    Toggle("Oraciones Finales", isOn: $editorViewModel.config.includeFinalPrayers)
                    
                    Toggle("Peticiones Finales", isOn: $editorViewModel.config.includePetitions)
                }
                
                // Acciones
                Section {
                    Button(action: { showResetConfirm = true }) {
                        Text("Restaurar valores por defecto")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        editorViewModel.saveChanges()
                        // Aquí llamamos al callback para actualizar el VM principal
                        editorViewModel.onSave = onSave
                        editorViewModel.saveChanges()
                    }) {
                        Text("Aplicar Cambios")
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.62, green: 0.42, blue: 0.25))
                    }
                }
            }
            .navigationTitle("Personalizar Rosario")
            .alert("Restaurar", isPresented: $showResetConfirm) {
                Button("Cancelar", role: .cancel) { }
                Button("Restaurar", role: .destructive) {
                    editorViewModel.resetToDefault()
                }
            } message: {
                Text("¿Volver a la configuración original?")
            }
        }
    }
}

// MARK: - Componentes

struct WoodBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.78, blue: 0.68),
                Color(red: 0.75, green: 0.65, blue: 0.50)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            Image(systemName: "leaf.fill") // Cambiado a leaf temporalmente si no tienes 'wood'
                .resizable()
                .scaledToFill()
                .opacity(0.02)
                .rotationEffect(.degrees(45))
        )
    }
}

struct RosaryBeadProgress: View {
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Mostramos solo un porcentaje o barra simple para no saturar si hay muchos items
            ProgressView(value: Double(current), total: Double(total))
                .tint(Color(red: 0.62, green: 0.42, blue: 0.25))
                .padding(.horizontal)
            
            Text("Paso \(current + 1) de \(total)")
                .font(.caption)
                .foregroundColor(.brown)
        }
        .padding()
        .background(Color.white.opacity(0.6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("voiceGender") var voiceGender: String = "female"
    @AppStorage("enableVibration") var enableVibration: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Voz") {
                    Picker("Género de voz", selection: $voiceGender) {
                        Text("Masculina").tag("male")
                        Text("Femenina").tag("female")
                    }
                }
                
                Section("Otros") {
                    Toggle("Vibración", isOn: $enableVibration)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}

#Preview {
    ContentView()
}
