import AVFoundation

@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    var currentlyPlayingID: UUID?

    /// Honduran Spanish voice (es-HN), falls back to Mexican (es-MX) if unavailable.
    private var voiceIdentifier: String {
        if AVSpeechSynthesisVoice(language: "es-HN") != nil {
            return "es-HN"
        }
        return "es-MX"
    }

    func speak(_ text: String, id: UUID) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Use .playback category so audio plays even when the mute switch is on
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Strip leading punctuation marks that don't affect pronunciation
        let cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: "¡¿"))

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceIdentifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.45
        utterance.pitchMultiplier = 1.0

        currentlyPlayingID = id
        synthesizer.speak(utterance)

        // Clear the playing state after estimated duration
        let estimatedDuration = max(1.0, Double(cleaned.count) * 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) { [weak self] in
            if self?.currentlyPlayingID == id {
                self?.currentlyPlayingID = nil
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentlyPlayingID = nil
    }
}
