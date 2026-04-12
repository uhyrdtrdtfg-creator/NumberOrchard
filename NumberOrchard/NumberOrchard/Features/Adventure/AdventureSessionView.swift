import SwiftUI
import SwiftData

struct AdventureSessionView: View {
    let station: Station?
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: AdventureSessionViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isSessionComplete {
                    sessionCompleteView(viewModel: viewModel)
                } else if let question = viewModel.currentQuestion {
                    gameView(for: question, viewModel: viewModel)
                }
            } else {
                ProgressView("加载中...")
            }
        }
        .onAppear {
            let profile = profiles.first ?? createDefaultProfile()
            viewModel = AdventureSessionViewModel(profile: profile, station: station, modelContext: modelContext)
            AudioManager.shared.playMusic("adventure_bgm.wav")
        }
    }

    @ViewBuilder
    private func gameView(for question: MathQuestion, viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(viewModel.questionsCompleted + 1)/\(viewModel.totalQuestions) 题")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("暂停") {
                    viewModel.finishSession()
                    onFinish()
                }
                .font(.callout)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Group {
                switch question.gameMode {
                case .pickFruit:
                    PickFruitView(question: question) { correct, time in
                        viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                    }
                case .shareFruit:
                    ShareFruitView(question: question) { correct, time in
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
            ConfettiView()
            VStack(spacing: 24) {
                Text("太棒了！")
                    .font(.system(size: 56, weight: .bold))
                    .modifier(PopInModifier(delay: 0.1))

                if let reward = viewModel.lastReward {
                    VStack(spacing: 10) {
                        Text("获得 ⭐ +\(reward.starsEarned)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                            .modifier(PopInModifier(delay: 0.3))
                        if reward.seedsEarned > 0 {
                            Text("获得 🌱 +\(reward.seedsEarned)")
                                .font(.title2)
                                .foregroundStyle(.green)
                                .modifier(PopInModifier(delay: 0.5))
                        }
                        if let fruit = viewModel.newlyUnlockedFruit {
                            VStack(spacing: 8) {
                                Text(fruit.emoji)
                                    .font(.system(size: 140))
                                    .modifier(PopInModifier(delay: 0.7, fromScale: 0.0, rotate: true))
                                Text("解锁新水果: \(fruit.name)")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.purple)
                                    .modifier(PopInModifier(delay: 0.9))
                            }
                        }
                    }
                } else {
                    Text("获得经验 +\(viewModel.experienceGained)")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .modifier(PopInModifier(delay: 0.3))
                }

                Button(action: onFinish) {
                    Text("回到果园")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 22)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
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
    private let pieces: [ConfettiPiece] = (0..<30).map { _ in
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
        .allowsHitTesting(false)
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
