import SwiftUI
import SpriteKit

struct ShareFruitView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: ShareFruitScene?
    @State private var coordinator: ShareFruitCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = ShareFruitScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: question)
                        let newCoordinator = ShareFruitCoordinator(onComplete: onComplete)
                        newScene.gameDelegate = newCoordinator
                        coordinator = newCoordinator
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class ShareFruitCoordinator: NSObject, ShareFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func shareFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
