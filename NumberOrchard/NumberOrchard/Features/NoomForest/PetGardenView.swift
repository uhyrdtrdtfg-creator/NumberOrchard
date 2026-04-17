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
    @State private var showTheater = false
    @State private var showDice = false
    @State private var showMatchTen = false
    @State private var showFishing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let viewModel {
                    PetFeedingArea(viewModel: viewModel)
                    if viewModel.activePet != nil {
                        theaterButton(gardenVM: viewModel)
                    }
                    HStack(spacing: 12) {
                        diceButton
                        matchTenButton
                    }
                    fishingButton
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
                Text("🎭").font(.system(size: 26))
                Text("数学小剧场").font(CartoonFont.bodyLarge).foregroundStyle(.white)
            }
            .frame(width: 240, height: 64)
        }
    }

    private var diceButton: some View {
        CartoonButton(
            tint: CartoonColor.sky,
            accessibilityLabel: "骰子速算",
            action: {
                diceViewModel = DiceQuickMathViewModel(profile: profile, modelContext: modelContext)
                showDice = true
            }
        ) {
            VStack(spacing: 2) {
                Text("🎲").font(.system(size: 26))
                Text("骰子速算").font(CartoonFont.bodySmall).foregroundStyle(.white)
            }
            .frame(width: 120, height: 72)
        }
    }

    private var matchTenButton: some View {
        CartoonButton(
            tint: CartoonColor.coral,
            accessibilityLabel: "凑十消消乐",
            action: {
                matchTenViewModel = MatchTenViewModel(profile: profile, modelContext: modelContext)
                showMatchTen = true
            }
        ) {
            VStack(spacing: 2) {
                Text("🍭").font(.system(size: 26))
                Text("凑十消消乐").font(CartoonFont.bodySmall).foregroundStyle(.white)
            }
            .frame(width: 120, height: 72)
        }
    }

    private var fishingButton: some View {
        CartoonButton(
            tint: CartoonColor.leaf,
            accessibilityLabel: "数字钓鱼",
            action: {
                fishingViewModel = FishingViewModel(profile: profile, modelContext: modelContext)
                showFishing = true
            }
        ) {
            HStack(spacing: 8) {
                Text("🎣").font(.system(size: 26))
                Text("数字钓鱼").font(CartoonFont.bodyLarge).foregroundStyle(.white)
            }
            .frame(width: 240, height: 64)
        }
    }
}
