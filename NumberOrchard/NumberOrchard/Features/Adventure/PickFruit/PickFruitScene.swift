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

@MainActor
protocol PickFruitSceneDelegate: AnyObject {
    func pickFruitSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class PickFruitScene: SKScene {
    weak var gameDelegate: PickFruitSceneDelegate?

    private var gameState: PickFruitGameState!
    private var fruitNodes: [SKSpriteNode] = []
    private var basketNode: SKSpriteNode!
    private var basketLabel: SKLabelNode!
    private var treeNode: SKSpriteNode!
    private var questionLabel: SKNode!
    private var draggingNode: SKSpriteNode?
    private var startTime: Date!

    private let fruitSize: CGFloat = 72

    func configure(with question: MathQuestion) {
        self.gameState = PickFruitGameState(question: question)
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

        let groundSize = CGSize(width: size.width, height: 140)
        let ground = SKSpriteNode(texture: CartoonSKTextureCache.grassGradient(size: groundSize))
        ground.size = groundSize
        ground.position = CGPoint(x: size.width / 2, y: 70 + safeAreaBottom)
        ground.zPosition = -50
        addChild(ground)
    }

    private func setupScene() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        // Question pill at top (offset below notch)
        questionLabel = SKNode.cartoonPillLabel(
            text: gameState.question.displayText,
            fontSize: 34
        )
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight - safeAreaTop - 40)
        addChild(questionLabel)

        // Tree trunk on left
        let trunkTexture = SKTexture(image: renderTreeTrunk(size: CGSize(width: 60, height: 160)))
        let trunk = SKSpriteNode(texture: trunkTexture, size: CGSize(width: 68, height: 168))
        trunk.position = CGPoint(x: sceneWidth * 0.25, y: sceneHeight * 0.28)
        addChild(trunk)

        // Tree crown (big green disc)
        treeNode = SKNode.cartoonDisc(diameter: 280, fill: CartoonSK.leaf)
        treeNode.position = CGPoint(x: sceneWidth * 0.25, y: sceneHeight * 0.55)
        addChild(treeNode)

        // Basket on right
        let basketTexture = SKTexture(image: renderBasket(size: CGSize(width: 180, height: 130)))
        basketNode = SKSpriteNode(texture: basketTexture, size: CGSize(width: 188, height: 140))
        basketNode.position = CGPoint(x: sceneWidth * 0.72, y: sceneHeight * 0.32)
        basketNode.name = "basket"
        addChild(basketNode)

        basketLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        basketLabel.text = "\(gameState.basketCount)"
        basketLabel.fontSize = 48
        basketLabel.fontColor = CartoonSK.ink
        basketLabel.verticalAlignmentMode = .center
        basketLabel.position = CGPoint(x: basketNode.position.x, y: basketNode.position.y + 95)
        addChild(basketLabel)

        // Fruits on tree
        let fruitTexture = SKTexture(imageNamed: "Fruits/apple")
        let fruitCount = gameState.fruitsOnTree
        for i in 0..<fruitCount {
            let fruit = SKSpriteNode(texture: fruitTexture, size: CGSize(width: fruitSize, height: fruitSize))
            fruit.name = "fruit_\(i)"
            let twoPi = Double.pi * 2
            let slice = twoPi / Double(max(fruitCount, 1))
            let angle: Double = Double(i) * slice + Double.pi / 6
            let radius: CGFloat = 90
            let offsetX = CGFloat(cos(angle)) * radius
            let offsetY = CGFloat(sin(angle)) * radius * 0.8
            fruit.position = CGPoint(
                x: treeNode.position.x + offsetX,
                y: treeNode.position.y + offsetY
            )
            addChild(fruit)
            fruitNodes.append(fruit)

            // Subtle idle animation
            let wiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.8),
                SKAction.rotate(byAngle: -0.16, duration: 1.6),
                SKAction.rotate(byAngle: 0.08, duration: 0.8)
            ])
            fruit.run(SKAction.repeatForever(wiggle))
        }

        // Pre-existing basket fruits (visual only)
        addApplesToBasket(gameState.basketCount, animated: false)
    }

    private func renderTreeTrunk(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
            CartoonSK.wood.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    private func renderBasket(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Basket body (trapezoid)
            let basketBody = UIBezierPath()
            let inset: CGFloat = 20
            basketBody.move(to: CGPoint(x: inset, y: size.height * 0.25))
            basketBody.addLine(to: CGPoint(x: size.width - inset, y: size.height * 0.25))
            basketBody.addLine(to: CGPoint(x: size.width - inset - 10, y: size.height))
            basketBody.addLine(to: CGPoint(x: inset + 10, y: size.height))
            basketBody.close()
            UIColor(red: 0.78, green: 0.55, blue: 0.30, alpha: 1.0).setFill()
            basketBody.fill()
            CartoonSK.ink.setStroke()
            basketBody.lineWidth = 3
            basketBody.stroke()

            // Weave lines (cartoon detail)
            for i in 1...3 {
                let y = size.height * 0.25 + CGFloat(i) * (size.height * 0.75 / 4)
                let weave = UIBezierPath()
                weave.move(to: CGPoint(x: inset + 10, y: y))
                weave.addLine(to: CGPoint(x: size.width - inset - 10, y: y))
                CartoonSK.ink.withAlphaComponent(0.3).setStroke()
                weave.lineWidth = 2
                weave.stroke()
            }

            // Rim (top oval)
            let rimRect = CGRect(x: 8, y: size.height * 0.1, width: size.width - 16, height: 34)
            let rim = UIBezierPath(roundedRect: rimRect, cornerRadius: 17)
            UIColor(red: 0.60, green: 0.40, blue: 0.20, alpha: 1.0).setFill()
            rim.fill()
            CartoonSK.ink.setStroke()
            rim.lineWidth = 3
            rim.stroke()
        }
    }

    private func addApplesToBasket(_ count: Int, animated: Bool = true) {
        // Clear existing apple sprites (keep the label via z-ordering check)
        basketNode.children.compactMap { $0 as? SKSpriteNode }.forEach { $0.removeFromParent() }
        let fruitTexture = SKTexture(imageNamed: "Fruits/apple")
        for i in 0..<count {
            let fruit = SKSpriteNode(texture: fruitTexture, size: CGSize(width: 48, height: 48))
            fruit.zPosition = 1
            let col = i % 3 - 1
            let row = i / 3
            fruit.position = CGPoint(x: CGFloat(col) * 42, y: CGFloat(row) * 42 - 5)
            if animated {
                fruit.setScale(0.1)
                fruit.run(SKAction.scale(to: 1.0, duration: 0.2))
            }
            basketNode.addChild(fruit)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for fruit in fruitNodes {
            if fruit.contains(location) && fruit.parent == self {
                draggingNode = fruit
                fruit.removeAllActions()  // Stop wiggle
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
        let basketFrame = basketNode.frame.insetBy(
            dx: -CartoonSKTouch.largeHitPadding,
            dy: -CartoonSKTouch.largeHitPadding
        )

        if basketFrame.intersects(fruitFrame) {
            node.run(SKAction.sequence([
                SKAction.scale(to: 0.8, duration: 0.15),
                SKAction.move(to: basketNode.position, duration: 0.2),
                SKAction.removeFromParent()
            ]))
            run(SKAction.playSoundFileNamed("fruit_drop.wav", waitForCompletion: false))

            gameState.pickFruit()
            basketLabel.text = "\(gameState.basketCount)"
            addApplesToBasket(gameState.basketCount)

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            node.zPosition = 0
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
            SKAction.wait(forDuration: 1.8),
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
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        basketNode.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        let equation = SKNode.cartoonPillLabel(
            text: "\(gameState.question.operand1) + \(gameState.question.operand2) = \(gameState.question.correctAnswer)",
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
    }
}
