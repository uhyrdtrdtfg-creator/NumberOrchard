import SwiftUI

/// Unified "game over / session complete" card. Shared by every
/// mini-game so their finale pacing, typography, and celebration
/// look consistent.
struct SessionCompleteCard: View {
    let emoji: String            // e.g. "🎉" or "🎣🎉"
    let title: String            // e.g. "太棒啦!"
    let primaryStat: String?     // e.g. "答对 4/5 题"
    let rewardLine: String?      // e.g. "+3 ⭐" (rendered gold)
    let buttonTitle: String      // e.g. "回到花园"
    let onDismiss: () -> Void

    init(
        emoji: String,
        title: String,
        primaryStat: String? = nil,
        rewardLine: String? = nil,
        buttonTitle: String = "回到花园",
        onDismiss: @escaping () -> Void
    ) {
        self.emoji = emoji
        self.title = title
        self.primaryStat = primaryStat
        self.rewardLine = rewardLine
        self.buttonTitle = buttonTitle
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 30)
            Text(emoji).font(.system(size: 80))
            Text(title)
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            if let primaryStat {
                Text(primaryStat)
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            if let rewardLine {
                Text(rewardLine)
                    .font(CartoonFont.title)
                    .foregroundStyle(CartoonColor.gold)
            }
            Spacer().frame(height: 10)
            CartoonButton(
                tint: CartoonColor.gold,
                accessibilityLabel: buttonTitle,
                action: onDismiss
            ) {
                Text(buttonTitle)
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 60)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}
