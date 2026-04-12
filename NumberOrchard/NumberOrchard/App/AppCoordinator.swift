import SwiftUI
import SwiftData

enum AppScreen: Equatable {
    case home
    case adventure(station: Station?)
    case parentCenter
    case map
    case collection
    case decorate
    case battle
}

struct AppCoordinator: View {
    @State private var currentScreen: AppScreen = .home
    @State private var eyeCareManager = EyeCareManager()
    @State private var showEyeCareAlert = false
    @State private var eyeCareTimer: Timer?

    @Query private var profiles: [ChildProfile]

    var body: some View {
        ZStack {
            Group {
                switch currentScreen {
                case .home:
                    HomeView(
                        onStartAdventure: { startAdventure(station: nil) },
                        onOpenParentCenter: { currentScreen = .parentCenter },
                        onOpenMap: { currentScreen = .map },
                        onOpenCollection: { currentScreen = .collection },
                        onOpenDecorate: { currentScreen = .decorate },
                        onOpenBattle: { currentScreen = .battle }
                    )
                case .adventure(let station):
                    AdventureSessionView(
                        station: station,
                        onFinish: { stopAdventure() }
                    )
                case .parentCenter:
                    ParentCenterView(onDismiss: { currentScreen = .home })
                case .map:
                    ExplorationMapView(
                        onDismiss: { currentScreen = .home },
                        onStartStation: { station in startAdventure(station: station) }
                    )
                case .collection:
                    FruitCollectionView(onDismiss: { currentScreen = .home })
                case .decorate:
                    DecorateOrchardView(onDismiss: { currentScreen = .home })
                case .battle:
                    BattleView(onFinish: { currentScreen = .home })
                }
            }

            if showEyeCareAlert {
                eyeCareOverlay
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden(true)
    }

    private var eyeCareOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 28) {
                Text("🌳").font(.system(size: 120))
                Text("小果农休息一下吧！").font(.system(size: 38, weight: .bold)).foregroundStyle(.white)
                Text("站起来看看窗外～").font(.title2).foregroundStyle(.white.opacity(0.85))
                if !eyeCareManager.hasUsedExtension {
                    Button {
                        eyeCareManager.useExtension()
                        showEyeCareAlert = false
                    } label: {
                        Text("再玩 5 分钟")
                            .font(.title3).fontWeight(.semibold)
                            .padding(.horizontal, 36).padding(.vertical, 18)
                            .background(.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Button {
                    stopAdventure()
                    showEyeCareAlert = false
                } label: {
                    Text("结束今天的学习")
                        .font(.title3).fontWeight(.semibold)
                        .padding(.horizontal, 36).padding(.vertical, 18)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func startAdventure(station: Station?) {
        let timeLimit = profiles.first?.dailyTimeLimitMinutes ?? 20
        eyeCareManager = EyeCareManager(timeLimitMinutes: timeLimit)
        eyeCareManager.startSession()
        currentScreen = .adventure(station: station)
        startEyeCareMonitoring()
    }

    private func stopAdventure() {
        eyeCareTimer?.invalidate()
        eyeCareTimer = nil
        currentScreen = .home
    }

    private func startEyeCareMonitoring() {
        eyeCareTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                let level = eyeCareManager.currentAlertLevel
                if level == .gentle || level == .locked {
                    showEyeCareAlert = true
                }
                if level == .locked {
                    eyeCareTimer?.invalidate()
                }
            }
        }
    }
}
