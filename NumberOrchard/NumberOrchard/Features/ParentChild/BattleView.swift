import SwiftUI
import SwiftData

struct BattleView: View {
    let onFinish: () -> Void

    @Query private var profiles: [ChildProfile]
    @State private var viewModel: BattleViewModel?

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.battleComplete {
                    battleResultView(viewModel: viewModel)
                } else {
                    battleContentView(viewModel: viewModel)
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
                color: .blue
            )
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity)

            ZStack {
                Rectangle().fill(.brown.opacity(0.3)).frame(height: 40)
                HStack(spacing: 20) {
                    Text("🏆 第 \(viewModel.currentRound)/\(viewModel.totalRounds) 轮")
                    Text("孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                        .fontWeight(.bold)
                    if viewModel.roundComplete {
                        Button("下一轮") { viewModel.nextRound() }
                            .fontWeight(.bold)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.green, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .font(.callout)
            }

            battleSide(
                question: viewModel.childQuestion?.displayText ?? "",
                input: viewModel.childInput,
                keypadScale: 1.0,
                onDigit: { viewModel.appendDigit($0, to: .child) },
                onClear: { viewModel.clearInput(for: .child) },
                onSubmit: { viewModel.submitChild() },
                label: "孩子",
                color: .green
            )
            .frame(maxWidth: .infinity)
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
        color: Color
    ) -> some View {
        VStack(spacing: 16) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(question).font(.title2).fontWeight(.semibold)
            Text(input.isEmpty ? "_" : input)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(minWidth: 80)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 10) {
                ForEach(0..<10) { i in
                    Button(action: { onDigit("\(i)") }) {
                        Text("\(i)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(width: max(44, 52 * keypadScale), height: max(44, 52 * keypadScale))
                            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("数字 \(i)")
                }
            }
            HStack(spacing: 20) {
                Button("清空", action: onClear)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.gray.opacity(0.25), in: Capsule())
                    .foregroundStyle(.primary)
                Button("提交", action: onSubmit)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(color, in: Capsule())
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
            }
        }
        .padding()
    }

    private func battleResultView(viewModel: BattleViewModel) -> some View {
        ZStack {
            if viewModel.finalWinner == .child {
                ConfettiView()
            }
            VStack(spacing: 24) {
                switch viewModel.finalWinner {
                case .child:
                    Text("🎆")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1, fromScale: 0.0, rotate: true))
                    Text("你比爸爸/妈妈还厉害！")
                        .font(.title)
                        .fontWeight(.bold)
                        .modifier(PopInModifier(delay: 0.4))
                case .parent:
                    Text("🤗")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1))
                    Text("差一点就赢了，下次一定！")
                        .font(.title)
                        .fontWeight(.bold)
                        .modifier(PopInModifier(delay: 0.3))
                case .tie, nil:
                    Text("🙌")
                        .font(.system(size: 160))
                        .accessibilityHidden(true)
                        .modifier(PopInModifier(delay: 0.1))
                    Text("你们都很棒！")
                        .font(.title)
                        .fontWeight(.bold)
                        .modifier(PopInModifier(delay: 0.3))
                }
                Text("最终 孩子 \(viewModel.childScore) : \(viewModel.parentScore) 家长")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .modifier(PopInModifier(delay: 0.6))
                Button(action: onFinish) {
                    Text("返回主页")
                        .font(.title2).fontWeight(.semibold)
                        .padding(.horizontal, 50).padding(.vertical, 20)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
                .modifier(PopInModifier(delay: 0.8))
            }
        }
    }
}
