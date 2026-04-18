import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class PetGardenViewModel {
    let profile: ChildProfile
    private let modelContext: ModelContext
    private let xpCalculator = PetXPCalculator()
    private let evolutionLogic = PetEvolutionLogic()

    var lastEvolvedNoomNumber: Int?
    var lastFedXP: Int = 0
    var lastFedWasPreferred: Bool = false
    /// When the most recent feed pushed the active pet from a lower skill
    /// tier to a higher one, this tuple is populated so the view can show
    /// a full-screen "技能进化!" banner. Cleared after the view dismisses.
    var pendingTierEvolution: (noom: Noom, skill: NoomSkill, newTier: NoomSkill.Tier)? = nil

    init(profile: ChildProfile, modelContext: ModelContext) {
        self.profile = profile
        self.modelContext = modelContext
    }

    /// Pets that are owned (one PetProgress entry per collected Noom).
    /// Lazily creates PetProgress for any CollectedNoom that doesn't have one yet.
    func ownedPets() -> [PetProgress] {
        let owned = profile.collectedNooms.map(\.noomNumber)
        for n in owned where !profile.petProgress.contains(where: { $0.noomNumber == n }) {
            let p = PetProgress(noomNumber: n)
            profile.petProgress.append(p)
            modelContext.insert(p)
        }
        return profile.petProgress
            .filter { owned.contains($0.noomNumber) }
            .sorted { $0.noomNumber < $1.noomNumber }
    }

    var activePet: PetProgress? {
        ownedPets().first(where: { $0.isActive }) ?? ownedPets().first
    }

    func setActive(_ pet: PetProgress) {
        for p in profile.petProgress {
            p.isActive = (p.noomNumber == pet.noomNumber)
        }
    }

    /// Feed `fruitId` to the active pet. Returns the XP gained, whether it was preferred, and whether evolved.
    /// If the active pet has an unlocked `xpBoost` skill, XP is boosted by the tier's fraction
    /// (Tier 1 = +50%, Tier 2 = +100%).
    @discardableResult
    func feedActivePet(fruitId: String) -> (xp: Int, preferred: Bool, didEvolve: Bool) {
        guard let pet = activePet else { return (0, false, false) }
        var xp = xpCalculator.xpFor(fruitId: fruitId, noomNumber: pet.noomNumber)
        let skill = NoomSkillCatalog.skill(for: pet.noomNumber)
        let tier = NoomSkill.tier(forStage: pet.stage)
        if skill == .xpBoost && tier != .none {
            xp = Int(Double(xp) * (1.0 + NoomSkill.xpBoostFraction(tier: tier)))
        }
        let oldStage = pet.stage
        let oldTier = NoomSkill.tier(forStage: oldStage)
        pet.xp += xp
        let newStage = evolutionLogic.stage(for: pet.xp)
        var didEvolve = false
        if newStage > oldStage {
            pet.stage = newStage
            if newStage == 2 && pet.matureAt == nil {
                pet.matureAt = Date()
            }
            lastEvolvedNoomNumber = pet.noomNumber
            didEvolve = true
            // Surface skill-tier transitions (none→one, one→two) so the
            // view layer can celebrate them with a dedicated banner.
            let newTier = NoomSkill.tier(forStage: newStage)
            if newTier > oldTier, let noom = NoomCatalog.noom(for: pet.noomNumber) {
                pendingTierEvolution = (
                    noom: noom,
                    skill: NoomSkillCatalog.skill(for: pet.noomNumber),
                    newTier: newTier
                )
            }
        }
        let preferred = PetPreferenceMap.isPreferred(fruitId: fruitId, for: pet.noomNumber)
        lastFedXP = xp
        lastFedWasPreferred = preferred
        return (xp, preferred, didEvolve)
    }

    /// The active pet's unlocked skill, or nil if no active pet / still a baby.
    var activeSkill: NoomSkill? {
        guard let pet = activePet, NoomSkill.isUnlocked(stage: pet.stage) else { return nil }
        return NoomSkillCatalog.skill(for: pet.noomNumber)
    }

    /// Tier of the active pet's skill (none / one / two). Game systems use
    /// this to scale the skill's effect — see NoomSkill.*(tier:) helpers.
    var activeSkillTier: NoomSkill.Tier {
        guard let pet = activePet else { return .none }
        return NoomSkill.tier(forStage: pet.stage)
    }

    /// Currently-equipped cosmetic hat on the active pet, if any.
    /// Looked up lazily against the profile's CollectedSkin rows so
    /// putting on a new hat in the wardrobe immediately reflects here.
    var activeSkin: NoomSkin? {
        guard let pet = activePet else { return nil }
        guard let cs = profile.collectedSkins.first(where: {
            $0.equippedOnNoomNumber == pet.noomNumber
        }) else { return nil }
        return NoomSkinCatalog.skin(id: cs.skinId)
    }

    /// Mature small Nooms eligible for hatching (1-10 only).
    func maturePets() -> [PetProgress] {
        ownedPets().filter { evolutionLogic.isMature(xp: $0.xp) && $0.noomNumber <= 10 }
    }

    /// Available fruit items (those collected by the child).
    func availableFruits() -> [FruitItem] {
        let collectedIds = Set(profile.collectedFruits.map(\.fruitId))
        return FruitCatalog.fruits.filter { collectedIds.contains($0.id) }
    }

    /// Try to hatch a big-Noom from two mature small Nooms.
    @discardableResult
    func tryHatch(petA: PetProgress, petB: PetProgress) -> Int? {
        guard evolutionLogic.isMature(xp: petA.xp), evolutionLogic.isMature(xp: petB.xp) else {
            return nil
        }
        guard let result = evolutionLogic.canHatch(matureNoomA: petA.noomNumber, matureNoomB: petB.noomNumber) else {
            return nil
        }
        if profile.collectedNooms.contains(where: { $0.noomNumber == result }) {
            return nil
        }
        let cn = CollectedNoom(noomNumber: result)
        profile.collectedNooms.append(cn)
        modelContext.insert(cn)
        let pp = PetProgress(noomNumber: result)
        profile.petProgress.append(pp)
        modelContext.insert(pp)
        return result
    }
}
