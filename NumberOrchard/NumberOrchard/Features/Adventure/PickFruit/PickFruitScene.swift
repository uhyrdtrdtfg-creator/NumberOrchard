import SpriteKit

struct PickFruitGameState: Sendable {
    let question: MathQuestion
    private(set) var basketCount: Int
    private(set) var fruitsOnTree: Int
    private(set) var isComplete: Bool = false
    private(set) var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.basketCount = question.operand1
        self.fruitsOnTree = question.operand2
    }

    mutating func pickFruit() {
        guard !isComplete, fruitsOnTree > 0 else { return }
        fruitsOnTree -= 1
        basketCount += 1
        if fruitsOnTree == 0 {
            isComplete = true
            isCorrect = (basketCount == question.correctAnswer)
        }
    }
}

protocol PickFruitSceneDelegate: AnyObject {
    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class PickFruitScene: SKScene {
    weak var gameDelegate: PickFruitSceneDelegate?

    private var gameState: PickFruitGameState!
    private var fruitNodes: [SKSpriteNode] = []
    private var basketNode: SKSpriteNode!
    private var basketLabel: SKLabelNode!
    private var questionLabel: SKLabelNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    func configure(with question: MathQuestion) {
        self.gameState = PickFruitGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        // Question label at top
        questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 28
        questionLabel.fontColor = .darkGray
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight - 60)
        questionLabel.preferredMaxLayoutWidth = sceneWidth - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        // Basket on the right
        if let basketTexture = SKTexture(imageNamed: "Basket/basket") as SKTexture? {
            basketNode = SKSpriteNode(texture: basketTexture, size: CGSize(width: 160, height: 120))
        } else {
            basketNode = SKSpriteNode(color: .brown.withAlphaComponent(0.3), size: CGSize(width: 160, height: 120))
        }
        basketNode.position = CGPoint(x: sceneWidth * 0.7, y: sceneHeight * 0.4)
        basketNode.name = "basket"
        addChild(basketNode)

        basketLabel = SKLabelNode(text: "\(gameState.basketCount)")
        basketLabel.fontSize = 36
        basketLabel.fontColor = .darkGray
        basketLabel.fontName = "PingFangSC-Semibold"
        basketLabel.position = CGPoint(x: 0, y: -50)
        basketNode.addChild(basketLabel)

        // Tree area on the left
        let treeNode = SKSpriteNode(color: .green.withAlphaComponent(0.2), size: CGSize(width: 200, height: 250))
        treeNode.position = CGPoint(x: sceneWidth * 0.25, y: sceneHeight * 0.45)
        addChild(treeNode)

        // Fruits on tree
        let fruitTexture = SKTexture(imageNamed: "Fruits/apple")
        for i in 0..<gameState.fruitsOnTree {
            let fruit = SKSpriteNode(texture: fruitTexture, size: CGSize(width: 50, height: 50))
            fruit.name = "fruit_\(i)"
            let xOffset = CGFloat(i % 3 - 1) * 60
            let yOffset = CGFloat(i / 3) * 60
            fruit.position = CGPoint(
                x: sceneWidth * 0.25 + xOffset,
                y: sceneHeight * 0.5 + yOffset
            )
            addChild(fruit)
            fruitNodes.append(fruit)
        }

        // Pre-existing fruits in basket (visual only)
        for i in 0..<gameState.basketCount {
            let fruit = SKSpriteNode(color: .red, size: CGSize(width: 35, height: 35))
            fruit.texture = SKTexture(image: createCircleImage(color: .systemOrange, size: 35))
            let xOffset = CGFloat(i % 3 - 1) * 40
            let yOffset = CGFloat(i / 3) * 40 - 10
            fruit.position = CGPoint(x: xOffset, y: yOffset)
            basketNode.addChild(fruit)
        }
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
        let basketFrame = basketNode.frame.insetBy(dx: -30, dy: -30)

        if basketFrame.intersects(fruitFrame) {
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.8, duration: 0.1),
                SKAction.move(to: basketNode.position, duration: 0.2),
                SKAction.removeFromParent()
            ]))
            run(SKAction.playSoundFileNamed("Sounds/SFX/fruit_drop.wav", waitForCompletion: false))

            gameState.pickFruit()
            basketLabel.text = "\(gameState.basketCount)"

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            node.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)

        let celebration = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.showCelebration()
            },
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.gameDelegate?.pickFruitSceneDidComplete(
                    correct: true,
                    responseTime: responseTime
                )
            }
        ])
        run(celebration)
    }

    private func showCelebration() {
        run(SKAction.playSoundFileNamed("Sounds/SFX/correct.wav", waitForCompletion: false))
        // Speak the equation aloud
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        basketNode.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        let equation = SKLabelNode(text: "\(gameState.question.operand1) + \(gameState.question.operand2) = \(gameState.question.correctAnswer)")
        equation.fontSize = 40
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width / 2, y: size.height / 2)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
}
