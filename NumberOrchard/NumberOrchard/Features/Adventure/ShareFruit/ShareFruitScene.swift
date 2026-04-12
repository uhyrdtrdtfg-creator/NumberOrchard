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
    private var plateLabel: SKLabelNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    func configure(with question: MathQuestion) {
        self.gameState = ShareFruitGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        let questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 28
        questionLabel.fontColor = .darkGray
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight - 60)
        questionLabel.preferredMaxLayoutWidth = sceneWidth - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        let plateNode = SKSpriteNode(color: .white.withAlphaComponent(0.5), size: CGSize(width: 280, height: 180))
        plateNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.55)
        addChild(plateNode)

        plateLabel = SKLabelNode(text: "\(gameState.plateCount)")
        plateLabel.fontSize = 32
        plateLabel.fontColor = .darkGray
        plateLabel.fontName = "PingFangSC-Semibold"
        plateLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.55 - 110)
        addChild(plateLabel)

        let fruitTexture = SKTexture(imageNamed: "Fruits/strawberry")
        for i in 0..<gameState.plateCount {
            let fruit = SKSpriteNode(texture: fruitTexture, size: CGSize(width: 40, height: 40))
            fruit.name = "fruit_\(i)"
            let col = i % 4
            let row = i / 4
            fruit.position = CGPoint(
                x: sceneWidth / 2 + CGFloat(col - 2) * 50 + 25,
                y: sceneHeight * 0.55 + CGFloat(row) * 50 - 30
            )
            addChild(fruit)
            fruitNodes.append(fruit)
        }

        animalNode = SKSpriteNode(color: .gray.withAlphaComponent(0.3), size: CGSize(width: 100, height: 100))
        animalNode.position = CGPoint(x: sceneWidth * 0.3, y: sceneHeight * 0.15)
        animalNode.name = "animal"
        addChild(animalNode)

        let animalLabel = SKLabelNode(text: "🐰")
        animalLabel.fontSize = 50
        animalLabel.position = CGPoint(x: 0, y: -15)
        animalNode.addChild(animalLabel)
    }

    private func createCircleImage(color: UIColor, size: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for fruit in fruitNodes {
            if fruit.contains(location) && fruit.parent == self {
                draggingNode = fruit
                fruit.run(SKAction.scale(to: 1.2, duration: 0.1))
                run(SKAction.playSoundFileNamed("Sounds/SFX/fruit_pick.wav", waitForCompletion: false))
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
        let animalFrame = animalNode.frame.insetBy(dx: -30, dy: -30)

        if animalFrame.intersects(fruitFrame) {
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.5, duration: 0.15),
                SKAction.move(to: animalNode.position, duration: 0.15),
                SKAction.removeFromParent()
            ]))
            run(SKAction.playSoundFileNamed("Sounds/SFX/fruit_drop.wav", waitForCompletion: false))

            animalNode.run(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))

            gameState.giveFruit()
            plateLabel.text = "\(gameState.plateCount)"

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            node.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("Sounds/SFX/correct.wav", waitForCompletion: false))
        // Speak the equation aloud
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        let equation = SKLabelNode(text: "\(gameState.question.operand1) - \(gameState.question.operand2) = \(gameState.question.correctAnswer)")
        equation.fontSize = 40
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width / 2, y: size.height / 2)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.3))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.gameDelegate?.shareFruitSceneDidComplete(
                    correct: true,
                    responseTime: responseTime
                )
            }
        ]))
    }
}
