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
}
