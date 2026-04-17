import SwiftUI
import SwiftData

struct AdventureSessionView: View {
    let station: Station?
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: AdventureSessionViewModel?
    @State private var loadingTimedOut = false

    var body: some View {
        ZStack {
            if viewModel == nil {
                CartoonSkyBackground()
            }

            Group {
                if let viewModel {
                    if viewModel.isSessionComplete {
                        sessionCompleteView(viewModel: viewModel)
                    } else if let question = viewModel.currentQuestion {
                        gameView(for: question, viewModel: viewModel)
                    }
                } else if loadingTimedOut {
                    loadingErrorView
                } else {
                    loadingView
                }
            }
        }
        .onAppear {
            let profile = profiles.first ?? createDefaultProfile()
            viewModel = AdventureSessionViewModel(profile: profile, station: station, modelContext: modelContext)
            AudioManager.shared.playMusic("adventure_bgm.wav")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if viewModel == nil { loadingTimedOut = true }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: CartoonDimensions.spacingRegular) {
            ProgressView()
                .controlSize(.large)
                .tint(CartoonColor.leaf)
            Text("加载中...")
                .cartoonBody(size: CartoonDimensions.fontBodyLarge)
        }
    }

    private var loadingErrorView: some View {
        VStack(spacing: CartoonDimensions.spacingRegular) {
            Text("🌧️").font(.system(size: 100)).accessibilityHidden(true)
            Text("加载失败了")
                .cartoonTitle(size: CartoonDimensions.fontTitle)
            Text("请返回重试")
                .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            CartoonButton(tint: CartoonColor.leaf, accessibilityLabel: "返回", action: onFinish) {
                Text("返回")
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(.white)
                    .frame(width: 180, height: 64)
            }
        }
    }

    @ViewBuilder
    private func gameView(for question: MathQuestion, viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(viewModel.questionsCompleted + 1)/\(viewModel.totalQuestions) 题")
                    .cartoonBody(size: CartoonDimensions.fontBody)
                    .foregroundStyle(CartoonColor.text.opacity(0.75))
                Spacer()
                Button {
                    viewModel.finishSession()
                    onFinish()
                } label: {
                    Text("暂停")
                        .cartoonBody(size: CartoonDimensions.fontBody)
                        .padding(.horizontal, CartoonDimensions.spacingRegular)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .accessibilityHint("暂停并返回")
            }
            .padding(.horizontal, CartoonDimensions.spacingRegular + 4)
            .padding(.top, CartoonDimensions.spacingTight)

            Group {
                let themeEmoji = stationFruitEmoji(viewModel: viewModel)
                let animalEmoji = stationAnimalEmoji(viewModel: viewModel)
                switch question.gameMode {
                case .pickFruit:
                    PickFruitView(question: question, themeEmoji: themeEmoji) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .shareFruit:
                    ShareFruitView(question: question, themeEmoji: themeEmoji, animalEmoji: animalEmoji) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .numberTrain:
                    let countingMode = (viewModel.station?.level.rawValue ?? 1) <= 3
                    NumberTrainView(question: question, countingMode: countingMode) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .balance:
                    BalanceView(question: question) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                }
            }
            .id("\(question.operand1)-\(question.operand2)-\(question.operation.rawValue)-\(question.gameMode.rawValue)-\(viewModel.questionsCompleted)")
        }
    }

    private func sessionCompleteView(viewModel: AdventureSessionViewModel) -> some View {
        ZStack {
            CartoonSkyBackground()
            ConfettiView()
            VStack(spacing: CartoonDimensions.spacingMedium + 2) {
                Text("太棒了！")
                    .font(CartoonFont.displayHuge)
                    .foregroundStyle(CartoonColor.text)
                    .modifier(PopInModifier(delay: 0.1))

                if let reward = viewModel.lastReward {
                    VStack(spacing: 10) {
                        Text("获得 ⭐ +\(reward.starsEarned)")
                            .font(CartoonFont.title)
                            .foregroundStyle(CartoonColor.gold)
                            .modifier(PopInModifier(delay: 0.3))
                        if reward.seedsEarned > 0 {
                            Text("获得 🌱 +\(reward.seedsEarned)")
                                .font(CartoonFont.titleSmall)
                                .foregroundStyle(CartoonColor.leaf)
                                .modifier(PopInModifier(delay: 0.5))
                        }
                        if let fruit = viewModel.newlyUnlockedFruit {
                            VStack(spacing: CartoonDimensions.spacingTight) {
                                Text(fruit.emoji)
                                    .font(.system(size: 140))
                                    .accessibilityHidden(true)
                                    .modifier(PopInModifier(delay: 0.7, fromScale: 0.0, rotate: true))
                                Text("解锁新水果: \(fruit.name)")
                                    .cartoonTitle(size: CartoonDimensions.fontTitleSmall)
                                    .foregroundStyle(CartoonColor.berry)
                                    .modifier(PopInModifier(delay: 0.9))
                            }
                        }
                    }
                } else {
                    Text("获得经验 +\(viewModel.experienceGained)")
                        .cartoonTitle(size: CartoonDimensions.fontTitleSmall)
                        .foregroundStyle(CartoonColor.gold)
                        .modifier(PopInModifier(delay: 0.3))
                }

                CartoonButton(tint: CartoonColor.leaf, accessibilityLabel: "回到果园", action: onFinish) {
                    Text("🌳 回到果园")
                        .font(CartoonFont.titleSmall)
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 280, height: 80)
                }
                .modifier(PopInModifier(delay: 1.1))
            }
        }
    }

    private func createDefaultProfile() -> ChildProfile {
        let profile = ChildProfile(name: "小果农")
        modelContext.insert(profile)
        return profile
    }

    /// Theme fruit for the active station (falls back to apple).
    private func stationFruitEmoji(viewModel: AdventureSessionViewModel) -> String {
        if let id = viewModel.station?.starFruitId, let fruit = FruitCatalog.fruit(id: id) {
            return fruit.emoji
        }
        return "🍎"
    }

    /// Rotating friendly animal per station so the "share" game isn't always the rabbit.
    private func stationAnimalEmoji(viewModel: AdventureSessionViewModel) -> String {
        let animals = ["🐰", "🐻", "🐼", "🦊", "🐨", "🐯", "🐸", "🐱", "🐶", "🐷"]
        guard let id = viewModel.station?.id else { return "🐰" }
        // Stable pseudo-hash on station id so same station always picks same animal.
        let hash = abs(id.hashValue)
        return animals[hash % animals.count]
    }
}

// MARK: - Animation helpers

struct PopInModifier: ViewModifier {
    let delay: Double
    var fromScale: Double = 0.3
    var rotate: Bool = false

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1.0 : fromScale)
            .rotationEffect(.degrees(appeared ? 0 : (rotate ? -180 : 0)))
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appeared)
            .onAppear { appeared = true }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let pieces: [ConfettiPiece] = (0..<16).map { _ in
        ConfettiPiece(
            emoji: ["⭐", "🎉", "✨", "🌟", "💫", "🎊"].randomElement()!,
            xOffset: Double.random(in: -180...180),
            yStart: Double.random(in: -400 ... -100),
            yEnd: Double.random(in: 300...600),
            size: Double.random(in: 28...52),
            duration: Double.random(in: 1.8...3.0),
            rotation: Double.random(in: -360...360),
            delay: Double.random(in: 0...0.6)
        )
    }

    var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(pieces) { piece in
                    Text(piece.emoji)
                        .font(.system(size: piece.size))
                        .offset(
                            x: piece.xOffset,
                            y: animate ? piece.yEnd : piece.yStart
                        )
                        .rotationEffect(.degrees(animate ? piece.rotation : 0))
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeIn(duration: piece.duration).delay(piece.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { animate = true }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    let xOffset: Double
    let yStart: Double
    let yEnd: Double
    let size: Double
    let duration: Double
    let rotation: Double
    let delay: Double
}
