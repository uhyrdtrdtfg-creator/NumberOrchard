import SwiftUI
import SwiftData

struct ExplorationMapView: View {
    let onDismiss: () -> Void
    let onStartStation: (Station) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var viewModel: ExplorationMapViewModel?
    @State private var selectedStation: Station?

    /// Multiplier for scrollable vertical space. Larger = more spacing between stations.
    private let heightMultiplier: CGFloat = 3.2

    var body: some View {
        ZStack {
            CartoonSkyBackground()

            if let viewModel {
                mapContent(viewModel: viewModel)
            }

            // Top bar (floats above scroll)
            VStack {
                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        ZStack {
                            Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 68, height: 68).offset(y: 4)
                            Circle().fill(CartoonColor.paper).frame(width: 68, height: 68)
                            Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5).frame(width: 68, height: 68)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(CartoonColor.text)
                        }
                        .frame(width: 72, height: 72)
                        .contentShape(Circle())
                    }
                    .accessibilityLabel("返回")
                    Spacer()
                    CartoonHUD(icon: "star.fill", value: "\(profile.stars)", tint: CartoonColor.gold, accessibilityLabel: "星星 \(profile.stars)")
                    CartoonHUD(icon: "leaf.fill", value: "\(profile.seeds)", tint: CartoonColor.leaf, accessibilityLabel: "种子 \(profile.seeds)")
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                Spacer()
            }
            .allowsHitTesting(true)
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
            let contentHeight = geo.size.height * heightMultiplier

            ScrollView([.vertical], showsIndicators: false) {
                ZStack {
                    // Paths
                    Canvas { ctx, size in
                        for station in MapCatalog.stations {
                            for unlockId in station.unlocks where unlockId != "end" {
                                if let target = MapCatalog.station(id: unlockId) {
                                    var path = Path()
                                    path.move(to: CGPoint(x: station.mapX * size.width, y: station.mapY * size.height))
                                    path.addLine(to: CGPoint(x: target.mapX * size.width, y: target.mapY * size.height))
                                    let completed = viewModel.completedStationIds.contains(station.id)
                                    // Outer ink outline
                                    ctx.stroke(path,
                                              with: .color(CartoonColor.ink.opacity(0.7)),
                                              style: StrokeStyle(lineWidth: 34, lineCap: .round, lineJoin: .round))
                                    // Colored fill
                                    ctx.stroke(path,
                                              with: .color(completed
                                                           ? CartoonColor.gold
                                                           : Color(red: 0.88, green: 0.80, blue: 0.62)),
                                              style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))
                                    // Highlight band (only on completed)
                                    if completed {
                                        ctx.stroke(path,
                                                  with: .color(Color.white.opacity(0.4)),
                                                  style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round,
                                                                     dash: [4, 14]))
                                    } else {
                                        ctx.stroke(path,
                                                  with: .color(Color.white.opacity(0.5)),
                                                  style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round,
                                                                     dash: [10, 12]))
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: contentHeight)

                    // End station marker at top
                    if viewModel.isUnlocked(MapCatalog.endStationId) {
                        endStationMarker
                            .position(x: geo.size.width / 2, y: 80)
                    } else {
                        endStationMarker
                            .grayscale(1.0)
                            .opacity(0.4)
                            .position(x: geo.size.width / 2, y: 80)
                    }

                    // Station nodes
                    ForEach(MapCatalog.stations) { station in
                        StationNodeView(
                            station: station,
                            stars: viewModel.stars(for: station.id),
                            isUnlocked: viewModel.isUnlocked(station.id)
                        )
                        .position(
                            x: station.mapX * geo.size.width,
                            y: station.mapY * contentHeight
                        )
                        .onTapGesture {
                            selectedStation = station
                        }
                    }
                }
                .frame(width: geo.size.width, height: contentHeight)
                .padding(.top, 100) // Space for top bar
            }
        }
    }

    private var endStationMarker: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(0.9)).frame(width: 120, height: 120).offset(y: 5)
                Circle().fill(CartoonColor.gold).frame(width: 120, height: 120)
                Circle().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 4).frame(width: 120, height: 120)
                Text("🏆").font(.system(size: 60)).accessibilityHidden(true)
            }
            Text("终点果园")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(CartoonColor.paper))
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("终点果园")
    }
}

struct StationNodeView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool

    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCTA: Bool { isUnlocked && stars == 0 }
    private let size: CGFloat = 100

    /// Color of the station disc surface based on region (L1-L6).
    private var regionColor: Color {
        switch station.level {
        case .seed:      return Color(red: 0.95, green: 0.85, blue: 0.55)  // pale yellow
        case .sprout:    return Color(red: 0.80, green: 0.92, blue: 0.55)  // lime
        case .smallTree: return Color(red: 0.70, green: 0.90, blue: 0.80)  // mint
        case .bigTree:   return Color(red: 0.70, green: 0.85, blue: 1.00)  // sky
        case .bloom:     return Color(red: 0.90, green: 0.72, blue: 1.00)  // lavender
        case .harvest:   return Color(red: 1.00, green: 0.70, blue: 0.70)  // coral
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Pulsing glow ring for current-available
                if isCTA && !reduceMotion {
                    Circle()
                        .stroke(CartoonColor.gold, lineWidth: 8)
                        .frame(width: size + 22, height: size + 22)
                        .scaleEffect(pulsing ? 1.2 : 1.0)
                        .opacity(pulsing ? 0.0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                }

                // Shadow (offset, fully opaque ink)
                Circle()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: size, height: size)
                    .offset(y: 5)

                // Surface (SOLID color — no transparency so shadow doesn't bleed)
                Circle()
                    .fill(isUnlocked ? regionColor : Color(red: 0.82, green: 0.76, blue: 0.68))
                    .frame(width: size, height: size)

                // Outline
                Circle()
                    .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 4)
                    .frame(width: size, height: size)

                // Emoji
                Text(station.emoji)
                    .font(.system(size: 54))
                    .saturation(isUnlocked ? 1 : 0.3)
                    .opacity(isUnlocked ? 1 : 0.6)
                    .scaleEffect(reduceMotion ? 1.0 : (isCTA && pulsing ? 1.08 : 1.0))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)

                // Lock overlay for locked stations
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(CartoonColor.ink.opacity(0.55))
                        .offset(y: 2)
                }
            }
            .onAppear { pulsing = true }

            // Name label
            Text(station.displayName)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(isUnlocked ? CartoonColor.text : CartoonColor.text.opacity(0.5))
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(CartoonColor.paper)
                )
                .overlay(
                    Capsule()
                        .stroke(CartoonColor.ink.opacity(0.6), lineWidth: 2)
                )

            // Stars
            if stars > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(i < stars ? CartoonColor.gold : CartoonColor.ink.opacity(0.2))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isUnlocked ? "\(station.displayName),\(stars) 颗星" : "\(station.displayName),未解锁")
        .accessibilityAddTraits(.isButton)
    }
}
