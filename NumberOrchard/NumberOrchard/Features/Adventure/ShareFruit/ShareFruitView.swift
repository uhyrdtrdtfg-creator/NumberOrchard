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
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = ShareFruitScene(size: CGSize(width: 1194, height: 834))
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question)
            let newCoordinator = ShareFruitCoordinator(onComplete: onComplete)
            newScene.gameDelegate = newCoordinator
            coordinator = newCoordinator
            scene = newScene
        }
    }
}

private class ShareFruitCoordinator: NSObject, ShareFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func shareFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        Task { @MainActor in
            onComplete(correct, responseTime)
        }
    }
}
