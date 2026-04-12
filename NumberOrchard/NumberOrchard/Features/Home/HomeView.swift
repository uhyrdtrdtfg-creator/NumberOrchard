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
    @Query private var profiles: [ChildProfile]
    @State private var viewModel = HomeViewModel()
    @State private var treeBreathing = false
    @State private var buttonsBobbing = false

    private var profile: ChildProfile {
        if let existing = profiles.first { return existing }
        let newProfile = ChildProfile(name: "小果农")
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        ZStack {
            // 1. Sky background
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.95, blue: 0.78),  // warm cream top
                    Color(red: 0.98, green: 0.88, blue: 0.70),  // peach middle
                    Color(red: 0.92, green: 0.80, blue: 0.58),  // golden hour bottom
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 2. Sun/cloud in sky
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 140, height: 140)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.12)
                    .blur(radius: 8)
                Text("☁️")
                    .font(.system(size: 80))
                    .opacity(0.7)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.2)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            // 3. Ground layer
            VStack {
                Spacer()
                ZStack(alignment: .top) {
                    // Hill silhouette
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 80))
                        path.addQuadCurve(
                            to: CGPoint(x: UIScreen.main.bounds.width, y: 80),
                            control: CGPoint(x: UIScreen.main.bounds.width / 2, y: -20)
                        )
                        path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 300))
                        path.addLine(to: CGPoint(x: 0, y: 300))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.56, green: 0.75, blue: 0.42),  // soft grass
                                Color(red: 0.44, green: 0.62, blue: 0.32),  // deeper grass
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 300)

                    // Decorations sitting on ground
                    GeometryReader { geo in
                        ForEach(Array(profile.decorations.filter { $0.isPlaced }.enumerated()), id: \.element.id) { index, deco in
                            if let item = DecorationCatalog.item(id: deco.itemId) {
                                WigglingDecoration(
                                    emoji: item.emoji,
                                    phaseOffset: Double(index) * 0.3
                                )
                                .position(
                                    x: deco.positionX * geo.size.width,
                                    y: 60 + (deco.positionY * 100)  // band on the hill
                                )
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()

            // 4. Content layer
            VStack(spacing: 0) {
                // Top HUD
                HStack(spacing: 12) {
                    HUDPill(icon: "star.fill", value: "\(profile.stars)", color: .orange)
                    HUDPill(icon: "leaf.fill", value: "\(profile.seeds)", color: .green)
                    Spacer()
                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color(red: 0.6, green: 0.5, blue: 0.35))
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.85), in: Circle())
                            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)

                Spacer()

                // Hero: tree + progress
                VStack(spacing: 18) {
                    Text(viewModel.treeStageEmoji)
                        .font(.system(size: 150))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
                        .scaleEffect(treeBreathing ? 1.04 : 1.0)
                        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: treeBreathing)

                    // Custom progress bar
                    TreeProgressBar(progress: viewModel.treeProgress, level: profile.difficultyLevel.displayName)
                }
                .padding(.bottom, 40)

                Spacer().frame(height: 40)

                // Feature buttons — 2x2 would be cleaner, but horizontal strip with consistent design
                HStack(spacing: 28) {
                    featureButton(emoji: "🗺️", label: "探险", tint: .orange, bobDelay: 0.0) { onOpenMap() }
                    featureButton(emoji: "🎨", label: "装饰", tint: .pink, bobDelay: 0.15) { onOpenDecorate() }
                    featureButton(emoji: "🍎", label: "图鉴", tint: .red, bobDelay: 0.30) { onOpenCollection() }
                    featureButton(emoji: "👨‍👦", label: "对战", tint: .purple, bobDelay: 0.45) {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            viewModel.checkDailyLogin(profile: profile)
            AudioManager.shared.playMusic("home_bgm.wav")
            treeBreathing = true
            buttonsBobbing = true
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

    private func featureButton(emoji: String, label: String, tint: Color, bobDelay: Double, action: @escaping () -> Void) -> some View {
        BobbingButton(
            emoji: emoji,
            label: label,
            tint: tint,
            bobDelay: bobDelay,
            action: action
        )
    }
}

// MARK: - UI Components

private struct HUDPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85), in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }
}

private struct TreeProgressBar: View {
    let progress: Double
    let level: String

    var body: some View {
        VStack(spacing: 8) {
            Text(level)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.42, green: 0.30, blue: 0.18))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.7), in: Capsule())

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 18)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.3), Color(red: 1.0, green: 0.55, blue: 0.2)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, progress * geo.size.width), height: 18)
                        .shadow(color: .orange.opacity(0.5), radius: 4, y: 2)
                }
            }
            .frame(width: 240, height: 18)
        }
    }
}

private struct BobbingButton: View {
    let emoji: String
    let label: String
    let tint: Color
    let bobDelay: Double
    let action: () -> Void

    @State private var bobbing = false
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 64))
                Text(label)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
            }
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(tint.opacity(0.3), lineWidth: 3)
            )
        }
        .scaleEffect(pressed ? 0.90 : (bobbing ? 1.02 : 1.0))
        .offset(y: bobbing ? -5 : 0)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(bobDelay), value: bobbing)
        .onAppear { bobbing = true }
    }
}

private struct WigglingDecoration: View {
    let emoji: String
    let phaseOffset: Double

    @State private var wiggling = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 56))
            .rotationEffect(.degrees(wiggling ? 4 : -4))
            .animation(
                .easeInOut(duration: 2.2 + phaseOffset.truncatingRemainder(dividingBy: 1.0))
                    .repeatForever(autoreverses: true)
                    .delay(phaseOffset),
                value: wiggling
            )
            .onAppear { wiggling = true }
    }
}
