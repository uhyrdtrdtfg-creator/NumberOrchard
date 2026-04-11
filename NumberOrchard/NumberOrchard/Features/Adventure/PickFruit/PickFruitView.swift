import SwiftUI
import SpriteKit

struct PickFruitView: View {
    let question: MathQuestion
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: PickFruitScene?
    @State private var coordinator: PickFruitCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            let newScene = PickFruitScene(size: CGSize(width: 1194, height: 834))
            newScene.scaleMode = .aspectFill
            newScene.configure(with: question)
            let newCoordinator = PickFruitCoordinator(onComplete: onComplete)
            newScene.gameDelegate = newCoordinator
            coordinator = newCoordinator
            scene = newScene
        }
    }
}

private class PickFruitCoordinator: NSObject, PickFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        Task { @MainActor in
            onComplete(correct, responseTime)
        }
    }
}
