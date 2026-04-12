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
                            .font(.system(size: 44))
                            .position(
                                x: deco.positionX * geo.size.width,
                                y: deco.positionY * geo.size.height
                            )
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    HStack(spacing: 12) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title3)

                    Spacer()

                    Button {
                        viewModel.showParentalGate = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 10) {
                    Text(viewModel.treeStageEmoji).font(.system(size: 90))
                    ProgressView(value: viewModel.treeProgress).frame(width: 180).tint(.green)
                    Text(profile.difficultyLevel.displayName).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 20) {
                    featureButton(emoji: "🗺️", label: "探险", color: .green) { onOpenMap() }
                    featureButton(emoji: "🎨", label: "装饰", color: .purple) { onOpenDecorate() }
                    featureButton(emoji: "🍎", label: "图鉴", color: .red) { onOpenCollection() }
                    featureButton(emoji: "👨‍👦", label: "对战", color: .blue) {
                        viewModel.showParentalGate = true
                        viewModel.parentGateIntent = .battle
                    }
                }
                .padding(.bottom, 40)
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
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 40))
                Text(label).font(.footnote).fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.primary)
            .shadow(color: color.opacity(0.3), radius: 6, y: 3)
        }
    }
}
