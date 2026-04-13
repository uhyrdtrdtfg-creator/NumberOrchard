import SwiftUI
import SpriteKit

struct NoomChallengeView: View {
    let challenge: NoomChallengeType
    let onComplete: ([Int]) -> Void

    @State private var scene: NoomChallengeScene?
    @State private var coordinator: NoomChallengeCoordinator?

    var body: some View {
        GeometryReader { geo in
            if let scene {
                SpriteView(scene: scene).ignoresSafeArea()
            } else {
                Color.clear
                    .onAppear {
                        let newScene = NoomChallengeScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.configure(with: challenge)
                        let coord = NoomChallengeCoordinator(onComplete: onComplete)
                        newScene.sceneDelegate = coord
                        coordinator = coord
                        scene = newScene
                    }
            }
        }
    }
}

@MainActor
private class NoomChallengeCoordinator: NSObject, NoomChallengeSceneDelegate {
    let onComplete: ([Int]) -> Void
    init(onComplete: @escaping ([Int]) -> Void) { self.onComplete = onComplete }
    func noomChallengeDidComplete(unlockedNumbers: [Int]) {
        onComplete(unlockedNumbers)
    }
}
