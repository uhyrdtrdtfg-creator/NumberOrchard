import SwiftUI
import SwiftData

struct NoomForestView: View {
    let onDismiss: () -> Void
    let onStartChallenge: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var viewModel: NoomForestViewModel?
    @State private var inspectedNoom: Noom?

    private var profile: ChildProfile? { profiles.first }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 24) {
                topBar

                Text("🐾 小精灵森林")
                    .font(CartoonFont.displayLarge)
                    .foregroundStyle(CartoonColor.text)

                tabPicker

                if viewModel?.selectedTab == .garden, let profile {
                    // Pet garden owns its own ScrollView; let it expand
                    // into the remaining height. Before this, a legacy
                    // "🎮 开始挑战" button + Spacer below the garden ate
                    // ~30% of the viewport, hiding the 3×3 mini-game grid
                    // and clipping the fruit inventory.
                    PetGardenView(profile: profile)
                } else {
                    Text("图鉴: \(viewModel?.unlockedCount ?? 0) / 20")
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))

                    dexGrid

                    Spacer()

                    // The classic NoomChallenge entry only makes sense on
                    // the dex tab now that the garden has its own 3×3
                    // grid of mini-games. Keeping it here so the dex
                    // still has a primary action.
                    CartoonButton(
                        tint: CartoonColor.gold,
                        cornerRadius: CartoonRadius.chunky,
                        accessibilityLabel: "开始挑战",
                        action: onStartChallenge
                    ) {
                        Text("🎮 开始挑战")
                            .font(CartoonFont.titleSmall)
                            .foregroundStyle(.white)
                            .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                            .frame(width: 260, height: 76)
                    }

                    Spacer().frame(height: 30)
                }
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            if let profile { viewModel = NoomForestViewModel(profile: profile) }
        }
        .sheet(item: $inspectedNoom) { noom in
            noomDetailSheet(noom: noom)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 60, height: 60).offset(y: 4)
                    Circle().fill(CartoonColor.paper).frame(width: 60, height: 60)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 60, height: 60)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            CartoonHUD(icon: "star.fill", value: "\(profile?.stars ?? 0)", tint: CartoonColor.gold)
            CartoonHUD(icon: "leaf.fill", value: "\(profile?.seeds ?? 0)", tint: CartoonColor.leaf)
        }
        .padding(.top, 20)
    }

    private var tabPicker: some View {
        HStack(spacing: 12) {
            ForEach(NoomForestTab.allCases, id: \.self) { tab in
                let selected = (viewModel?.selectedTab == tab)
                Button(action: {
                    viewModel?.selectedTab = tab
                }) {
                    Text(tab.title)
                        .font(CartoonFont.body)
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .foregroundStyle(selected ? .white : CartoonColor.text)
                        .background(
                            ZStack {
                                Capsule().fill(CartoonColor.ink.opacity(0.9)).offset(y: 4)
                                Capsule().fill(selected ? CartoonColor.gold : CartoonColor.paper)
                                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3)
                            }
                        )
                        .fixedSize()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dexGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
            ForEach(NoomCatalog.all) { noom in
                noomCell(noom: noom)
                    .onTapGesture {
                        if viewModel?.isUnlocked(noom.number) ?? false {
                            inspectedNoom = noom
                        }
                    }
            }
        }
    }

    private func noomCell(noom: Noom) -> some View {
        let unlocked = viewModel?.isUnlocked(noom.number) ?? false
        return IdleBobbingNoomCell(noom: noom, unlocked: unlocked)
    }

    private func noomDetailSheet(noom: Noom) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: NoomRenderer.image(for: noom, expression: .happy, size: CGSize(width: 200, height: 200)))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text(noom.name)
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("我是数字 \(noom.number)！")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            CartoonPanel(cornerRadius: 20) {
                Text(noom.catchphrase)
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.text)
                    .padding(20)
            }
            Button("关闭") { inspectedNoom = nil }
                .font(CartoonFont.body)
                .padding(.top)
        }
        .padding(40)
        .presentationDetents([.medium])
    }
}

/// Dex grid cell with a gentle idle bob. Each cell's bob is phase-
/// offset by the Noom number so they don't all breathe in sync —
/// dex reads as a lively crowd rather than a marching band.
private struct IdleBobbingNoomCell: View {
    let noom: Noom
    let unlocked: Bool

    @State private var bob = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 110, height: 110).offset(y: 5)
            Circle().fill(unlocked ? Color(uiColor: noom.bodyColor) : Color.gray.opacity(0.4))
                .frame(width: 110, height: 110)
            Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 110, height: 110)
            if unlocked {
                // Full personality-face portrait (same renderer as feeding
                // area) so the dex shows the creature's real look, not
                // just a silhouette.
                Image(uiImage: NoomRenderer.image(
                    for: noom, expression: .happy,
                    size: CGSize(width: 100, height: 100)
                ))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .offset(y: reduceMotion ? 0 : (bob ? -2 : 2))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(CartoonColor.ink.opacity(0.55))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            // Phase-shift per Noom number so the crowd doesn't bob in unison.
            let delay = Double(noom.number % 5) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    bob = true
                }
            }
        }
    }
}
