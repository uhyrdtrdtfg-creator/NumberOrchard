import SpriteKit

struct BalanceGameState: Sendable {
    let question: MathQuestion
    let leftSide: Int
    let rightFixed: Int
    let targetRightAdd: Int
    var rightUserPlaced: Int = 0
    var isComplete: Bool = false

    var isBalanced: Bool {
        leftSide == rightFixed + rightUserPlaced
    }

    var tiltAngleDegrees: Double {
        let diff = Double((rightFixed + rightUserPlaced) - leftSide)
        return max(-30, min(30, diff * 5))
    }

    init(question: MathQuestion) {
        self.question = question
        self.leftSide = question.correctAnswer
        self.rightFixed = question.operand1
        self.targetRightAdd = question.operand2
    }

    mutating func placeBlock() {
        guard !isComplete else { return }
        rightUserPlaced += 1
        if isBalanced { isComplete = true }
    }

    mutating func removeBlock() {
        guard !isComplete else { return }
        rightUserPlaced = max(0, rightUserPlaced - 1)
    }
}

@MainActor
protocol BalanceSceneDelegate: AnyObject {
    func balanceSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class BalanceScene: SKScene {
    weak var gameDelegate: BalanceSceneDelegate?

    private var gameState: BalanceGameState!
    private var leftPan: SKSpriteNode!
    private var rightPan: SKSpriteNode!
    private var beam: SKSpriteNode!
    private var pivot: SKSpriteNode!
    private var leftBlocks: [SKSpriteNode] = []
    private var rightBlocks: [SKSpriteNode] = []
    private var poolBlocks: [SKSpriteNode] = []
    private var poolHomePositions: [CGPoint] = []
    private var draggingBlock: SKSpriteNode?
    private var startTime: Date!
    private var questionLabel: SKNode!

    private let blockSize = CGSize(width: 60, height: 48)

    func configure(with question: MathQuestion) {
        self.gameState = BalanceGameState(question: question)
    }

    private var safeAreaTop: CGFloat { view?.safeAreaInsets.top ?? 0 }
    private var safeAreaBottom: CGFloat { view?.safeAreaInsets.bottom ?? 0 }

    override func didMove(to view: SKView) {
        backgroundColor = CartoonSK.skyTop
        view.preferredFramesPerSecond = 60
        startTime = Date()
        setupBackground()
        setupScene()
    }

    private func setupBackground() {
        let bg = SKSpriteNode(texture: CartoonSKTextureCache.skyGradient(size: size))
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        addChild(bg)
    }

    private func setupScene() {
        let w = size.width
        let h = size.height

        questionLabel = SKNode.cartoonPillLabel(
            text: gameState.question.displayText,
            fontSize: 34
        )
        questionLabel.position = CGPoint(x: w/2, y: h - safeAreaTop - 40)
        addChild(questionLabel)

        // Pivot (wood pole)
        let pivotTexture = SKTexture(image: renderPivot(size: CGSize(width: 30, height: 110)))
        pivot = SKSpriteNode(texture: pivotTexture, size: CGSize(width: 38, height: 118))
        pivot.position = CGPoint(x: w/2, y: h * 0.42)
        addChild(pivot)

        // Beam (rounded brown log)
        let beamTexture = SKTexture(image: renderBeam(size: CGSize(width: 480, height: 22)))
        beam = SKSpriteNode(texture: beamTexture, size: CGSize(width: 488, height: 30))
        beam.position = CGPoint(x: 0, y: 50)
        pivot.addChild(beam)

        // Left pan
        leftPan = makePan(color: CartoonSK.sky)
        leftPan.position = CGPoint(x: -200, y: -40)
        beam.addChild(leftPan)
        let leftLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        leftLabel.text = "\(gameState.leftSide)"
        leftLabel.fontSize = 52
        leftLabel.fontColor = CartoonSK.ink
        leftLabel.verticalAlignmentMode = .center
        leftLabel.position = CGPoint(x: 0, y: 78)
        leftPan.addChild(leftLabel)

        for i in 0..<gameState.leftSide {
            let block = SKNode.cartoonBlock(size: blockSize, fill: CartoonSK.sky)
            let col = i % 3 - 1
            let row = i / 3
            block.position = CGPoint(x: CGFloat(col) * 60, y: CGFloat(row) * 52 + 25)
            leftPan.addChild(block)
            leftBlocks.append(block)
        }

        // Right pan
        rightPan = makePan(color: CartoonSK.coral)
        rightPan.position = CGPoint(x: 200, y: -40)
        rightPan.name = "right_pan"
        beam.addChild(rightPan)
        let rightLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        rightLabel.text = "\(gameState.rightFixed) + ?"
        rightLabel.fontSize = 44
        rightLabel.fontColor = CartoonSK.ink
        rightLabel.verticalAlignmentMode = .center
        rightLabel.position = CGPoint(x: 0, y: 78)
        rightPan.addChild(rightLabel)

        for i in 0..<gameState.rightFixed {
            let block = SKNode.cartoonBlock(size: blockSize, fill: CartoonSK.coral)
            let col = i % 3 - 1
            let row = i / 3
            block.position = CGPoint(x: CGFloat(col) * 60, y: CGFloat(row) * 52 + 25)
            rightPan.addChild(block)
            rightBlocks.append(block)
        }

        // Pool blocks: just enough + 2 buffer. Use FIXED spacing for reliability.
        let totalCount = max(gameState.targetRightAdd + 2, 4)
        let blockSpacing: CGFloat = 92  // larger than block width (60+8 texture) so they never overlap
        let groupWidth = CGFloat(totalCount - 1) * blockSpacing

        // Tray sized to exactly hold all blocks with margins, capped to screen width
        let trayMargin: CGFloat = 40
        let poolHeight: CGFloat = 140
        let poolWidth = min(w - 60, groupWidth + trayMargin * 2 + blockSize.width)
        let poolY: CGFloat = max(120, safeAreaBottom + poolHeight / 2 + 10)

        let poolTexture = SKTexture(image: renderPoolTray(size: CGSize(width: poolWidth, height: poolHeight)))
        let poolBG = SKSpriteNode(texture: poolTexture, size: CGSize(width: poolWidth + 8, height: poolHeight + 10))
        poolBG.position = CGPoint(x: w/2, y: poolY)
        poolBG.zPosition = -1
        addChild(poolBG)

        // Pool label at top of tray
        let poolLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        poolLabel.text = "🟦 积木池"
        poolLabel.fontSize = 22
        poolLabel.fontColor = CartoonSK.text
        poolLabel.verticalAlignmentMode = .center
        poolLabel.horizontalAlignmentMode = .center
        poolLabel.position = CGPoint(x: w/2, y: poolY + poolHeight / 2 - 16)
        addChild(poolLabel)

        // Blocks: centered horizontally, below label, with fixed spacing
        let firstX = w/2 - groupWidth / 2
        let blockY = poolY - 16
        for i in 0..<totalCount {
            let block = SKNode.cartoonBlock(size: blockSize, fill: CartoonSK.coral)
            let homePos = CGPoint(x: firstX + CGFloat(i) * blockSpacing, y: blockY)
            block.position = homePos
            block.name = "pool_\(i)"
            addChild(block)
            poolBlocks.append(block)
            poolHomePositions.append(homePos)
        }
    }

    private func makePan(color: UIColor) -> SKSpriteNode {
        let tex = SKTexture(image: renderPan(size: CGSize(width: 180, height: 80), color: color))
        let pan = SKSpriteNode(texture: tex, size: CGSize(width: 188, height: 90))
        return pan
    }

    private func renderPivot(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
            CartoonSK.wood.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 3
            path.stroke()
            // Triangle base
            let baseRect = CGRect(x: -10, y: size.height - 20, width: size.width + 20, height: 20)
            let baseTriangle = UIBezierPath()
            baseTriangle.move(to: CGPoint(x: baseRect.minX, y: baseRect.maxY))
            baseTriangle.addLine(to: CGPoint(x: baseRect.maxX, y: baseRect.maxY))
            baseTriangle.addLine(to: CGPoint(x: baseRect.midX, y: baseRect.minY))
            baseTriangle.close()
            CartoonSK.wood.darker(by: 0.1).setFill()
            baseTriangle.fill()
            CartoonSK.ink.setStroke()
            baseTriangle.lineWidth = 3
            baseTriangle.stroke()
        }
    }

    private func renderBeam(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size.height / 2)
            CartoonSK.wood.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    private func renderPan(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Pan cup (curved rectangle)
            let rect = CGRect(x: 0, y: size.height * 0.3, width: size.width, height: size.height * 0.7)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + 20, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 20, y: rect.maxY),
                             controlPoint: CGPoint(x: rect.midX, y: rect.maxY + 12))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.close()
            color.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 3
            path.stroke()
            // Rim
            let rimRect = CGRect(x: 0, y: size.height * 0.22, width: size.width, height: 14)
            let rim = UIBezierPath(roundedRect: rimRect, cornerRadius: 7)
            color.darker(by: 0.15).setFill()
            rim.fill()
            CartoonSK.ink.setStroke()
            rim.lineWidth = 3
            rim.stroke()
            // Chain connector
            let chain = UIBezierPath()
            chain.move(to: CGPoint(x: size.width / 2, y: 0))
            chain.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.2))
            CartoonSK.wood.setStroke()
            chain.lineWidth = 5
            chain.stroke()
        }
    }

    private func renderPoolTray(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(red: 0.92, green: 0.85, blue: 0.70, alpha: 0.9).setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isComplete, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Use an expanded hit area around each pool block (kids' fingers are imprecise).
        // Pick the CLOSEST block within hit range (not just the first match).
        let padding = CartoonSKTouch.largeHitPadding
        var bestBlock: SKSpriteNode?
        var bestDistance: CGFloat = .greatestFiniteMagnitude
        for block in poolBlocks where block.parent != nil {
            let expandedFrame = block.frame.insetBy(dx: -padding, dy: -padding)
            guard expandedFrame.contains(location) else { continue }
            let dx = block.position.x - location.x
            let dy = block.position.y - location.y
            let dist = dx * dx + dy * dy
            if dist < bestDistance {
                bestDistance = dist
                bestBlock = block
            }
        }
        if let block = bestBlock {
            draggingBlock = block
            block.zPosition = 100
            block.run(SKAction.scale(to: 1.15, duration: 0.1))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let block = draggingBlock else { return }
        block.position = touch.location(in: self)
    }

    /// Is `scenePoint` close enough to the right pan's center to count as a drop? Exposed for tests.
    /// rightPan lives inside beam (rotated) inside pivot, so we must convert to scene space
    /// rather than comparing `block.frame` to `rightPan.calculateAccumulatedFrame()`, which live in
    /// different coordinate spaces and caused drops to never register after the scene became responsive.
    func isInRightPanDropZone(_ scenePoint: CGPoint) -> Bool {
        guard rightPan != nil else { return false }
        let panCenterInScene = rightPan.convert(CGPoint.zero, to: self)
        let panRadius = max(rightPan.size.width, rightPan.size.height) / 2 + CartoonSKTouch.largeHitPadding
        let dx = scenePoint.x - panCenterInScene.x
        let dy = scenePoint.y - panCenterInScene.y
        return hypot(dx, dy) < panRadius
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let block = draggingBlock else { return }
        draggingBlock = nil

        if isInRightPanDropZone(block.position) {
            block.run(SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.15),
                SKAction.removeFromParent()
            ]))
            run(SKAction.playSoundFileNamed("fruit_drop.wav", waitForCompletion: false))

            gameState.placeBlock()
            let newBlock = SKNode.cartoonBlock(size: blockSize, fill: CartoonSK.coral)
            let idx = gameState.rightFixed + gameState.rightUserPlaced - 1
            let col = idx % 3 - 1
            let row = idx / 3
            newBlock.position = CGPoint(x: CGFloat(col) * 60, y: CGFloat(row) * 52 + 25)
            newBlock.setScale(0.1)
            rightPan.addChild(newBlock)
            newBlock.run(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            rightBlocks.append(newBlock)

            updateTilt()
            if gameState.isComplete { handleCompletion() }
        } else {
            block.zPosition = 0
            // Snap back to original pool slot so children can try again.
            if let idx = poolBlocks.firstIndex(of: block), idx < poolHomePositions.count {
                let home = poolHomePositions[idx]
                block.run(SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.2),
                    SKAction.move(to: home, duration: 0.25)
                ]))
            } else {
                block.run(SKAction.scale(to: 1.0, duration: 0.15))
            }
        }
    }

    private func updateTilt() {
        let angleRadians = gameState.tiltAngleDegrees * .pi / 180
        beam.run(SKAction.rotate(toAngle: angleRadians, duration: 0.3, shortestUnitArc: true))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        // Speak the equation
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        // Celebrate: beam glows gold
        beam.run(SKAction.colorize(with: CartoonSK.gold, colorBlendFactor: 0.7, duration: 0.3))

        // Equation banner
        let equation = SKNode.cartoonPillLabel(
            text: "\(gameState.leftSide) = \(gameState.rightFixed) + \(gameState.rightUserPlaced)",
            fontSize: 42,
            fill: CartoonSK.gold
        )
        equation.position = CGPoint(x: size.width/2, y: size.height * 0.72)
        equation.setScale(0.1)
        equation.zPosition = 200
        addChild(equation)
        equation.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.run { [weak self] in
                self?.gameDelegate?.balanceSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
