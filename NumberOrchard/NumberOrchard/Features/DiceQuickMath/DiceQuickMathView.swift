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
        }
        .onAppear(perform: scheduleRollStop)
        .onChange(of: viewModel.phase) { _, new in
            if new == .rolling { scheduleRollStop() }
        }
        .onDisappear { rollDeadlineTask?.cancel() }
    }

    // MARK: - Layout pieces

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 56, height: 56).offset(y: 3)
                    Circle().fill(CartoonColor.paper).frame(width: 56, height: 56)
                    Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3).frame(width: 56, height: 56)
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("🎲 骰子速算")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.top, 16)
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
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { col in
                        padKey("\(row * 3 + col)")
                    }
                }
            }
            HStack(spacing: 10) {
                padKey("清", tint: CartoonColor.coral) { entered = "" }
                padKey("0")
                padKey("✓", tint: CartoonColor.leaf) { submit() }
            }
        }
    }

    private func padKey(
        _ label: String,
        tint: Color = CartoonColor.paper,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: {
            if let action {
                action()
            } else if viewModel.phase == .answering && entered.count < 2 {
                entered += label
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 76, height: 60).offset(y: 3)
                RoundedRectangle(cornerRadius: 18).fill(tint)
                    .frame(width: 76, height: 60)
                RoundedRectangle(cornerRadius: 18).stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3)
                    .frame(width: 76, height: 60)
                Text(label)
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(tint == CartoonColor.paper ? CartoonColor.text : .white)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phase == .rolling)
        .opacity(viewModel.phase == .rolling ? 0.55 : 1.0)
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
        VStack(spacing: 18) {
            Spacer().frame(height: 30)
            Text("🎲🎉")
                .font(.system(size: 80))
            Text("速算挑战结束！")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("总分 \(viewModel.totalPoints)  答对 \(viewModel.correctCount)/\(viewModel.rolls.count)")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.8))
            Text("最快答题 \(viewModel.sessionFastestDisplay)")
                .font(CartoonFont.body)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            Text("+\(DiceQuickMathViewModel.stars(forTotalPoints: viewModel.totalPoints)) ⭐")
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

    // MARK: - Actions

    private func scheduleRollStop() {
        guard viewModel.phase == .rolling else { return }
        rollDeadlineTask?.cancel()
        rollDeadlineTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(DiceQuickMathViewModel.rollDuration * 1_000_000_000))
            if !Task.isCancelled, viewModel.phase == .rolling {
                viewModel.startAnswering()
            }
        }
    }

    private func submit() {
        guard viewModel.phase == .answering, let value = Int(entered) else { return }
        let correct = viewModel.submit(value)
        if correct {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                entered = ""
                viewModel.advance()
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
