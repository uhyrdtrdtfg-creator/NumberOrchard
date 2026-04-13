import SwiftUI
import SwiftData

/// Full-screen edit mode for placing decorations on the home orchard:
///   • Drag an item to reposition (positionX/Y updated as 0-1 fractions of the band).
///   • Tap an item to toggle a delete (×) badge — tap the badge to remove.
struct OrchardEditView: View {
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [ChildProfile]
    @State private var selectedId: PersistentIdentifier?

    private var profile: ChildProfile? { profiles.first }
    private var placed: [CollectedDecoration] {
        (profile?.decorations ?? [])
            .filter { $0.isPlaced }
            .sorted { $0.positionY < $1.positionY }
    }

    var body: some View {
        ZStack {
            CartoonSkyBackground()
            CartoonGround(height: 280)

            GeometryReader { geo in
                let band = decorationBand(in: geo.size)

                // Draggable decorations
                ForEach(placed) { deco in
                    if let item = DecorationCatalog.item(id: deco.itemId) {
                        decorationRow(deco: deco, item: item, band: band)
                    }
                }

                // Tap on empty area deselects
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { selectedId = nil }
                    .zIndex(-1)
            }

            VStack {
                topBar
                Spacer()
                hintBar
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func decorationRow(deco: CollectedDecoration, item: DecorationItem, band: DecorationBand) -> some View {
        let position = CGPoint(
            x: deco.positionX * band.width,
            y: band.top + deco.positionY * band.height
        )
        let isSelected = selectedId == deco.persistentModelID

        ZStack {
            PlacedDecorationView(
                emoji: item.emoji,
                size: item.category.placedSize,
                wiggle: !isSelected
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .overlay(alignment: .top) {
                if isSelected {
                    Button {
                        remove(deco)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(CartoonColor.coral)
                                .frame(width: 38, height: 38)
                            Circle()
                                .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                                .frame(width: 38, height: 38)
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel("删除 \(item.name)")
                    .offset(y: -item.category.placedSize * 0.7)
                }
            }
        }
        .position(position)
        .zIndex(orchardDepthZ(for: deco.positionY) + (isSelected ? 1000 : 0))
        .onTapGesture {
            selectedId = (selectedId == deco.persistentModelID) ? nil : deco.persistentModelID
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    selectedId = deco.persistentModelID
                    updatePosition(for: deco, to: value.location, band: band)
                }
                .onEnded { _ in
                    try? modelContext.save()
                }
        )
    }

    private var topBar: some View {
        HStack {
            CartoonCircleIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: "完成",
                action: onDismiss
            )
            Spacer()
            Text("🏡 摆放果园")
                .cartoonTitle(size: CartoonDimensions.fontTitle)
            Spacer()
            // Invisible spacer to balance the back button
            Color.clear.frame(width: CartoonDimensions.iconButtonHitSize, height: CartoonDimensions.iconButtonHitSize)
        }
        .padding(.horizontal, CartoonDimensions.spacingLarge)
        .padding(.top, 20)
    }

    private var hintBar: some View {
        Text(placed.isEmpty
             ? "还没有装饰,先去商店买一些吧～"
             : "拖动移动 · 点击出现 ✕ 可删除")
            .cartoonBody(size: CartoonDimensions.fontBodyLarge)
            .foregroundStyle(.white)
            .padding(.horizontal, CartoonDimensions.spacingMedium)
            .padding(.vertical, CartoonDimensions.spacingSmall)
            .background(
                Capsule()
                    .fill(CartoonColor.ink.opacity(0.75))
            )
            .padding(.bottom, 40)
    }

    // MARK: - Placement helpers

    private struct DecorationBand {
        let width: CGFloat
        let top: CGFloat
        let height: CGFloat
    }

    private func decorationBand(in size: CGSize) -> DecorationBand {
        DecorationBand(
            width: size.width,
            top: size.height * 0.55,
            height: size.height * 0.18
        )
    }

    private func updatePosition(for deco: CollectedDecoration, to point: CGPoint, band: DecorationBand) {
        guard band.width > 0, band.height > 0 else { return }
        let nx = min(max(point.x / band.width, 0.05), 0.95)
        let ny = min(max((point.y - band.top) / band.height, 0.0), 1.0)
        deco.positionX = nx
        deco.positionY = ny
    }

    private func remove(_ deco: CollectedDecoration) {
        selectedId = nil
        profile?.decorations.removeAll { $0.id == deco.id }
        modelContext.delete(deco)
        try? modelContext.save()
    }
}
