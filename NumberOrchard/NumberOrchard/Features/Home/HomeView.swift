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
            LinearGradient(
                colors: [
                    Color(red: 0.70, green: 0.88, blue: 0.98),
                    Color(red: 0.85, green: 0.95, blue: 0.75),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ForEach(Array(profile.decorations.filter { $0.isPlaced }.enumerated()), id: \.element.id) { index, deco in
                    if let item = DecorationCatalog.item(id: deco.itemId) {
                        WigglingDecoration(
                            emoji: item.emoji,
                            phaseOffset: Double(index) * 0.3
                        )
                        .position(
                            x: deco.positionX * geo.size.width,
                            y: deco.positionY * geo.size.height
                        )
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 20) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.6), in: Capsule())

                    Spacer()

                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray)
                            .padding(12)
                            .background(.white.opacity(0.6), in: Circle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)

                Spacer()

                VStack(spacing: 16) {
                    Text(viewModel.treeStageEmoji)
                        .font(.system(size: 140))
                        .scaleEffect(treeBreathing ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: treeBreathing)
                    ProgressView(value: viewModel.treeProgress)
                        .frame(width: 260)
                        .tint(.green)
                        .scaleEffect(y: 2.0)
                    Text(profile.difficultyLevel.displayName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 40) {
                    featureButton(emoji: "🗺️", label: "探险", color: .green, bobDelay: 0.0) { onOpenMap() }
                    featureButton(emoji: "🎨", label: "装饰", color: .purple, bobDelay: 0.2) { onOpenDecorate() }
                    featureButton(emoji: "🍎", label: "图鉴", color: .red, bobDelay: 0.4) { onOpenCollection() }
                    featureButton(emoji: "👨‍👦", label: "对战", color: .blue, bobDelay: 0.6) {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
                .padding(.bottom, 60)
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

    private func featureButton(emoji: String, label: String, color: Color, bobDelay: Double, action: @escaping () -> Void) -> some View {
        BobbingButton(
            emoji: emoji,
            label: label,
            color: color,
            bobDelay: bobDelay,
            action: action
        )
    }
}

private struct BobbingButton: View {
    let emoji: String
    let label: String
    let color: Color
    let bobDelay: Double
    let action: () -> Void

    @State private var bobbing = false
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 72))
                    .rotationEffect(.degrees(bobbing ? 4 : -4))
                Text(label)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(width: 160, height: 160)
            .background(color.opacity(0.25), in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(color.opacity(0.5), lineWidth: 2)
            )
            .foregroundStyle(.primary)
            .shadow(color: color.opacity(0.4), radius: 10, y: 5)
        }
        .scaleEffect(pressed ? 0.92 : (bobbing ? 1.03 : 1.0))
        .offset(y: bobbing ? -6 : 0)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(bobDelay), value: bobbing)
        .onAppear {
            bobbing = true
        }
    }
}

private struct WigglingDecoration: View {
    let emoji: String
    let phaseOffset: Double

    @State private var wiggling = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 70))
            .rotationEffect(.degrees(wiggling ? 6 : -6))
            .scaleEffect(wiggling ? 1.05 : 0.97)
            .animation(
                .easeInOut(duration: 2.2 + phaseOffset.truncatingRemainder(dividingBy: 1.0))
                    .repeatForever(autoreverses: true)
                    .delay(phaseOffset),
                value: wiggling
            )
            .onAppear { wiggling = true }
    }
}
