import SwiftUI

struct EggHatchingArea: View {
    @Bindable var viewModel: PetGardenViewModel
    @State private var slotA: PetProgress?
    @State private var slotB: PetProgress?
    @State private var showPicker: Int?
    @State private var hatchedNoomNumber: Int?
    @State private var showHatchAnimation = false

    private let evolutionLogic = PetEvolutionLogic()

    var body: some View {
        CartoonPanel(cornerRadius: 24) {
            VStack(spacing: 12) {
                Text("🥚 孵蛋大本营")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.text)

                HStack(spacing: 18) {
                    slotView(pet: slotA, slotIndex: 0)
                    Text("+").font(.system(size: 32, weight: .black, design: .rounded))
                    slotView(pet: slotB, slotIndex: 1)
                    Text("=").font(.system(size: 32, weight: .black, design: .rounded))
                    resultView
                }

                hatchButton
            }
            .padding(20)
        }
        .sheet(item: Binding(
            get: { showPicker.map { SlotIndex(value: $0) } },
            set: { showPicker = $0?.value }
        )) { wrapper in
            picker(forSlot: wrapper.value)
        }
        .overlay {
            if showHatchAnimation, let n = hatchedNoomNumber, let noom = NoomCatalog.noom(for: n) {
                hatchOverlay(noom: noom)
            }
        }
    }

    private func slotView(pet: PetProgress?, slotIndex: Int) -> some View {
        Button(action: { showPicker = slotIndex }) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.85)).frame(width: 92, height: 92).offset(y: 4)
                Circle().fill(CartoonColor.paper).frame(width: 92, height: 92)
                Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3).frame(width: 92, height: 92)
                if let pet, let noom = NoomCatalog.noom(for: pet.noomNumber) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom,
                        expression: .neutral,
                        size: CGSize(width: 80, height: 80),
                        stage: pet.stage
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                } else {
                    Text("🥚").font(.system(size: 44))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultView: some View {
        let resultNumber: Int? = {
            guard let a = slotA, let b = slotB else { return nil }
            return evolutionLogic.canHatch(matureNoomA: a.noomNumber, matureNoomB: b.noomNumber)
        }()
        ZStack {
            Circle().fill(CartoonColor.ink.opacity(0.5)).frame(width: 92, height: 92).offset(y: 4)
            Circle().fill(CartoonColor.gold.opacity(resultNumber != nil ? 0.7 : 0.2))
                .frame(width: 92, height: 92)
            Circle().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3).frame(width: 92, height: 92)
            if let n = resultNumber {
                Text("\(n)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: CartoonColor.ink, radius: 0, x: 0, y: 2)
            } else {
                Text("?").font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(CartoonColor.ink.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private var hatchButton: some View {
        let canHatch: Bool = {
            guard let a = slotA, let b = slotB else { return false }
            guard let result = evolutionLogic.canHatch(matureNoomA: a.noomNumber, matureNoomB: b.noomNumber) else { return false }
            return !viewModel.profile.collectedNooms.contains(where: { $0.noomNumber == result })
        }()
        Button(action: triggerHatch) {
            Text("🐣 孵化！")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: CartoonColor.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .padding(.horizontal, 28).padding(.vertical, 12)
                .background(
                    Capsule().fill(canHatch ? CartoonColor.gold : Color.gray.opacity(0.4))
                )
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 3))
        }
        .buttonStyle(.plain)
        .disabled(!canHatch)
    }

    private func picker(forSlot slot: Int) -> some View {
        let mature = viewModel.maturePets()
        return VStack {
            Text("选一只成年 Noom")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .padding()
            if mature.isEmpty {
                Text("还没有成年 Noom 呢，先把 Noom 喂到 300 XP！")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(CartoonColor.text.opacity(0.6))
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(mature, id: \.noomNumber) { pet in
                            if let noom = NoomCatalog.noom(for: pet.noomNumber) {
                                Button(action: {
                                    if slot == 0 { slotA = pet } else { slotB = pet }
                                    showPicker = nil
                                }) {
                                    VStack {
                                        Image(uiImage: NoomRenderer.image(
                                            for: noom,
                                            expression: .neutral,
                                            size: CGSize(width: 80, height: 80),
                                            stage: 2
                                        ))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        Text(noom.name)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            Button("关闭") { showPicker = nil }.padding()
        }
    }

    private func triggerHatch() {
        guard let a = slotA, let b = slotB else { return }
        if let result = viewModel.tryHatch(petA: a, petB: b) {
            hatchedNoomNumber = result
            showHatchAnimation = true
            slotA = nil
            slotB = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showHatchAnimation = false
                hatchedNoomNumber = nil
            }
        }
    }

    private func hatchOverlay(noom: Noom) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(uiImage: NoomRenderer.image(
                    for: noom,
                    expression: .happy,
                    size: CGSize(width: 200, height: 200),
                    stage: 0
                ))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(showHatchAnimation ? 1.0 : 0.1)
                .animation(.spring(response: 0.6, dampingFraction: 0.55), value: showHatchAnimation)

                Text("\(noom.name) 诞生啦！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private struct SlotIndex: Identifiable {
        let value: Int
        var id: Int { value }
    }
}
