import SwiftUI
import SwiftData

struct PetGardenView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PetGardenViewModel?

    /// Stacking 8 separate `.fullScreenCover(isPresented:)` modifiers on
    /// one view hit SwiftUI's ambiguous-cover bug: only the last one
    /// attached reliably presented, the rest silently no-op'd — so most
    /// mini-game tiles appeared to "open a blank screen". Consolidated
    /// into a single `.fullScreenCover(item:)` driven by an enum.
    @State private var activeGame: ActiveGame?

    enum ActiveGame: Identifiable {
        case theater(PetTheaterViewModel)
        case dice(DiceQuickMathViewModel)
        case matchTen(MatchTenViewModel)
        case fishing(FishingViewModel)
        case rhythm(RhythmMathViewModel)
        case kitchen(KitchenViewModel)
        case maze(MazeViewModel)
        case diary

        var id: String {
            switch self {
            case .theater:  return "theater"
            case .dice:     return "dice"
            case .matchTen: return "matchTen"
            case .fishing:  return "fishing"
            case .rhythm:   return "rhythm"
            case .kitchen:  return "kitchen"
            case .maze:     return "maze"
            case .diary:    return "diary"
            }
        }
    }

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
        .fullScreenCover(item: $activeGame) { game in
            switch game {
            case .theater(let vm):
                PetTheaterView(viewModel: vm, onDismiss: { activeGame = nil })
            case .dice(let vm):
                DiceQuickMathView(viewModel: vm, onDismiss: { activeGame = nil })
            case .matchTen(let vm):
                MatchTenView(viewModel: vm, onDismiss: { activeGame = nil })
            case .fishing(let vm):
                FishingView(viewModel: vm, onDismiss: { activeGame = nil })
            case .rhythm(let vm):
                RhythmMathView(viewModel: vm, onDismiss: { activeGame = nil })
            case .kitchen(let vm):
                KitchenView(viewModel: vm, onDismiss: { activeGame = nil })
            case .maze(let vm):
                MazeView(viewModel: vm, onDismiss: { activeGame = nil })
            case .diary:
                NoomDiaryView(profile: profile, onDismiss: { activeGame = nil })
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
                    activeGame = .theater(PetTheaterViewModel(garden: gardenVM))
                }
            } else {
                tileLocked(emoji: "🎭", label: "剧场")
            }
            tile(emoji: "🎲", label: "骰子速算", tint: CartoonColor.sky) {
                activeGame = .dice(DiceQuickMathViewModel(profile: profile, modelContext: modelContext))
            }
            tile(emoji: "🎵", label: "节奏数学", tint: CartoonColor.berry) {
                activeGame = .rhythm(RhythmMathViewModel(profile: profile, modelContext: modelContext))
            }

            // Row 2 — combination / applied math
            tile(emoji: "🍭", label: "凑十消消", tint: CartoonColor.coral) {
                activeGame = .matchTen(MatchTenViewModel(profile: profile, modelContext: modelContext))
            }
            tile(emoji: "🎣", label: "数字钓鱼", tint: CartoonColor.leaf) {
                activeGame = .fishing(FishingViewModel(profile: profile, modelContext: modelContext))
            }
            tile(emoji: "🧩", label: "数字迷宫", tint: CartoonColor.leaf) {
                activeGame = .maze(MazeViewModel(profile: profile, modelContext: modelContext))
            }

            // Row 3 — applied math + memory
            tile(emoji: "🍳", label: "烹饪厨房", tint: CartoonColor.coral) {
                activeGame = .kitchen(KitchenViewModel(profile: profile, modelContext: modelContext))
            }
            tile(emoji: "📓", label: "成长日记", tint: CartoonColor.wood) {
                activeGame = .diary
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
