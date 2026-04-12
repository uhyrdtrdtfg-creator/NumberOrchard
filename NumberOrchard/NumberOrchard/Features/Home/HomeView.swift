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
    @State private var treeBreathing = false
    @State private var sunRotating = false

    private var profile: ChildProfile {
        if let existing = profiles.first { return existing }
        let newProfile = ChildProfile(name: "小果农")
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            // Sun + clouds
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

            CartoonGround(height: 280)

            // Decorations on ground
            GeometryReader { geo in
                ForEach(Array(profile.decorations.filter { $0.isPlaced }.enumerated()), id: \.element.id) { index, deco in
                    if let item = DecorationCatalog.item(id: deco.itemId) {
                        WigglingDecoration(
                            emoji: item.emoji,
                            phaseOffset: Double(index) * 0.3
                        )
                        .position(
                            x: deco.positionX * geo.size.width,
                            y: geo.size.height - 180 + (deco.positionY * 80)
                        )
                    }
                }
            }
            .allowsHitTesting(false)

            // Main content
            VStack(spacing: 0) {
                // Top HUD
                HStack(spacing: 12) {
                    CartoonHUD(icon: "star.fill", value: "\(profile.stars)", tint: CartoonColor.gold, accessibilityLabel: "星星 \(profile.stars)")
                    CartoonHUD(icon: "leaf.fill", value: "\(profile.seeds)", tint: CartoonColor.leaf, accessibilityLabel: "种子 \(profile.seeds)")
                    Spacer()
                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(CartoonColor.ink.opacity(0.9))
                                .frame(width: 68, height: 68)
                                .offset(y: 4)
                            Circle()
                                .fill(CartoonColor.paper)
                                .frame(width: 68, height: 68)
                            Circle()
                                .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
                                .frame(width: 68, height: 68)
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 30, weight: .black))
                                .foregroundStyle(CartoonColor.text)
                        }
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                    }
                    .accessibilityLabel("家长中心")
                    .accessibilityHint("打开家长设置")
                }
                .padding(.horizontal, 36)
                .padding(.top, 20)

                Spacer()

                // Hero tree
                VStack(spacing: 20) {
                    Text(viewModel.treeStageEmoji)
                        .font(.system(size: 160))
                        .shadow(color: CartoonColor.ink.opacity(0.3), radius: 0, x: 0, y: 6)
                        .scaleEffect(reduceMotion ? 1.0 : (treeBreathing ? 1.05 : 1.0))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: treeBreathing)
                        .accessibilityHidden(true)

                    TreeProgressBar(progress: viewModel.treeProgress, level: profile.difficultyLevel.displayName)
                }
                .padding(.bottom, 30)

                Spacer().frame(height: 40)

                // Feature buttons
                HStack(spacing: 20) {
                    CartoonFeatureButton(emoji: "🗺️", label: "探险", tint: CartoonColor.gold, bobDelay: 0.0) {
                        onOpenMap()
                    }
                    CartoonFeatureButton(emoji: "🎨", label: "装饰", tint: CartoonColor.coral, bobDelay: 0.15) {
                        onOpenDecorate()
                    }
                    CartoonFeatureButton(emoji: "🍎", label: "图鉴", tint: CartoonColor.leaf, bobDelay: 0.30) {
                        onOpenCollection()
                    }
                    CartoonFeatureButton(emoji: "👨‍👦", label: "对战", tint: CartoonColor.berry, bobDelay: 0.45) {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            viewModel.checkDailyLogin(profile: profile)
            AudioManager.shared.playMusic("home_bgm.wav")
            treeBreathing = true
            sunRotating = true
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

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 170, height: 44)
                    .offset(y: 4)
                Capsule()
                    .fill(CartoonColor.paper)
                    .frame(width: 170, height: 44)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
                    .frame(width: 170, height: 44)
                Text(level)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: 264, height: 26)
                    .offset(y: 4)
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 264, height: 26)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [CartoonColor.gold, CartoonColor.coral],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(26, progress * 264), height: 26)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3)
                    .frame(width: 264, height: 26)
            }
        }
    }
}

// MARK: - Decoration

private struct WigglingDecoration: View {
    let emoji: String
    let phaseOffset: Double

    @State private var wiggling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(emoji)
            .font(.system(size: 56))
            .rotationEffect(.degrees(reduceMotion ? 0 : (wiggling ? 5 : -5)))
            .animation(
                reduceMotion ? nil :
                    .easeInOut(duration: 2.4 + phaseOffset.truncatingRemainder(dividingBy: 1.0))
                    .repeatForever(autoreverses: true)
                    .delay(phaseOffset),
                value: wiggling
            )
            .onAppear { wiggling = true }
            .accessibilityHidden(true)
    }
}
