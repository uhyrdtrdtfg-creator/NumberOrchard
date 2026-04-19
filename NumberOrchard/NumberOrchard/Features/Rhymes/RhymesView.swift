import SwiftUI
import AVFoundation

/// Rhymes gallery + playback screen. Child picks one of the four
/// classic numbers rhymes; the view narrates the lines one by one
/// via AVSpeechSynthesizer and pops a glowing number badge whenever
/// a line has a highlight number.
struct RhymesView: View {
    let onDismiss: () -> Void

    @State private var selected: NumberRhyme?

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 16) {
                MiniGameTopBar(title: "🎵 数字儿歌", onClose: onDismiss)
                if let rhyme = selected {
                    RhymePlayer(rhyme: rhyme, onBack: { selected = nil })
                } else {
                    gallery
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 20)
        }
    }

    private var gallery: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("选一首儿歌,轻点开始")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                ForEach(NumberRhymeCatalog.all) { rhyme in
                    Button { selected = rhyme } label: {
                        galleryRow(rhyme: rhyme)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func galleryRow(rhyme: NumberRhyme) -> some View {
        CartoonPanel(cornerRadius: CartoonRadius.chunky) {
            HStack(spacing: 16) {
                Text(rhyme.emoji).font(.system(size: 48))
                VStack(alignment: .leading, spacing: 4) {
                    Text(rhyme.title)
                        .font(CartoonFont.titleSmall)
                        .foregroundStyle(CartoonColor.text)
                    Text(rhyme.lines.first?.text ?? "")
                        .font(CartoonFont.bodySmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(CartoonColor.gold)
            }
            .padding(16)
        }
    }
}

/// Active playback page — narrates each line with speech synthesis +
/// shows a glowing number badge whenever a line has `highlight`.
private struct RhymePlayer: View {
    let rhyme: NumberRhyme
    let onBack: () -> Void

    @State private var currentLine: Int = 0
    @State private var playing: Bool = false
    @State private var timer: Task<Void, Never>?
    private let synth = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button("← 返回", action: stopAndBack)
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(CartoonColor.paper))
                    .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.55), lineWidth: 2))
                Spacer()
                Text(rhyme.title)
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(CartoonColor.text)
                Spacer()
                Color.clear.frame(width: 60, height: 10)
            }

            Text(rhyme.emoji)
                .font(.system(size: 120))

            // Highlight badge when the current line has a number.
            let highlight = rhyme.lines.indices.contains(currentLine)
                ? rhyme.lines[currentLine].highlight : nil
            ZStack {
                if let n = highlight {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CartoonColor.gold.opacity(0.9),
                                         CartoonColor.gold.opacity(0.0)],
                                center: .center,
                                startRadius: 10, endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 4)
                    Text("\(n)")
                        .font(.system(size: 110, weight: .black, design: .rounded))
                        .foregroundStyle(CartoonColor.gold)
                        .shadow(color: CartoonColor.ink.opacity(0.4), radius: 0, x: 0, y: 3)
                }
            }
            .frame(height: 180)

            // Line-by-line lyrics with the active line highlighted.
            VStack(spacing: 10) {
                ForEach(Array(rhyme.lines.enumerated()), id: \.offset) { idx, line in
                    Text(line.text)
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(idx == currentLine
                                         ? CartoonColor.text
                                         : CartoonColor.text.opacity(0.45))
                }
            }
            .padding(14)
            .background(CartoonPanel(cornerRadius: CartoonRadius.chunky) { EmptyView() })

            // Play / pause toggle.
            CartoonButton(
                tint: playing ? CartoonColor.coral : CartoonColor.leaf,
                cornerRadius: CartoonRadius.chunky,
                accessibilityLabel: playing ? "暂停" : "播放",
                action: togglePlay
            ) {
                Text(playing ? "⏸ 暂停" : "▶️ 开始念")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 180, height: 52)
            }

            Spacer(minLength: 10)
        }
        .onDisappear { stopAndBack() }
    }

    private func togglePlay() {
        if playing {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        playing = true
        currentLine = 0
        narrate(index: 0)
        timer = Task { @MainActor in
            for idx in 0..<rhyme.lines.count {
                try? await Task.sleep(nanoseconds: 2_800_000_000)
                if Task.isCancelled { return }
                let next = min(idx + 1, rhyme.lines.count - 1)
                currentLine = next
                if next > idx {
                    narrate(index: next)
                }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled { playing = false }
        }
    }

    private func stopPlayback() {
        timer?.cancel()
        timer = nil
        synth.stopSpeaking(at: .immediate)
        playing = false
    }

    private func stopAndBack() {
        stopPlayback()
        onBack()
    }

    private func narrate(index: Int) {
        guard index < rhyme.lines.count else { return }
        let utterance = AVSpeechUtterance(string: rhyme.lines[index].text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.05
        synth.speak(utterance)
    }
}
