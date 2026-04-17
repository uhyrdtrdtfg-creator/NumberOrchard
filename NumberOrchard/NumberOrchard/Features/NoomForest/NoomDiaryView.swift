import SwiftUI
import Observation

/// Read-only "growth diary" for the child's owned Noom pets. A TabView of
/// one page per owned Noom, each summarising the bond so far — days since
/// unlocking, current stage, XP progress, preferred fruits, and a little
/// narrative sentence that makes the pet feel remembered.
///
/// Data is derived entirely from existing models (CollectedNoom,
/// PetProgress, PetPreferenceMap) — no new SwiftData schema needed.
struct NoomDiaryView: View {
    let profile: ChildProfile
    let onDismiss: () -> Void

    @State private var currentPage: Int = 0

    private var ownedPets: [PetProgress] {
        let owned = Set(profile.collectedNooms.map(\.noomNumber))
        return profile.petProgress
            .filter { owned.contains($0.noomNumber) }
            .sorted { $0.noomNumber < $1.noomNumber }
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            VStack(spacing: 14) {
                topBar
                if ownedPets.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(Array(ownedPets.enumerated()), id: \.element.noomNumber) { idx, pet in
                            DiaryPage(pet: pet, unlockDate: unlockDate(for: pet.noomNumber))
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }
            }
            .padding(.horizontal, 20)
        }
    }

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
            Text("📓 成长日记")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            if !ownedPets.isEmpty {
                Text("\(currentPage + 1) / \(ownedPets.count)")
                    .font(CartoonFont.bodySmall)
                    .foregroundStyle(CartoonColor.text.opacity(0.7))
                    .frame(width: 56, alignment: .trailing)
            } else {
                Color.clear.frame(width: 56, height: 56)
            }
        }
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Text("📔").font(.system(size: 80))
            Text("日记本还空着")
                .font(CartoonFont.displayLarge)
                .foregroundStyle(CartoonColor.text)
            Text("去解锁第一只小精灵吧！")
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            Spacer()
        }
    }

    private func unlockDate(for noomNumber: Int) -> Date? {
        profile.collectedNooms.first { $0.noomNumber == noomNumber }?.unlockedAt
    }
}

/// Single diary page showing one pet's story so far. Presentational only;
/// all interaction lives at the parent (swipe, dismiss).
private struct DiaryPage: View {
    let pet: PetProgress
    let unlockDate: Date?

    private var noom: Noom? { NoomCatalog.noom(for: pet.noomNumber) }
    private var daysTogether: Int {
        guard let d = unlockDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0)
    }
    private var preferredFruits: [String] {
        (PetPreferenceMap.preferences[pet.noomNumber] ?? []).compactMap {
            FruitCatalog.fruit(id: $0)?.emoji
        }
    }
    private var stageLabel: String {
        switch pet.stage {
        case 0: return "幼年"
        case 1: return "少年"
        case 2: return "成年"
        default: return ""
        }
    }
    private var narrative: String {
        guard let noom else { return "" }
        if pet.stage == 2 {
            return "\(noom.name)已经长成大精灵啦！\(daysTogether) 天的陪伴真不容易～"
        } else if pet.stage == 1 {
            return "\(noom.name)正在慢慢长大,继续喂它爱吃的吧！"
        } else {
            return "\(noom.name)还是小小的宝宝,每道题都是爱的灌溉。"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let noom {
                    portrait(noom: noom)
                    Text(noom.name)
                        .font(CartoonFont.displayLarge)
                        .foregroundStyle(CartoonColor.text)
                    Text(noom.catchphrase)
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(CartoonColor.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                statsPanel

                narrativePanel
            }
            .padding(.bottom, 40)
        }
    }

    private func portrait(noom: Noom) -> some View {
        Image(uiImage: NoomRenderer.image(
            for: noom, expression: .happy,
            size: CGSize(width: 180, height: 180), stage: pet.stage
        ))
        .resizable()
        .scaledToFit()
        .frame(width: 180, height: 180)
    }

    private var statsPanel: some View {
        CartoonPanel(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                statRow(label: "陪伴天数", value: "\(daysTogether) 天")
                statRow(label: "成长阶段", value: stageLabel)
                statRow(label: "当前经验", value: "\(pet.xp) XP")
                if !preferredFruits.isEmpty {
                    statRow(label: "最爱吃", value: preferredFruits.joined(separator: " "))
                }
            }
            .padding(18)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(CartoonFont.body)
                .foregroundStyle(CartoonColor.text.opacity(0.7))
            Spacer()
            Text(value)
                .font(CartoonFont.bodyLarge)
                .foregroundStyle(CartoonColor.text)
        }
    }

    private var narrativePanel: some View {
        CartoonPanel(cornerRadius: 22, strokeWidth: 3) {
            Text(narrative)
                .font(CartoonFont.body)
                .foregroundStyle(CartoonColor.text)
                .multilineTextAlignment(.center)
                .padding(20)
        }
    }
}
