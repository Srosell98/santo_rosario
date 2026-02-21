//
//  AudioService.swift
//  Rosario
//
//  Created by Santiago Rosell on 11/2/26.
//

import Foundation
import AVFoundation

class AudioService {
    static let shared = AudioService()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error setting up audio session: \(error)")
        }
        #endif
    }
    
    func playAudio(fileName: String, delegate: AVAudioPlayerDelegate? = nil) throws -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "") else {
            throw NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Archivo no encontrado: \(fileName)"])
        }
        
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = delegate
        player.play()
        
        self.audioPlayer = player
        return player
    }
    
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
    }
}

// MARK: - Text-to-Speech Helper

class TextToSpeechService {
    static let shared = TextToSpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, language: String = "es-ES", rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}



