import SwiftUI
import SwiftData

/// Top-level mini-game hub — surfaces every playable game in one place
/// so children don't have to drill through the Noom forest just to
/// reach 骰子速算 / 凑十消消乐 / 数字钓鱼 etc. Reached from the home
/// feature row's 🎮 游戏 button.
///
/// Backed by the shared MiniGameGrid (same 3×3 layout as the pet
/// garden) so the two entry points present an identical catalogue.
struct MiniGameHubView: View {
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var gardenViewModel: PetGardenViewModel?

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 24) {
                MiniGameTopBar(title: "🎮 游戏乐园", onClose: onDismiss)

                Text("选一个游戏开始吧")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))

                if let profile {
                    ScrollView {
                        MiniGameGrid(
                            profile: profile,
                            gardenViewModel: gardenViewModel
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Building the PetGardenViewModel unlocks the 数学剧场 tile
            // in the shared grid when the child has an active Noom.
            if let profile, gardenViewModel == nil {
                gardenViewModel = PetGardenViewModel(profile: profile,
                                                     modelContext: modelContext)
            }
        }
    }
}
