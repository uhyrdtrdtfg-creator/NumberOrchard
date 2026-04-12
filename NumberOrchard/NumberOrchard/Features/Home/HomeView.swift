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
                ForEach(profile.decorations.filter { $0.isPlaced }) { deco in
                    if let item = DecorationCatalog.item(id: deco.itemId) {
                        Text(item.emoji)
                            .font(.system(size: 70))
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
                    Text(viewModel.treeStageEmoji).font(.system(size: 140))
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
                    featureButton(emoji: "🗺️", label: "探险", color: .green) { onOpenMap() }
                    featureButton(emoji: "🎨", label: "装饰", color: .purple) { onOpenDecorate() }
                    featureButton(emoji: "🍎", label: "图鉴", color: .red) { onOpenCollection() }
                    featureButton(emoji: "👨‍👦", label: "对战", color: .blue) {
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

    private func featureButton(emoji: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji).font(.system(size: 72))
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
    }
}
