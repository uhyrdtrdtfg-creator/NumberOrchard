import SwiftUI
import SwiftData

struct AdventureSessionView: View {
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
            viewModel = AdventureSessionViewModel(profile: profile, modelContext: modelContext)
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

            switch question.gameMode {
            case .pickFruit:
                PickFruitView(question: question) { correct, time in
                    viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                }
            case .shareFruit:
                ShareFruitView(question: question) { correct, time in
                    viewModel.handleAnswer(correct: correct, responseTime: time, usedHint: false)
                }
            }
        }
    }

    private func sessionCompleteView(viewModel: AdventureSessionViewModel) -> some View {
        VStack(spacing: 24) {
            Text("太棒了！")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("今天完成了 \(viewModel.questionsCompleted) 道题")
                .font(.title2)

            Text("获得经验 +\(viewModel.experienceGained)")
                .font(.title3)
                .foregroundStyle(.orange)

            Button(action: onFinish) {
                Text("回到果园")
                    .font(.title3)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private func createDefaultProfile() -> ChildProfile {
        let profile = ChildProfile(name: "小果农")
        modelContext.insert(profile)
        return profile
    }
}
