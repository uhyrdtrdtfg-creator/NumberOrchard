import SwiftUI

struct HomeView: View {
    let onStartAdventure: () -> Void
    let onOpenParentCenter: () -> Void

    var body: some View {
        Text("数字果园")
            .font(.largeTitle)
    }
}
