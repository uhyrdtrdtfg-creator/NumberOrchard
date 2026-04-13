import SpriteKit

@MainActor
protocol NoomChallengeSceneDelegate: AnyObject {
    /// Called when a question completes. unlockedNumbers includes any Nooms revealed.
    func noomChallengeDidComplete(unlockedNumbers: [Int])
}

class NoomChallengeScene: SKScene {
    weak var sceneDelegate: NoomChallengeSceneDelegate?

    private var challenge: NoomChallengeType!
    private var questionLabel: SKNode!
    private var noomNodes: [SKSpriteNode] = []
    private var noomNumbers: [SKSpriteNode: Int] = [:]
    private var noomHomePositions: [SKSpriteNode: CGPoint] = [:]
    private var draggingNoom: SKSpriteNode?
    private var dragStartPosition: CGPoint = .zero
    private var splitPreviewLabel: SKLabelNode?
    private var isCompleted = false

    private let noomImageSize = CGSize(width: 140, height: 140)
    private let mergeLogic = NoomMergeLogic()
    private let splitLogic = NoomSplitLogic()

    func configure(with challenge: NoomChallengeType) {
        self.challenge = challenge
    }

    override func didMove(to view: SKView) {
        backgroundColor = CartoonSK.skyTop
        view.preferredFramesPerSecond = 60
        setupBackground()
        setupQuestion()
        switch challenge {
        case .merge(let a, let b):
            setupMerge(a: a, b: b)
        case .split(let total):
            setupSplit(total: total)
        case .none:
            break
        }
    }

    private func setupBackground() {
        let bg = SKSpriteNode(texture: CartoonSKTextureCache.skyGradient(size: size))
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        addChild(bg)
    }

    private var safeAreaTop: CGFloat { view?.safeAreaInsets.top ?? 0 }

    private func setupQuestion() {
        let text: String
        switch challenge {
        case .merge(let a, let b):
            let nameA = NoomCatalog.noom(for: a)?.name ?? "\(a)"
            let nameB = NoomCatalog.noom(for: b)?.name ?? "\(b)"
            text = "把 \(nameA) 和 \(nameB) 合在一起！"
        case .split(let total):
            let name = NoomCatalog.noom(for: total)?.name ?? "\(total)"
            text = "把 \(name) 向下拖拽分开！"
        case .none:
            text = ""
        }
        questionLabel = SKNode.cartoonPillLabel(text: text, fontSize: 26)
        questionLabel.position = CGPoint(x: size.width / 2, y: size.height - safeAreaTop - 50)
        addChild(questionLabel)
    }

    private func setupMerge(a: Int, b: Int) {
        guard let noomA = NoomCatalog.noom(for: a), let noomB = NoomCatalog.noom(for: b) else { return }
        let leftPos = CGPoint(x: size.width * 0.32, y: size.height * 0.45)
        let rightPos = CGPoint(x: size.width * 0.68, y: size.height * 0.45)
        let nodeA = makeNoomNode(noom: noomA, expression: .neutral)
        let nodeB = makeNoomNode(noom: noomB, expression: .neutral)
        nodeA.position = leftPos
        nodeB.position = rightPos
        addChild(nodeA); addChild(nodeB)
        noomNodes = [nodeA, nodeB]
        noomNumbers = [nodeA: a, nodeB: b]
        noomHomePositions = [nodeA: leftPos, nodeB: rightPos]

        addBreathingAction(to: nodeA)
        addBreathingAction(to: nodeB)
    }

    private func setupSplit(total: Int) {
        guard let noom = NoomCatalog.noom(for: total) else { return }
        let pos = CGPoint(x: size.width / 2, y: size.height * 0.50)
        let node = makeNoomNode(noom: noom, expression: .neutral)
        node.position = pos
        addChild(node)
        noomNodes = [node]
        noomNumbers = [node: total]
        noomHomePositions = [node: pos]

        // Visual cue under the noom
        let cuePath = CGMutablePath()
        cuePath.move(to: CGPoint(x: pos.x - 60, y: pos.y - 100))
        cuePath.addLine(to: CGPoint(x: pos.x + 60, y: pos.y - 100))
        let cueShape = SKShapeNode(path: cuePath)
        cueShape.strokeColor = CartoonSK.ink.withAlphaComponent(0.4)
        cueShape.lineWidth = 4
        let dashPattern: [CGFloat] = [10, 8]
        cueShape.path = cuePath.copy(dashingWithPhase: 0, lengths: dashPattern)
        addChild(cueShape)

        addBreathingAction(to: node)
    }

    private func makeNoomNode(noom: Noom, expression: NoomExpression) -> SKSpriteNode {
        let img = NoomRenderer.image(for: noom, expression: expression, size: noomImageSize)
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.size = noomImageSize
        node.name = "noom_\(noom.number)"
        return node
    }

    private func addBreathingAction(to node: SKSpriteNode) {
        let action = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 1.2),
            SKAction.scale(to: 1.0, duration: 1.2)
        ])
        node.run(SKAction.repeatForever(action))
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isCompleted, let location = touches.first?.location(in: self) else { return }

        let padding = CartoonSKTouch.largeHitPadding
        var best: SKSpriteNode?
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for node in noomNodes where node.parent != nil {
            let expanded = node.frame.insetBy(dx: -padding, dy: -padding)
            guard expanded.contains(location) else { continue }
            let dx = node.position.x - location.x
            let dy = node.position.y - location.y
            let d = dx * dx + dy * dy
            if d < bestDist { bestDist = d; best = node }
        }
        if let node = best {
            draggingNoom = node
            dragStartPosition = node.position
            node.removeAllActions()
            node.zPosition = 100
            node.run(SKAction.scale(to: 1.15, duration: 0.1))

            if case .split(let total) = challenge {
                if let noom = NoomCatalog.noom(for: total) {
                    let surprisedImg = NoomRenderer.image(for: noom, expression: .surprised, size: noomImageSize)
                    node.texture = SKTexture(image: surprisedImg)
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNoom else { return }
        node.position = touch.location(in: self)

        if case .split(let total) = challenge {
            let downDistance = max(0, dragStartPosition.y - node.position.y)
            if let (a, b) = splitLogic.splitFor(total: total, dragDistance: downDistance) {
                showSplitPreview(text: "\(a) 和 \(b)")
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = draggingNoom else { return }
        draggingNoom = nil

        switch challenge {
        case .merge(let a, let b):
            handleMergeRelease(node: node, a: a, b: b)
        case .split(let total):
            handleSplitRelease(node: node, total: total)
        case .none:
            break
        }
    }

    private func handleMergeRelease(node: SKSpriteNode, a: Int, b: Int) {
        guard let other = noomNodes.first(where: { $0 !== node }) else { return }
        let distance = hypot(node.position.x - other.position.x, node.position.y - other.position.y)
        if distance < 120 {
            performMerge(nodeA: node, nodeB: other, a: a, b: b)
        } else {
            snapBack(node: node)
        }
    }

    private func handleSplitRelease(node: SKSpriteNode, total: Int) {
        let downDistance = max(0, dragStartPosition.y - node.position.y)
        if downDistance < 25 {
            if let noom = NoomCatalog.noom(for: total) {
                let img = NoomRenderer.image(for: noom, expression: .neutral, size: noomImageSize)
                node.texture = SKTexture(image: img)
            }
            snapBack(node: node)
            removeSplitPreview()
            return
        }
        guard let (a, b) = splitLogic.splitFor(total: total, dragDistance: downDistance) else {
            snapBack(node: node)
            return
        }
        performSplit(node: node, total: total, a: a, b: b)
    }

    private func snapBack(node: SKSpriteNode) {
        node.zPosition = 0
        if let home = noomHomePositions[node] {
            node.run(SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.18),
                SKAction.move(to: home, duration: 0.22)
            ]))
        }
        addBreathingAction(to: node)
    }

    private func showSplitPreview(text: String) {
        if splitPreviewLabel == nil {
            let label = SKLabelNode(fontNamed: CartoonSK.chineseFont())
            label.fontSize = 36
            label.fontColor = CartoonSK.text
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
            label.zPosition = 200
            addChild(label)
            splitPreviewLabel = label
        }
        splitPreviewLabel?.text = text
    }

    private func removeSplitPreview() {
        splitPreviewLabel?.removeFromParent()
        splitPreviewLabel = nil
    }

    private func performMerge(nodeA: SKSpriteNode, nodeB: SKSpriteNode, a: Int, b: Int) {
        guard let resultNumber = mergeLogic.merge(a: a, b: b),
              let resultNoom = NoomCatalog.noom(for: resultNumber) else {
            snapBack(node: nodeA)
            return
        }
        isCompleted = true
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))
        Task { @MainActor in
            AudioManager.shared.speakEquation(MathQuestion(operand1: a, operand2: b, operation: .add, gameMode: .pickFruit))
        }

        let mid = CGPoint(x: (nodeA.position.x + nodeB.position.x) / 2,
                          y: (nodeA.position.y + nodeB.position.y) / 2)
        nodeA.removeAllActions()
        nodeB.removeAllActions()
        nodeA.run(SKAction.sequence([
            SKAction.move(to: mid, duration: 0.2),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))
        nodeB.run(SKAction.sequence([
            SKAction.move(to: mid, duration: 0.2),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                guard let self else { return }
                let newNode = self.makeNoomNode(noom: resultNoom, expression: .happy)
                newNode.position = mid
                newNode.setScale(0.1)
                self.addChild(newNode)
                newNode.run(SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.25),
                    SKAction.scale(to: 1.0, duration: 0.15)
                ]))
                self.showEquation(text: "\(a) + \(b) = \(resultNumber)")
            },
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                self?.sceneDelegate?.noomChallengeDidComplete(unlockedNumbers: [resultNumber])
            }
        ]))
    }

    private func performSplit(node: SKSpriteNode, total: Int, a: Int, b: Int) {
        guard let noomA = NoomCatalog.noom(for: a), let noomB = NoomCatalog.noom(for: b) else { return }
        isCompleted = true
        removeSplitPreview()
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        let originalPos = node.position
        node.removeAllActions()
        node.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 0.1, duration: 0.15),
            SKAction.removeFromParent()
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                guard let self else { return }
                let leftNode = self.makeNoomNode(noom: noomA, expression: .happy)
                let rightNode = self.makeNoomNode(noom: noomB, expression: .happy)
                leftNode.position = originalPos
                rightNode.position = originalPos
                leftNode.setScale(0.1)
                rightNode.setScale(0.1)
                self.addChild(leftNode)
                self.addChild(rightNode)
                leftNode.run(SKAction.group([
                    SKAction.move(by: CGVector(dx: -130, dy: 0), duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ]))
                rightNode.run(SKAction.group([
                    SKAction.move(by: CGVector(dx: 130, dy: 0), duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ]))
                self.showEquation(text: "\(total) = \(a) + \(b)")
            },
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                self?.sceneDelegate?.noomChallengeDidComplete(unlockedNumbers: [a, b, total])
            }
        ]))
    }

    private func showEquation(text: String) {
        let label = SKNode.cartoonPillLabel(text: text, fontSize: 38, fill: CartoonSK.gold)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        label.setScale(0.1)
        label.zPosition = 250
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
    }
}
