//
//  RosarioViewModels.swift
//  Rosario
//
//  Created by Santiago Rosell on 11/2/26.
//

import Foundation
import Combine
import AVFoundation
import MediaPlayer

// Estructura para identificar los puntos de salto en el menú
struct NavigationPoint: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let index: Int // Índice dentro de enabledSegments
}

class RosarioViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var currentSequence: RosarioSequence
    @Published var currentSegmentIndex: Int = 0          // Índice SOBRE enabledSegments()
    @Published var isPlaying: Bool = false
    @Published var isResponsorial: Bool = false          // true = responsorial, false = básico
    @Published var voiceResponds: Bool = true            // en responsorial: reproduce reply audible automáticamente
    @Published var currentText: String = ""
    @Published var errorMessage: String?
    
    // NUEVO: Publicamos el nombre de la imagen para que la vista se entere del cambio
    @Published var currentImageName: String = "img_intro"

    private var audioPlayer: AVAudioPlayer?
    private let settings: AppSettings

    private enum PlaybackPhase {
        case none
        case intro
        case replyAudible
        case replySilent
        case waitingForManualReply
    }

    private var phase: PlaybackPhase = .none
    private var pendingReplyFile: String?

    init(sequence: RosarioSequence, settings: AppSettings = AppSettings()) {
        self.currentSequence = sequence
        self.settings = settings
        super.init()
        setupAudioSession() // Configuramos el audio para modo silencio y bloqueo
        setupRemoteCommands()
        updateCurrentState()
    }

    // NUEVO MÉTODO PRIVADO (Añádelo al final de la clase o en la sección de Private Methods)
    private func setupAudioSession() {
        do {
            // .playback indica que el audio es esencial y no debe silenciarse con el interruptor lateral
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error al configurar AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Comando Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resumeRosario()
            return .success
        }

        // Comando Pausa
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseRosario()
            return .success
        }

        // Comando Siguiente
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextSegment()
            return .success
        }

        // Comando Anterior
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousSegment()
            return .success
        }
    }

    // MARK: - Public Methods

    func startRosario() {
        isPlaying = true
        playCurrentSegment()
    }

    func pauseRosario() {
        isPlaying = false
        audioPlayer?.stop()
        phase = .none
    }

    func resumeRosario() {
        isPlaying = true
        playCurrentSegment()
    }

    func nextSegment() {
        audioPlayer?.stop()
        phase = .none
        pendingReplyFile = nil

        let enabled = currentSequence.enabledSegments()
        let nextIndex = currentSegmentIndex + 1

        if nextIndex < enabled.count {
            currentSegmentIndex = nextIndex
            updateCurrentState()
            if isPlaying { playCurrentSegment() }
        } else {
            finishRosario()
        }
    }

    func previousSegment() {
        audioPlayer?.stop()
        phase = .none
        pendingReplyFile = nil

        let prevIndex = currentSegmentIndex - 1
        if prevIndex >= 0 {
            currentSegmentIndex = prevIndex
            updateCurrentState()
            if isPlaying { playCurrentSegment() }
        }
    }

    func toggleVoiceResponse() {
        voiceResponds.toggle()
    }

    func toggleResponsorial() {
        isResponsorial.toggle()
        if isPlaying {
            audioPlayer?.stop()
            phase = .none
            playCurrentSegment()
        }
    }

    func updateSequence(_ newSequence: RosarioSequence) {
        currentSequence = newSequence
        currentSegmentIndex = 0
        phase = .none
        pendingReplyFile = nil
        updateCurrentState()
    }
    
    // MARK: - Navegación Directa (Menú)

    var navigationPoints: [NavigationPoint] {
        var points: [NavigationPoint] = []
        let segments = currentSequence.enabledSegments()
        
        for (index, segment) in segments.enumerated() {
            
            // 1. Inicio
            if index == 0 {
                points.append(NavigationPoint(title: "Inicio", index: 0))
            }
            
            // 2. Misterios
            if segment.type == .mysteryIntro {
                let cleanTitle = segment.title.replacingOccurrences(of: "Misterio de ", with: "")
                points.append(NavigationPoint(title: cleanTitle, index: index))
            }
            
            // 3. Letanías
            if segment.type == .litanies {
                if !points.contains(where: { $0.title == "Letanías" }) {
                    points.append(NavigationPoint(title: "Letanías", index: index))
                }
            }
            
            // 4. Peticiones Finales
            if segment.type == .petitions {
                if !points.contains(where: { $0.title == "Peticiones" }) {
                    points.append(NavigationPoint(title: "Peticiones", index: index))
                }
            }
            
            // 5. Cierre
            if segment.type == .finalPrayers && segment.title == "Descansen en Paz" {
                 if !points.contains(where: { $0.title == "Cierre" }) {
                    points.append(NavigationPoint(title: "Cierre", index: index))
                }
            }
        }
        return points
    }

    func jumpTo(index: Int) {
        audioPlayer?.stop()
        phase = .none
        pendingReplyFile = nil
        
        let enabled = currentSequence.enabledSegments()
        if index < enabled.count {
            currentSegmentIndex = index
            updateCurrentState()
            if isPlaying {
                playCurrentSegment()
            }
        }
    }

    func respondNow() {
        guard isPlaying, isResponsorial else { return }
        guard phase == .waitingForManualReply else { return }

        let enabled = currentSequence.enabledSegments()
        guard currentSegmentIndex < enabled.count else { return }

        let segment = enabled[currentSegmentIndex]
        guard let reply = segment.audioReplyFile else {
            nextSegment()
            return
        }

        playAudio(file: reply, volume: 1.0)
        phase = .replyAudible
    }

    // MARK: - Private Methods
    
    /// Unifica la actualización de texto y de imagen
    private func updateCurrentState() {
        let enabledSegments = currentSequence.enabledSegments()
        guard currentSegmentIndex < enabledSegments.count else { return }
        
        let segment = enabledSegments[currentSegmentIndex]
        
        // 1. Actualizar Texto
        if segment.type.rawValue == segment.title {
            currentText = segment.title
        } else {
            currentText = "\(segment.type.rawValue)\n\(segment.title)"
        }
        
        if let mysteryNumber = segment.mysteryNumber,
           let group = segment.mysteryGroup {
            let mysteries = getMysteries(for: group)
            if let mystery = mysteries.first(where: { $0.number == mysteryNumber }) {
                currentText = mystery.description
            }
        }
        
        // 2. Actualizar Imagen
        currentImageName = determineImageName(for: segment)
        
        // 3. NOTIFICAR AL SISTEMA (Añade esta línea)
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        // Título: La oración actual o descripción del misterio
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentText
        
        // Subtítulo: Nombre de la App / Artista
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Santo Rosario"
        
        // Imagen: La misma que estás mostrando en la App
        if let image = UIImage(named: currentImageName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
        }
        
        // Informar al centro de control
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    /// Lógica para decidir qué imagen mostrar
    private func determineImageName(for segment: AudioSegment) -> String {
        
        // A. Si es parte de un Misterio
        if let group = segment.mysteryGroup, let number = segment.mysteryNumber {
            
            // EXCEPCIÓN: Si quieres que el Ave María tenga su propia imagen genérica
            if segment.type == .hailMary {
                // return "img_avemaria" // Descomenta si prefieres una imagen fija para el Ave María
            }
            
            // Mapeo limpio de grupos a prefijos de archivo (sin tildes/mayúsculas)
            let groupPrefix: String
            switch group {
            case .joyful: groupPrefix = "joyful"       // img_joyful_1
            case .sorrowful: groupPrefix = "sorrowful" // img_sorrowful_1
            case .glorious: groupPrefix = "glorious"   // img_glorious_1
            case .luminous: groupPrefix = "luminous"   // img_luminous_1
            }
            
            return "img_\(groupPrefix)_\(number)"
        }
        
        // B. Otras partes
        switch segment.type {
        case .signOfCross, .creed, .initialPrayers, .visita, .spiritualCommunion, .mysteryIntro:
             // mysteryIntro cae aquí si no tiene mysteryNumber asignado,
             // pero en tu modelo SÍ lo tiene, así que caerá en el 'if' de arriba.
             // Para las partes introductorias:
            return "img_intro"
            
        case .litanies:
            return "img_litanies"
            
        case .salve:
            return "img_salve"
            
        case .finalPrayers, .petitions, .threeHailMarysTrinity:
            return "img_final"
            
        default:
            return "img_default"
        }
    }
    
    private func shouldInvertMysteryPattern(segment: AudioSegment) -> Bool {
        guard let n = segment.mysteryNumber else { return false }
        if segment.type == .mysteryIntro { return false }
        return (n == 2 || n == 4) && (segment.type == .ourFather || segment.type == .hailMary)
    }

    private func playCurrentSegment() {
        let enabledSegments = currentSequence.enabledSegments()
        guard currentSegmentIndex < enabledSegments.count else {
            finishRosario()
            return
        }

        let segment = enabledSegments[currentSegmentIndex]
        pendingReplyFile = segment.audioReplyFile
        errorMessage = nil

        guard let introFile = segment.audioIntroFile else {
            nextSegment()
            return
        }
        
        // Si el título es "...", es nuestro silencio de volumen 0
        // (Esto cubre el caso de que no hayas actualizado el Model con 'case silence')
        var volume: Float = 1.0
        if segment.title == "..." {
            volume = 0.0
        }

        let invert = (!isResponsorial) && shouldInvertMysteryPattern(segment: segment)
        let finalVolume = invert ? 0.0 : volume

        playAudio(file: introFile, volume: finalVolume)
        phase = .intro
    }

    private func playAudio(file: String, volume: Float) {
        print("🔍 Intentando reproducir: \(file) (vol: \(volume))")

        guard let url = Bundle.main.url(forResource: file, withExtension: "") else {
            let errorMsg = "❌ No se encontró el archivo: \(file)"
            print(errorMsg)
            errorMessage = errorMsg
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            
            // --- CONFIGURACIÓN DE VELOCIDAD ---
            // 1. Habilitamos explícitamente el cambio de ritmo
            audioPlayer?.enableRate = true
            
            // 2. Recuperamos el valor guardado en AppStorage/UserDefaults
            // Usamos "playbackRate" que es el nombre que pusimos en SettingsView
            let savedRate = UserDefaults.standard.double(forKey: "playbackRate")
            
            // 3. Aplicamos la velocidad (si es 0 por algún error, ponemos 1.0 por defecto)
            audioPlayer?.rate = Float(savedRate > 0 ? savedRate : 1.0)
            // ----------------------------------

            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            let errorMsg = "❌ Error al reproducir audio: \(error)"
            print(errorMsg)
            errorMessage = errorMsg
        }
    }

    private func finishRosario() {
        isPlaying = false
        currentSegmentIndex = 0
        phase = .none
        pendingReplyFile = nil
        audioPlayer?.stop()
        currentText = "Rosario completado."
        currentImageName = "img_final" // Mostrar imagen final al terminar
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag, isPlaying else { return }

        switch phase {
        case .intro:
            let reply = pendingReplyFile

            if isResponsorial {
                if let reply {
                    if voiceResponds {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self, self.isPlaying else { return }
                            self.playAudio(file: reply, volume: 1.0)
                            self.phase = .replyAudible
                        }
                    } else {
                        phase = .waitingForManualReply
                    }
                } else {
                    nextSegment()
                }
            } else {
                let enabled = currentSequence.enabledSegments()
                guard currentSegmentIndex < enabled.count else {
                    finishRosario()
                    return
                }
                let segment = enabled[currentSegmentIndex]
                let invert = shouldInvertMysteryPattern(segment: segment)

                if let reply {
                    if invert {
                        playAudio(file: reply, volume: 1.0)
                        phase = .replyAudible
                    } else {
                        playAudio(file: reply, volume: 0.0)
                        phase = .replySilent
                    }
                } else {
                    nextSegment()
                }
            }

        case .replyAudible, .replySilent:
            nextSegment()

        case .waitingForManualReply:
            break

        case .none:
            break
        }
    }
}

// MARK: - EditorViewModel (Sin cambios, solo para que compile)

class EditorViewModel: ObservableObject {
    @Published var config: RosarioConfiguration
    private var currentMysteryGroup: MysteryGroup
    var onSave: ((RosarioSequence) -> Void)?
    
    init(initialConfig: RosarioConfiguration = RosarioConfiguration(), mysteryGroup: MysteryGroup) {
        self.config = initialConfig
        self.currentMysteryGroup = mysteryGroup
    }
    
    func saveChanges() {
        let newSequence = buildRosarioSequence(config: config, mysteryGroup: currentMysteryGroup)
        onSave?(newSequence)
    }
    
    func resetToDefault() {
        self.config = RosarioConfiguration()
    }
    
    func getMysteryForToday() -> MysteryGroup {
        return currentMysteryGroup
    }
}
