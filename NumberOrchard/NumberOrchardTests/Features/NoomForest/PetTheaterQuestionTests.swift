import Testing
@testable import NumberOrchard

@Test func theaterAdditionAnswerMatchesOperands() {
    let q = PetTheaterQuestion(
        operand1: 3, operand2: 2, op: .add,
        fruitId: "apple", fruitEmoji: "🍎", fruitName: "苹果",
        noomName: "小一"
    )
    #expect(q.answer == 5)
    #expect(q.prompt.contains("小一"))
    #expect(q.prompt.contains("苹果"))
    #expect(q.prompt.contains("3"))
    #expect(q.prompt.contains("2"))
}

@Test func theaterSubtractionAnswerMatchesOperands() {
    let q = PetTheaterQuestion(
        operand1: 5, operand2: 2, op: .subtract,
        fruitId: "apple", fruitEmoji: "🍎", fruitName: "苹果",
        noomName: "小一"
    )
    #expect(q.answer == 3)
    #expect(q.prompt.contains("吃掉"))
}

@Test func theaterGeneratorReturnsBatchSize() {
    let gen = PetTheaterQuestionGenerator()
    var rng = SystemRandomNumberGenerator()
    let batch = gen.generateBatch(
        count: 5, noomNumber: 1, noomName: "小一",
        difficulty: .seed, rng: &rng
    )
    #expect(batch.count == 5)
}

@Test func theaterGeneratorRespectsDifficultyMax() {
    // L1 (seed): sums must be ≤ 5 and no subtraction allowed.
    let gen = PetTheaterQuestionGenerator()
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<50 {
        let q = gen.generate(noomNumber: 1, noomName: "小一",
                             difficulty: .seed, rng: &rng)
        #expect(q.op == .add, "L1 must not include subtraction")
        #expect(q.operand1 + q.operand2 <= 5)
        #expect(q.operand1 >= 1 && q.operand2 >= 1)
    }
}

@Test func theaterGeneratorSubtractionNeverNegative() {
    // L2 (sprout): subtraction allowed, result must be ≥ 0.
    let gen = PetTheaterQuestionGenerator()
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<50 {
        let q = gen.generate(noomNumber: 2, noomName: "贝贝",
                             difficulty: .sprout, rng: &rng)
        if q.op == .subtract {
            #expect(q.operand1 > q.operand2, "subtraction must not yield negative")
            #expect(q.answer >= 1)
        }
    }
}

@Test func theaterGeneratorUsesPreferredFruit() {
    // Noom 1 prefers apple/strawberry — every generated question should
    // use one of those fruits.
    let gen = PetTheaterQuestionGenerator()
    var rng = SystemRandomNumberGenerator()
    let allowed: Set<String> = ["apple", "strawberry"]
    for _ in 0..<30 {
        let q = gen.generate(noomNumber: 1, noomName: "小一",
                             difficulty: .smallTree, rng: &rng)
        #expect(allowed.contains(q.fruitId))
    }
}

@Test func theaterGeneratorFallsBackWhenNoPreference() {
    // Noom 99 has no preference — generator must still return a valid fruit.
    let gen = PetTheaterQuestionGenerator()
    var rng = SystemRandomNumberGenerator()
    let q = gen.generate(noomNumber: 99, noomName: "未知",
                         difficulty: .seed, rng: &rng)
    #expect(!q.fruitId.isEmpty)
    #expect(!q.fruitName.isEmpty)
}
