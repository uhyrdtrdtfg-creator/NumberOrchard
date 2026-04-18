import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class NoomWardrobeViewModel {
    let profile: ChildProfile
    let activePet: PetProgress
    private let modelContext: ModelContext

    init(profile: ChildProfile, activePet: PetProgress, modelContext: ModelContext) {
        self.profile = profile
        self.activePet = activePet
        self.modelContext = modelContext
    }

    func isOwned(_ skin: NoomSkin) -> Bool {
        profile.collectedSkins.contains { $0.skinId == skin.id }
    }

    func isEquipped(_ skin: NoomSkin) -> Bool {
        profile.collectedSkins.contains {
            $0.skinId == skin.id && $0.equippedOnNoomNumber == activePet.noomNumber
        }
    }

    /// Deduct stars and record ownership. No-op if already owned or
    /// insufficient stars. Returns whether the purchase went through.
    @discardableResult
    func buy(_ skin: NoomSkin) -> Bool {
        guard !isOwned(skin), profile.stars >= skin.cost else { return false }
        profile.stars -= skin.cost
        let cs = CollectedSkin(skinId: skin.id)
        profile.collectedSkins.append(cs)
        modelContext.insert(cs)
        return true
    }

    /// Equip `skin` on the current active pet. Any other hat previously
    /// on this Noom is moved back to the closet. Idempotent.
    func equip(_ skin: NoomSkin) {
        guard isOwned(skin) else { return }
        for cs in profile.collectedSkins
        where cs.equippedOnNoomNumber == activePet.noomNumber {
            cs.equippedOnNoomNumber = nil
        }
        if let target = profile.collectedSkins.first(where: { $0.skinId == skin.id }) {
            target.equippedOnNoomNumber = activePet.noomNumber
        }
    }

    /// Take off whatever hat the active pet is wearing.
    func unequipCurrent() {
        for cs in profile.collectedSkins
        where cs.equippedOnNoomNumber == activePet.noomNumber {
            cs.equippedOnNoomNumber = nil
        }
    }

    var currentSkin: NoomSkin? {
        guard let cs = profile.collectedSkins.first(where: {
            $0.equippedOnNoomNumber == activePet.noomNumber
        }), let skin = NoomSkinCatalog.skin(id: cs.skinId) else { return nil }
        return skin
    }
}

/// Store + closet for Noom hats. Browse the catalogue, buy with stars,
/// equip to the active pet. Closed/opened as a sheet from the feeding
/// area.
struct NoomWardrobeView: View {
    @Bindable var viewModel: NoomWardrobeViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            VStack(spacing: 14) {
                topBar
                previewPanel
                Text("衣柜")
                    .font(CartoonFont.titleSmall)
                    .foregroundStyle(CartoonColor.text)
                    .padding(.top, 4)
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                        ForEach(NoomSkinCatalog.all) { skin in
                            skinCell(skin)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
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
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(CartoonColor.text)
                }
            }
            Spacer()
            Text("👗 小精灵衣柜")
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            Spacer()
            CartoonHUD(icon: "star.fill", value: "\(viewModel.profile.stars)", tint: CartoonColor.gold)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var previewPanel: some View {
        if let noom = NoomCatalog.noom(for: viewModel.activePet.noomNumber) {
            CartoonPanel(cornerRadius: 22) {
                HStack(spacing: 16) {
                    Image(uiImage: NoomRenderer.image(
                        for: noom, expression: .happy,
                        size: CGSize(width: 120, height: 120),
                        stage: viewModel.activePet.stage,
                        skin: viewModel.currentSkin
                    ))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(noom.name)
                            .font(CartoonFont.title)
                            .foregroundStyle(CartoonColor.text)
                        if let s = viewModel.currentSkin {
                            Text("正穿: \(s.glyph) \(s.name)")
                                .font(CartoonFont.bodySmall)
                                .foregroundStyle(CartoonColor.text.opacity(0.7))
                            Button("脱下") { viewModel.unequipCurrent() }
                                .font(CartoonFont.caption)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Capsule().fill(CartoonColor.paper))
                                .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.6), lineWidth: 1.5))
                        } else {
                            Text("还没戴帽子～")
                                .font(CartoonFont.bodySmall)
                                .foregroundStyle(CartoonColor.text.opacity(0.6))
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
        return VStack(spacing: 6) {
            Text(skin.glyph).font(.system(size: 54))
            Text(skin.name)
                .font(CartoonFont.bodySmall)
                .foregroundStyle(CartoonColor.text)
            Text(skin.flavour)
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            actionButton(skin: skin, owned: owned, equipped: equipped, canAfford: canAfford)
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
    private func actionButton(skin: NoomSkin, owned: Bool, equipped: Bool, canAfford: Bool) -> some View {
        if equipped {
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
