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
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = PickFruitScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: question)
                        let newCoordinator = PickFruitCoordinator(onComplete: onComplete)
                        newScene.gameDelegate = newCoordinator
                        coordinator = newCoordinator
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class PickFruitCoordinator: NSObject, PickFruitSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void

    init(onComplete: @escaping (Bool, TimeInterval) -> Void) {
        self.onComplete = onComplete
    }

    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
