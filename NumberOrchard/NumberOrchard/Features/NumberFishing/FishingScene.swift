import SpriteKit

/// Rendering + interaction layer for 数字钓鱼. Owns a simple SKScene with:
///   - a wavy pond background
///   - fish that drift horizontally, each carrying a number label
///   - tap-to-catch gesture that spawns a ripple and flies the fish
///     into the on-screen bucket
/// Game state is owned by the host view model; the scene only mirrors it
/// via `configure(with:)` calls when the round changes.
@MainActor
protocol FishingSceneDelegate: AnyObject {
    func fishingScene(_ scene: FishingScene, didCatchFishAt pondIndex: Int)
}

final class FishingScene: SKScene {
    weak var gameDelegate: FishingSceneDelegate?

    private var fishNodes: [SKNode] = []    // index-aligned with pondFish
    private var pondRect: CGRect = .zero
    private var bucketCenter: CGPoint = .zero

    /// Rebuild fish nodes from the current round's pond contents. Call this
    /// whenever the round advances.
    func configure(pondFish: [Int?], bucketCenterInScene: CGPoint) {
        removeAllChildren()
        fishNodes.removeAll()
        backgroundColor = .clear

        layoutPond()
        drawPondBackground()
        bucketCenter = bucketCenterInScene

        for (idx, value) in pondFish.enumerated() {
            guard let v = value else {
                fishNodes.append(SKNode())
                continue
            }
            let fish = makeFishNode(value: v, index: idx)
            fish.position = spawnPoint(for: idx, total: pondFish.count)
            addChild(fish)
            fishNodes.append(fish)
            startSwim(fish)
        }
    }

    /// Remove the fish node at `pondIndex` with a celebratory fly-to-bucket
    /// animation + ripple. Called by the host view when state changes.
    func animateCatch(at pondIndex: Int) {
        guard pondIndex < fishNodes.count else { return }
        let node = fishNodes[pondIndex]
        guard node.parent != nil else { return }

        spawnRipple(at: node.position)

        let arc = SKAction.group([
            SKAction.move(to: bucketCenter, duration: 0.45),
            SKAction.scale(to: 0.3, duration: 0.45),
            SKAction.fadeOut(withDuration: 0.45)
        ])
        node.run(SKAction.sequence([arc, SKAction.removeFromParent()]))
    }

    // MARK: - Setup

    private func layoutPond() {
        pondRect = CGRect(
            x: size.width * 0.05,
            y: size.height * 0.25,
            width: size.width * 0.9,
            height: size.height * 0.5
        )
    }

    private func drawPondBackground() {
        let bg = SKShapeNode(rectOf: CGSize(width: pondRect.width, height: pondRect.height),
                             cornerRadius: 32)
        bg.position = CGPoint(x: pondRect.midX, y: pondRect.midY)
        bg.fillColor = UIColor(red: 0.48, green: 0.80, blue: 0.96, alpha: 1.0)
        bg.strokeColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.6)
        bg.lineWidth = 3
        bg.zPosition = -10
        addChild(bg)

        // Gentle wavy lines across the surface.
        for i in 0..<3 {
            let wave = SKShapeNode()
            let path = CGMutablePath()
            let y = pondRect.minY + CGFloat(i) * (pondRect.height / 3) + 20
            path.move(to: CGPoint(x: pondRect.minX + 10, y: y))
            for step in stride(from: CGFloat(0), through: pondRect.width - 20, by: 20) {
                let xx = pondRect.minX + 10 + step
                let yy = y + sin(step / 40) * 4
                path.addLine(to: CGPoint(x: xx, y: yy))
            }
            wave.path = path
            wave.strokeColor = .white.withAlphaComponent(0.35)
            wave.lineWidth = 2
            wave.zPosition = -8
            addChild(wave)
        }
    }

    private func spawnPoint(for index: Int, total: Int) -> CGPoint {
        let cols = 4
        let row = index / cols
        let col = index % cols
        let cellW = pondRect.width / CGFloat(cols)
        let cellH = pondRect.height / 3
        return CGPoint(
            x: pondRect.minX + cellW * (CGFloat(col) + 0.5),
            y: pondRect.maxY - cellH * (CGFloat(row) + 0.5)
        )
    }

    private func makeFishNode(value: Int, index: Int) -> SKNode {
        let container = SKNode()
        container.name = "fish_\(index)"

        let body = SKShapeNode(ellipseOf: CGSize(width: 70, height: 44))
        body.fillColor = UIColor(red: 1.00, green: 0.72, blue: 0.42, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85)
        body.lineWidth = 3
        container.addChild(body)

        // Triangular tail.
        let tail = SKShapeNode()
        let tp = CGMutablePath()
        tp.move(to: CGPoint(x: -30, y: 0))
        tp.addLine(to: CGPoint(x: -50, y: 16))
        tp.addLine(to: CGPoint(x: -50, y: -16))
        tp.closeSubpath()
        tail.path = tp
        tail.fillColor = UIColor(red: 0.94, green: 0.58, blue: 0.30, alpha: 1.0)
        tail.strokeColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85)
        tail.lineWidth = 3
        container.addChild(tail)

        // Eye.
        let eye = SKShapeNode(circleOfRadius: 5)
        eye.fillColor = .white
        eye.strokeColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85)
        eye.lineWidth = 1.5
        eye.position = CGPoint(x: 18, y: 6)
        container.addChild(eye)
        let pupil = SKShapeNode(circleOfRadius: 2.5)
        pupil.fillColor = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        pupil.position = CGPoint(x: 19, y: 6)
        container.addChild(pupil)

        // Number label.
        let label = SKLabelNode(fontNamed: "PingFangSC-Heavy")
        label.text = "\(value)"
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: -4, y: -2)
        label.zPosition = 2
        container.addChild(label)

        return container
    }

    private func startSwim(_ fish: SKNode) {
        // Gentle bob + drift. Low amplitude so fish don't collide.
        let dx = CGFloat.random(in: -18...18)
        let dy = CGFloat.random(in: -8...8)
        let duration = Double.random(in: 2.0...3.5)
        let drift = SKAction.sequence([
            SKAction.moveBy(x: dx, y: dy, duration: duration),
            SKAction.moveBy(x: -dx, y: -dy, duration: duration),
        ])
        fish.run(SKAction.repeatForever(drift))
    }

    private func spawnRipple(at p: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 6)
        ring.position = p
        ring.fillColor = .clear
        ring.strokeColor = .white.withAlphaComponent(0.9)
        ring.lineWidth = 3
        ring.zPosition = -5
        addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 6, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let location = t.location(in: self)

        var best: Int?
        var bestDist: CGFloat = 60 * 60     // max reach squared
        for (idx, node) in fishNodes.enumerated() where node.parent != nil {
            let dx = node.position.x - location.x
            let dy = node.position.y - location.y
            let d = dx * dx + dy * dy
            if d < bestDist {
                bestDist = d
                best = idx
            }
        }
        if let picked = best {
            gameDelegate?.fishingScene(self, didCatchFishAt: picked)
        }
    }

    /// Testing hook for hit detection, mirrors touchesBegan.
    func hitTestFish(at scenePoint: CGPoint, maxReach: CGFloat = 60) -> Int? {
        let maxSq = maxReach * maxReach
        var best: Int?
        var bestDist = maxSq
        for (idx, node) in fishNodes.enumerated() where node.parent != nil {
            let dx = node.position.x - scenePoint.x
            let dy = node.position.y - scenePoint.y
            let d = dx * dx + dy * dy
            if d < bestDist {
                bestDist = d
                best = idx
            }
        }
        return best
    }
}
