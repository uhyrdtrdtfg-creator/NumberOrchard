import SwiftUI
import SwiftData

/// Full-screen Noom storybook. One page per Noom that has a NoomStory
/// written, paged with a TabView. Each page is a narrated scene + an
/// embedded math question — the child taps the correct answer to earn
/// the story's "seal of reading".
struct StorybookView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var currentIndex = 0
    @State private var answered: [Int: Bool] = [:]   // noomNumber → correct?

    private var profile: ChildProfile? { profiles.first }

    /// Stories ordered by Noom number. Locked pages still appear (to
    /// show "next story coming!") but their question is disabled.
    private var stories: [NoomStory] {
        NoomStoryCatalog.all.sorted { $0.noomNumber < $1.noomNumber }
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 14) {
                MiniGameTopBar(title: "📖 数字故事书", onClose: onDismiss) {
                    Text("\(currentIndex + 1) / \(stories.count)")
                        .font(CartoonFont.bodySmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))
                }

                TabView(selection: $currentIndex) {
                    ForEach(Array(stories.enumerated()), id: \.offset) { idx, story in
                        StoryPage(
                            story: story,
                            alreadyCorrect: answered[story.noomNumber] == true,
                            onAnswer: { chosen in
                                handleAnswer(story: story, chosen: chosen)
                            }
                        )
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .padding(.horizontal, 20)
        }
    }

    private func handleAnswer(story: NoomStory, chosen: Int) {
        let correct = chosen == story.answer
        answered[story.noomNumber] = correct
        if correct {
            Haptics.success()
            AudioManager.shared.playSound("correct.wav")
            if let profile {
                profile.stars += 1
            }
        } else {
            Haptics.warning()
            AudioManager.shared.playSound("wrong.wav")
        }
    }
}

/// Single storybook page — big Noom portrait at the top, narrative
/// beats stacked below, then an inline question with 3 tap-choices.
private struct StoryPage: View {
    let story: NoomStory
    let alreadyCorrect: Bool
    let onAnswer: (Int) -> Void

    @State private var selectedChoice: Int?

    private var noom: Noom? { NoomCatalog.noom(for: story.noomNumber) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let noom {
                    Image(uiImage: NoomRenderer.image(
                        for: noom, expression: .happy,
                        size: CGSize(width: 140, height: 140)
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .padding(.top, 8)
                }

                CartoonPanel(cornerRadius: CartoonRadius.chunky) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(story.lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(CartoonFont.bodyLarge)
                                .foregroundStyle(CartoonColor.text)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }

                Text(story.question)
                    .font(CartoonFont.title)
                    .foregroundStyle(CartoonColor.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    ForEach(story.choices, id: \.self) { choice in
                        choiceButton(choice)
                    }
                }

                if alreadyCorrect {
                    Text("✨ 读过啦!")
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(CartoonColor.gold)
                        .padding(.top, 4)
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
    }

    private func choiceButton(_ value: Int) -> some View {
        let isChosen = selectedChoice == value
        let isCorrect = isChosen && value == story.answer
        let isWrong = isChosen && value != story.answer
        let tint: Color = {
            if isCorrect { return CartoonColor.leaf }
            if isWrong   { return CartoonColor.coral }
            return CartoonColor.gold
        }()
        return Button {
            selectedChoice = value
            onAnswer(value)
        } label: {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 72, height: 72).offset(y: 4)
                Circle().fill(
                    LinearGradient(colors: [.white.opacity(0.6), tint],
                                   startPoint: .top, endPoint: .bottom)
                ).frame(width: 72, height: 72)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3)
                    .frame(width: 72, height: 72)
                Text("\(value)")
                    .font(CartoonFont.title)
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink.opacity(0.6), radius: 0, x: 0, y: 2)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(alreadyCorrect)
    }
}
