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
    case noomForest
    case noomChallenge
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
                        onOpenBattle: { currentScreen = .battle },
                        onOpenNoomForest: { currentScreen = .noomForest }
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
                case .noomForest:
                    NoomForestView(
                        onDismiss: { currentScreen = .home },
                        onStartChallenge: { currentScreen = .noomChallenge }
                    )
                case .noomChallenge:
                    NoomChallengeSessionView(onFinish: { currentScreen = .noomForest })
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
            CartoonColor.overlayDark.ignoresSafeArea()
            VStack(spacing: CartoonDimensions.spacingLarge) {
                Text("🌳")
                    .font(.system(size: 120))
                    .accessibilityHidden(true)
                Text("小果农休息一下吧！")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("站起来看看窗外～")
                    .font(.system(size: CartoonDimensions.fontBodyLarge, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                if !eyeCareManager.hasUsedExtension {
                    CartoonButton(
                        tint: CartoonColor.gold,
                        accessibilityLabel: "再玩 5 分钟",
                        action: {
                            eyeCareManager.useExtension()
                            showEyeCareAlert = false
                        }
                    ) {
                        Text("再玩 5 分钟")
                            .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                            .frame(width: 240, height: 72)
                    }
                }

                CartoonButton(
                    tint: CartoonColor.leaf,
                    accessibilityLabel: "结束今天的学习",
                    action: {
                        stopAdventure()
                        showEyeCareAlert = false
                    }
                ) {
                    Text("结束今天的学习")
                        .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 280, height: 72)
                }
            }
            .padding(CartoonDimensions.spacingLarge)
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
