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
                        let savedMode = UserDefaults.standard.string(forKey: "prayerMode") ?? "complete"
                        viewModel.isResponsorial = (savedMode == "responsorial")
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
                VStack(spacing: 5) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Hoy se rezan los misterios")
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
                    VStack(spacing: 1) {
                        let mysteries = getMysteries(for: mysteryToday)
                        ForEach(mysteries) { mystery in
                            HStack {
                                Text("\(mystery.number).")
                                    .fontWeight(.bold)
                                    .foregroundColor(.brown)
                                
                                VStack(alignment: .leading, spacing: 2) {
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
                    
                    Spacer(minLength: 5)
                                        
                    // Botón de acción único - Empezar
                    Button(action: {
                        let prayerMode = UserDefaults.standard.string(forKey: "prayerMode") ?? "complete"
                        let isResponsorial = prayerMode == "responsorial"
                        onPlayComplete(isResponsorial)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Empezar Santo Rosario")
                                  .font(.custom("New York", size: 25))
                        }
                    }
                    .frame(minHeight: 64)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(red: 0.62, green: 0.42, blue: 0.25))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(radius: 20)
                }
                .padding()
            }
            .navigationTitle("Santo Rosario")
        }
    }
}// MARK: - Player View
struct PlayerView: View {
    @ObservedObject var viewModel: RosarioViewModel
    @State private var showNavigationSheet = false
    
    private func isCurrentSection(_ sectionIndex: Int) -> Bool {
        return viewModel.currentSegmentIndex >= sectionIndex &&
               viewModel.currentSegmentIndex < (sectionIndex + 20)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- BLOQUE SUPERIOR ---
                VStack(spacing: 12) {
                    // 1. Progreso visual
                    RosaryBeadProgress(
                        current: viewModel.currentSegmentIndex,
                        total: viewModel.currentSequence.enabledSegments().count
                    )
                    .padding(.top)

                    // 2. Bloque de Texto Estilizado (Igual al botón de inicio)
                    VStack {
                        Text(viewModel.currentText)
                            .font(.custom("New York", size: 25)) // Fuente solicitada
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white) // Letra blanca
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80) // Asegura un tamaño mínimo elegante
                    .background(Color(red: 0.62, green: 0.42, blue: 0.25)) // El color marrón exacto
                    .cornerRadius(14) // Radio solicitado
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10) // Sombra profunda
                    .padding(.horizontal)

                    // Error o Indicador de Ave María
                    VStack(spacing: 8) {
                        if let error = viewModel.errorMessage {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let segment = (viewModel.currentSegmentIndex < viewModel.currentSequence.enabledSegments().count) ? viewModel.currentSequence.enabledSegments()[viewModel.currentSegmentIndex] : nil,
                           segment.type == .hailMary,
                           let number = segment.mysteryNumber, let group = segment.mysteryGroup {
                            
                            let hailsInMystery = viewModel.currentSequence.enabledSegments().filter { $0.type == .hailMary && $0.mysteryNumber == number && $0.mysteryGroup == group }
                            
                            if let idx = hailsInMystery.firstIndex(where: { $0.id == segment.id }) {
                                Text("Ave María \(idx + 1) de \(hailsInMystery.count)")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundColor(.brown)
                                    .italic()
                            }
                        }
                    }
                }

                // --- ESPACIADO DINÁMICO ---
                Spacer()
                
                // 3. IMAGEN DINÁMICA (CENTRAL)
                Image(viewModel.currentImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.horizontal)
                    .id(viewModel.currentImageName)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                
                Spacer()
                // --------------------------

                // 4. CONTROLES DE REPRODUCCIÓN (ABAJO)
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
                }
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showNavigationSheet = true }) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brown)
                    }
                }
            }
            .sheet(isPresented: $showNavigationSheet) {
                NavigationStack {
                    List {
                        ForEach(viewModel.navigationPoints, id: \.id) { point in
                            Button(action: {
                                viewModel.jumpTo(index: point.index)
                                showNavigationSheet = false
                            }) {
                                HStack {
                                    Text(point.title)
                                        .foregroundColor(.brown)
                                    
                                    Spacer()
                                    
                                    if isCurrentSection(point.index) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Ir a sección")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Cerrar") {
                                showNavigationSheet = false
                            }
                        }
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
                    
                    // Agregado: Toggle para incluir Salve después de los Misterios
                    Toggle("Salve (después de los Misterios)", isOn: $editorViewModel.config.includeSalve)
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
    @AppStorage("prayerMode") var prayerMode: String = "complete"
    
    // Nueva propiedad para la velocidad (por defecto 1.0)
    @AppStorage("playbackRate") var playbackRate: Double = 1.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Modo de Oración") {
                    Picker("Tipo de oración", selection: $prayerMode) {
                        Text("Modo Completo").tag("complete")
                        Text("Modo Responsorial").tag("responsorial")
                    }
                }
                
                // NUEVA SECCIÓN DE VELOCIDAD
                Section(header: Text("Velocidad de audio")) {
                    VStack {
                        HStack {
                            Text("Velocidad")
                            Spacer()
                            Text("\(playbackRate, specifier: "%.1f")x")
                                .bold()
                                .foregroundColor(Color(red: 0.62, green: 0.42, blue: 0.25))
                        }
                        Slider(value: $playbackRate, in: 0.5...2.0, step: 0.1)
                            .tint(Color(red: 0.62, green: 0.42, blue: 0.25)) // Tu color marrón
                    }
                }
                
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

