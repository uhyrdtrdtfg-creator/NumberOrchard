import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void
    let onOpenMap: () -> Void
    let onOpenCollection: () -> Void
    let onOpenDecorate: () -> Void
    let onOpenBattle: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [ChildProfile]
    @State private var viewModel = HomeViewModel()

    private var profile: ChildProfile {
        if let existing = profiles.first { return existing }
        let newProfile = ChildProfile(name: "小果农")
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            HomeSkyLayer()
            CartoonGround(height: 280)
            HomeDecorationsLayer(decorations: profile.decorations)

            VStack(spacing: 0) {
                HomeTopHUD(
                    stars: profile.stars,
                    seeds: profile.seeds,
                    onSettings: { viewModel.showParentalGate = true }
                )

                Spacer()

                HomeTreeHero(
                    treeEmoji: viewModel.treeStageEmoji,
                    treeProgress: viewModel.treeProgress,
                    levelLabel: profile.difficultyLevel.displayName
                )
                .padding(.bottom, CartoonDimensions.spacingLarge)

                Spacer().frame(height: 40)

                HomeFeatureRow(
                    onOpenMap: onOpenMap,
                    onOpenDecorate: onOpenDecorate,
                    onOpenCollection: onOpenCollection,
                    onOpenBattle: {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                )
                .padding(.horizontal, CartoonDimensions.spacingRegular)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            viewModel.checkDailyLogin(profile: profile)
            AudioManager.shared.playMusic("home_bgm.wav")
        }
        .fullScreenCover(isPresented: $viewModel.showCheckIn) {
            CheckInView(
                consecutiveDays: profile.consecutiveLoginDays,
                onDismiss: { viewModel.showCheckIn = false }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showParentalGate) {
            ParentalGateView(
                onSuccess: {
                    viewModel.showParentalGate = false
                    switch viewModel.parentGateIntent {
                    case .settings: onOpenParentCenter()
                    case .battle: onOpenBattle()
                    }
                    viewModel.parentGateIntent = .settings
                },
                onCancel: {
                    viewModel.showParentalGate = false
                    viewModel.parentGateIntent = .settings
                }
            )
        }
    }
}

// MARK: - Sky layer (sun + clouds)

private struct HomeSkyLayer: View {
    @State private var sunRotating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            Text("🌞")
                .font(.system(size: 110))
                .rotationEffect(.degrees(reduceMotion ? 0 : (sunRotating ? 12 : -12)))
                .animation(reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: sunRotating)
                .position(x: geo.size.width * 0.88, y: geo.size.height * 0.14)

            Text("☁️")
                .font(.system(size: 90))
                .position(x: geo.size.width * 0.15, y: geo.size.height * 0.18)

            Text("☁️")
                .font(.system(size: 60))
                .position(x: geo.size.width * 0.55, y: geo.size.height * 0.12)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { sunRotating = true }
    }
}

// MARK: - Ground decorations

private struct HomeDecorationsLayer: View {
    let decorations: [CollectedDecoration]

    /// Sort by positionY so decorations further "back" render first (and those in front layer over).
    private var sortedPlaced: [(offset: Int, element: CollectedDecoration)] {
        let placed = decorations.filter { $0.isPlaced }
            .sorted { $0.positionY < $1.positionY }
        return Array(placed.enumerated())
    }

    var body: some View {
        GeometryReader { geo in
            let bandTop = geo.size.height * 0.55
            let bandHeight = geo.size.height * 0.18
            ForEach(sortedPlaced, id: \.element.id) { index, deco in
                if let item = DecorationCatalog.item(id: deco.itemId) {
                    PlacedDecorationView(
                        emoji: item.emoji,
                        size: item.category.placedSize,
                        phaseOffset: Double(index) * 0.3
                    )
                    .position(
                        x: deco.positionX * geo.size.width,
                        y: bandTop + deco.positionY * bandHeight
                    )
                    .zIndex(orchardDepthZ(for: deco.positionY))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Top HUD

private struct HomeTopHUD: View {
    let stars: Int
    let seeds: Int
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: CartoonDimensions.spacingSmall) {
            CartoonHUD(icon: "star.fill", value: "\(stars)", tint: CartoonColor.gold, accessibilityLabel: "星星 \(stars)")
            CartoonHUD(icon: "leaf.fill", value: "\(seeds)", tint: CartoonColor.leaf, accessibilityLabel: "种子 \(seeds)")
            Spacer()
            CartoonCircleIconButton(
                systemImage: "gearshape.fill",
                iconSize: 30,
                accessibilityLabel: "家长中心",
                accessibilityHint: "打开家长设置",
                action: onSettings
            )
        }
        .padding(.horizontal, 36)
        .padding(.top, 20)
    }
}

// MARK: - Tree hero

private struct HomeTreeHero: View {
    let treeEmoji: String
    let treeProgress: Double
    let levelLabel: String

    @State private var treeBreathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Text(treeEmoji)
                .font(.system(size: 160))
                .cartoonInkShadow(y: CartoonDimensions.shadowOffsetLarge)
                .scaleEffect(reduceMotion ? 1.0 : (treeBreathing ? 1.05 : 1.0))
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: treeBreathing)
                .accessibilityHidden(true)

            TreeProgressBar(progress: treeProgress, level: levelLabel)
        }
        .onAppear { treeBreathing = true }
    }
}

// MARK: - Feature row

private struct HomeFeatureRow: View {
    let onOpenMap: () -> Void
    let onOpenDecorate: () -> Void
    let onOpenCollection: () -> Void
    let onOpenBattle: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            CartoonFeatureButton(emoji: "🗺️", label: "探险", tint: CartoonColor.gold, bobDelay: 0.0, action: onOpenMap)
            CartoonFeatureButton(emoji: "🎨", label: "装饰", tint: CartoonColor.coral, bobDelay: 0.15, action: onOpenDecorate)
            CartoonFeatureButton(emoji: "🍎", label: "图鉴", tint: CartoonColor.leaf, bobDelay: 0.30, action: onOpenCollection)
            CartoonFeatureButton(emoji: "👨‍👦", label: "对战", tint: CartoonColor.berry, bobDelay: 0.45, action: onOpenBattle)
        }
    }
}

// MARK: - Feature button

private struct CartoonFeatureButton: View {
    let emoji: String
    let label: String
    let tint: Color
    let bobDelay: Double
    let action: () -> Void

    @State private var bobbing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var buttonSize: CGFloat = 150
    @ScaledMetric(relativeTo: .title) private var emojiSize: CGFloat = 62
    @ScaledMetric(relativeTo: .title) private var labelSize: CGFloat = 26

    var body: some View {
        CartoonButton(tint: tint, accessibilityLabel: label, action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: emojiSize))
                Text(label)
                    .font(.system(size: labelSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .offset(y: reduceMotion ? 0 : (bobbing ? -4 : 2))
        .rotationEffect(.degrees(reduceMotion ? 0 : (bobbing ? 1.5 : -1.5)))
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(bobDelay), value: bobbing)
        .onAppear { bobbing = true }
    }
}

// MARK: - Progress bar

private struct TreeProgressBar: View {
    let progress: Double
    let level: String

    @ScaledMetric(relativeTo: .title3) private var pillWidth: CGFloat = 170
    @ScaledMetric(relativeTo: .title3) private var barWidth: CGFloat = 264

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Capsule()
                    .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                    .frame(width: pillWidth, height: 44)
                    .offset(y: CartoonDimensions.shadowOffsetRegular)
                Capsule()
                    .fill(CartoonColor.paper)
                    .frame(width: pillWidth, height: 44)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                    .frame(width: pillWidth, height: 44)
                Text(level)
                    .cartoonTitle(size: CartoonDimensions.fontBodyLarge)
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: barWidth, height: 26)
                    .offset(y: CartoonDimensions.shadowOffsetRegular)
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: barWidth, height: 26)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [CartoonColor.gold, CartoonColor.coral],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(26, progress * barWidth), height: 26)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeRegular)
                    .frame(width: barWidth, height: 26)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("当前级别 \(level),成长进度 \(Int(progress * 100)) 百分比")
    }
}

#Preview {
    HomeView(
        onStartAdventure: {},
        onOpenParentCenter: {},
        onOpenMap: {},
        onOpenCollection: {},
        onOpenDecorate: {},
        onOpenBattle: {}
    )
    .modelContainer(for: ChildProfile.self, inMemory: true)
}
