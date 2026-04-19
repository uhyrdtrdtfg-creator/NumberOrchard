import SwiftUI
import SwiftData
import Observation

/// 瞄一眼 — flash a random N dots (1-9) for ~1 second, then ask the
/// child how many they saw. Trains subitizing (瞬时识别数量), the
/// pre-counting skill research calls the foundation of number sense.
///
/// We never let the child go back and count; once the flash ends the
/// dots are hidden while they answer. 6 rounds per session.
@Observable
@MainActor
final class SubitizingViewModel {
    let profile: ChildProfile
    static let rounds = 6
    static let flashSeconds: TimeInterval = 1.2

    enum Phase { case showing, answering, result, complete }

    var phase: Phase = .showing
    var currentRound: Int = 0
    var currentCount: Int = 0
    var currentLayout: [CGPoint] = []  // normalized 0-1 positions
    var lastResult: Bool? = nil
    var correctCount: Int = 0

    init(profile: ChildProfile) {
        self.profile = profile
        newRound()
    }

    func newRound() {
        currentCount = Int.random(in: 2...9)
        currentLayout = Self.makeRandomLayout(count: currentCount)
        lastResult = nil
        phase = .showing
    }

    func beginAnswer() { phase = .answering }

    func submit(_ answer: Int) {
        let correct = (answer == currentCount)
        lastResult = correct
        if correct {
            correctCount += 1
            Haptics.success()
            AudioManager.shared.playSound("correct.wav")
        } else {
            Haptics.warning()
            AudioManager.shared.playSound("wrong.wav")
        }
        phase = .result
    }

    func advance() {
        currentRound += 1
        if currentRound >= Self.rounds {
            phase = .complete
            profile.stars += max(1, correctCount / 2)
            AudioManager.shared.playSound("level_up.wav")
        } else {
            newRound()
        }
    }

    /// Arrange up to 9 dots in a slightly-jittered 3×3 grid so the
    /// child can't subitize by memorized position alone.
    static func makeRandomLayout(count: Int) -> [CGPoint] {
        var rng = SystemRandomNumberGenerator()
        var slots: [CGPoint] = []
        for row in 0..<3 {
            for col in 0..<3 {
                let x = CGFloat(col + 1) / 4.0 + CGFloat.random(in: -0.04...0.04, using: &rng)
                let y = CGFloat(row + 1) / 4.0 + CGFloat.random(in: -0.04...0.04, using: &rng)
                slots.append(CGPoint(x: x, y: y))
            }
        }
        slots.shuffle(using: &rng)
        return Array(slots.prefix(count))
    }

    var progressText: String { "\(min(currentRound + 1, Self.rounds)) / \(Self.rounds)" }
}

struct SubitizingGameView: View {
    @Bindable var viewModel: SubitizingViewModel
    let onDismiss: () -> Void

    @State private var dotsVisible: Bool = true
    @State private var tick: Task<Void, Never>?

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 18) {
                MiniGameTopBar(title: "👀 瞄一眼",
                               progress: "第 \(viewModel.progressText)",
                               onClose: onDismiss)
                if viewModel.phase == .complete {
                    SessionCompleteCard(
                        emoji: "👀🎉",
                        title: "瞄一眼结束!",
                        primaryStat: "答对 \(viewModel.correctCount) / \(SubitizingViewModel.rounds)",
                        rewardLine: "+\(max(1, viewModel.correctCount / 2)) ⭐",
                        onDismiss: onDismiss
                    )
                } else {
                    prompt
                    dotsArena
                    if viewModel.phase == .answering {
                        answerPad
                    } else if viewModel.phase == .result {
                        resultRow
                    }
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
        }
        .onAppear(perform: scheduleFlash)
        .onChange(of: viewModel.phase, initial: false) { _, new in
            if new == .showing { scheduleFlash() }
        }
        .onDisappear { tick?.cancel() }
    }

    private var prompt: some View {
        Text(promptText)
            .font(CartoonFont.title)
            .foregroundStyle(CartoonColor.text)
    }

    private var promptText: String {
        switch viewModel.phase {
        case .showing:   return "看好啦!快瞄一眼~"
        case .answering: return "刚才有几个?"
        case .result:    return viewModel.lastResult == true ? "太棒了!" : "答案是 \(viewModel.currentCount) 个"
        case .complete:  return ""
        }
    }

    private var dotsArena: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CartoonRadius.xl)
                .fill(CartoonColor.paper)
            RoundedRectangle(cornerRadius: CartoonRadius.xl)
                .stroke(CartoonColor.ink.opacity(0.6), lineWidth: 3)
            GeometryReader { geo in
                ForEach(Array(viewModel.currentLayout.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CartoonColor.coral, CartoonColor.coral.opacity(0.8)],
                                center: .topLeading, startRadius: 4, endRadius: 40
                            )
                        )
                        .overlay(Circle().stroke(CartoonColor.ink.opacity(0.5), lineWidth: 2))
                        .frame(width: 44, height: 44)
                        .position(x: geo.size.width * p.x, y: geo.size.height * p.y)
                        .opacity(dotsVisible ? 1 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .animation(.easeInOut(duration: 0.2), value: dotsVisible)
    }

    private var answerPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(64), spacing: 10), count: 5),
                  spacing: 10) {
            ForEach(1...9, id: \.self) { n in
                Button { viewModel.submit(n) } label: {
                    Text("\(n)")
                        .font(CartoonFont.title)
                        .foregroundStyle(CartoonColor.text)
                        .frame(width: 64, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                                .fill(CartoonColor.paper)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                                .stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2.5)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var resultRow: some View {
        CartoonButton(
            tint: viewModel.lastResult == true ? CartoonColor.leaf : CartoonColor.coral,
            cornerRadius: CartoonRadius.chunky,
            accessibilityLabel: "下一题",
            action: {
                dotsVisible = true
                viewModel.advance()
            }
        ) {
            Text("下一题 →")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(.white)
                .frame(width: 180, height: 54)
        }
    }

    private func scheduleFlash() {
        guard viewModel.phase == .showing else { return }
        dotsVisible = true
        tick?.cancel()
        tick = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(SubitizingViewModel.flashSeconds * 1_000_000_000))
            if Task.isCancelled { return }
            dotsVisible = false
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled { viewModel.beginAnswer() }
        }
    }
}
