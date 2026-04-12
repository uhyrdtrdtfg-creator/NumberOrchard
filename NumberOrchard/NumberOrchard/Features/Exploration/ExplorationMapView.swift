import SwiftUI
import SwiftData

struct ExplorationMapView: View {
    let onDismiss: () -> Void
    let onStartStation: (Station) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: ExplorationMapViewModel?
    @State private var selectedStation: Station?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 0.95),
                    Color(red: 0.85, green: 0.95, blue: 0.75),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if let viewModel {
                mapContent(viewModel: viewModel)
            }

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .padding()
                            .background(.thinMaterial, in: Circle())
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Label("\(profile.stars)", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                        Label("\(profile.seeds)", systemImage: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.title3)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            viewModel = ExplorationMapViewModel(profile: profile)
        }
        .sheet(item: $selectedStation) { station in
            StationDetailView(
                station: station,
                stars: viewModel?.stars(for: station.id) ?? 0,
                isUnlocked: viewModel?.isUnlocked(station.id) ?? false,
                onStart: {
                    selectedStation = nil
                    onStartStation(station)
                },
                onDismiss: { selectedStation = nil }
            )
        }
    }

    private var profile: ChildProfile {
        profiles.first ?? ChildProfile(name: "小果农")
    }

    private func mapContent(viewModel: ExplorationMapViewModel) -> some View {
        GeometryReader { geo in
            ScrollView([.vertical]) {
                ZStack {
                    Canvas { ctx, size in
                        for station in MapCatalog.stations {
                            for unlockId in station.unlocks where unlockId != "end" {
                                if let target = MapCatalog.station(id: unlockId) {
                                    var path = Path()
                                    path.move(to: CGPoint(x: station.mapX * size.width, y: station.mapY * size.height))
                                    path.addLine(to: CGPoint(x: target.mapX * size.width, y: target.mapY * size.height))
                                    let completed = viewModel.completedStationIds.contains(station.id)
                                    ctx.stroke(path,
                                              with: .color(completed ? .green : .gray.opacity(0.4)),
                                              lineWidth: 4)
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height * 2)

                    ForEach(MapCatalog.stations) { station in
                        StationNodeView(
                            station: station,
                            stars: viewModel.stars(for: station.id),
                            isUnlocked: viewModel.isUnlocked(station.id)
                        )
                        .position(
                            x: station.mapX * geo.size.width,
                            y: station.mapY * (geo.size.height * 2)
                        )
                        .onTapGesture {
                            selectedStation = station
                        }
                    }

                    if viewModel.isUnlocked(MapCatalog.endStationId) {
                        VStack(spacing: 8) {
                            Text("⭐🌈🏆")
                                .font(.system(size: 90))
                            Text("终点果园")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .position(
                            x: 0.5 * geo.size.width,
                            y: 0.01 * (geo.size.height * 2)
                        )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 2)
            }
        }
    }
}

struct StationNodeView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 110, height: 110)
                    .shadow(radius: 4)
                Text(station.emoji)
                    .font(.system(size: 60))
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }
            Text(station.displayName)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(isUnlocked ? .primary : .secondary)

            if stars > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.body)
                            .foregroundStyle(i < stars ? .orange : .gray)
                    }
                }
            }
        }
        .scaleEffect(isUnlocked && stars == 0 ? 1.05 : 1.0)
    }
}
