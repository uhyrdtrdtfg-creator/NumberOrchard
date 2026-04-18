import SwiftUI
import SwiftData

struct PetGardenView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PetGardenViewModel?
    @State private var theaterViewModel: PetTheaterViewModel?
    @State private var diceViewModel: DiceQuickMathViewModel?
    @State private var matchTenViewModel: MatchTenViewModel?
    @State private var fishingViewModel: FishingViewModel?
    @State private var rhythmViewModel: RhythmMathViewModel?
    @State private var kitchenViewModel: KitchenViewModel?
    @State private var mazeViewModel: MazeViewModel?
    @State private var showTheater = false
    @State private var showDice = false
    @State private var showMatchTen = false
    @State private var showFishing = false
    @State private var showDiary = false
    @State private var showRhythm = false
    @State private var showKitchen = false
    @State private var showMaze = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let viewModel {
                    PetFeedingArea(viewModel: viewModel)
                    miniGameGrid(gardenVM: viewModel)
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
        .fullScreenCover(isPresented: $showDice) {
            if let vm = diceViewModel {
                DiceQuickMathView(viewModel: vm, onDismiss: {
                    showDice = false
                    diceViewModel = nil
                })
            }
        }
        .fullScreenCover(isPresented: $showMatchTen) {
            if let vm = matchTenViewModel {
                MatchTenView(viewModel: vm, onDismiss: {
                    showMatchTen = false
                    matchTenViewModel = nil
                })
            }
        }
        .fullScreenCover(isPresented: $showFishing) {
            if let vm = fishingViewModel {
                FishingView(viewModel: vm, onDismiss: {
                    showFishing = false
                    fishingViewModel = nil
                })
            }
        }
        .fullScreenCover(isPresented: $showDiary) {
            NoomDiaryView(profile: profile, onDismiss: { showDiary = false })
        }
        .fullScreenCover(isPresented: $showRhythm) {
            if let vm = rhythmViewModel {
                RhythmMathView(viewModel: vm, onDismiss: {
                    showRhythm = false
                    rhythmViewModel = nil
                })
            }
        }
        .fullScreenCover(isPresented: $showKitchen) {
            if let vm = kitchenViewModel {
                KitchenView(viewModel: vm, onDismiss: {
                    showKitchen = false
                    kitchenViewModel = nil
                })
            }
        }
        .fullScreenCover(isPresented: $showMaze) {
            if let vm = mazeViewModel {
                MazeView(viewModel: vm, onDismiss: {
                    showMaze = false
                    mazeViewModel = nil
                })
            }
        }
    }

    // MARK: - Unified mini-game grid
    //
    // All 9 entry points rendered as a 3×3 grid of same-size tiles. Each
    // tile carries its own emoji / label / tint / action; callers don't
    // care about the underlying ViewModel construction order. Keeps the
    // garden scannable even as new mini-games are added.
    @ViewBuilder
    private func miniGameGrid(gardenVM: PetGardenViewModel) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        LazyVGrid(columns: columns, spacing: 10) {
            // Row 1 — Noom-centric math (theater needs an owned pet)
            if gardenVM.activePet != nil {
                tile(emoji: "🎭", label: "数学剧场", tint: CartoonColor.berry) {
                    theaterViewModel = PetTheaterViewModel(garden: gardenVM)
                    showTheater = true
                }
            } else {
                tileLocked(emoji: "🎭", label: "剧场")
            }
            tile(emoji: "🎲", label: "骰子速算", tint: CartoonColor.sky) {
                diceViewModel = DiceQuickMathViewModel(profile: profile, modelContext: modelContext)
                showDice = true
            }
            tile(emoji: "🎵", label: "节奏数学", tint: CartoonColor.berry) {
                rhythmViewModel = RhythmMathViewModel(profile: profile, modelContext: modelContext)
                showRhythm = true
            }

            // Row 2 — combination / applied math
            tile(emoji: "🍭", label: "凑十消消", tint: CartoonColor.coral) {
                matchTenViewModel = MatchTenViewModel(profile: profile, modelContext: modelContext)
                showMatchTen = true
            }
            tile(emoji: "🎣", label: "数字钓鱼", tint: CartoonColor.leaf) {
                fishingViewModel = FishingViewModel(profile: profile, modelContext: modelContext)
                showFishing = true
            }
            tile(emoji: "🧩", label: "数字迷宫", tint: CartoonColor.leaf) {
                mazeViewModel = MazeViewModel(profile: profile, modelContext: modelContext)
                showMaze = true
            }

            // Row 3 — applied math + memory
            tile(emoji: "🍳", label: "烹饪厨房", tint: CartoonColor.coral) {
                kitchenViewModel = KitchenViewModel(profile: profile, modelContext: modelContext)
                showKitchen = true
            }
            tile(emoji: "📓", label: "成长日记", tint: CartoonColor.wood) {
                showDiary = true
            }
            // 9th slot reserved for future mini-games; shown as a
            // "more coming" placeholder so the grid stays visually
            // complete and the layout doesn't jump around.
            tileLocked(emoji: "✨", label: "更多…")
        }
    }

    private func tile(
        emoji: String, label: String, tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        CartoonButton(tint: tint, cornerRadius: CartoonRadius.chunky,
                      accessibilityLabel: label, action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 34))
                Text(label)
                    .font(CartoonFont.bodySmall)
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink.opacity(0.4), radius: 0, x: 0, y: 1)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
        }
    }

    private func tileLocked(emoji: String, label: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: CartoonRadius.chunky)
                .fill(CartoonColor.paper.opacity(0.7))
                .frame(height: 88)
            RoundedRectangle(cornerRadius: CartoonRadius.chunky)
                .stroke(CartoonColor.ink.opacity(0.35),
                        style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 88)
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 32)).opacity(0.55)
                Text(label)
                    .font(CartoonFont.caption)
                    .foregroundStyle(CartoonColor.text.opacity(0.45))
            }
        }
    }
}
