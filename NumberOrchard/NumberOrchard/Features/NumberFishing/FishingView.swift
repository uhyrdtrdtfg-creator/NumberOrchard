import SwiftUI
import SwiftData
import Observation
import SpriteKit

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

    func catchFish(at idx: Int) {
        state.catchFish(at: idx)
        AudioManager.shared.playSound("fruit_pick.wav")
        Haptics.tap()
    }
    func release(bucketIndex idx: Int) {
        _ = state.release(bucketIndex: idx)
        AudioManager.shared.playSound("button_click.wav")
        Haptics.tap()
    }

    /// Lock in the bucket — if it hits target, record a win and advance.
    /// If overfilled or under, the view offers retry via clearBucket.
    func submit() {
        guard state.isComplete else { return }
        correctRounds += 1
        AudioManager.shared.playSound("correct.wav")
        Haptics.success()
        advance()
        if sessionComplete {
            AudioManager.shared.playSound("level_up.wav")
            Haptics.milestone()
        }
    }

    func clearBucket() {
        // Release everything back into the pond.
        while !state.bucketFish.isEmpty {
            _ = state.release(bucketIndex: 0)
        }
        AudioManager.shared.playSound("button_click.wav")
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
        MiniGameTopBar(
            title: "🎣 数字钓鱼",
            progress: "第 \(viewModel.progressText) 轮",
            onClose: onDismiss
        )
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
            Text("🌊 池塘 — 点一条鱼把它捞进桶里")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.75))
            FishingSceneContainer(viewModel: viewModel)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(CartoonColor.ink.opacity(0.55), lineWidth: 3)
                )
        }
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
                            // Paper chip with soft top sheen, matches the
                            // sticker aesthetic used elsewhere.
                            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, CartoonColor.paper],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(width: 56, height: 56)
                            RoundedRectangle(cornerRadius: CartoonRadius.rounded)
                                .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2.5)
                                .frame(width: 56, height: 56)
                            Text("\(v)")
                                .font(CartoonFont.titleSmall)
                                .foregroundStyle(CartoonColor.text)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("放回鱼 \(v)")
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

    // MARK: - SpriteKit bridge

    private var completeView: some View {
        SessionCompleteCard(
            emoji: "🎣🎉",
            title: "钓鱼结束!",
            primaryStat: "答对 \(viewModel.correctRounds) / \(viewModel.totalRounds)",
            rewardLine: "+\(max(1, viewModel.correctRounds / 2)) ⭐",
            onDismiss: onDismiss
        )
    }
}

// MARK: - SpriteKit bridge

/// Hosts the FishingScene and syncs it with the view model. When the pond
/// contents change (new round / fish caught) the scene is reconfigured or
/// asked to animate the caught fish out.
private struct FishingSceneContainer: View {
    @Bindable var viewModel: FishingViewModel
    @State private var coordinator = FishingSceneCoordinator()

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: coordinator.scene(size: geo.size))
                .onAppear {
                    coordinator.bind(viewModel: viewModel, sceneSize: geo.size)
                }
                .onChange(of: viewModel.currentRound) { _, _ in
                    coordinator.syncPond()
                }
                .onChange(of: viewModel.state.pondFish.compactMap { $0 }.count) { _, _ in
                    coordinator.syncPond()
                }
        }
    }
}

@MainActor
private final class FishingSceneCoordinator: NSObject, FishingSceneDelegate {
    private let fishingScene = FishingScene(size: CGSize(width: 600, height: 320))
    private weak var viewModel: FishingViewModel?
    private var lastSeenIndices: Set<Int> = []

    override init() {
        super.init()
        fishingScene.scaleMode = .resizeFill
        fishingScene.gameDelegate = self
    }

    func scene(size: CGSize) -> FishingScene {
        fishingScene.size = size
        return fishingScene
    }

    func bind(viewModel: FishingViewModel, sceneSize: CGSize) {
        self.viewModel = viewModel
        fishingScene.size = sceneSize
        syncPond(fullRebuild: true)
    }

    /// Detect the delta between the VM's pond state and what the scene is
    /// showing, then either animate caught fish or rebuild on round change.
    func syncPond(fullRebuild: Bool = false) {
        guard let vm = viewModel else { return }
        let currentIndices = Set(vm.state.pondFish.enumerated().compactMap { $0.element == nil ? nil : $0.offset })

        if fullRebuild || currentIndices.count > lastSeenIndices.count {
            // Round changed (or first bind): rebuild everything.
            fishingScene.configure(
                pondFish: vm.state.pondFish,
                bucketCenterInScene: CGPoint(x: fishingScene.size.width / 2,
                                             y: 30)
            )
            lastSeenIndices = currentIndices
            return
        }

        let newlyRemoved = lastSeenIndices.subtracting(currentIndices)
        for idx in newlyRemoved {
            fishingScene.animateCatch(at: idx)
        }
        lastSeenIndices = currentIndices
    }

    nonisolated func fishingScene(_ scene: FishingScene, didCatchFishAt pondIndex: Int) {
        Task { @MainActor in
            self.viewModel?.catchFish(at: pondIndex)
        }
    }
}
