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

                    Text(viewModel.stageName)
                        .font(.title3)
                        .foregroundStyle(.brown)

                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.progress)
                            .frame(width: 200)
                            .tint(.green)
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
