import SwiftUI

/// Reusable top bar for every mini-game's full-screen cover. A circular
/// close button on the left, a centered title, and an optional trailing
/// slot for progress text or a trophy count.
///
/// Before this existed each mini-game hand-rolled its own bar, which
/// drifted in padding, button size, and typography. This bar is the
/// one source of truth.
struct MiniGameTopBar<Trailing: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    init(title: String, onClose: @escaping () -> Void,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.onClose = onClose
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Button(action: onClose) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9))
                        .frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3)
                        .frame(width: 56, height: 56)
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            .accessibilityLabel("关闭")
            Spacer()
            Text(title)
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            ZStack(alignment: .trailing) {
                // Invisible spacer mirroring the close button so the title
                // stays centered even when `trailing` is empty.
                Color.clear.frame(width: 56, height: 56)
                trailing()
            }
        }
        .padding(.top, 16)
    }
}

extension MiniGameTopBar where Trailing == Text {
    /// Convenience initializer for the common "第 2/5 题" right-aligned label.
    init(title: String, progress: String, onClose: @escaping () -> Void) {
        self.init(title: title, onClose: onClose) {
            Text(progress)
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
        }
    }
}
