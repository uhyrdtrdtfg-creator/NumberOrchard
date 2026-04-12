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
            CartoonSkyBackground()

            if let viewModel {
                mapContent(viewModel: viewModel)
            }

            VStack {
                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(CartoonColor.ink.opacity(0.9))
                                .frame(width: 60, height: 60)
                                .offset(y: 4)
                            Circle()
                                .fill(CartoonColor.paper)
                                .frame(width: 60, height: 60)
                            Circle()
                                .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
                                .frame(width: 60, height: 60)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 26, weight: .black))
                                .foregroundStyle(CartoonColor.text)
                        }
                    }
                    Spacer()
                    CartoonHUD(icon: "star.fill", value: "\(profile.stars)", tint: CartoonColor.gold)
                    CartoonHUD(icon: "leaf.fill", value: "\(profile.seeds)", tint: CartoonColor.leaf)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
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
                                    // Outer stroke (darker border for contrast)
                                    ctx.stroke(path,
                                              with: .color(completed ? .green.opacity(0.9) : .brown.opacity(0.5)),
                                              style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round))
                                    // Inner stroke (lighter fill on top)
                                    ctx.stroke(path,
                                              with: .color(completed ? .yellow.opacity(0.8) : .white.opacity(0.7)),
                                              style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round,
                                                                 dash: completed ? [] : [12, 10]))
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

    @State private var pulsing = false

    private var isCTA: Bool { isUnlocked && stars == 0 }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if isCTA {
                    Circle()
                        .stroke(CartoonColor.gold, lineWidth: 8)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulsing ? 1.2 : 1.0)
                        .opacity(pulsing ? 0.0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                }

                // Shadow circle
                Circle()
                    .fill(CartoonColor.ink.opacity(0.9))
                    .frame(width: 118, height: 118)
                    .offset(y: 5)

                // Surface circle
                Circle()
                    .fill(isUnlocked ? CartoonColor.paper : Color.gray.opacity(0.4))
                    .frame(width: 118, height: 118)

                // Ink outline
                Circle()
                    .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 4)
                    .frame(width: 118, height: 118)

                Text(station.emoji)
                    .font(.system(size: 62))
                    .opacity(isUnlocked ? 1.0 : 0.3)
                    .scaleEffect(isCTA && pulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
            }
            .onAppear { pulsing = true }

            Text(station.displayName)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(isUnlocked ? CartoonColor.text : CartoonColor.text.opacity(0.4))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(CartoonColor.paper.opacity(isUnlocked ? 0.9 : 0.5)))

            if stars > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(i < stars ? CartoonColor.gold : CartoonColor.ink.opacity(0.2))
                    }
                }
            }
        }
        .scaleEffect(isUnlocked && stars == 0 ? 1.05 : 1.0)
    }
}
