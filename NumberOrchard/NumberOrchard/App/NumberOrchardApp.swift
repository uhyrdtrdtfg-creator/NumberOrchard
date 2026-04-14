import SwiftUI
import SwiftData

@main
struct NumberOrchardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChildProfile.self,
            LearningSession.self,
            QuestionRecord.self,
            StationProgress.self,
            CollectedDecoration.self,
            CollectedFruit.self,
            CollectedNoom.self,
            PetProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
        .modelContainer(sharedModelContainer)
    }
}
