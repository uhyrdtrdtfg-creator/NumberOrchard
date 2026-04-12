import SpriteKit

struct NumberTrainGameState: Sendable {
    let question: MathQuestion
    let totalSeats: Int
    let occupiedSeats: Int
    var emptySeats: Int { totalSeats - occupiedSeats }
    var userInput: Int?
    var countedSeats: Int = 0
    var isComplete: Bool = false
    var isCorrect: Bool = false

    init(question: MathQuestion) {
        self.question = question
        self.totalSeats = question.operand1 + question.operand2
        self.occupiedSeats = question.operand1
    }

    mutating func submitAnswer(_ answer: Int) {
        userInput = answer
        if answer == question.operand2 {
            isComplete = true
            isCorrect = true
        } else {
            isCorrect = false
        }
    }

    mutating func tapEmptySeat() {
        guard !isComplete else { return }
        countedSeats = min(countedSeats + 1, emptySeats)
    }

    mutating func commitCountedAnswer() {
        submitAnswer(countedSeats)
    }
}

@MainActor
protocol NumberTrainSceneDelegate: AnyObject {
    func numberTrainSceneDidComplete(correct: Bool, responseTime: TimeInterval)
}

class NumberTrainScene: SKScene {
    weak var gameDelegate: NumberTrainSceneDelegate?

    private var gameState: NumberTrainGameState!
    private var seatNodes: [SKSpriteNode] = []
    private var answerLabel: SKLabelNode!
    private var keypadNodes: [SKSpriteNode] = []
    private var startTime: Date!
    private var useCountingMode: Bool = false
    private var questionLabel: SKLabelNode!

    func configure(with question: MathQuestion, countingMode: Bool) {
        self.gameState = NumberTrainGameState(question: question)
        self.useCountingMode = countingMode
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

        let seatWidth: CGFloat = 60
        let seatSpacing: CGFloat = 6
        let trainWidth = CGFloat(gameState.totalSeats) * (seatWidth + seatSpacing) - seatSpacing
        let startX = (w - trainWidth) / 2
        let trainY = h * 0.55

        for i in 0..<gameState.totalSeats {
            let isOccupied = i < gameState.occupiedSeats
            let seat = SKSpriteNode(color: isOccupied ? .systemOrange : .white.withAlphaComponent(0.4),
                                    size: CGSize(width: seatWidth, height: seatWidth))
            seat.position = CGPoint(x: startX + CGFloat(i) * (seatWidth + seatSpacing) + seatWidth/2, y: trainY)
            seat.name = "seat_\(i)"
            addChild(seat)
            seatNodes.append(seat)

            if isOccupied {
                let animals = ["🐻", "🐰", "🐸", "🐶", "🐱", "🐷", "🐨", "🐼", "🦁", "🐯"]
                let animal = SKLabelNode(text: animals[i % animals.count])
                animal.fontSize = 36
                animal.verticalAlignmentMode = .center
                animal.horizontalAlignmentMode = .center
                seat.addChild(animal)
            }
        }

        answerLabel = SKLabelNode(text: "答案: _")
        answerLabel.fontSize = 32
        answerLabel.fontName = "PingFangSC-Semibold"
        answerLabel.fontColor = .systemGreen
        answerLabel.position = CGPoint(x: w/2, y: h * 0.35)
        addChild(answerLabel)

        if useCountingMode {
            let hint = SKLabelNode(text: "点击空座位数一数，然后点确认")
            hint.fontSize = 20
            hint.fontName = "PingFangSC-Regular"
            hint.fontColor = .gray
            hint.position = CGPoint(x: w/2, y: h * 0.22)
            addChild(hint)

            let confirmBtn = SKSpriteNode(color: .systemGreen, size: CGSize(width: 120, height: 50))
            confirmBtn.position = CGPoint(x: w/2, y: h * 0.12)
            confirmBtn.name = "confirm"
            addChild(confirmBtn)
            let confirmLbl = SKLabelNode(text: "确认")
            confirmLbl.fontSize = 24
            confirmLbl.fontColor = .white
            confirmLbl.fontName = "PingFangSC-Semibold"
            confirmLbl.verticalAlignmentMode = .center
            confirmBtn.addChild(confirmLbl)
        } else {
            let keypadY = h * 0.18
            let keyW: CGFloat = 70
            let keyH: CGFloat = 60
            let keysPerRow = 5
            let totalW = CGFloat(keysPerRow) * (keyW + 6) - 6
            let keyStartX = (w - totalW) / 2

            for i in 0...9 {
                let row = i / keysPerRow
                let col = i % keysPerRow
                let key = SKSpriteNode(color: .systemBlue.withAlphaComponent(0.7),
                                       size: CGSize(width: keyW, height: keyH))
                key.position = CGPoint(x: keyStartX + CGFloat(col) * (keyW + 6) + keyW/2,
                                       y: keypadY - CGFloat(row) * (keyH + 6))
                key.name = "key_\(i)"
                addChild(key)
                keypadNodes.append(key)

                let label = SKLabelNode(text: "\(i)")
                label.fontSize = 32
                label.fontColor = .white
                label.fontName = "PingFangSC-Semibold"
                label.verticalAlignmentMode = .center
                key.addChild(label)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isComplete, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        if useCountingMode {
            if let seatName = node.name ?? node.parent?.name, seatName.hasPrefix("seat_") {
                let index = Int(seatName.dropFirst(5)) ?? 0
                if index >= gameState.occupiedSeats {
                    gameState.tapEmptySeat()
                    seatNodes[index].color = .systemGreen
                    answerLabel.text = "答案: \(gameState.countedSeats)"
                }
            } else if node.name == "confirm" || node.parent?.name == "confirm" {
                gameState.commitCountedAnswer()
                if gameState.isCorrect { handleCompletion() } else { flashWrong() }
            }
            return
        }

        if let name = node.name ?? node.parent?.name, name.hasPrefix("key_") {
            let digit = Int(name.dropFirst(4)) ?? 0
            gameState.submitAnswer(digit)
            answerLabel.text = "答案: \(digit)"
            if gameState.isCorrect {
                handleCompletion()
            } else {
                flashWrong()
            }
        }
    }

    private func flashWrong() {
        answerLabel.run(SKAction.sequence([
            SKAction.colorize(with: .systemRed, colorBlendFactor: 1.0, duration: 0.15),
            SKAction.wait(forDuration: 0.3),
            SKAction.colorize(with: .systemGreen, colorBlendFactor: 1.0, duration: 0.15),
        ]))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))

        for i in gameState.occupiedSeats..<gameState.totalSeats {
            let seat = seatNodes[i]
            seat.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i - gameState.occupiedSeats) * 0.1),
                SKAction.colorize(with: .systemOrange, colorBlendFactor: 1.0, duration: 0.2),
            ]))
            let animals = ["🐼", "🐨", "🦊", "🐰", "🐻"]
            let animal = SKLabelNode(text: animals.randomElement()!)
            animal.fontSize = 36
            animal.verticalAlignmentMode = .center
            animal.setScale(0.1)
            seat.addChild(animal)
            animal.run(SKAction.scale(to: 1.0, duration: 0.3))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.gameDelegate?.numberTrainSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
