import SwiftUI

/// Generic empty-state copy block used by diary pages, feeding area,
/// fishing bucket, wardrobe closet, etc. Large emoji + warm title +
/// optional softer hint, centered. Centralising this keeps tone
/// consistent — previously each view reinvented the layout.
struct CartoonEmptyState: View {
    let emoji: String
    let title: String
    let hint: String?

    init(emoji: String, title: String, hint: String? = nil) {
        self.emoji = emoji
        self.title = title
        self.hint = hint
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            Text(emoji).font(.system(size: 80))
            Text(title)
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            if let hint {
                Text(hint)
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
        }
    }
}
