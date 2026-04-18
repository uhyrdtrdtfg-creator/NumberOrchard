import SwiftUI
import SwiftData

struct ParentCenterView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedTab = 0

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            if let profile {
                Group {
                    switch selectedTab {
                    case 0: BasicReportView(profile: profile)
                    case 1: NoomWeeklyReportView(profile: profile)
                    default: SettingsView(profile: profile)
                    }
                }
            } else {
                Spacer()
                Text("暂无数据").cartoonBody()
                Spacer()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: CartoonDimensions.spacingSmall) {
            Button("返回") { onDismiss() }
                .font(.headline)
                .padding(.horizontal, CartoonDimensions.spacingSmall + 2)
                .padding(.vertical, CartoonDimensions.spacingTight)
                .accessibilityLabel("返回")

            Spacer()

            Picker("", selection: $selectedTab) {
                Label("学习", systemImage: "chart.bar").tag(0)
                Label("小精灵", systemImage: "pawprint").tag(1)
                Label("设置", systemImage: "gearshape").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Spacer()

            // Invisible spacer matching return button width for balanced layout
            Text("返回")
                .font(.headline)
                .padding(.horizontal, CartoonDimensions.spacingSmall + 2)
                .padding(.vertical, CartoonDimensions.spacingTight)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, CartoonDimensions.spacingRegular)
        .padding(.vertical, CartoonDimensions.spacingSmall)
    }
}

#Preview {
    ParentCenterView(onDismiss: {})
        .modelContainer(for: ChildProfile.self, inMemory: true)
}
