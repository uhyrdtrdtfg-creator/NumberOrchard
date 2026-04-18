import SwiftUI

/// Parent-facing weekly companionship report. Shows, for each owned Noom,
/// how long the child has been caring for it, its current stage, and a
/// plain-language summary sentence. Designed for the parent center tab;
/// no new data model — derived from existing CollectedNoom + PetProgress.
struct NoomWeeklyReportView: View {
    let profile: ChildProfile

    private var ownedPets: [PetProgress] {
        let owned = Set(profile.collectedNooms.map(\.noomNumber))
        return profile.petProgress
            .filter { owned.contains($0.noomNumber) }
            .sorted { $0.noomNumber < $1.noomNumber }
    }

    private var totalPets: Int { ownedPets.count }
    private var adultCount: Int { ownedPets.filter { $0.stage == 2 }.count }
    private var teenCount: Int { ownedPets.filter { $0.stage == 1 }.count }

    /// Newest Noom unlocked within the last 7 days (if any).
    private var newlyUnlocked: CollectedNoom? {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        return profile.collectedNooms
            .filter { $0.unlockedAt > oneWeekAgo }
            .max { $0.unlockedAt < $1.unlockedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryPanel
                if let newly = newlyUnlocked, let noom = NoomCatalog.noom(for: newly.noomNumber) {
                    highlightPanel(noom: noom)
                }
                Text("所有小精灵")
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(CartoonColor.text)
                    .padding(.top, 8)
                if ownedPets.isEmpty {
                    Text("孩子还没有解锁小精灵～")
                        .font(CartoonFont.body)
                        .foregroundStyle(CartoonColor.text.opacity(0.6))
                } else {
                    ForEach(ownedPets, id: \.noomNumber) { pet in
                        petRow(pet: pet)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Sections

    private var summaryPanel: some View {
        CartoonPanel(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("🗓️ 本周陪伴总览")
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(CartoonColor.text)
                HStack(spacing: 28) {
                    stat(value: "\(totalPets)", label: "已拥有")
                    stat(value: "\(adultCount)", label: "已成年")
                    stat(value: "\(teenCount)", label: "少年期")
                }
            }
            .padding(18)
        }
    }

    private func highlightPanel(noom: Noom) -> some View {
        CartoonPanel(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("🎉 本周新朋友")
                    .font(CartoonFont.bodyLarge)
                    .foregroundStyle(CartoonColor.gold)
                HStack(spacing: 14) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom, expression: .happy,
                        size: CGSize(width: 72, height: 72)
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(noom.name)
                            .font(CartoonFont.titleSmall)
                            .foregroundStyle(CartoonColor.text)
                        Text(noom.catchphrase)
                            .font(CartoonFont.bodySmall)
                            .foregroundStyle(CartoonColor.text.opacity(0.7))
                    }
                }
            }
            .padding(18)
        }
    }

    private func petRow(pet: PetProgress) -> some View {
        guard let noom = NoomCatalog.noom(for: pet.noomNumber) else {
            return AnyView(EmptyView())
        }
        let days = daysSince(pet.noomNumber)
        return AnyView(
            CartoonPanel(cornerRadius: 18, strokeWidth: 3) {
                HStack(spacing: 14) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom, expression: .happy,
                        size: CGSize(width: 56, height: 56), stage: pet.stage
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(noom.name)
                            .font(CartoonFont.bodyLarge)
                            .foregroundStyle(CartoonColor.text)
                        Text(sentence(for: pet, days: days))
                            .font(CartoonFont.caption)
                            .foregroundStyle(CartoonColor.text.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(stageLabel(pet.stage))
                            .font(CartoonFont.caption)
                            .foregroundStyle(tint(for: pet.stage))
                        Text("\(pet.xp) XP")
                            .font(CartoonFont.caption)
                            .foregroundStyle(CartoonColor.text.opacity(0.6))
                    }
                }
                .padding(14)
            }
        )
    }

    // MARK: - Helpers

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.text)
            Text(label)
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.65))
        }
    }

    private func daysSince(_ noomNumber: Int) -> Int {
        guard let d = profile.collectedNooms.first(where: { $0.noomNumber == noomNumber })?.unlockedAt else {
            return 0
        }
        return max(0, Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0)
    }

    private func sentence(for pet: PetProgress, days: Int) -> String {
        switch pet.stage {
        case 2: return "陪伴 \(days) 天,已长成大精灵"
        case 1: return "陪伴 \(days) 天,正在茁壮成长"
        default: return "陪伴 \(days) 天,每日都在进步"
        }
    }

    private func stageLabel(_ stage: Int) -> String {
        switch stage {
        case 0: return "幼年"
        case 1: return "少年"
        case 2: return "成年"
        default: return ""
        }
    }

    private func tint(for stage: Int) -> Color {
        switch stage {
        case 2: return CartoonColor.gold
        case 1: return CartoonColor.coral
        default: return CartoonColor.leaf
        }
    }
}
