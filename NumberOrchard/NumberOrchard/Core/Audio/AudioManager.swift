import AVFoundation
import Observation

@Observable
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    var isMusicEnabled = true
    var isSoundEnabled = true
    var isVoiceEnabled = true

    private var musicPlayer: AVAudioPlayer?
    private var soundPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func playMusic(_ filename: String) {
        guard isMusicEnabled else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.3
            musicPlayer?.play()
        } catch {
            print("Music play failed: \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func playSound(_ filename: String) {
        guard isSoundEnabled else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            soundPlayers[filename] = player
        } catch {
            print("Sound play failed: \(error)")
        }
    }

    func playVoice(_ filename: String) {
        guard isVoiceEnabled else { return }
        playSound(filename)
    }

    // MARK: - Speech Synthesis (for dynamic equation readout)

    private let synthesizer = AVSpeechSynthesizer()

    /// Speak an equation aloud, e.g. "三加二等于五"
    func speakEquation(_ question: MathQuestion) {
        guard isVoiceEnabled else { return }

        let op1Text = chineseNumber(question.operand1)
        let opText = question.operation == .add ? "加" : "减"
        let op2Text = chineseNumber(question.operand2)
        let ansText = chineseNumber(question.correctAnswer)
        let text = "\(op1Text)\(opText)\(op2Text)等于\(ansText)！"

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.2
        synthesizer.speak(utterance)
    }

    private func chineseNumber(_ n: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        if n <= 10 { return digits[n] }
        if n < 20 { return "十\(digits[n - 10])" }
        return "二十"
    }
}
