import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class RhythmMathViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    static let roundCount = 8
    /// Seconds for a ball to traverse the screen from spawn to despawn.
    static let beatSeconds: TimeInterval = 4.0

    var rounds: [RhythmRound] = []
    var currentIndex: Int = 0
    var score: Int = 0
    var combo: Int = 0
    var sessionComplete: Bool = false
    /// Monotonic timestamp when the current round's balls started falling.
    /// Used by the view to interpolate ball positions without a per-frame
    /// state update.
    var roundStart: Date = .distantPast
    var lastResult: Bool? = nil

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        var rng = SystemRandomNumberGenerator()
        let maxTotal = min(profile.difficultyLevel.maxNumber, 10)
        rounds = (0..<Self.roundCount).map { _ in
            RhythmMathGenerator.makeRound(maxTotal: maxTotal, rng: &rng)
        }
        roundStart = Date()
    }

    var current: RhythmRound? {
        currentIndex < rounds.count ? rounds[currentIndex] : nil
    }

    var progressText: String { "\(min(currentIndex + 1, rounds.count)) / \(rounds.count)" }

    func tap(_ value: Int) {
        guard let r = current else { return }
        let correct = value == r.correctAnswer
        lastResult = correct
        if correct {
            combo += 1
            score += 10 * combo
            AudioManager.shared.playSound("star_collect.wav")
        } else {
            combo = 0
            AudioManager.shared.playSound("wrong.wav")
        }
        advance()
    }

    func timeout() {
        // Missed the beat — count as wrong, break combo.
        lastResult = false
        combo = 0
        AudioManager.shared.playSound("wrong.wav")
        advance()
    }

    private func advance() {
        currentIndex += 1
        roundStart = Date()
        if currentIndex >= rounds.count {
            sessionComplete = true
            profile.stars += max(1, score / 50)
            AudioManager.shared.playSound("level_up.wav")
        }
    }
}

/// Full-screen 节奏数学 — an equation sits at the top, three numbered
/// balls drop from above at a steady beat. The child taps the ball that
/// equals the answer before it falls off-screen. Missing the beat breaks
/// the combo.
struct RhythmMathView: View {
    @Bindable var viewModel: RhythmMathViewModel
    let onDismiss: () -> Void

    @State private var timerTick: Date = .distantPast
    private let tickTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 18) {
                topBar
                if viewModel.sessionComplete {
                    completeView
                } else {
                    scoreBar
                    equationPanel
                    GeometryReader { geo in
                        ZStack {
                            if let round = viewModel.current {
                                ForEach(Array(round.choices.enumerated()), id: \.offset) { idx, val in
                                    fallingBall(value: val, lane: idx, total: round.choices.count, geo: geo)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
        }
        .onReceive(tickTimer) { now in
            timerTick = now
            // Check if the current round's balls have fallen off-screen.
            let elapsed = now.timeIntervalSince(viewModel.roundStart)
            if elapsed >= RhythmMathViewModel.beatSeconds, !viewModel.sessionComplete,
               viewModel.lastResult == nil || elapsed > RhythmMathViewModel.beatSeconds + 0.2 {
                viewModel.timeout()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 56, height: 56)
                    Image(systemName: "xmark").font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("🎵 节奏数学").font(CartoonFont.titleSmall).foregroundStyle(CartoonColor.text)
            Spacer()
            Text("第 \(viewModel.progressText)")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
                .frame(width: 96, alignment: .trailing)
        }
        .padding(.top, 16)
    }

    private var scoreBar: some View {
        HStack(spacing: 20) {
            Text("得分 \(viewModel.score)").font(CartoonFont.bodyLarge).foregroundStyle(CartoonColor.gold)
            if viewModel.combo >= 2 {
                Text("连击 ×\(viewModel.combo)")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.coral)
            }
        }
    }

    private var equationPanel: some View {
        CartoonPanel(cornerRadius: 22) {
            Text(viewModel.current?.displayText ?? "")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
                .padding(20)
        }
    }

    private func fallingBall(value: Int, lane: Int, total: Int, geo: GeometryProxy) -> some View {
        let elapsed = timerTick.timeIntervalSince(viewModel.roundStart)
        let progress = min(1.0, max(0.0, elapsed / RhythmMathViewModel.beatSeconds))
        // Spawn above the top, exit below the bottom.
        let y = -60 + progress * (geo.size.height + 120)
        let xSpacing = geo.size.width / CGFloat(total + 1)
        let x = xSpacing * CGFloat(lane + 1)
        let isInZone = progress > 0.55 && progress < 0.90
        let tint: Color = isInZone ? CartoonColor.gold : CartoonColor.sky
        return Button {
            viewModel.tap(value)
        } label: {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 70, height: 70).offset(y: 4)
                Circle().fill(tint).frame(width: 70, height: 70)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 70, height: 70)
                Text("\(value)")
                    .font(CartoonFont.title)
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .position(x: x, y: y)
        .opacity(progress < 1.0 ? 1.0 : 0.0)
    }

    private var completeView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)
            Text("🎵🎉").font(.system(size: 80))
            Text("节奏结束!")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("得分 \(viewModel.score)  +\(max(1, viewModel.score / 50)) ⭐")
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.gold)
            Spacer().frame(height: 10)
            CartoonButton(tint: CartoonColor.gold, accessibilityLabel: "完成", action: onDismiss) {
                Text("回到花园")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 60)
            }
        }
    }
}
