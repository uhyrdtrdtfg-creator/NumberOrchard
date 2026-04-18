import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MazeViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    static let totalRounds = 3

    var grid: MazeGrid
    var currentRound: Int = 0
    var solved: Int = 0
    var sessionComplete: Bool = false
    var lastHint: String? = nil

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
        var rng = SystemRandomNumberGenerator()
        self.grid = MazeGridGenerator.make(rng: &rng)
    }

    func tap(_ r: Int, _ c: Int) {
        let result = grid.tap(r, c)
        switch result {
        case .advanced:
            AudioManager.shared.playSound("fruit_pick.wav")
        case .backtracked:
            AudioManager.shared.playSound("button_click.wav")
        case .notAdjacent:
            lastHint = "只能走相邻的格子哦"
        case .alreadyInPath:
            lastHint = "这个格子走过啦"
        case .noop:
            break
        }
        if grid.isOverstepped {
            lastHint = "和太大了,点上一个格子回退"
        } else if result == .advanced || result == .backtracked {
            lastHint = nil
        }
    }

    func submit() {
        guard grid.isComplete else { return }
        solved += 1
        AudioManager.shared.playSound("correct.wav")
        advance()
    }

    func resetCurrentPath() {
        grid.resetPath()
        AudioManager.shared.playSound("button_click.wav")
    }

    private func advance() {
        currentRound += 1
        if currentRound >= Self.totalRounds {
            sessionComplete = true
            profile.stars += max(1, solved)
            AudioManager.shared.playSound("level_up.wav")
        } else {
            var rng = SystemRandomNumberGenerator()
            grid = MazeGridGenerator.make(rng: &rng)
            lastHint = nil
        }
    }

    var progressText: String { "\(min(currentRound + 1, Self.totalRounds)) / \(Self.totalRounds)" }
}

/// Full-screen 数字迷宫 — a 5×5 grid with a target sum. Child taps cells
/// from start (top-left) to exit (bottom-right) building a path whose
/// running sum must equal the target on arrival. Strengthens adjacency
/// reasoning + rolling-sum mental math.
struct MazeView: View {
    @Bindable var viewModel: MazeViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 14) {
                topBar
                if viewModel.sessionComplete {
                    completeView
                } else {
                    header
                    gridView
                    hintRow
                    actionRow
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 20)
        }
    }

    private var topBar: some View {
        MiniGameTopBar(
            title: "🧩 数字迷宫",
            progress: "第 \(viewModel.progressText)",
            onClose: onDismiss
        )
    }

    private var header: some View {
        HStack(spacing: 16) {
            CartoonPanel(cornerRadius: 18) {
                HStack(spacing: 8) {
                    Text("目标")
                        .font(CartoonFont.bodySmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))
                    Text("\(viewModel.grid.target)")
                        .font(CartoonFont.title)
                        .foregroundStyle(CartoonColor.gold)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
            CartoonPanel(cornerRadius: 18) {
                HStack(spacing: 8) {
                    Text("当前")
                        .font(CartoonFont.bodySmall)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))
                    Text("\(viewModel.grid.pathSum)")
                        .font(CartoonFont.title)
                        .foregroundStyle(viewModel.grid.isOverstepped ? CartoonColor.coral : CartoonColor.text)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
        }
    }

    private var gridView: some View {
        VStack(spacing: 6) {
            ForEach(0..<viewModel.grid.rows, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.grid.cols, id: \.self) { c in
                        cell(r, c)
                    }
                }
            }
        }
    }

    private func cell(_ r: Int, _ c: Int) -> some View {
        let cellRef = MazeGrid.Cell(r: r, c: c)
        let pathIndex = viewModel.grid.path.firstIndex(of: cellRef)
        let inPath = pathIndex != nil
        let isStart = cellRef == viewModel.grid.start
        let isExit = cellRef == viewModel.grid.exit
        let isTip = viewModel.grid.path.last == cellRef
        let tint: Color = {
            if isTip { return CartoonColor.gold }
            if inPath { return CartoonColor.coral.opacity(0.7) }
            if isStart { return CartoonColor.leaf.opacity(0.5) }
            if isExit { return CartoonColor.berry.opacity(0.5) }
            return CartoonColor.paper
        }()
        let borderColor: Color = isTip ? CartoonColor.coral : CartoonColor.ink.opacity(0.6)
        return Button { viewModel.tap(r, c) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: 54, height: 54).offset(y: 2)
                RoundedRectangle(cornerRadius: 10).fill(tint).frame(width: 54, height: 54)
                RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: isTip ? 3 : 1.5)
                    .frame(width: 54, height: 54)
                VStack(spacing: 2) {
                    Text("\(viewModel.grid.cells[r][c])")
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(inPath ? .white : CartoonColor.text)
                    if isStart || isExit {
                        Text(isStart ? "起点" : "终点")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(inPath ? .white : CartoonColor.text.opacity(0.7))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var hintRow: some View {
        if let hint = viewModel.lastHint {
            Text(hint)
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.coral)
        } else {
            Text("从起点开始,经过相邻格子到终点,累加等于目标")
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.55))
        }
    }

    private var actionRow: some View {
        HStack(spacing: 14) {
            Button("重新走") { viewModel.resetCurrentPath() }
                .font(CartoonFont.bodyLarge)
                .padding(.horizontal, 22).padding(.vertical, 8)
                .background(Capsule().fill(CartoonColor.paper))
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.5), lineWidth: 2))
            CartoonButton(
                tint: viewModel.grid.isComplete ? CartoonColor.leaf : CartoonColor.ink.opacity(0.35),
                accessibilityLabel: "完成",
                action: { viewModel.submit() }
            ) {
                Text(viewModel.grid.isComplete ? "✓ 完成!" : "走到终点")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 52)
            }
        }
    }

    private var completeView: some View {
        SessionCompleteCard(
            emoji: "🧩🎉",
            title: "迷宫通关!",
            primaryStat: "走通 \(viewModel.solved) / \(MazeViewModel.totalRounds)",
            rewardLine: "+\(max(1, viewModel.solved)) ⭐",
            onDismiss: onDismiss
        )
    }
}
