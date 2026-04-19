import SwiftUI
import SwiftData

/// Full-screen storybook. Top picker switches between the 🐾 小精灵
/// and 🚒 汪汮队 collections; each collection paginates with a
/// TabView. Each page is a narrated scene + an embedded math question
/// — the child taps the correct answer to earn a star.
struct StorybookView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedBook: StoryBook = .noom
    @State private var indexByBook: [StoryBook: Int] = [:]
    @State private var answered: [String: Bool] = [:]   // entry id → correct?

    private var profile: ChildProfile? { profiles.first }

    private var entries: [StoryEntry] {
        StoryCatalog.entries(in: selectedBook)
    }

    private var currentIndex: Binding<Int> {
        Binding(
            get: { indexByBook[selectedBook] ?? 0 },
            set: { indexByBook[selectedBook] = $0 }
        )
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 14) {
                MiniGameTopBar(title: "📖 故事书", onClose: onDismiss) {
                    Text("\((indexByBook[selectedBook] ?? 0) + 1) / \(entries.count)")
                        .font(CartoonFont.bodySmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))
                }
                bookPicker
                TabView(selection: currentIndex) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        StoryPage(
                            entry: entry,
                            alreadyCorrect: answered[entry.id] == true,
                            onAnswer: { chosen in handleAnswer(entry: entry, chosen: chosen) }
                        )
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .padding(.horizontal, 20)
        }
    }

    private var bookPicker: some View {
        HStack(spacing: 10) {
            ForEach(StoryBook.allCases) { book in
                let selected = book == selectedBook
                Button {
                    selectedBook = book
                } label: {
                    Text(book.rawValue)
                        .font(CartoonFont.body)
                        .foregroundStyle(selected ? .white : CartoonColor.text)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected ? CartoonColor.coral : CartoonColor.paper)
                        )
                        .overlay(
                            Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private func handleAnswer(entry: StoryEntry, chosen: Int) {
        let correct = chosen == entry.answer
        answered[entry.id] = correct
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

/// Single storybook page — hero illustration (Noom portrait or emoji),
/// narrative beats, then an inline question with 3 tap-choices.
private struct StoryPage: View {
    let entry: StoryEntry
    let alreadyCorrect: Bool
    let onAnswer: (Int) -> Void

    @State private var selectedChoice: Int?

    private var noom: Noom? {
        guard let n = entry.noomNumber else { return nil }
        return NoomCatalog.noom(for: n)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                CartoonPanel(cornerRadius: CartoonRadius.chunky) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(entry.lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(CartoonFont.bodyLarge)
                                .foregroundStyle(CartoonColor.text)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }

                Text(entry.question)
                    .font(CartoonFont.title)
                    .foregroundStyle(CartoonColor.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    ForEach(entry.choices, id: \.self) { choice in
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

    /// Either the Noom portrait (when the page belongs to the Noom
    /// book) or the emoji glyph (汪汪队 etc.).
    @ViewBuilder
    private var hero: some View {
        if let noom {
            Image(uiImage: NoomRenderer.image(
                for: noom, expression: .happy,
                size: CGSize(width: 140, height: 140)
            ))
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
            .padding(.top, 8)
        } else if let glyph = entry.illustration {
            Text(glyph)
                .font(.system(size: 110))
                .padding(20)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, CartoonColor.paper],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(Circle().stroke(CartoonColor.ink.opacity(0.55), lineWidth: 3))
                        .shadow(color: CartoonColor.ink.opacity(0.3), radius: 0, x: 0, y: 4)
                )
                .padding(.top, 8)
        }
    }

    private func choiceButton(_ value: Int) -> some View {
        let isChosen = selectedChoice == value
        let isCorrect = isChosen && value == entry.answer
        let isWrong = isChosen && value != entry.answer
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
