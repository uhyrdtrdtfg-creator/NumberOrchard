import SwiftUI
import SwiftData

struct PetGardenView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PetGardenViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let viewModel {
                    PetFeedingArea(viewModel: viewModel)
                    // The same 3×3 layout also lives at the top level in
                    // MiniGameHubView. Both entry points feed through the
                    // shared MiniGameGrid component so tiles stay in sync.
                    MiniGameGrid(profile: profile, gardenViewModel: viewModel)
                    EggHatchingArea(viewModel: viewModel)
                } else {
                    ProgressView()
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PetGardenViewModel(profile: profile, modelContext: modelContext)
            }
        }
    }
}
