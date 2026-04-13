import SwiftUI
import SwiftData

struct NoomChallengeSessionView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: NoomChallengeViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isSessionComplete {
                    resultView(viewModel: viewModel)
                } else if let challenge = viewModel.currentChallenge {
                    challengeView(challenge: challenge, viewModel: viewModel)
                } else {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            let profile = profiles.first ?? createDefaultProfile()
            viewModel = NoomChallengeViewModel(profile: profile, modelContext: modelContext)
        }
    }

    private func challengeView(challenge: NoomChallengeType, viewModel: NoomChallengeViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("第 \(viewModel.questionsCompleted + 1)/\(viewModel.totalQuestions) 题")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("暂停") { onFinish() }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            NoomChallengeView(challenge: challenge) { unlocked in
                viewModel.handleCompletion(unlockedNumbers: unlocked)
            }
            .id(viewModel.questionsCompleted)
        }
    }

    private func resultView(viewModel: NoomChallengeViewModel) -> some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 24) {
                Text("🎉 太棒了！")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                Text("完成 5 道题")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.7))

                if !viewModel.newlyUnlockedNooms.isEmpty {
                    Text("解锁新伙伴")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CartoonColor.berry)
                    HStack(spacing: 16) {
                        ForEach(viewModel.newlyUnlockedNooms.prefix(5)) { noom in
                            VStack(spacing: 4) {
                                Image(uiImage: NoomRenderer.image(for: noom, expression: .happy, size: CGSize(width: 90, height: 90)))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                Text(noom.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(CartoonColor.text)
                            }
                        }
                    }
                }

                Text("⭐ +\(viewModel.starsEarned)   🌱 +\(viewModel.seedsEarned)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.gold)

                CartoonButton(tint: CartoonColor.leaf, action: onFinish) {
                    Text("🌳 回到森林")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 240, height: 70)
                }
            }
        }
    }

    private func createDefaultProfile() -> ChildProfile {
        let profile = ChildProfile(name: "小果农")
        modelContext.insert(profile)
        return profile
    }
}
