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
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 56, height: 56)
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("🎭 数学小剧场")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.top, 16)
    }

    private var progressIndicator: some View {
        Text("第 \(viewModel.progressText) 题")
            .font(CartoonFont.bodySmall)
            .foregroundStyle(CartoonColor.text.opacity(0.7))
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
        Image(uiImage: NoomRenderer.image(
            for: noom, expression: .happy,
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
            RoundedRectangle(cornerRadius: 16)
                .fill(CartoonColor.paper)
                .frame(width: 160, height: 60)
            RoundedRectangle(cornerRadius: 16)
                .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                .frame(width: 160, height: 60)
            Text(entered.isEmpty ? "?" : entered)
                .font(CartoonFont.numericLarge)
                .foregroundStyle(CartoonColor.text)
        }
    }

    private var numberPad: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { col in
                        padKey("\(row * 3 + col)")
                    }
                }
            }
            HStack(spacing: 10) {
                padKey("清", tint: CartoonColor.coral) { entered = "" }
                padKey("0")
                padKey("✓", tint: CartoonColor.leaf) { submit() }
            }
        }
    }

    private func padKey(
        _ label: String,
        tint: Color = CartoonColor.paper,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: {
            if let action {
                action()
            } else if entered.count < 2 {
                entered += label
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 76, height: 60).offset(y: 3)
                RoundedRectangle(cornerRadius: 18).fill(tint)
                    .frame(width: 76, height: 60)
                RoundedRectangle(cornerRadius: 18).stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                    .frame(width: 76, height: 60)
                Text(label)
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(tint == CartoonColor.paper ? CartoonColor.text : .white)
            }
        }
        .buttonStyle(.plain)
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)
            Text("🎉")
                .font(.system(size: 80))
            Text("太棒啦！")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            if let pet = viewModel.garden.activePet,
               let noom = NoomCatalog.noom(for: pet.noomNumber) {
                Text("你让\(noom.name)吃到了 \(viewModel.totalFruitsEaten) 个水果！")
                    .font(CartoonFont.body)
                    .foregroundStyle(CartoonColor.text.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            Text("答对 \(viewModel.correctCount) / \(viewModel.questions.count)  +1 ⭐")
                .font(CartoonFont.body)
                .foregroundStyle(CartoonColor.gold)
            Spacer().frame(height: 20)
            CartoonButton(tint: CartoonColor.gold, accessibilityLabel: "完成", action: onDismiss) {
                Text("回到花园")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 60)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    private func submit() {
        guard let _ = viewModel.currentQuestion,
              let value = Int(entered) else { return }
        let correct = viewModel.submit(value)
        entered = ""
        if correct {
            triggerCelebration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                viewModel.advance()
            }
        } else {
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

private struct FruitParticle: Identifiable {
    let id: UUID
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

