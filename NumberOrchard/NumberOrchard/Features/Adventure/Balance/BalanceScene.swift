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
    private var draggingBlock: SKSpriteNode?
    private var startTime: Date!
    private var questionLabel: SKLabelNode!

    func configure(with question: MathQuestion) {
        self.gameState = BalanceGameState(question: question)
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0)
        startTime = Date()
        setupScene()
    }

    private func setupScene() {
        let w = size.width
        let h = size.height

        questionLabel = SKLabelNode(text: gameState.question.displayText)
        questionLabel.fontSize = 26
        questionLabel.fontName = "PingFangSC-Medium"
        questionLabel.fontColor = .darkGray
        questionLabel.position = CGPoint(x: w/2, y: h - 60)
        questionLabel.preferredMaxLayoutWidth = w - 80
        questionLabel.numberOfLines = 2
        addChild(questionLabel)

        pivot = SKSpriteNode(color: .brown, size: CGSize(width: 20, height: 80))
        pivot.position = CGPoint(x: w/2, y: h * 0.42)
        addChild(pivot)

        beam = SKSpriteNode(color: .darkGray, size: CGSize(width: 400, height: 8))
        beam.position = CGPoint(x: 0, y: 40)
        pivot.addChild(beam)

        leftPan = SKSpriteNode(color: .systemGray.withAlphaComponent(0.4), size: CGSize(width: 150, height: 10))
        leftPan.position = CGPoint(x: -180, y: -30)
        beam.addChild(leftPan)
        let leftLabel = SKLabelNode(text: "\(gameState.leftSide)")
        leftLabel.fontSize = 36
        leftLabel.fontColor = .systemBlue
        leftLabel.fontName = "PingFangSC-Semibold"
        leftLabel.position = CGPoint(x: 0, y: 50)
        leftPan.addChild(leftLabel)

        for i in 0..<gameState.leftSide {
            let block = makeBlock()
            block.position = CGPoint(x: CGFloat(i % 3 - 1) * 45, y: CGFloat(i / 3) * 35 + 20)
            leftPan.addChild(block)
            leftBlocks.append(block)
        }

        rightPan = SKSpriteNode(color: .systemGray.withAlphaComponent(0.4), size: CGSize(width: 150, height: 10))
        rightPan.position = CGPoint(x: 180, y: -30)
        rightPan.name = "right_pan"
        beam.addChild(rightPan)
        let rightLabel = SKLabelNode(text: "\(gameState.rightFixed) + ?")
        rightLabel.fontSize = 32
        rightLabel.fontColor = .systemOrange
        rightLabel.fontName = "PingFangSC-Semibold"
        rightLabel.position = CGPoint(x: 0, y: 50)
        rightPan.addChild(rightLabel)

        for i in 0..<gameState.rightFixed {
            let block = makeBlock()
            block.position = CGPoint(x: CGFloat(i % 3 - 1) * 45, y: CGFloat(i / 3) * 35 + 20)
            rightPan.addChild(block)
            rightBlocks.append(block)
        }

        let poolY: CGFloat = 100
        for i in 0..<10 {
            let block = makeBlock()
            block.position = CGPoint(x: 120 + CGFloat(i) * 60, y: poolY)
            block.name = "pool_\(i)"
            addChild(block)
            poolBlocks.append(block)
        }
    }

    private func makeBlock() -> SKSpriteNode {
        let b = SKSpriteNode(color: .systemBlue, size: CGSize(width: 40, height: 30))
        b.name = "block"
        return b
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isComplete, let touch = touches.first else { return }
        let location = touch.location(in: self)
        for block in poolBlocks where block.contains(location) {
            draggingBlock = block
            block.run(SKAction.scale(to: 1.2, duration: 0.1))
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let block = draggingBlock else { return }
        block.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let block = draggingBlock else { return }
        draggingBlock = nil

        let rightPanSceneFrame = rightPan.calculateAccumulatedFrame()
        if rightPanSceneFrame.intersects(block.frame) {
            block.removeFromParent()
            poolBlocks.removeAll { $0 === block }

            gameState.placeBlock()
            let newBlock = makeBlock()
            let idx = gameState.rightFixed + gameState.rightUserPlaced - 1
            newBlock.position = CGPoint(x: CGFloat(idx % 3 - 1) * 45, y: CGFloat(idx / 3) * 35 + 20)
            newBlock.setScale(0.1)
            rightPan.addChild(newBlock)
            newBlock.run(SKAction.scale(to: 1.0, duration: 0.2))
            rightBlocks.append(newBlock)

            updateTilt()

            if gameState.isComplete {
                handleCompletion()
            }
        } else {
            block.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func updateTilt() {
        let angleRadians = gameState.tiltAngleDegrees * .pi / 180
        beam.run(SKAction.rotate(toAngle: angleRadians, duration: 0.3, shortestUnitArc: true))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        beam.run(SKAction.colorize(with: .systemYellow, colorBlendFactor: 0.6, duration: 0.3))
        let equation = SKLabelNode(text: "\(gameState.leftSide) = \(gameState.rightFixed) + \(gameState.rightUserPlaced)")
        equation.fontSize = 42
        equation.fontColor = .systemGreen
        equation.fontName = "PingFangSC-Semibold"
        equation.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        equation.setScale(0.1)
        addChild(equation)
        equation.run(SKAction.scale(to: 1.0, duration: 0.4))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.gameDelegate?.balanceSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
