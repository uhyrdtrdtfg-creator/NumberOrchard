import SwiftUI
import SwiftData

struct PetGardenView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PetGardenViewModel?
    @State private var theaterViewModel: PetTheaterViewModel?
    @State private var showTheater = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let viewModel {
                    PetFeedingArea(viewModel: viewModel)
                    if viewModel.activePet != nil {
                        theaterButton(gardenVM: viewModel)
                    }
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
        .fullScreenCover(isPresented: $showTheater) {
            if let vm = theaterViewModel {
                PetTheaterView(viewModel: vm, onDismiss: {
                    showTheater = false
                    theaterViewModel = nil
                })
            }
        }
    }

    private func theaterButton(gardenVM: PetGardenViewModel) -> some View {
        CartoonButton(
            tint: CartoonColor.berry,
            accessibilityLabel: "数学小剧场",
            action: {
                theaterViewModel = PetTheaterViewModel(garden: gardenVM)
                showTheater = true
            }
        ) {
            HStack(spacing: 8) {
                Text("🎭")
                    .font(.system(size: 26))
                Text("数学小剧场")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 240, height: 64)
        }
    }
}
