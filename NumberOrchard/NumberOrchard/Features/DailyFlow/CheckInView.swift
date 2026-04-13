import SwiftUI

struct CheckInView: View {
    let consecutiveDays: Int
    let onDismiss: () -> Void

    @State private var showReward = false

    var body: some View {
        ZStack {
            CartoonColor.paperWarm
                .ignoresSafeArea()

            VStack(spacing: CartoonDimensions.spacingLarge) {
                Text("欢迎回来，小果农！")
                    .cartoonTitle(size: CartoonDimensions.fontTitleLarge)

                HStack(spacing: CartoonDimensions.spacingTight) {
                    ForEach(1...7, id: \.self) { day in
                        Circle()
                            .fill(day <= (consecutiveDays % 7 == 0 ? 7 : consecutiveDays % 7) ? CartoonColor.gold : Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text("\(day)")
                                    .font(.system(size: CartoonDimensions.fontBodySmall, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .overlay(Circle().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStrokeLight), lineWidth: CartoonDimensions.strokeThin))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("连续登录 \(consecutiveDays) 天")

                if showReward {
                    VStack(spacing: CartoonDimensions.spacingSmall) {
                        Text("🌱")
                            .font(.system(size: 110))
                            .accessibilityHidden(true)
                        Text("获得种子 ×1")
                            .cartoonTitle(size: CartoonDimensions.fontTitle)
                            .foregroundStyle(CartoonColor.leaf)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                CartoonButton(
                    tint: CartoonColor.leaf,
                    accessibilityLabel: "开始今天的冒险",
                    action: onDismiss
                ) {
                    Text("🚀 开始今天的冒险")
                        .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 300, height: 80)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.5)) {
                showReward = true
            }
        }
    }
}

#Preview {
    CheckInView(consecutiveDays: 3, onDismiss: {})
}
