import SwiftUI

struct CheckInView: View {
    let consecutiveDays: Int
    let onDismiss: () -> Void

    @State private var showReward = false

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.97, blue: 0.91)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("欢迎回来，小果农！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown)

                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { day in
                        VStack {
                            Circle()
                                .fill(day <= (consecutiveDays % 7 == 0 ? 7 : consecutiveDays % 7) ? .orange : .gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text("\(day)")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                }

                if showReward {
                    VStack(spacing: 8) {
                        Text("🌱")
                            .font(.system(size: 60))
                        Text("获得种子 ×1")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button(action: onDismiss) {
                    Text("开始今天的冒险")
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
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
