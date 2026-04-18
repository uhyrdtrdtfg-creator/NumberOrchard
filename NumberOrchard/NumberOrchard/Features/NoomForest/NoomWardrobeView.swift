import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class NoomWardrobeViewModel {
    let profile: ChildProfile
    let activePet: PetProgress
    private let modelContext: ModelContext

    /// Last skin rolled by the gacha today, shown to the child as a
    /// "got this!" banner until dismissed.
    var lastGachaRoll: NoomSkin? = nil

    init(profile: ChildProfile, activePet: PetProgress, modelContext: ModelContext) {
        self.profile = profile
        self.activePet = activePet
        self.modelContext = modelContext
    }

    // MARK: - Ownership / equip

    func isOwned(_ skin: NoomSkin) -> Bool {
        profile.collectedSkins.contains { $0.skinId == skin.id }
    }

    func isEquipped(_ skin: NoomSkin) -> Bool {
        profile.collectedSkins.contains {
            $0.skinId == skin.id && $0.equippedOnNoomNumber == activePet.noomNumber
        }
    }

    /// Items equipped on the active pet, grouped by slot. A pet can wear
    /// up to one item per slot.
    var equipped: [NoomSkin.Slot: NoomSkin] {
        var map: [NoomSkin.Slot: NoomSkin] = [:]
        for cs in profile.collectedSkins
        where cs.equippedOnNoomNumber == activePet.noomNumber {
            if let s = NoomSkinCatalog.skin(id: cs.skinId) {
                map[s.slot] = s
            }
        }
        return map
    }

    /// True if the active pet's stage meets this skin's unlock gate.
    /// Items like the 🎭 drama mask need Adult stage; lower-tier items
    /// have unlockStage == 0 and are always satisfied.
    func stageMeetsUnlock(_ skin: NoomSkin) -> Bool {
        activePet.stage >= skin.unlockStage
    }

    /// Deduct stars and record ownership. No-op if already owned, stage-
    /// gated, or insufficient stars. Returns whether the purchase went
    /// through.
    @discardableResult
    func buy(_ skin: NoomSkin) -> Bool {
        guard !isOwned(skin),
              stageMeetsUnlock(skin),
              profile.stars >= skin.cost else { return false }
        profile.stars -= skin.cost
        let cs = CollectedSkin(skinId: skin.id)
        profile.collectedSkins.append(cs)
        modelContext.insert(cs)
        return true
    }

    /// Equip `skin` on the current active pet. Only the previously-
    /// equipped item *in the same slot* is displaced — a hat and collar
    /// can coexist. Respects unlock gate.
    func equip(_ skin: NoomSkin) {
        guard isOwned(skin), stageMeetsUnlock(skin) else { return }
        for cs in profile.collectedSkins
        where cs.equippedOnNoomNumber == activePet.noomNumber {
            if let other = NoomSkinCatalog.skin(id: cs.skinId), other.slot == skin.slot {
                cs.equippedOnNoomNumber = nil
            }
        }
        if let target = profile.collectedSkins.first(where: { $0.skinId == skin.id }) {
            target.equippedOnNoomNumber = activePet.noomNumber
        }
    }

    /// Take off whatever items the active pet is wearing, optionally
    /// scoped to a single slot.
    func unequipCurrent(slot: NoomSkin.Slot? = nil) {
        for cs in profile.collectedSkins
        where cs.equippedOnNoomNumber == activePet.noomNumber {
            if let slot {
                if let s = NoomSkinCatalog.skin(id: cs.skinId), s.slot == slot {
                    cs.equippedOnNoomNumber = nil
                }
            } else {
                cs.equippedOnNoomNumber = nil
            }
        }
    }

    // MARK: - Daily gacha

    var canClaimGacha: Bool {
        DailyGachaLogic.isClaimable(lastClaim: profile.lastGachaDate)
    }

    /// Roll the daily gacha. If the child already owns the rolled skin,
    /// it silently re-rolls up to 3 times to try to pick a fresh one.
    /// Returns the awarded skin (already added to the wardrobe).
    @discardableResult
    func claimDailyGacha() -> NoomSkin? {
        guard canClaimGacha else { return nil }
        var rng = SystemRandomNumberGenerator()
        var award: NoomSkin?
        for _ in 0..<3 {
            guard let pick = DailyGachaLogic.roll(rng: &rng) else { break }
            if !isOwned(pick) {
                award = pick
                break
            }
            award = pick
        }
        guard let final = award else { return nil }
        if !isOwned(final) {
            let cs = CollectedSkin(skinId: final.id)
            profile.collectedSkins.append(cs)
            modelContext.insert(cs)
        }
        profile.lastGachaDate = Date()
        lastGachaRoll = final
        AudioManager.shared.playSound("level_up.wav")
        return final
    }
}

/// Store + closet for Noom hats. Browse the catalogue, buy with stars,
/// equip to the active pet. Closed/opened as a sheet from the feeding
/// area.
struct NoomWardrobeView: View {
    @Bindable var viewModel: NoomWardrobeViewModel
    let onDismiss: () -> Void

    @State private var selectedSlot: NoomSkin.Slot = .hat

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 14) {
                topBar
                previewPanel
                gachaRow
                slotPicker
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                        ForEach(NoomSkinCatalog.all.filter { $0.slot == selectedSlot }) { skin in
                            skinCell(skin)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }

            if let roll = viewModel.lastGachaRoll {
                gachaBanner(skin: roll)
            }
        }
    }

    private var slotPicker: some View {
        HStack(spacing: 12) {
            ForEach(NoomSkin.Slot.allCases, id: \.self) { slot in
                let selected = selectedSlot == slot
                Button {
                    selectedSlot = slot
                } label: {
                    Text(slot == .hat ? "👒 帽子" : "🎀 颈饰")
                        .font(CartoonFont.body)
                        .foregroundStyle(selected ? .white : CartoonColor.text)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected ? CartoonColor.gold : CartoonColor.paper)
                        )
                        .overlay(
                            Capsule().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var gachaRow: some View {
        HStack {
            Text("🎁 每日免费抽取")
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text.opacity(0.8))
            Spacer()
            if viewModel.canClaimGacha {
                Button("领取今日") { _ = viewModel.claimDailyGacha() }
                    .font(CartoonFont.bodyLarge)
                    .padding(.horizontal, 18).padding(.vertical, 6)
                    .background(Capsule().fill(CartoonColor.coral))
                    .foregroundStyle(.white)
                    .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.7), lineWidth: 2))
            } else {
                Text("明天再来～")
                    .font(CartoonFont.caption)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(CartoonColor.ink.opacity(0.2)))
                    .foregroundStyle(CartoonColor.text.opacity(0.55))
            }
        }
        .padding(.horizontal, 20)
    }

    private func gachaBanner(skin: NoomSkin) -> some View {
        VStack(spacing: 10) {
            Text("🎉 每日礼物 🎉")
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.ink)
            Text(skin.glyph).font(.system(size: 72))
            Text(skin.name)
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.ink)
            Text(skin.flavour)
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.ink.opacity(0.8))
            Button("收下") { viewModel.lastGachaRoll = nil }
                .font(CartoonFont.bodyLarge)
                .padding(.horizontal, 22).padding(.vertical, 8)
                .background(Capsule().fill(CartoonColor.leaf))
                .foregroundStyle(.white)
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(CartoonColor.ink.opacity(0.9)).offset(y: 6)
                RoundedRectangle(cornerRadius: 28).fill(CartoonColor.gold)
                RoundedRectangle(cornerRadius: 28).stroke(CartoonColor.ink, lineWidth: 4)
            }
        )
        .padding(.horizontal, 40)
        .transition(.scale.combined(with: .opacity))
    }

    private var topBar: some View {
        MiniGameTopBar(title: "👗 小精灵衣柜", onClose: onDismiss) {
            CartoonHUD(icon: "star.fill", value: "\(viewModel.profile.stars)", tint: CartoonColor.gold)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var previewPanel: some View {
        if let noom = NoomCatalog.noom(for: viewModel.activePet.noomNumber) {
            let equipped = viewModel.equipped
            CartoonPanel(cornerRadius: 22) {
                HStack(spacing: 16) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom, expression: .happy,
                        size: CGSize(width: 120, height: 120),
                        stage: viewModel.activePet.stage,
                        skins: Array(equipped.values)
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(noom.name)
                            .font(CartoonFont.title)
                            .foregroundStyle(CartoonColor.text)
                        if equipped.isEmpty {
                            Text("光着头呢～")
                                .font(CartoonFont.bodySmall)
                                .foregroundStyle(CartoonColor.text.opacity(0.6))
                        } else {
                            ForEach(NoomSkin.Slot.allCases, id: \.self) { slot in
                                if let s = equipped[slot] {
                                    HStack(spacing: 6) {
                                        Text(s.glyph)
                                        Text(s.name)
                                            .font(CartoonFont.bodySmall)
                                            .foregroundStyle(CartoonColor.text.opacity(0.7))
                                        Button("脱下") {
                                            viewModel.unequipCurrent(slot: slot)
                                        }
                                        .font(CartoonFont.caption)
                                        .padding(.horizontal, 10).padding(.vertical, 2)
                                        .background(Capsule().fill(CartoonColor.paper))
                                        .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(16)
            }
            .padding(.horizontal, 20)
        }
    }

    private func skinCell(_ skin: NoomSkin) -> some View {
        let owned = viewModel.isOwned(skin)
        let equipped = viewModel.isEquipped(skin)
        let canAfford = viewModel.profile.stars >= skin.cost
        let unlocked = viewModel.stageMeetsUnlock(skin)
        return VStack(spacing: 6) {
            ZStack {
                Text(skin.glyph)
                    .font(.system(size: 54))
                    .opacity(unlocked ? 1.0 : 0.4)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.ink.opacity(0.7))
                        .offset(x: 20, y: 18)
                }
            }
            Text(skin.name)
                .font(CartoonFont.bodySmall)
                .foregroundStyle(unlocked ? CartoonColor.text : CartoonColor.text.opacity(0.5))
            Text(unlocked ? skin.flavour : "成年后解锁")
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            actionButton(skin: skin, owned: owned, equipped: equipped,
                         canAfford: canAfford, unlocked: unlocked)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(equipped ? CartoonColor.gold.opacity(0.22) : CartoonColor.paper)
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(equipped ? CartoonColor.coral : CartoonColor.ink.opacity(0.55),
                            lineWidth: equipped ? 3 : 2))
        )
    }

    @ViewBuilder
    private func actionButton(skin: NoomSkin, owned: Bool, equipped: Bool,
                              canAfford: Bool, unlocked: Bool) -> some View {
        if !unlocked {
            Text("🔒 成年解锁")
                .font(CartoonFont.caption)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(CartoonColor.ink.opacity(0.25)))
                .foregroundStyle(CartoonColor.text.opacity(0.5))
        } else if equipped {
            Text("已佩戴")
                .font(CartoonFont.caption)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(CartoonColor.coral.opacity(0.3)))
                .foregroundStyle(CartoonColor.text)
        } else if owned {
            Button("佩戴") { viewModel.equip(skin) }
                .font(CartoonFont.bodySmall)
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(CartoonColor.leaf))
                .foregroundStyle(.white)
        } else {
            Button {
                if canAfford { viewModel.buy(skin) }
            } label: {
                HStack(spacing: 4) {
                    Text("⭐").font(.system(size: 14))
                    Text("\(skin.cost)")
                        .font(CartoonFont.bodySmall)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 5)
            .background(Capsule().fill(canAfford ? CartoonColor.gold : CartoonColor.ink.opacity(0.3)))
            .foregroundStyle(canAfford ? CartoonColor.text : .white.opacity(0.7))
            .disabled(!canAfford)
        }
    }
}
