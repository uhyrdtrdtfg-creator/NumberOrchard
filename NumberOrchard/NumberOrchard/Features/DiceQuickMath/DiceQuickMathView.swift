import SwiftUI

/// Full-screen 骰子速算 game. Two dice roll, child enters the sum on
/// the number pad, faster answers earn more points.
struct DiceQuickMathView: View {
    @Bindable var viewModel: DiceQuickMathViewModel
    let onDismiss: () -> Void

    @State private var entered = ""
    @State private var rollDeadlineTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 20) {
                topBar
                if viewModel.phase == .complete {
                    sessionComplete
                } else {
                    progressLabel
                    diceRow
                    questionLabel
                    inputDisplay
                    numberPad
                    pointsBadge
                }
                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)

            if let drop = viewModel.lastLegendaryDrop {
                LegendaryDropBanner(fruit: drop)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear(perform: scheduleRollStop)
        .onChange(of: viewModel.phase) { _, new in
            if new == .rolling { scheduleRollStop() }
        }
        .onDisappear { rollDeadlineTask?.cancel() }
    }

    // MARK: - Layout pieces

    private var topBar: some View {
        MiniGameTopBar(title: "🎲 骰子速算", onClose: onDismiss)
    }

    private var progressLabel: some View {
        Text("第 \(viewModel.progressText) 题")
            .font(CartoonFont.bodySmall)
            .foregroundStyle(CartoonColor.text.opacity(0.7))
    }

    private var diceRow: some View {
        HStack(spacing: 28) {
            DiceView(face: viewModel.currentRoll.0,
                     rolling: viewModel.phase == .rolling, size: 100)
            Text("+")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            DiceView(face: viewModel.currentRoll.1,
                     rolling: viewModel.phase == .rolling, size: 100)
        }
    }

    private var questionLabel: some View {
        let (a, b) = viewModel.currentRoll
        let prompt = viewModel.phase == .rolling
            ? "? + ? = ?"
            : "\(a) + \(b) = ?"
        return Text(prompt)
            .font(CartoonFont.title)
            .foregroundStyle(CartoonColor.text)
    }

    private var inputDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(resultTint)
                .frame(width: 160, height: 60)
            RoundedRectangle(cornerRadius: 16)
                .stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                .frame(width: 160, height: 60)
            Text(entered.isEmpty ? "?" : entered)
                .font(CartoonFont.numericLarge)
                .foregroundStyle(CartoonColor.text)
        }
        .animation(CartoonAnim.snappy, value: viewModel.lastResult)
    }

    private var resultTint: Color {
        switch viewModel.lastResult {
        case .some(true):  return CartoonColor.leaf.opacity(0.35)
        case .some(false): return CartoonColor.coral.opacity(0.35)
        case .none:        return CartoonColor.paper
        }
    }

    private var numberPad: some View {
        NumberPad(
            disabled: viewModel.phase == .rolling,
            onDigit: { digit in
                if viewModel.phase == .answering && entered.count < 2 {
                    entered += "\(digit)"
                }
            },
            onClear: { entered = "" },
            onSubmit: submit
        )
    }

    private var pointsBadge: some View {
        HStack(spacing: 12) {
            Text("⚡ 总分 \(viewModel.totalPoints)")
                .font(CartoonFont.body)
                .foregroundStyle(CartoonColor.gold)
            if viewModel.fastestSeconds.isFinite {
                Text("最快 \(viewModel.sessionFastestDisplay)")
                    .font(CartoonFont.caption)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
            }
        }
        .padding(.top, 6)
    }

    private var sessionComplete: some View {
        SessionCompleteCard(
            emoji: "🎲🎉",
            title: "速算挑战结束!",
            primaryStat: "总分 \(viewModel.totalPoints)  答对 \(viewModel.correctCount)/\(viewModel.rolls.count)\n最快答题 \(viewModel.sessionFastestDisplay)",
            rewardLine: "+\(DiceQuickMathViewModel.stars(forTotalPoints: viewModel.totalPoints)) ⭐",
            onDismiss: onDismiss
        )
    }

    // MARK: - Actions

    private func scheduleRollStop() {
        guard viewModel.phase == .rolling else { return }
        rollDeadlineTask?.cancel()
        // Tumble sound plays once when the dice start rolling.
        AudioManager.shared.playSound("button_click.wav")
        rollDeadlineTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(DiceQuickMathViewModel.rollDuration * 1_000_000_000))
            if !Task.isCancelled, viewModel.phase == .rolling {
                viewModel.startAnswering()
                AudioManager.shared.playSound("fruit_drop.wav")
            }
        }
    }

    private func submit() {
        guard viewModel.phase == .answering, let value = Int(entered) else { return }
        let correct = viewModel.submit(value)
        AudioManager.shared.playSound(correct ? "correct.wav" : "wrong.wav")
        if correct { Haptics.success() } else { Haptics.warning() }
        if correct {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                entered = ""
                viewModel.advance()
                if viewModel.phase == .complete {
                    AudioManager.shared.playSound("level_up.wav")
                }
            }
        } else {
            // Brief pause, then let child retry the same roll.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                entered = ""
                viewModel.retryCurrent()
            }
        }
    }
}
