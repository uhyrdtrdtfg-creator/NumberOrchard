import SwiftUI

/// Full-screen theater presentation: the active Noom asks themed math
/// questions via a speech bubble. Child answers with a number pad.
/// Correct answers → celebration + XP (via existing feeding pipeline).
struct PetTheaterView: View {
    @Bindable var viewModel: PetTheaterViewModel
    let onDismiss: () -> Void

    @State private var entered = ""
    @State private var bounce = false
    @State private var spin = false
    @State private var shake = false
    @State private var idleBreath = false
    @State private var fruitRain: [FruitParticle] = []

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 20) {
                topBar

                if viewModel.sessionComplete {
                    sessionCompleteView
                } else if let q = viewModel.currentQuestion,
                          let pet = viewModel.garden.activePet,
                          let noom = NoomCatalog.noom(for: pet.noomNumber) {
                    progressIndicator
                    speechBubble(text: q.prompt)
                    petStage(noom: noom, stage: pet.stage)
                    inputDisplay
                    numberPad
                }

                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)

            // Floating fruit rain overlay
            ForEach(fruitRain) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            // Rare legendary fruit drop banner
            if let drop = viewModel.lastLegendaryDrop {
                LegendaryDropBanner(fruit: drop)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(CartoonAnim.breathe) { idleBreath = true }
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        MiniGameTopBar(title: "🎭 数学小剧场", onClose: onDismiss)
    }

    private var progressIndicator: some View {
        HStack(spacing: 14) {
            Text("第 \(viewModel.progressText) 题")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            if viewModel.garden.activeSkill == .calmClock, viewModel.calmClockBonus > 0 {
                Text("⏳ +\(Int(viewModel.calmClockBonus))s 从容")
                    .font(CartoonFont.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(CartoonColor.gold.opacity(0.25)))
                    .foregroundStyle(CartoonColor.text)
            }
            ThinkCountdownPill(totalSeconds: viewModel.thinkBudgetSeconds,
                               resetKey: viewModel.currentIndex)
        }
    }

    private func speechBubble(text: String) -> some View {
        CartoonPanel(cornerRadius: 24) {
            Text(text)
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text)
                .multilineTextAlignment(.center)
                .padding(18)
        }
        .offset(x: shake ? -8 : 0)
        .animation(CartoonAnim.snappy, value: shake)
    }

    private func petStage(noom: Noom, stage: Int) -> some View {
        // Noom mirrors the child's last action: correct → surprised
        // (wide eyes celebrating), wrong → neutral (gently sad), idle
        // or before answering → happy.
        let expression: NoomExpression = {
            switch viewModel.lastResult {
            case .correct: return .surprised
            case .wrong:   return .neutral
            case .none:    return .happy
            }
        }()
        return Image(uiImage: NoomRenderer.image(
            for: noom, expression: expression,
            size: CGSize(width: 160, height: 160), stage: stage
        ))
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 160)
        .scaleEffect(bounce ? 1.25 : (idleBreath ? 1.03 : 1.0))
        .rotationEffect(.degrees(spin ? 10 : 0))
        .animation(CartoonAnim.bouncy, value: bounce)
        .animation(CartoonAnim.bouncy, value: spin)
    }

    private var inputDisplay: some View {
        ZStack {
            // Soft "display screen" with a subtle top-to-bottom gradient
            // that hints at depth (like a real calculator LCD bezel).
            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                .fill(
                    LinearGradient(
                        colors: [Color.white, CartoonColor.paper],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 60)
            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                .frame(width: 160, height: 60)
            Text(entered.isEmpty ? "?" : entered)
                .font(CartoonFont.numericLarge)
                .foregroundStyle(CartoonColor.text)
        }
    }

    private var numberPad: some View {
        NumberPad(
            onDigit: { digit in
                if entered.count < 2 { entered += "\(digit)" }
            },
            onClear: { entered = "" },
            onSubmit: submit
        )
    }

    private var sessionCompleteView: some View {
        let petName: String = {
            if let pet = viewModel.garden.activePet,
               let noom = NoomCatalog.noom(for: pet.noomNumber) {
                return "你让\(noom.name)吃到了 \(viewModel.totalFruitsEaten) 个水果!"
            }
            return "这一局小剧场结束啦!"
        }()
        return SessionCompleteCard(
            emoji: "🎉",
            title: "太棒啦!",
            primaryStat: "\(petName)\n答对 \(viewModel.correctCount) / \(viewModel.questions.count)",
            rewardLine: "+1 ⭐",
            onDismiss: onDismiss
        )
    }

    // MARK: - Actions

    private func submit() {
        guard let _ = viewModel.currentQuestion,
              let value = Int(entered) else { return }
        let correct = viewModel.submit(value)
        entered = ""
        if correct {
            AudioManager.shared.playSound("correct.wav")
            Haptics.success()
            if viewModel.lastLegendaryDrop != nil {
                AudioManager.shared.playSound("level_up.wav")
                Haptics.milestone()
            }
            triggerCelebration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                viewModel.advance()
                if viewModel.sessionComplete {
                    AudioManager.shared.playSound("star_collect.wav")
                }
            }
        } else {
            AudioManager.shared.playSound("wrong.wav")
            Haptics.warning()
            triggerShake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                viewModel.clearResult()
            }
        }
    }

    private func triggerCelebration() {
        bounce = true
        spin = true
        let emoji = viewModel.currentQuestion?.fruitEmoji ?? "⭐"
        fruitRain = (0..<10).map { _ in
            FruitParticle(
                id: UUID(), emoji: emoji,
                x: CGFloat.random(in: -140...140),
                y: -40, size: CGFloat.random(in: 28...46),
                opacity: 1.0
            )
        }
        withAnimation(CartoonAnim.fall) {
            fruitRain = fruitRain.map {
                var p = $0
                p.y = 240
                p.opacity = 0
                return p
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            spin = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            bounce = false
            fruitRain = []
        }
    }

    private func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            shake = false
        }
    }
}

/// A friendly countdown pill that ticks from `totalSeconds` to 0 over the
/// current question. Purely visual — never auto-submits an answer — its
/// job is to give kids a gentle sense of pace. Restarts whenever
/// `resetKey` changes (used by the parent when advancing questions).
private struct ThinkCountdownPill: View {
    let totalSeconds: TimeInterval
    let resetKey: Int

    @State private var remaining: TimeInterval = 0
    @State private var ticker: Task<Void, Never>? = nil

    var body: some View {
        let fraction = max(0, min(1, remaining / totalSeconds))
        let tint: Color = fraction > 0.5 ? CartoonColor.leaf
            : fraction > 0.25 ? CartoonColor.gold : CartoonColor.coral
        return HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text("\(Int(ceil(remaining)))s")
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.2)))
        .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
        .onAppear { restart() }
        .onChange(of: resetKey, initial: false) { _, _ in restart() }
        .onDisappear { ticker?.cancel() }
    }

    private func restart() {
        ticker?.cancel()
        remaining = totalSeconds
        ticker = Task { @MainActor in
            while !Task.isCancelled && remaining > 0 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                remaining -= 0.2
            }
            remaining = 0
        }
    }
}

private struct FruitParticle: Identifiable {
    let id: UUID
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

