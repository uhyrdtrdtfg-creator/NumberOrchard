import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void

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
                colors: [Color(red: 0.85, green: 0.95, blue: 0.85), Color(red: 1.0, green: 0.97, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    HStack(spacing: 16) {
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
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 12) {
                    Text(viewModel.treeStageEmoji)
                        .font(.system(size: 100))

                    ProgressView(value: viewModel.treeProgress)
                        .frame(width: 200)
                        .tint(.green)

                    Text(profile.difficultyLevel.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onStartAdventure) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("今日冒险")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                }

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            AudioManager.shared.playMusic("home_bgm.wav")
            viewModel.checkDailyLogin(profile: profile)
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
                    onOpenParentCenter()
                },
                onCancel: {
                    viewModel.showParentalGate = false
                }
            )
        }
    }
}
