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
    /// If the active pet has an unlocked `xpBoost` skill, XP is multiplied by 1.5×.
    @discardableResult
    func feedActivePet(fruitId: String) -> (xp: Int, preferred: Bool, didEvolve: Bool) {
        guard let pet = activePet else { return (0, false, false) }
        var xp = xpCalculator.xpFor(fruitId: fruitId, noomNumber: pet.noomNumber)
        let skill = NoomSkillCatalog.skill(for: pet.noomNumber)
        if skill == .xpBoost && NoomSkill.isUnlocked(stage: pet.stage) {
            xp = Int(Double(xp) * 1.5)
        }
        let oldStage = pet.stage
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
