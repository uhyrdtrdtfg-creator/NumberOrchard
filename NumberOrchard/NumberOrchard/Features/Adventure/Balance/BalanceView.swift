import SwiftUI
import SpriteKit

struct BalanceView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: BalanceScene?
    @State private var coordinator: BalanceCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = BalanceScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: question)
                        let coord = BalanceCoordinator(onComplete: onComplete)
                        newScene.gameDelegate = coord
                        coordinator = coord
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class BalanceCoordinator: NSObject, BalanceSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void
    init(onComplete: @escaping (Bool, TimeInterval) -> Void) { self.onComplete = onComplete }
    func balanceSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
