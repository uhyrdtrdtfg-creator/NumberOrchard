import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class FishingViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    var currentRound: Int = 0
    let totalRounds: Int = 5
    var state: FishingGameState
    var correctRounds: Int = 0
    var sessionComplete: Bool = false

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        self.state = FishingGameState(target: Self.pickTarget(round: 0))
    }

    static func pickTarget(round: Int) -> Int {
        // Ramp gently: rounds 0-1 target 5-7, 2-3 target 8-10, last round 10-12.
        switch round {
        case 0, 1: return Int.random(in: 5...7)
        case 2, 3: return Int.random(in: 8...10)
        default:   return Int.random(in: 9...12)
        }
    }

    func catchFish(at idx: Int) { state.catchFish(at: idx) }
    func release(bucketIndex idx: Int) { _ = state.release(bucketIndex: idx) }

    /// Lock in the bucket — if it hits target, record a win and advance.
    /// If overfilled or under, the view offers retry via clearBucket.
    func submit() {
        guard state.isComplete else { return }
        correctRounds += 1
        advance()
    }

    func clearBucket() {
        // Release everything back into the pond.
        while !state.bucketFish.isEmpty {
            _ = state.release(bucketIndex: 0)
        }
    }

    private func advance() {
        currentRound += 1
        if currentRound >= totalRounds {
            sessionComplete = true
            profile.stars += max(1, correctRounds / 2)
        } else {
            state = FishingGameState(target: Self.pickTarget(round: currentRound))
        }
    }

    var progressText: String { "\(min(currentRound + 1, totalRounds)) / \(totalRounds)" }
}

/// Full-screen 数字钓鱼 — numbered fish drift in a pond; child taps a fish to
/// put it in the bucket. Bucket sum must match the round's target.
struct FishingView: View {
    @Bindable var viewModel: FishingViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CartoonColor.sky.opacity(0.6), CartoonColor.sky.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                topBar
                if viewModel.sessionComplete {
                    completeView
                } else {
                    targetPill
                    pondView
                    bucketView
                    actionRow
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 56, height: 56)
                    Image(systemName: "xmark").font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("🎣 数字钓鱼")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            Text("第 \(viewModel.progressText) 轮")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
                .frame(width: 96, alignment: .trailing)
        }
        .padding(.top, 16)
    }

    private var targetPill: some View {
        CartoonPanel(cornerRadius: 20) {
            HStack(spacing: 10) {
                Text("钓出总和")
                    .font(CartoonFont.body)
                    .foregroundStyle(CartoonColor.text)
                Text("= \(viewModel.state.target)")
                    .font(CartoonFont.title)
                    .foregroundStyle(CartoonColor.gold)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }

    private var pondView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌊 池塘")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.75))
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(Array(viewModel.state.pondFish.enumerated()), id: \.offset) { idx, value in
                    if let v = value {
                        fishButton(value: v) {
                            viewModel.catchFish(at: idx)
                        }
                    } else {
                        Color.clear.frame(height: 72)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(CartoonColor.sky.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(CartoonColor.ink.opacity(0.55), lineWidth: 3))
        )
    }

    private func fishButton(value: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text("🐟").font(.system(size: 56))
                Text("\(value)")
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
            }
            .frame(height: 72)
        }
        .buttonStyle(.plain)
    }

    private var bucketView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🪣 鱼桶 (和 \(viewModel.state.bucketSum))")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(viewModel.state.isOverfilled ? CartoonColor.coral : CartoonColor.text.opacity(0.75))
            HStack(spacing: 10) {
                ForEach(Array(viewModel.state.bucketFish.enumerated()), id: \.offset) { idx, v in
                    Button(action: { viewModel.release(bucketIndex: idx) }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(CartoonColor.paper)
                                .frame(width: 56, height: 56)
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2.5)
                                .frame(width: 56, height: 56)
                            Text("\(v)")
                                .font(CartoonFont.titleSmall)
                                .foregroundStyle(CartoonColor.text)
                        }
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.state.bucketFish.isEmpty {
                    Text("点鱼放进桶里～")
                        .font(CartoonFont.caption)
                        .foregroundStyle(CartoonColor.text.opacity(0.55))
                }
            }
            .frame(minHeight: 62)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(CartoonColor.paperWarm)
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(CartoonColor.ink.opacity(0.55), lineWidth: 3))
        )
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 16) {
            CartoonButton(tint: CartoonColor.coral,
                         accessibilityLabel: "全放回",
                         action: { viewModel.clearBucket() }) {
                Text("全放回")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 58)
            }
            CartoonButton(tint: viewModel.state.isComplete ? CartoonColor.leaf : CartoonColor.ink.opacity(0.35),
                         accessibilityLabel: "确认",
                         action: { viewModel.submit() }) {
                Text(viewModel.state.isComplete ? "✓ 成功！" : "继续钓")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 180, height: 58)
            }
        }
    }

    private var completeView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)
            Text("🎣🎉").font(.system(size: 80))
            Text("钓鱼结束！")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("答对 \(viewModel.correctRounds) / \(viewModel.totalRounds)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.8))
            Text("+\(max(1, viewModel.correctRounds / 2)) ⭐")
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.gold)
            Spacer().frame(height: 10)
            CartoonButton(tint: CartoonColor.gold, accessibilityLabel: "完成", action: onDismiss) {
                Text("回到花园")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 60)
            }
        }
    }
}
