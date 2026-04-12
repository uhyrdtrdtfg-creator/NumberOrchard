import SwiftUI

struct TreeGrowthView: View {
    let profile: ChildProfile

    @State private var viewModel: TreeGrowthViewModel?

    var body: some View {
        Group {
            if let viewModel {
                VStack(spacing: 20) {
                    Text("我的果树")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.stageEmoji)
                        .font(.system(size: 120))
                        .shadow(radius: 5)
                        .accessibilityHidden(true)

                    Text(viewModel.stageName)
                        .font(.title3)
                        .foregroundStyle(.brown)

                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.progress)
                            .tint(.green)
                            .padding(.horizontal, 40)
                        Text(viewModel.experienceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel = TreeGrowthViewModel(profile: profile)
        }
    }
}
