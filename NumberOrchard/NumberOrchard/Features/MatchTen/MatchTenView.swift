import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MatchTenViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    var game: MatchTenGame
    var feedbackTile: (Int, Int)? = nil       // last invalid-pair or non-adjacent tile (for flash)
    var lastClearAt: (Int, Int)? = nil        // last cleared cell (for sparkle)
    /// Transient "+10 x2" style floating score text from the last clear.
    /// Cleared after a short delay in the view.
    var lastClearBurst: String? = nil

    init(profile: ChildProfile, modelContext: ModelContext,
         rows: Int = 4, cols: Int = 5, targetClears: Int = 10) {
        self.profile = profile
        self.modelContext = modelContext
        // If the active Noom has the `comboSeed` skill, start the game
        // with a built-in combo seeded by the pet's tier:
        //   Tier 1 (少年) → combo 1   Tier 2 (成年) → combo 2
        let active = profile.petProgress.first(where: { $0.isActive })
            ?? profile.petProgress.first
        var starting = 0
        if let pet = active,
           NoomSkillCatalog.skill(for: pet.noomNumber) == .comboSeed {
            starting = NoomSkill.comboSeed(tier: NoomSkill.tier(forStage: pet.stage))
        }
        self.game = MatchTenGame(rows: rows, cols: cols,
                                 targetClears: targetClears,
                                 startingCombo: starting)
    }

    /// Tap wrapper: runs game logic + awards stars on completion.
    /// Combo milestones (3 / 5 / 10) trigger escalating SFX tiers so
    /// children feel the streak rather than just seeing the number rise.
    func tap(_ r: Int, _ c: Int) {
        var rng = SystemRandomNumberGenerator()
        let result = game.tap(r, c, rng: &rng)
        switch result {
        case .cleared(let pts, let combo, _):
            lastClearAt = (r, c)
            lastClearBurst = combo >= 2 ? "+\(pts) x\(combo) 连击!" : "+\(pts)"
            playComboSfx(combo: combo)
        case .invalidPair, .notAdjacent:
            feedbackTile = (r, c)
        default:
            break
        }
        if game.isComplete, !completionRewarded {
            completionRewarded = true
            profile.stars += 3
        }
    }

    /// Pick an SFX asset based on the current combo tier. 1-2: soft pickup
    /// chime, 3-4: brighter star-collect, 5-9: the "correct answer"
    /// fanfare, 10+: level-up trumpet. All asset files already ship with
    /// the app — no new resources needed.
    private func playComboSfx(combo: Int) {
        let file: String
        switch combo {
        case 0...1: file = "fruit_pick.wav"
        case 2...2: file = "star_collect.wav"
        case 3...4: file = "star_collect.wav"
        case 5...9: file = "correct.wav"
        default:    file = "level_up.wav"
        }
        AudioManager.shared.playSound(file)
    }

    private var completionRewarded = false
}

/// Full-screen 凑十消消乐 — tap two orthogonally adjacent tiles whose values
/// sum to 10 to clear them. Clear the target number of pairs to finish.
struct MatchTenView: View {
    @Bindable var viewModel: MatchTenViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 18) {
                topBar
                if viewModel.game.isComplete {
                    completeView
                } else {
                    progressPill
                    gridView
                    hintText
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)

            if let burst = viewModel.lastClearBurst {
                Text(burst)
                    .font(CartoonFont.title)
                    .foregroundStyle(viewModel.game.combo >= 2 ? CartoonColor.coral : CartoonColor.gold)
                    .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(CartoonAnim.fadeFast) {
                                viewModel.lastClearBurst = nil
                            }
                        }
                    }
            }
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
            Text("🍭 凑十消消乐")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.top, 16)
    }

    private var progressPill: some View {
        HStack(spacing: 20) {
            Text("消除 \(viewModel.game.clearsMade) / \(viewModel.game.targetClears)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.8))
            Text("得分 \(viewModel.game.score)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.gold)
            if viewModel.game.combo >= 2 {
                Text("连击 ×\(viewModel.game.combo)")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.coral)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(CartoonAnim.snappy, value: viewModel.game.combo)
    }

    private var gridView: some View {
        VStack(spacing: 10) {
            ForEach(0..<viewModel.game.rows, id: \.self) { r in
                HStack(spacing: 10) {
                    ForEach(0..<viewModel.game.cols, id: \.self) { c in
                        tile(r, c)
                    }
                }
            }
        }
    }

    private func tile(_ r: Int, _ c: Int) -> some View {
        let value = viewModel.game.value(at: r, c)
        let isSelected: Bool = {
            guard let sel = viewModel.game.selected else { return false }
            return sel.0 == r && sel.1 == c
        }()
        let tint: Color = isSelected ? CartoonColor.gold : CartoonColor.paper
        return Button(action: { viewModel.tap(r, c) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 64, height: 64).offset(y: 3)
                RoundedRectangle(cornerRadius: 18).fill(tint)
                    .frame(width: 64, height: 64)
                RoundedRectangle(cornerRadius: 18)
                    .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                    .frame(width: 64, height: 64)
                if let v = value {
                    Text("\(v)")
                        .font(CartoonFont.title)
                        .foregroundStyle(isSelected ? .white : CartoonColor.text)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(CartoonAnim.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var hintText: some View {
        Text("点两个相邻的数,和等于 10 就消除～")
            .font(CartoonFont.caption)
            .foregroundStyle(CartoonColor.text.opacity(0.6))
            .multilineTextAlignment(.center)
    }

    private var completeView: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 40)
            Text("🎉").font(.system(size: 80))
            Text("全部清空啦！")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("+3 ⭐")
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
        .transition(.scale.combined(with: .opacity))
    }
}

