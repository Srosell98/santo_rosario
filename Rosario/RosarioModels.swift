//
//  RosarioModels.swift
//  Rosario
//
//  Created by Santiago Rosell on 11/2/26.
//
//
//
//
//  RosarioModels.swift
//  Rosario
//
//  Created by Santiago Rosell on 11/2/26.
//

import Foundation
import Combine

// MARK: - Enums

enum RosarioPartType: String, Codable, CaseIterable {
    // Iniciales
    case signOfCross = "Señal de la Cruz"
    case initialPrayers = "Rezos Iniciales" // signal_cross_extended + vocal_prayers
    case visita = "La Visita" // 3x(PN, Ave, Gloria) + comunión
    case spiritualCommunion = "Comunión Espiritual"
    case creed = "Credo"
    
    // Centrales
    case ourFather = "Padre Nuestro"
    case hailMary = "Ave María"
    case gloryBe = "Gloria"
    case mysteryIntro = "Anuncio del Misterio"
    case fatimaPrayer = "Jaculatoria"
    case salve = "Salve"
    
    // Finales
    case threeHailMarysTrinity = "3 Avemarías (Trinidad)"
    case litanies = "Letanías"
    case finalPrayers = "Oraciones Finales" // Letanías lauretanas (audio)
    case petitions = "Peticiones Finales" // Iglesia, Obispo, Almas
}

enum MysteryGroup: String, Codable, CaseIterable {
    case joyful = "Gozosos"
    case sorrowful = "Dolorosos"
    case glorious = "Gloriosos"
    case luminous = "Luminosos"
}

enum DayOfWeek: Int, Codable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    var mysteryGroup: MysteryGroup {
        switch self {
        case .monday, .saturday: return .joyful
        case .tuesday, .friday: return .sorrowful
        case .wednesday, .sunday: return .glorious
        case .thursday: return .luminous
        }
    }
}

enum VoiceGender: String, Codable {
    case male = "Masculina"
    case female = "Femenina"
}

// MARK: - Configuration Struct (NUEVO)

struct RosarioConfiguration: Codable {
    // Sección Inicial
    var includeInitialPrayers: Bool = true // signal_cross_extended + vocal_prayers
    var includeCredo: Bool = false
    var includeVisita: Bool = true         // 3x(PN, Ave, Gloria) + comunión
    var includeIntroPrayers: Bool = true    //PN + 3 Aves + Gloria
    // Sección Central (Fija, no editable)
    
    // Sección Final
    var includeTrinity: Bool = true         // 3 Avemarías finales
    var includeLitanies: Bool = true        // Letanías normales
    var includeFinalPrayers: Bool = true   // Oraciones finales extra (lauretanas)
    var includePetitions: Bool = true       // Iglesia, Obispo, Almas
}

// MARK: - Structs

struct AudioSegment: Identifiable, Codable {
    let id: UUID
    let type: RosarioPartType
    let title: String
    var order: Int
    let audioIntroFile: String?
    let audioReplyFile: String?
    let mysteryNumber: Int?
    let mysteryGroup: MysteryGroup?
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        type: RosarioPartType,
        title: String,
        order: Int,
        audioIntroFile: String? = nil,
        audioReplyFile: String? = nil,
        mysteryNumber: Int? = nil,
        mysteryGroup: MysteryGroup? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.order = order
        self.audioIntroFile = audioIntroFile
        self.audioReplyFile = audioReplyFile
        self.mysteryNumber = mysteryNumber
        self.mysteryGroup = mysteryGroup
        self.isEnabled = isEnabled
    }
}

struct Mystery: Identifiable, Codable {
    let id: UUID
    let number: Int
    let title: String
    let description: String
    let group: MysteryGroup
    
    init(
        id: UUID = UUID(),
        number: Int,
        title: String,
        description: String,
        group: MysteryGroup
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.description = description
        self.group = group
    }
}

struct RosarioSequence: Identifiable, Codable {
    let id: UUID
    var segments: [AudioSegment]
    
    init(id: UUID = UUID(), segments: [AudioSegment] = []) {
        self.id = id
        self.segments = segments
    }
    
    func enabledSegments() -> [AudioSegment] {
        return segments.filter { $0.isEnabled }
    }
}

struct AppSettings: Codable {
    var voiceGender: VoiceGender = .female
    var language: String = "es"
    var enableVibration: Bool = true
    var enableLetanies: Bool = true
    var enableFinalPetitions: Bool = true
}

// MARK: - Mystery Data

let mysteriesJoyful: [Mystery] = [
    Mystery(number: 1, title: "Anunciación", description: "Anunciación del Ángel Gabriel a María", group: .joyful),
    Mystery(number: 2, title: "Visitación", description: "Visitación de María a su prima Isabel", group: .joyful),
    Mystery(number: 3, title: "Nacimiento", description: "Nacimiento de Nuestro Señor Jesucristo", group: .joyful),
    Mystery(number: 4, title: "Presentación", description: "Presentación de Jesús en el Templo", group: .joyful),
    Mystery(number: 5, title: "Hallazgo", description: "Hallazgo del Niño Jesús en el Templo", group: .joyful)
]

let mysteriesSorrowful: [Mystery] = [
    Mystery(number: 1, title: "Oración en el Huerto", description: "Oración de Jesús en el Huerto", group: .sorrowful),
    Mystery(number: 2, title: "Azotamiento", description: "Azotamiento de Nuestro Señor Jesucristo", group: .sorrowful),
    Mystery(number: 3, title: "Coronación de Espinas", description: "Coronación de espinas", group: .sorrowful),
    Mystery(number: 4, title: "Camino del Calvario", description: "Camino del Calvario", group: .sorrowful),
    Mystery(number: 5, title: "Crucifixión", description: "Crucifixión y muerte de Nuestro Señor Jesucristo", group: .sorrowful)
]

let mysteriesGlorious: [Mystery] = [
    Mystery(number: 1, title: "Resurrección", description: "Resurrección de Nuestro Señor Jesucristo", group: .glorious),
    Mystery(number: 2, title: "Ascensión", description: "Ascensión de Nuestro Señor Jesucristo", group: .glorious),
    Mystery(number: 3, title: "Venida del Espíritu Santo", description: "Venida del Espíritu Santo", group: .glorious),
    Mystery(number: 4, title: "Asunción", description: "Asunción de Nuestra Señora María", group: .glorious),
    Mystery(number: 5, title: "Coronación", description: "Coronación de Nuestra Señora María", group: .glorious)
]

let mysteriesLuminous: [Mystery] = [
    Mystery(number: 1, title: "Bautismo", description: "Bautismo de Jesús en el Jordán", group: .luminous),
    Mystery(number: 2, title: "Bodas de Caná", description: "Milagro de Caná", group: .luminous),
    Mystery(number: 3, title: "Predicación", description: "Predicación de Jesús y su llamada al arrepentimiento", group: .luminous),
    Mystery(number: 4, title: "Transfiguración", description: "Transfiguración de Jesús", group: .luminous),
    Mystery(number: 5, title: "Eucaristía", description: "Institución de la Eucaristía", group: .luminous)
]

func getMysteries(for group: MysteryGroup) -> [Mystery] {
    switch group {
    case .joyful:
        return mysteriesJoyful
    case .sorrowful:
        return mysteriesSorrowful
    case .glorious:
        return mysteriesGlorious
    case .luminous:
        return mysteriesLuminous
    }
}

// MARK: - Default Rosario Sequence Builder

func buildRosarioSequence(config: RosarioConfiguration, mysteryGroup: MysteryGroup) -> RosarioSequence {
    var segments: [AudioSegment] = []
    var order = 0
    
    // ---------------------------------------------------------
    // 1. SECCIÓN INICIAL
    // ---------------------------------------------------------
    
    // SIEMPRE añadir Señal de la Cruz básica primero
    segments.append(AudioSegment(type: .signOfCross, title: "Señal de la Cruz", order: order, audioIntroFile: "sign_of_cross.m4a"))
    order += 1
    
    // Opción 1: Credo (ahora independiente)
    if config.includeCredo {
        segments.append(AudioSegment(type: .creed, title: "Credo", order: order, audioIntroFile: "creed.m4a"))
        order += 1
    }
    
    // Opción 2: La Visita (3x PN, Ave, Gloria + Comunión)
    // Opción 2: La Visita (3x [Oración Inicial, PN, Ave, Gloria] + Comunión)
    if config.includeVisita {
        
        // Repetir 3 veces el ciclo completo
        for i in 1...3 {
            // 1. Oración inicial de visita (antes de cada PN)
            segments.append(AudioSegment(
                type: .visita,
                title: "Visita \(i) - Oración Inicial",
                order: order,
                audioIntroFile: "initial_prayer_visita.m4a" // Se repite 3 veces
            ))
            order += 1
            
            // 2. Padre Nuestro
            segments.append(AudioSegment(
                type: .ourFather,
                title: "Visita \(i) - Padre Nuestro",
                order: order,
                audioIntroFile: "padre_nuestro_intro.m4a",
                audioReplyFile: "padre_nuestro_reply.m4a"
            ))
            order += 1
            
            // 3. Ave María
            segments.append(AudioSegment(
                type: .hailMary,
                title: "Visita \(i) - Ave María",
                order: order,
                audioIntroFile: "ave_maria_intro.m4a",
                audioReplyFile: "ave_maria_reply.m4a"
            ))
            order += 1
            
            // 4. Gloria
            segments.append(AudioSegment(
                type: .gloryBe,
                title: "Visita \(i) - Gloria",
                order: order,
                audioIntroFile: "gloria_intro.m4a",
                audioReplyFile: "gloria_reply.m4a"
            ))
            order += 1
        }
        
        // Comunión espiritual (solo una vez al final)
        segments.append(AudioSegment(
            type: .spiritualCommunion,
            title: "Comunión Espiritual",
            order: order,
            audioIntroFile: "spiritual_communion.m4a"
        ))
        order += 1
    }    // Opción 3: Rezos Iniciales (Extended + Vocal Prayers)
    if config.includeInitialPrayers {
        segments.append(AudioSegment(type: .initialPrayers, title: "Señal Cruz Extendida", order: order, audioIntroFile: "signal_cross_extended.m4a"))
        order += 1
        segments.append(AudioSegment(type: .initialPrayers, title: "Oraciones Vocales", order: order, audioIntroFile: "vocal_prayers.m4a"))
        order += 1
    }
    
    // ---------------------------------------------------------
    // 2. SECCIÓN CENTRAL (MISTERIOS) - FIJO
    // ---------------------------------------------------------
    
    // Intro Prayers (PN + 3 Aves + Gloria)
    if config.includeIntroPrayers {
        // Introducción a los misterios
        segments.append(AudioSegment(type: .ourFather, title: "Padre Nuestro (Inicio)", order: order, audioIntroFile: "padre_nuestro_intro.m4a", audioReplyFile: "padre_nuestro_reply.m4a"))
        order += 1
        
        // 3 Avemarías iniciales
        for i in 1...3 {
            segments.append(AudioSegment(type: .hailMary, title: "Ave María \(i)", order: order, audioIntroFile: "ave_maria_intro.m4a", audioReplyFile: "ave_maria_reply.m4a"))
            order += 1
        }
        
        segments.append(AudioSegment(type: .gloryBe, title: "Gloria", order: order, audioIntroFile: "gloria_intro.m4a", audioReplyFile: "gloria_reply.m4a"))
        order += 1
    }
    
    // Los 5 Misterios del día
    let mysteries = getMysteries(for: mysteryGroup)
    for mystery in mysteries {
        // 1. Anuncio
        segments.append(AudioSegment(
            type: .mysteryIntro, title: "Misterio \(mystery.number): \(mystery.title)", order: order,
            audioIntroFile: "mystery_\(mysteryGroup.rawValue.lowercased())_\(mystery.number).m4a",
            mysteryNumber: mystery.number, mysteryGroup: mysteryGroup
        ))
        order += 1
        
        // 2. Padre Nuestro
        segments.append(AudioSegment(
            type: .ourFather, title: "Padre Nuestro", order: order,
            audioIntroFile: "padre_nuestro_intro.m4a", audioReplyFile: "padre_nuestro_reply.m4a",
            mysteryNumber: mystery.number, mysteryGroup: mysteryGroup
        ))
        order += 1
        
        // 3. 10 Avemarías
        for i in 1...10 {
            segments.append(AudioSegment(
                type: .hailMary, title: "Ave María \(i)", order: order,
                audioIntroFile: "ave_maria_intro.m4a", audioReplyFile: "ave_maria_reply.m4a",
                mysteryNumber: mystery.number, mysteryGroup: mysteryGroup
            ))
            order += 1
        }
        
        // 4. Gloria
        segments.append(AudioSegment(
            type: .gloryBe, title: "Gloria", order: order,
            audioIntroFile: "gloria_intro.m4a", audioReplyFile: "gloria_reply.m4a",
            mysteryNumber: mystery.number, mysteryGroup: mysteryGroup
        ))
        order += 1
        
        // 5. Jaculatoria
        segments.append(AudioSegment(
            type: .fatimaPrayer, title: "Jaculatoria", order: order,
            audioIntroFile: "jaculatoria.m4a",
            mysteryNumber: mystery.number, mysteryGroup: mysteryGroup
        ))
        order += 1
    }
    
    // Salve (Siempre presente tras misterios)
    segments.append(AudioSegment(type: .salve, title: "Salve", order: order, audioIntroFile: "salve.m4a"))
    order += 1
    
    // ---------------------------------------------------------
    // 3. SECCIÓN FINAL
    // ---------------------------------------------------------
    
    // Opción 1: Trinidad (3 Avemarías)
    if config.includeTrinity {
        let titles = ["Hija del Padre", "Madre del Hijo", "Esposa del Espíritu Santo"]
        for (idx, t) in titles.enumerated() {
            segments.append(AudioSegment(type: .threeHailMarysTrinity, title: "Ave María (\(t))", order: order,
                                         audioIntroFile: "ave_maria_trinity_intro_\(idx+1).m4a",
                                         audioReplyFile: "ave_maria_reply.m4a"))
            order += 1
        }
    }
    
    // Opción 2: Letanías (normales)
    if config.includeLitanies {
        segments.append(AudioSegment(type: .litanies, title: "Letanías", order: order, audioIntroFile: "litanies.m4a"))
        order += 1
    }
    
    // Opción 3: Oraciones Finales (Lauretanas)
    if config.includeFinalPrayers {
        segments.append(AudioSegment(type: .finalPrayers, title: "Oración Final (Lauretanas)", order: order, audioIntroFile: "final_prayers_lauretanas.m4a"))
        order += 1
    }
    
    // Opción 4: Peticiones Finales
    if config.includePetitions {
        
        // 1. Por la Iglesia (Intro + PN + Ave + Gloria)
        segments.append(AudioSegment(type: .petitions, title: "Por la Iglesia - Intención", order: order, audioIntroFile: "petition_church_intro.m4a"))
        order += 1
        segments.append(AudioSegment(type: .ourFather, title: "Por la Iglesia - Padre Nuestro", order: order, audioIntroFile: "padre_nuestro_intro.m4a", audioReplyFile: "padre_nuestro_reply.m4a"))
        order += 1
        segments.append(AudioSegment(type: .hailMary, title: "Por la Iglesia - Ave María", order: order, audioIntroFile: "ave_maria_intro.m4a", audioReplyFile: "ave_maria_reply.m4a"))
        order += 1
        segments.append(AudioSegment(type: .gloryBe, title: "Por la Iglesia - Gloria", order: order, audioIntroFile: "gloria_intro.m4a", audioReplyFile: "gloria_reply.m4a"))
        order += 1
        
        // 2. Por el Obispo (Intro + PN + Ave + Gloria)
        segments.append(AudioSegment(type: .petitions, title: "Por el Obispo - Intención", order: order, audioIntroFile: "petition_bishop_intro.m4a"))
        order += 1
        segments.append(AudioSegment(type: .ourFather, title: "Por el Obispo - Padre Nuestro", order: order, audioIntroFile: "padre_nuestro_intro.m4a", audioReplyFile: "padre_nuestro_reply.m4a"))
        order += 1
        segments.append(AudioSegment(type: .hailMary, title: "Por el Obispo - Ave María", order: order, audioIntroFile: "ave_maria_intro.m4a", audioReplyFile: "ave_maria_reply.m4a"))
        order += 1
        segments.append(AudioSegment(type: .gloryBe, title: "Por el Obispo - Gloria", order: order, audioIntroFile: "gloria_intro.m4a", audioReplyFile: "gloria_reply.m4a"))
        order += 1

        // 3. Por las Almas (Intro + PN + Ave) -> SIN GLORIA
        segments.append(AudioSegment(type: .petitions, title: "Por las Almas - Intención", order: order, audioIntroFile: "petition_souls_intro.m4a"))
        order += 1
        segments.append(AudioSegment(type: .ourFather, title: "Por las Almas - Padre Nuestro", order: order, audioIntroFile: "padre_nuestro_intro.m4a", audioReplyFile: "padre_nuestro_reply.m4a"))
        order += 1
        segments.append(AudioSegment(type: .hailMary, title: "Por las Almas - Ave María", order: order, audioIntroFile: "ave_maria_intro.m4a", audioReplyFile: "ave_maria_reply.m4a"))
        order += 1
        // AQUÍ NO VA GLORIA
    }
    
    // ---------------------------------------------------------
    // CIERRE FINAL (SIEMPRE)
    // ---------------------------------------------------------
    
    // 1. Requiescat in Pace (Audible)
    segments.append(AudioSegment(
        type: .finalPrayers,
        title: "Descansen en Paz",
        order: order,
        audioIntroFile: "rest_in_peace.m4a"
    ))
    order += 1
    
    // 2. Silencio de 1.5s (Usando el mismo archivo con volumen 0)
    // Para que esto funcione, asegúrate de añadir 'case silence' en RosarioPartType
    // y la lógica de volumen 0 en playCurrentSegment()
    segments.append(AudioSegment(
        type: .finalPrayers,
        title: "...",
        order: order,
        audioIntroFile: "rest_in_peace.m4a" // ✅ Volumen 0
    ))
    order += 1
    
    // 3. Señal de la Cruz Final
    segments.append(AudioSegment(
        type: .signOfCross,
        title: "Señal de la Cruz Final",
        order: order,
        audioIntroFile: "sign_of_cross.m4a"
    ))
    order += 1
    
    return RosarioSequence(segments: segments)
}

// Función helper para crear por defecto (usando configuración base)
func buildDefaultRosarioSequence(mysteryGroup: MysteryGroup) -> RosarioSequence {
    // Configuración por defecto: Credo, Trinidad, Letanías, Peticiones
    let defaultConfig = RosarioConfiguration(
        includeInitialPrayers: true,
        includeCredo: false,
        includeVisita: true,
        includeTrinity: true,
        includeLitanies: true,
        includeFinalPrayers: true,
        includePetitions: true
    )
    return buildRosarioSequence(config: defaultConfig, mysteryGroup: mysteryGroup)
}
