import SwiftUI
import SpriteKit

struct NumberTrainView: View {
    let question: MathQuestion
    let countingMode: Bool
    let onComplete: (Bool, TimeInterval) -> Void

    @State private var scene: NumberTrainScene?
    @State private var coordinator: NumberTrainCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = NumberTrainScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: question, countingMode: countingMode)
                        let coord = NumberTrainCoordinator(onComplete: onComplete)
                        newScene.gameDelegate = coord
                        coordinator = coord
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class NumberTrainCoordinator: NSObject, NumberTrainSceneDelegate {
    let onComplete: (Bool, TimeInterval) -> Void
    init(onComplete: @escaping (Bool, TimeInterval) -> Void) { self.onComplete = onComplete }
    func numberTrainSceneDidComplete(correct: Bool, responseTime: TimeInterval) {
        onComplete(correct, responseTime)
    }
}
