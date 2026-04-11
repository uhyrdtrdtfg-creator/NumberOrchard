import SwiftUI
import SwiftData

struct ParentCenterView: View {
    let onDismiss: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var selectedTab = 0

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            if let profile {
                TabView(selection: $selectedTab) {
                    BasicReportView(profile: profile)
                        .tag(0)
                        .tabItem {
                            Label("学习报告", systemImage: "chart.bar")
                        }

                    SettingsView(profile: profile)
                        .tag(1)
                        .tabItem {
                            Label("设置", systemImage: "gearshape")
                        }
                }
                .navigationTitle("家长中心")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("返回") { onDismiss() }
                    }
                }
            } else {
                Text("暂无数据")
            }
        }
    }
}
