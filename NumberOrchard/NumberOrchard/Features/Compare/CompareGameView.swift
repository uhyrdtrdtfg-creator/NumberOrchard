import SwiftUI
import SwiftData
import Observation

/// 谁多谁少 — show two baskets of fruit, child taps the one with more.
/// Teaches numerical *comparison* without formally counting: early
/// rounds are easy (3 vs 7), later rounds are close (6 vs 7) so kids
/// have to actually estimate / subitize rather than eyeball volume.
@Observable
@MainActor
final class CompareViewModel {
    let profile: ChildProfile
    static let rounds = 6

    var currentRound = 0
    var leftCount: Int = 0
    var rightCount: Int = 0
    var emoji: String = "🍎"
    var lastResult: Bool? = nil
    var correctCount: Int = 0
    var sessionComplete: Bool = false

    init(profile: ChildProfile) {
        self.profile = profile
        nextRound()
    }

    /// Difficulty ramps: round 0-1 have a 4+ gap, 2-3 a 2-3 gap, 4-5
    /// a 1-2 gap. Forces real estimation by the end.
    func nextRound() {
        var rng = SystemRandomNumberGenerator()
        let minGap: Int
        let maxGap: Int
        switch currentRound {
        case 0...1: minGap = 4; maxGap = 6
        case 2...3: minGap = 2; maxGap = 3
        default:    minGap = 1; maxGap = 2
        }
        let gap = Int.random(in: minGap...maxGap, using: &rng)
        let big = Int.random(in: (1 + gap)...12, using: &rng)
        let small = big - gap
        // Shuffle which side is bigger so it's not always left.
        if Bool.random(using: &rng) {
            leftCount = big
            rightCount = small
        } else {
            leftCount = small
            rightCount = big
        }
        emoji = ["🍎", "🍓", "🍋", "🍇", "🍑", "🍒"].randomElement(using: &rng) ?? "🍎"
        lastResult = nil
    }

    /// Caller passes which side they picked (.left / .right). Right
    /// answer is whichever has more.
    func submit(pickedLeft: Bool) {
        let leftIsBigger = leftCount > rightCount
        let correct = (pickedLeft && leftIsBigger) || (!pickedLeft && !leftIsBigger)
        lastResult = correct
        if correct {
            correctCount += 1
            Haptics.success()
            AudioManager.shared.playSound("correct.wav")
        } else {
            Haptics.warning()
            AudioManager.shared.playSound("wrong.wav")
        }
    }

    func advance() {
        currentRound += 1
        if currentRound >= Self.rounds {
            sessionComplete = true
            profile.stars += max(1, correctCount / 2)
            AudioManager.shared.playSound("level_up.wav")
        } else {
            nextRound()
        }
    }

    var progressText: String { "\(min(currentRound + 1, Self.rounds)) / \(Self.rounds)" }
}

struct CompareGameView: View {
    @Bindable var viewModel: CompareViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 18) {
                MiniGameTopBar(title: "⚖️ 谁多谁少",
                               progress: "第 \(viewModel.progressText)",
                               onClose: onDismiss)
                if viewModel.sessionComplete {
                    SessionCompleteCard(
                        emoji: "⚖️🎉",
                        title: "比较大赛结束!",
                        primaryStat: "答对 \(viewModel.correctCount) / \(CompareViewModel.rounds)",
                        rewardLine: "+\(max(1, viewModel.correctCount / 2)) ⭐",
                        onDismiss: onDismiss
                    )
                } else {
                    Text("哪一边多?轻轻点一下")
                        .font(CartoonFont.titleSmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.75))
                    HStack(spacing: 14) {
                        pileButton(side: .left,
                                   count: viewModel.leftCount)
                        Text("VS")
                            .font(CartoonFont.displayLarge)
                            .foregroundStyle(CartoonColor.gold)
                            .shadow(color: CartoonColor.ink.opacity(0.4),
                                    radius: 0, x: 0, y: 2)
                        pileButton(side: .right,
                                   count: viewModel.rightCount)
                    }
                    if viewModel.lastResult != nil {
                        nextButton
                    }
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
        }
    }

    private enum Side { case left, right }

    private func pileButton(side: Side, count: Int) -> some View {
        let pickedLeft = (side == .left)
        let answered = viewModel.lastResult != nil
        let isCorrectPick = answered && viewModel.lastResult == true &&
            ((side == .left && viewModel.leftCount > viewModel.rightCount) ||
             (side == .right && viewModel.rightCount > viewModel.leftCount))
        let tint: Color = isCorrectPick ? CartoonColor.leaf : CartoonColor.paper
        return Button {
            guard !answered else { return }
            viewModel.submit(pickedLeft: pickedLeft)
        } label: {
            VStack(spacing: 6) {
                // Arrange up to 12 emoji in a 3-wide flowing cluster —
                // slightly jittered so counts don't line up in neat rows
                // that could be counted instead of compared.
                pileLayout(count: count)
                    .frame(width: 150, height: 170)
                if answered {
                    Text("\(count) 个")
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(CartoonColor.text)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: CartoonRadius.chunky)
                    .fill(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CartoonRadius.chunky)
                    .stroke(CartoonColor.ink.opacity(0.55), lineWidth: 3)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(side == .left ? "左边 \(count) 个" : "右边 \(count) 个")
    }

    private func pileLayout(count: Int) -> some View {
        let positions: [(CGFloat, CGFloat)] = (0..<count).map { i in
            // Jittered 4×3 grid.
            let row = i / 4, col = i % 4
            let jx = CGFloat.random(in: -6...6)
            let jy = CGFloat.random(in: -6...6)
            return (CGFloat(col) * 30 + 20 + jx,
                    CGFloat(row) * 40 + 20 + jy)
        }
        return ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                Text(viewModel.emoji)
                    .font(.system(size: 28))
                    .position(x: pos.0, y: pos.1)
            }
        }
    }

    private var nextButton: some View {
        CartoonButton(
            tint: viewModel.lastResult == true ? CartoonColor.leaf : CartoonColor.coral,
            cornerRadius: CartoonRadius.chunky,
            accessibilityLabel: "下一题",
            action: viewModel.advance
        ) {
            Text("下一题 →")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(.white)
                .frame(width: 180, height: 54)
        }
    }
}
