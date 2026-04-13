import SwiftUI
import SwiftData

struct ExplorationMapView: View {
    let onDismiss: () -> Void
    let onStartStation: (Station) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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

            VStack {
                ExplorationMapTopBar(
                    stars: profile.stars,
                    seeds: profile.seeds,
                    onDismiss: onDismiss
                )
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

            ScrollViewReader { proxy in
                ScrollView([.vertical], showsIndicators: false) {
                    ZStack {
                        MapPathsCanvas(
                            completedIds: viewModel.completedStationIds,
                            geoSize: CGSize(width: geo.size.width, height: contentHeight)
                        )
                        .frame(width: geo.size.width, height: contentHeight)

                        EndStationMarker(
                            unlocked: viewModel.isUnlocked(MapCatalog.endStationId)
                        )
                        .position(x: geo.size.width / 2, y: 80)

                        ForEach(MapCatalog.stations) { station in
                            StationNodeView(
                                station: station,
                                stars: viewModel.stars(for: station.id),
                                isUnlocked: viewModel.isUnlocked(station.id)
                            )
                            .id(station.id)
                            .position(
                                x: station.mapX * geo.size.width,
                                y: station.mapY * contentHeight
                            )
                            .onTapGesture { selectedStation = station }
                        }
                    }
                    .frame(width: geo.size.width, height: contentHeight)
                    .padding(.top, 100)
                }
                .onAppear {
                    let targetId = viewModel.recommendedStationId
                    guard !targetId.isEmpty else { return }
                    // Give layout a moment to settle before scrolling.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.6)) {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Top bar

private struct ExplorationMapTopBar: View {
    let stars: Int
    let seeds: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: CartoonDimensions.spacingSmall) {
            CartoonCircleIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: "返回",
                action: onDismiss
            )
            Spacer()
            CartoonHUD(icon: "star.fill", value: "\(stars)", tint: CartoonColor.gold, accessibilityLabel: "星星 \(stars)")
            CartoonHUD(icon: "leaf.fill", value: "\(seeds)", tint: CartoonColor.leaf, accessibilityLabel: "种子 \(seeds)")
        }
        .padding(.horizontal, CartoonDimensions.spacingLarge)
        .padding(.top, 20)
    }
}

// MARK: - Paths canvas

private struct MapPathsCanvas: View {
    let completedIds: Set<String>
    let geoSize: CGSize

    var body: some View {
        Canvas { ctx, size in
            for station in MapCatalog.stations {
                for unlockId in station.unlocks where unlockId != "end" {
                    if let target = MapCatalog.station(id: unlockId) {
                        var path = Path()
                        path.move(to: CGPoint(x: station.mapX * size.width, y: station.mapY * size.height))
                        path.addLine(to: CGPoint(x: target.mapX * size.width, y: target.mapY * size.height))
                        let completed = completedIds.contains(station.id)
                        ctx.stroke(path,
                                  with: .color(CartoonColor.ink.opacity(0.7)),
                                  style: StrokeStyle(lineWidth: 34, lineCap: .round, lineJoin: .round))
                        ctx.stroke(path,
                                  with: .color(completed ? CartoonColor.gold : CartoonColor.lockedPath),
                                  style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))
                        if completed {
                            ctx.stroke(path,
                                      with: .color(Color.white.opacity(0.4)),
                                      style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round, dash: [4, 14]))
                        } else {
                            ctx.stroke(path,
                                      with: .color(Color.white.opacity(0.5)),
                                      style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [10, 12]))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - End station marker

private struct EndStationMarker: View {
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                    .frame(width: 120, height: 120)
                    .offset(y: 5)
                Circle().fill(CartoonColor.gold).frame(width: 120, height: 120)
                Circle().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeHeavy)
                    .frame(width: 120, height: 120)
                Text("🏆").font(.system(size: 60)).accessibilityHidden(true)
            }
            Text("终点果园")
                .cartoonTitle(size: CartoonDimensions.fontBody)
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(CartoonColor.paper))
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeRegular))
        }
        .grayscale(unlocked ? 0 : 1)
        .opacity(unlocked ? 1 : 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(unlocked ? "终点果园,已解锁" : "终点果园,未解锁")
    }
}

// MARK: - Station node

struct StationNodeView: View {
    let station: Station
    let stars: Int
    let isUnlocked: Bool

    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCTA: Bool { isUnlocked && stars == 0 }
    private let size: CGFloat = 100

    private var regionColor: Color {
        switch station.level {
        case .seed:      return CartoonColor.regionSeed
        case .sprout:    return CartoonColor.regionSprout
        case .smallTree: return CartoonColor.regionSmallTree
        case .bigTree:   return CartoonColor.regionBigTree
        case .bloom:     return CartoonColor.regionBloom
        case .harvest:   return CartoonColor.regionHarvest
        }
    }

    /// Symbol overlay to help colorblind users distinguish regions.
    private var regionSymbol: String {
        switch station.level {
        case .seed:      return "circle.fill"
        case .sprout:    return "leaf.fill"
        case .smallTree: return "triangle.fill"
        case .bigTree:   return "square.fill"
        case .bloom:     return "diamond.fill"
        case .harvest:   return "star.fill"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isCTA && !reduceMotion {
                    Circle()
                        .stroke(CartoonColor.gold, lineWidth: 8)
                        .frame(width: size + 22, height: size + 22)
                        .scaleEffect(pulsing ? 1.2 : 1.0)
                        .opacity(pulsing ? 0.0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                }

                Circle()
                    .fill(CartoonColor.ink.opacity(0.85))
                    .frame(width: size, height: size)
                    .offset(y: 5)

                Circle()
                    .fill(isUnlocked ? regionColor : CartoonColor.lockedStation)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeHeavy)
                    .frame(width: size, height: size)

                // Region symbol watermark (top-right corner)
                if isUnlocked {
                    Image(systemName: regionSymbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CartoonColor.ink.opacity(0.35))
                        .offset(x: size/2 - 16, y: -size/2 + 16)
                }

                Text(station.emoji)
                    .font(.system(size: 54))
                    .saturation(isUnlocked ? 1 : 0.3)
                    .opacity(isUnlocked ? 1 : 0.6)
                    .scaleEffect(reduceMotion ? 1.0 : (isCTA && pulsing ? 1.08 : 1.0))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(CartoonColor.ink.opacity(0.55))
                        .offset(y: 2)
                }
            }
            .onAppear { pulsing = true }

            Text(station.displayName)
                .font(.system(size: CartoonDimensions.fontCaption, weight: .black, design: .rounded))
                .foregroundStyle(isUnlocked ? CartoonColor.text : CartoonColor.text.opacity(0.5))
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Capsule().fill(CartoonColor.paper))
                .overlay(Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStrokeLight), lineWidth: CartoonDimensions.strokeThin))

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

#Preview {
    ExplorationMapView(onDismiss: {}, onStartStation: { _ in })
        .modelContainer(for: ChildProfile.self, inMemory: true)
}
