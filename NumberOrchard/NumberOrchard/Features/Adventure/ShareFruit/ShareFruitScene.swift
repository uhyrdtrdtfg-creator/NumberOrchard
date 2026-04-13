import SpriteKit

struct ShareFruitGameState: Sendable {
    let question: MathQuestion
    private(set) var plateCount: Int
    private(set) var givenCount: Int = 0
    let targetGiveCount: Int
    private(set) var isComplete: Bool = false
    private(set) var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.plateCount = question.operand1
        self.targetGiveCount = question.operand2
    }

    mutating func giveFruit() {
        guard !isComplete, givenCount < targetGiveCount else { return }
        givenCount += 1
        plateCount -= 1
        if givenCount == targetGiveCount {
            isComplete = true
            isCorrect = (plateCount == question.correctAnswer)
        }
    }
}

@MainActor
protocol ShareFruitSceneDelegate: AnyObject {
    func shareFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class ShareFruitScene: SKScene {
    weak var gameDelegate: ShareFruitSceneDelegate?

    private var gameState: ShareFruitGameState!
    private var fruitNodes: [SKSpriteNode] = []
    private var animalNode: SKSpriteNode!
    private var plateNode: SKSpriteNode!
    private var plateLabel: SKLabelNode!
    private var questionLabel: SKNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    func configure(with question: MathQuestion) {
        self.gameState = ShareFruitGameState(question: question)
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
        questionLabel.position = CGPoint(x: w / 2, y: h - safeAreaTop - 40)
        addChild(questionLabel)

        // Plate (big round disc in center-upper)
        plateNode = SKSpriteNode(texture: SKTexture(image: renderPlate(size: CGSize(width: 360, height: 220))))
        plateNode.size = CGSize(width: 368, height: 228)
        plateNode.position = CGPoint(x: w / 2, y: h * 0.58)
        plateNode.zPosition = 1
        addChild(plateNode)

        // Count label above plate
        plateLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        plateLabel.text = "\(gameState.plateCount)"
        plateLabel.fontSize = 56
        plateLabel.fontColor = CartoonSK.ink
        plateLabel.verticalAlignmentMode = .center
        plateLabel.position = CGPoint(x: w / 2, y: plateNode.position.y + 145)
        addChild(plateLabel)

        // Fruits on plate
        let fruitTexture = SKTexture(imageNamed: "Fruits/strawberry")
        for i in 0..<gameState.plateCount {
            let fruit = SKSpriteNode(texture: fruitTexture, size: CGSize(width: 62, height: 62))
            fruit.name = "fruit_\(i)"
            fruit.zPosition = 5
            let col = i % 4
            let row = i / 4
            fruit.position = CGPoint(
                x: w / 2 + CGFloat(col - 2) * 68 + 34,
                y: plateNode.position.y + CGFloat(row) * 58 - 10
            )
            addChild(fruit)
            fruitNodes.append(fruit)
        }

        // Animal bubble at bottom (respect home indicator)
        animalNode = SKSpriteNode(texture: SKTexture(image: renderAnimalBubble(size: CGSize(width: 160, height: 160))))
        animalNode.size = CGSize(width: 168, height: 168)
        animalNode.position = CGPoint(x: w * 0.28, y: max(h * 0.22, safeAreaBottom + 100))
        animalNode.name = "animal"
        addChild(animalNode)

        let animalEmoji = SKLabelNode(text: "🐰")
        animalEmoji.fontSize = 90
        animalEmoji.verticalAlignmentMode = .center
        animalEmoji.horizontalAlignmentMode = .center
        animalEmoji.position = CGPoint(x: 0, y: 0)
        animalNode.addChild(animalEmoji)

        // Animal pointer hint
        let hint = SKNode.cartoonPillLabel(
            text: "🐰 给小兔 \(gameState.targetGiveCount) 个",
            fontSize: 28,
            fill: CartoonSK.coral.lighter(by: 0.3)
        )
        hint.position = CGPoint(x: animalNode.position.x, y: animalNode.position.y - 110)
        addChild(hint)
    }

    private func renderPlate(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Shadow
            let shadowRect = CGRect(x: 0, y: 10, width: size.width, height: size.height - 10)
            let shadow = UIBezierPath(ovalIn: shadowRect)
            CartoonSK.ink.withAlphaComponent(0.4).setFill()
            shadow.fill()

            // Plate outer
            let plateRect = CGRect(x: 0, y: 0, width: size.width, height: size.height - 10)
            let plate = UIBezierPath(ovalIn: plateRect)
            CartoonSK.paper.setFill()
            plate.fill()
            CartoonSK.ink.setStroke()
            plate.lineWidth = 4
            plate.stroke()

            // Inner rim
            let innerRect = plateRect.insetBy(dx: 20, dy: 20)
            let inner = UIBezierPath(ovalIn: innerRect)
            CartoonSK.ink.setStroke()
            inner.lineWidth = 2
            inner.stroke()
        }
    }

    private func renderAnimalBubble(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let path = UIBezierPath(ovalIn: rect)
            CartoonSK.paper.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 4
            path.stroke()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for fruit in fruitNodes {
            if fruit.contains(location) && fruit.parent == self {
                draggingNode = fruit
                fruit.zPosition = 100
                fruit.run(SKAction.scale(to: 1.2, duration: 0.1))
                run(SKAction.playSoundFileNamed("fruit_pick.wav", waitForCompletion: false))
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNode else { return }
        node.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = draggingNode else { return }
        draggingNode = nil

        let fruitFrame = node.frame
        let animalFrame = animalNode.frame.insetBy(
            dx: -CartoonSKTouch.largeHitPadding,
            dy: -CartoonSKTouch.largeHitPadding
        )

        if animalFrame.intersects(fruitFrame) {
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.4, duration: 0.15),
                SKAction.move(to: animalNode.position, duration: 0.15),
                SKAction.removeFromParent()
            ]))
            run(SKAction.playSoundFileNamed("fruit_drop.wav", waitForCompletion: false))

            animalNode.run(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))

            gameState.giveFruit()
            plateLabel.text = "\(gameState.plateCount)"

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            node.zPosition = 5
            node.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        let equation = SKNode.cartoonPillLabel(
            text: "\(gameState.question.operand1) - \(gameState.question.operand2) = \(gameState.question.correctAnswer)",
            fontSize: 44,
            fill: CartoonSK.gold
        )
        equation.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        equation.setScale(0.1)
        equation.zPosition = 200
        addChild(equation)
        equation.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.gameDelegate?.shareFruitSceneDidComplete(
                    correct: true,
                    responseTime: responseTime
                )
            }
        ]))
    }
}
