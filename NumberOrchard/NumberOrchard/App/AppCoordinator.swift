import SwiftUI

enum AppScreen {
    case home
    case adventure
    case parentCenter
}

struct AppCoordinator: View {
    @State private var currentScreen: AppScreen = .home

    var body: some View {
        Group {
            switch currentScreen {
            case .home:
                HomeView(
                    onStartAdventure: { currentScreen = .adventure },
                    onOpenParentCenter: { currentScreen = .parentCenter }
                )
            case .adventure:
                AdventureSessionView(
                    onFinish: { currentScreen = .home }
                )
            case .parentCenter:
                ParentCenterView(
                    onDismiss: { currentScreen = .home }
                )
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden(true)
    }
}
