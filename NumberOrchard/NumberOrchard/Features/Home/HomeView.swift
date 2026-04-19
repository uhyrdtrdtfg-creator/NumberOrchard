import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void
    let onOpenMap: () -> Void
    let onOpenCollection: () -> Void
    let onOpenDecorate: () -> Void
    let onOpenBattle: () -> Void
    let onOpenNoomForest: () -> Void
    let onOpenMiniGames: () -> Void

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
            // Warm storybook sky — home gets its own peach-pink gradient
            // instead of the standard blue so the child lands on a cosier,
            // more playful scene (matches the reference illustration style).
            HomeStorybookSky()
            CartoonGround(height: 280)
            // Floating ambient particles (hearts / clovers / sparkles) to
            // make the scene feel alive even when the child is idle.
            HomeAmbientParticles()
                .allowsHitTesting(false)
            // Decorations must render ABOVE the foreground VStack
            // (HomeTreeHero's large emoji otherwise sits on top of
            // anything the child has placed in the orchard band).
            HomeDecorationsLayer(decorations: profile.decorations)
                .zIndex(5)

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
                    onOpenNoomForest: onOpenNoomForest,
                    onOpenBattle: {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    },
                    onOpenMiniGames: onOpenMiniGames
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
            // Ground hill tops out around 280pt high. Previously the
            // decoration band (0.55-0.73) sat right where the shared
            // vector sun-and-clouds backdrop draws its lowest cloud —
            // clouds + tree both ended up covering decorations. Lifting
            // the band to 0.48-0.62 places decorations in the grassy
            // strip between the tree hero and the hill curve, visible
            // under any scenery.
            let bandTop = geo.size.height * 0.48
            let bandHeight = geo.size.height * 0.14
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
    let onOpenNoomForest: () -> Void
    let onOpenBattle: () -> Void
    let onOpenMiniGames: () -> Void

    // Soft pastel colour per feature — each "house" gets its own
    // storybook-friendly tint, with a matching darker shade baked into
    // the gradient. Based on the reference illustration palette.
    private static let gamesFill    = Color(red: 0.97, green: 0.73, blue: 0.78)  // rose
    private static let exploreFill  = Color(red: 0.98, green: 0.87, blue: 0.55)  // buttercup
    private static let decorateFill = Color(red: 0.96, green: 0.78, blue: 0.87)  // blush pink
    private static let dexFill      = Color(red: 0.76, green: 0.89, blue: 0.62)  // pastel sage
    private static let noomFill     = Color(red: 0.72, green: 0.85, blue: 0.95)  // powder blue
    private static let battleFill   = Color(red: 0.82, green: 0.74, blue: 0.95)  // soft lavender

    var body: some View {
        // 6 house-shaped tiles with label printed beneath — the top-level
        // entry points to the whole app. Games goes first because it's
        // the most common destination.
        HStack(alignment: .top, spacing: 14) {
            HomeFeatureHouse(emoji: "🎮", label: "游戏",   fill: Self.gamesFill,    bobDelay: 0.00, action: onOpenMiniGames)
            HomeFeatureHouse(emoji: "🗺️", label: "探索",   fill: Self.exploreFill,  bobDelay: 0.12, action: onOpenMap)
            HomeFeatureHouse(emoji: "🎨", label: "装饰",   fill: Self.decorateFill, bobDelay: 0.24, action: onOpenDecorate)
            HomeFeatureHouse(emoji: "🍎", label: "图鉴",   fill: Self.dexFill,      bobDelay: 0.36, action: onOpenCollection)
            HomeFeatureHouse(emoji: "🐾", label: "小精灵", fill: Self.noomFill,     bobDelay: 0.48, action: onOpenNoomForest)
            HomeFeatureHouse(emoji: "🦊", label: "对战",   fill: Self.battleFill,   bobDelay: 0.60, action: onOpenBattle)
        }
    }
}

// MARK: - Feature house-tile

/// House-shaped feature tile inspired by the storybook reference art —
/// peaked-roof body with a pastel fill + soft top highlight + an ink
/// outline, and the label printed beneath the shape (not inside it).
/// A subtle idle bob with per-tile phase offset gives the row a gentle
/// "village" feel without the jittery wobble of the old tile style.
private struct HomeFeatureHouse: View {
    let emoji: String
    let label: String
    let fill: Color
    let bobDelay: Double
    let action: () -> Void

    @State private var bobbing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var tileWidth: CGFloat = 110
    @ScaledMetric(relativeTo: .title) private var tileHeight: CGFloat = 180
    @ScaledMetric(relativeTo: .title) private var emojiSize: CGFloat = 58
    @ScaledMetric(relativeTo: .title) private var labelSize: CGFloat = 22

    var body: some View {
        VStack(spacing: 10) {
            Button(action: { Haptics.tap(); action() }) {
                ZStack {
                    // Hard drop-shadow silhouette
                    HouseTileShape()
                        .fill(CartoonColor.ink.opacity(0.3))
                        .offset(y: 5)
                    // Pastel body + a gentle top-to-center white sheen
                    HouseTileShape()
                        .fill(fill)
                    HouseTileShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), .clear],
                                startPoint: .top, endPoint: .center
                            )
                        )
                    // Ink outline
                    HouseTileShape()
                        .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                    // Emoji icon centred in the body (offset down a touch
                    // so the peaked roof has breathing room)
                    Text(emoji)
                        .font(.system(size: emojiSize))
                        .offset(y: 8)
                }
                .frame(width: tileWidth, height: tileHeight)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(label)

            // Label printed beneath the house — matches the reference.
            Text(label)
                .font(.system(size: labelSize, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
                .shadow(color: .white.opacity(0.55), radius: 0, x: 0, y: 1)
        }
        .offset(y: reduceMotion ? 0 : (bobbing ? -3 : 3))
        .animation(reduceMotion ? nil : .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true).delay(bobDelay), value: bobbing)
        .onAppear { bobbing = true }
    }
}

/// Shape used by HomeFeatureHouse — rectangular body with rounded
/// bottom corners and a sharp peaked roof on top, like a little toy
/// house silhouette.
private struct HouseTileShape: Shape {
    var cornerRadius: CGFloat = 22
    var roofHeightRatio: CGFloat = 0.16

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = cornerRadius
        let roofY = rect.minY + rect.height * roofHeightRatio

        // Start at the roof peak (top-center) and go clockwise.
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: roofY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.minX, y: roofY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Storybook sky + ambient particles

/// Warm peach-to-rose gradient sky with soft layered clouds + a big
/// pastel sun. Used only on the home screen; other screens keep the
/// clean blue CartoonSkyBackground.
private struct HomeStorybookSky: View {
    @State private var drift: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.93, blue: 0.88),  // warm cream top
                    Color(red: 0.99, green: 0.85, blue: 0.82),  // peachy mid
                    Color(red: 0.98, green: 0.80, blue: 0.82)   // blush bottom
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                // Big soft sun upper-right
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.00, green: 0.93, blue: 0.60).opacity(0.95),
                                Color(red: 1.00, green: 0.82, blue: 0.50).opacity(0.45),
                                .clear
                            ],
                            center: .center,
                            startRadius: 18, endRadius: 160
                        )
                    )
                    .frame(width: 280, height: 280)
                    .position(x: geo.size.width * 0.90, y: geo.size.height * 0.14)

                // Layered pillowy clouds with a soft grey lower tint.
                cloud(size: 180, opacity: 0.95)
                    .position(x: geo.size.width * 0.15 + drift * 40,
                              y: geo.size.height * 0.12)
                cloud(size: 140, opacity: 0.92)
                    .position(x: geo.size.width * 0.62 - drift * 25,
                              y: geo.size.height * 0.08)
                cloud(size: 110, opacity: 0.85)
                    .position(x: geo.size.width * 0.38 + drift * 30,
                              y: geo.size.height * 0.22)
            }
            .allowsHitTesting(false)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    drift = 1
                }
            }
        }
    }

    /// Pillowy cloud — 3 overlapping circles with a soft lower grey
    /// layer behind the white body so clouds feel volumetric.
    private func cloud(size: CGFloat, opacity: Double) -> some View {
        ZStack {
            // Shadow-tinted underlayer (gives depth)
            Group {
                Circle().frame(width: size * 0.72, height: size * 0.72)
                    .offset(x: -size * 0.22, y: size * 0.14)
                Circle().frame(width: size * 0.88, height: size * 0.88)
                    .offset(y: size * 0.06)
                Circle().frame(width: size * 0.60, height: size * 0.60)
                    .offset(x: size * 0.28, y: size * 0.12)
            }
            .foregroundStyle(Color(red: 0.88, green: 0.78, blue: 0.84))
            // White body on top
            Group {
                Circle().frame(width: size * 0.70, height: size * 0.70)
                    .offset(x: -size * 0.22, y: size * 0.08)
                Circle().frame(width: size * 0.85, height: size * 0.85)
                Circle().frame(width: size * 0.58, height: size * 0.58)
                    .offset(x: size * 0.28, y: size * 0.06)
            }
            .foregroundStyle(.white)
        }
        .frame(width: size, height: size * 0.6)
        .opacity(opacity)
    }
}

/// Scattered hearts / clovers / sparkles floating around the home view
/// to add storybook life without needing custom illustrations. Each
/// particle has its own position + slow drift + gentle alpha bob.
private struct HomeAmbientParticles: View {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Fixed positions + glyphs — keeps layout stable across launches.
    private struct Particle: Identifiable {
        let id = UUID()
        let glyph: String
        let xRatio: CGFloat
        let yRatio: CGFloat
        let size: CGFloat
        let phaseOffset: Double
    }

    private static let particles: [Particle] = [
        .init(glyph: "💗", xRatio: 0.18, yRatio: 0.34, size: 22, phaseOffset: 0.0),
        .init(glyph: "🍀", xRatio: 0.32, yRatio: 0.22, size: 20, phaseOffset: 0.3),
        .init(glyph: "💜", xRatio: 0.48, yRatio: 0.12, size: 18, phaseOffset: 0.6),
        .init(glyph: "✨", xRatio: 0.42, yRatio: 0.38, size: 20, phaseOffset: 0.2),
        .init(glyph: "🍀", xRatio: 0.56, yRatio: 0.26, size: 18, phaseOffset: 0.5),
        .init(glyph: "💛", xRatio: 0.62, yRatio: 0.38, size: 22, phaseOffset: 0.9),
        .init(glyph: "✨", xRatio: 0.72, yRatio: 0.18, size: 24, phaseOffset: 0.1),
        .init(glyph: "💗", xRatio: 0.78, yRatio: 0.32, size: 20, phaseOffset: 0.7),
        .init(glyph: "🍀", xRatio: 0.08, yRatio: 0.48, size: 18, phaseOffset: 0.4),
        .init(glyph: "✨", xRatio: 0.88, yRatio: 0.46, size: 18, phaseOffset: 0.8),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Self.particles) { p in
                let bob = reduceMotion ? 0 : sin((phase + p.phaseOffset) * .pi * 2) * 4
                Text(p.glyph)
                    .font(.system(size: p.size))
                    .position(
                        x: geo.size.width * p.xRatio,
                        y: geo.size.height * p.yRatio + bob
                    )
                    .opacity(0.85)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
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
        onOpenBattle: {},
        onOpenNoomForest: {},
        onOpenMiniGames: {}
    )
    .modelContainer(for: ChildProfile.self, inMemory: true)
}
