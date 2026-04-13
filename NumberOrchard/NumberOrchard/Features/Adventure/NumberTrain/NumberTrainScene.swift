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
    private var answerBG: SKSpriteNode!
    private var keypadNodes: [SKSpriteNode] = []
    private var confirmButton: SKSpriteNode?
    private var startTime: Date!
    private var useCountingMode: Bool = false
    private var questionLabel: SKNode!

    private let seatSize = CGSize(width: 72, height: 72)

    func configure(with question: MathQuestion, countingMode: Bool) {
        self.gameState = NumberTrainGameState(question: question)
        self.useCountingMode = countingMode
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
            fontSize: 24
        )
        questionLabel.position = CGPoint(x: w / 2, y: h - safeAreaTop - 40)
        addChild(questionLabel)

        // Locomotive head on left
        let locoTexture = SKTexture(image: renderLocomotive(size: CGSize(width: 100, height: 90)))
        let loco = SKSpriteNode(texture: locoTexture, size: CGSize(width: 108, height: 98))
        loco.position = CGPoint(x: 80, y: h * 0.60)
        addChild(loco)

        // Train track
        let seatSpacing: CGFloat = 82
        let trainWidth = CGFloat(gameState.totalSeats) * seatSpacing
        let startX = max(160, (w - trainWidth) / 2 + seatSize.width / 2)
        let trainY = h * 0.60

        let trackPath = UIBezierPath()
        let trackLineY = trainY - seatSize.height / 2 - 20
        trackPath.move(to: CGPoint(x: 30, y: trackLineY))
        trackPath.addLine(to: CGPoint(x: w - 30, y: trackLineY))
        let trackShape = SKShapeNode(path: trackPath.cgPath)
        trackShape.strokeColor = CartoonSK.wood.darker(by: 0.2)
        trackShape.lineWidth = 8
        addChild(trackShape)

        for i in 0..<gameState.totalSeats {
            let isOccupied = i < gameState.occupiedSeats
            let seat = SKNode.cartoonBlock(
                size: seatSize,
                fill: isOccupied ? CartoonSK.gold : CartoonSK.paper,
                cornerRadius: 14
            )
            seat.position = CGPoint(x: startX + CGFloat(i) * seatSpacing, y: trainY)
            seat.name = "seat_\(i)"
            addChild(seat)
            seatNodes.append(seat)

            if isOccupied {
                let animals = ["🐻", "🐰", "🐸", "🐶", "🐱", "🐷", "🐨", "🐼", "🦁", "🐯"]
                let animal = SKLabelNode(text: animals[i % animals.count])
                animal.fontSize = 44
                animal.verticalAlignmentMode = .center
                animal.horizontalAlignmentMode = .center
                seat.addChild(animal)
            }
        }

        // Answer display pill
        answerBG = SKSpriteNode(texture: SKTexture(image: renderAnswerBox(size: CGSize(width: 220, height: 80))))
        answerBG.size = CGSize(width: 228, height: 88)
        answerBG.position = CGPoint(x: w / 2, y: h * 0.40)
        addChild(answerBG)

        answerLabel = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        answerLabel.text = "_"
        answerLabel.fontSize = 48
        answerLabel.fontColor = CartoonSK.ink
        answerLabel.verticalAlignmentMode = .center
        answerLabel.position = CGPoint(x: w / 2, y: h * 0.40)
        addChild(answerLabel)

        if useCountingMode {
            let hint = SKNode.cartoonPillLabel(
                text: "点空座位数一数",
                fontSize: 20,
                fill: CartoonSK.leaf.lighter(by: 0.3)
            )
            hint.position = CGPoint(x: w / 2, y: h * 0.27)
            addChild(hint)

            let confirmTex = SKTexture(image: renderCartoonButton(
                size: CGSize(width: 180, height: 70),
                fill: CartoonSK.leaf,
                label: "确认"
            ))
            let confirm = SKSpriteNode(texture: confirmTex, size: CGSize(width: 188, height: 80))
            confirm.position = CGPoint(x: w / 2, y: max(h * 0.15, safeAreaBottom + 60))
            confirm.name = "confirm"
            addChild(confirm)
            confirmButton = confirm
        } else {
            let keyW: CGFloat = 78
            let keyH: CGFloat = 68
            let keysPerRow = 5
            let totalW = CGFloat(keysPerRow) * (keyW + 8) - 8
            let keyStartX = (w - totalW) / 2 + keyW / 2
            // Ensure bottom row clears home indicator
            let keypadYTop = max(h * 0.22, safeAreaBottom + keyH + 40)

            for i in 0...9 {
                let row = i / keysPerRow
                let col = i % keysPerRow
                let keyTex = SKTexture(image: renderCartoonButton(
                    size: CGSize(width: keyW, height: keyH),
                    fill: CartoonSK.sky,
                    label: "\(i)"
                ))
                let key = SKSpriteNode(texture: keyTex, size: CGSize(width: keyW + 8, height: keyH + 10))
                key.position = CGPoint(
                    x: keyStartX + CGFloat(col) * (keyW + 8),
                    y: keypadYTop - CGFloat(row) * (keyH + 8)
                )
                key.name = "key_\(i)"
                addChild(key)
                keypadNodes.append(key)
            }
        }
    }

    private func renderLocomotive(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let bodyRect = CGRect(x: 0, y: size.height * 0.25, width: size.width * 0.85, height: size.height * 0.65)
            let body = UIBezierPath(roundedRect: bodyRect, cornerRadius: 10)
            CartoonSK.coral.setFill()
            body.fill()
            CartoonSK.ink.setStroke()
            body.lineWidth = 3
            body.stroke()

            let stackRect = CGRect(x: size.width * 0.15, y: 5, width: 18, height: size.height * 0.3)
            let stack = UIBezierPath(roundedRect: stackRect, cornerRadius: 4)
            CartoonSK.ink.setFill()
            stack.fill()

            let windowRect = CGRect(x: size.width * 0.4, y: size.height * 0.35, width: 24, height: 24)
            let window = UIBezierPath(roundedRect: windowRect, cornerRadius: 4)
            CartoonSK.sky.setFill()
            window.fill()
            CartoonSK.ink.setStroke()
            window.lineWidth = 2
            window.stroke()

            let noseRect = CGRect(x: size.width * 0.78, y: size.height * 0.4, width: size.width * 0.22, height: size.height * 0.45)
            let nose = UIBezierPath(roundedRect: noseRect, cornerRadius: 8)
            CartoonSK.coral.darker(by: 0.1).setFill()
            nose.fill()
            CartoonSK.ink.setStroke()
            nose.lineWidth = 3
            nose.stroke()

            for xPos in [CGFloat(18), CGFloat(55)] {
                let wheelRect = CGRect(x: xPos, y: size.height * 0.80, width: 20, height: 20)
                let wheel = UIBezierPath(ovalIn: wheelRect)
                CartoonSK.ink.setFill()
                wheel.fill()
            }
        }
    }

    private func renderAnswerBox(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let shadowRect = CGRect(x: 0, y: 6, width: size.width, height: size.height - 6)
            let shadow = UIBezierPath(roundedRect: shadowRect, cornerRadius: 18)
            CartoonSK.ink.setFill()
            shadow.fill()

            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height - 6)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            CartoonSK.paper.setFill()
            path.fill()
            CartoonSK.ink.setStroke()
            path.lineWidth = 4
            path.stroke()
        }
    }

    private func renderCartoonButton(size: CGSize, fill: UIColor, label: String) -> UIImage {
        let padding: CGFloat = 4
        let shadowOff: CGFloat = 6
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2 + shadowOff)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        return renderer.image { ctx in
            let shadow = UIBezierPath(roundedRect: CGRect(x: padding, y: padding + shadowOff, width: size.width, height: size.height), cornerRadius: 16)
            CartoonSK.ink.setFill()
            shadow.fill()

            let body = UIBezierPath(roundedRect: CGRect(x: padding, y: padding, width: size.width, height: size.height), cornerRadius: 16)
            if let cgContext = ctx.cgContext as CGContext? {
                cgContext.saveGState()
                body.addClip()
                let colors = [fill.lighter(by: 0.2).cgColor, fill.cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                    cgContext.drawLinearGradient(gradient,
                        start: CGPoint(x: padding, y: padding),
                        end: CGPoint(x: padding, y: padding + size.height),
                        options: [])
                }
                cgContext.restoreGState()
            }
            CartoonSK.ink.setStroke()
            body.lineWidth = 3
            body.stroke()

            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: CartoonSK.chineseFont(), size: 30) ?? UIFont.boldSystemFont(ofSize: 30),
                .foregroundColor: UIColor.white
            ]
            let textSize = label.size(withAttributes: labelAttrs)
            let textRect = CGRect(
                x: padding + (size.width - textSize.width) / 2,
                y: padding + (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            label.draw(in: textRect, withAttributes: labelAttrs)
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
                    let seatSprite = seatNodes[index]
                    seatSprite.run(SKAction.sequence([
                        SKAction.scale(to: 1.15, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ]))
                    // Add a checkmark
                    let check = SKLabelNode(text: "✓")
                    check.fontSize = 48
                    check.fontColor = CartoonSK.leaf
                    check.verticalAlignmentMode = .center
                    check.horizontalAlignmentMode = .center
                    seatSprite.addChild(check)
                    answerLabel.text = "\(gameState.countedSeats)"
                }
            } else if let name = node.name ?? node.parent?.name, name == "confirm" {
                gameState.commitCountedAnswer()
                if gameState.isCorrect { handleCompletion() } else { flashWrong() }
            }
            return
        }

        if let name = node.name ?? node.parent?.name, name.hasPrefix("key_") {
            let digit = Int(name.dropFirst(4)) ?? 0
            if let keyNode = keypadNodes.first(where: { $0.name == name }) {
                keyNode.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.08),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ]))
            }
            gameState.submitAnswer(digit)
            answerLabel.text = "\(digit)"
            if gameState.isCorrect {
                handleCompletion()
            } else {
                flashWrong()
            }
        }
    }

    private func flashWrong() {
        answerBG.run(SKAction.sequence([
            SKAction.colorize(with: CartoonSK.coral, colorBlendFactor: 0.6, duration: 0.12),
            SKAction.wait(forDuration: 0.3),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.12)
        ]))
        run(SKAction.playSoundFileNamed("wrong.wav", waitForCompletion: false))
    }

    private func handleCompletion() {
        let responseTime = Date().timeIntervalSince(startTime)
        run(SKAction.playSoundFileNamed("correct.wav", waitForCompletion: false))
        Task { @MainActor in
            AudioManager.shared.speakEquation(gameState.question)
        }

        for i in gameState.occupiedSeats..<gameState.totalSeats {
            let seat = seatNodes[i]
            seat.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i - gameState.occupiedSeats) * 0.1),
                SKAction.scale(to: 1.2, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            let animals = ["🐼", "🐨", "🦊", "🐰", "🐻"]
            let animal = SKLabelNode(text: animals.randomElement()!)
            animal.fontSize = 44
            animal.verticalAlignmentMode = .center
            animal.horizontalAlignmentMode = .center
            animal.setScale(0.1)
            seat.addChild(animal)
            animal.run(SKAction.scale(to: 1.0, duration: 0.3))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.run { [weak self] in
                self?.gameDelegate?.numberTrainSceneDidComplete(correct: true, responseTime: responseTime)
            }
        ]))
    }
}
