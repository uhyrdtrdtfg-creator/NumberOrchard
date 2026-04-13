import SwiftUI
import SwiftData

struct BattleView: View {
    let onFinish: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var viewModel: BattleViewModel?

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            Group {
                if let viewModel {
                    if viewModel.battleComplete {
                        battleResultView(viewModel: viewModel)
                    } else {
                        battleContentView(viewModel: viewModel)
                    }
                }
            }
        }
        .onAppear {
            let level = profiles.first?.difficultyLevel ?? .seed
            viewModel = BattleViewModel(childLevel: level)
        }
    }

    @ViewBuilder
    private func battleContentView(viewModel: BattleViewModel) -> some View {
        VStack(spacing: 0) {
            battleSide(
                question: viewModel.parentQuestion?.displayText ?? "",
                input: viewModel.parentInput,
                keypadScale: viewModel.parentKeypadScale,
                onDigit: { viewModel.appendDigit($0, to: .parent) },
                onClear: { viewModel.clearInput(for: .parent) },
                onSubmit: { viewModel.submitParent() },
                label: "家长",
                tint: CartoonColor.sky
            )
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity)

            scoreboardRow(viewModel: viewModel)

            battleSide(
                question: viewModel.childQuestion?.displayText ?? "",
                input: viewModel.childInput,
                keypadScale: 1.0,
                onDigit: { viewModel.appendDigit($0, to: .child) },
                onClear: { viewModel.clearInput(for: .child) },
                onSubmit: { viewModel.submitChild() },
                label: "孩子",
                tint: CartoonColor.leaf
            )
            .frame(maxWidth: .infinity)
        }
    }

    private func scoreboardRow(viewModel: BattleViewModel) -> some View {
        ZStack {
            Rectangle()
                .fill(CartoonColor.wood.opacity(0.3))
                .frame(height: 44)
            HStack(spacing: CartoonDimensions.spacingRegular + 4) {
                Text("🏆 第 \(viewModel.currentRound)/\(viewModel.totalRounds) 轮")
                    .cartoonBody(size: CartoonDimensions.fontBodySmall)
                Text("孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                    .cartoonTitle(size: CartoonDimensions.fontBodySmall)
                if viewModel.roundComplete {
                    Button("下一轮") { viewModel.nextRound() }
                        .fontWeight(.bold)
                        .padding(.horizontal, CartoonDimensions.spacingRegular + 2)
                        .padding(.vertical, 10)
                        .background(CartoonColor.leaf, in: Capsule())
                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeThin))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func battleSide(
        question: String,
        input: String,
        keypadScale: Double,
        onDigit: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        label: String,
        tint: Color
    ) -> some View {
        VStack(spacing: CartoonDimensions.spacingRegular) {
            Text(label)
                .cartoonCaption()
            Text(question)
                .cartoonTitle(size: CartoonDimensions.fontTitleSmall)
            Text(input.isEmpty ? "_" : input)
                .font(.system(size: CartoonDimensions.fontTitleLarge, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
                .frame(minWidth: 96)
                .padding(.horizontal, CartoonDimensions.spacingSmall)
                .padding(.vertical, CartoonDimensions.spacingTight)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: CartoonDimensions.radiusMedium)
                            .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).offset(y: CartoonDimensions.shadowOffsetRegular)
                        RoundedRectangle(cornerRadius: CartoonDimensions.radiusMedium).fill(CartoonColor.paper)
                        RoundedRectangle(cornerRadius: CartoonDimensions.radiusMedium).stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                    }
                )
            HStack(spacing: 10) {
                ForEach(0..<10) { i in
                    Button(action: { onDigit("\(i)") }) {
                        Text("\(i)")
                            .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                            .foregroundStyle(CartoonColor.text)
                            .frame(width: max(48, 54 * keypadScale), height: max(48, 54 * keypadScale))
                            .background(tint.opacity(0.2), in: RoundedRectangle(cornerRadius: CartoonDimensions.radiusSmall))
                            .overlay(RoundedRectangle(cornerRadius: CartoonDimensions.radiusSmall).stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStrokeLight), lineWidth: CartoonDimensions.strokeThin))
                    }
                    .accessibilityLabel("数字 \(i)")
                }
            }
            HStack(spacing: CartoonDimensions.spacingRegular + 4) {
                Button("清空", action: onClear)
                    .cartoonBody()
                    .padding(.horizontal, CartoonDimensions.spacingRegular + 2)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.25), in: Capsule())
                    .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStrokeLight), lineWidth: CartoonDimensions.strokeThin))
                    .accessibilityLabel("清空")
                Button("提交", action: onSubmit)
                    .font(.system(size: CartoonDimensions.fontBodyLarge, weight: .black, design: .rounded))
                    .padding(.horizontal, CartoonDimensions.spacingMedium)
                    .padding(.vertical, CartoonDimensions.spacingSmall)
                    .background(tint, in: Capsule())
                    .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeRegular))
                    .foregroundStyle(.white)
                    .accessibilityLabel("提交")
            }
        }
        .padding()
    }

    private func battleResultView(viewModel: BattleViewModel) -> some View {
        ZStack {
            if viewModel.finalWinner == .child {
                ConfettiView()
            }
            VStack(spacing: CartoonDimensions.spacingMedium + 2) {
                switch viewModel.finalWinner {
                case .child:
                    Text("🎆")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1, fromScale: 0.0, rotate: true))
                    Text("你比爸爸/妈妈还厉害！")
                        .cartoonTitle(size: CartoonDimensions.fontTitle)
                        .modifier(PopInModifier(delay: 0.4))
                case .parent:
                    Text("🤗")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1))
                    Text("差一点就赢了，下次一定！")
                        .cartoonTitle(size: CartoonDimensions.fontTitle)
                        .modifier(PopInModifier(delay: 0.3))
                case .tie, nil:
                    Text("🙌")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1))
                    Text("你们都很棒！")
                        .cartoonTitle(size: CartoonDimensions.fontTitle)
                        .modifier(PopInModifier(delay: 0.3))
                }
                Text("最终 孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                    .cartoonBody(size: CartoonDimensions.fontBodyLarge)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                    .modifier(PopInModifier(delay: 0.6))

                CartoonButton(tint: CartoonColor.leaf, accessibilityLabel: "返回主页", action: onFinish) {
                    Text("返回主页")
                        .font(.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                        .frame(width: 240, height: 72)
                }
                .modifier(PopInModifier(delay: 0.8))
            }
        }
    }
}
