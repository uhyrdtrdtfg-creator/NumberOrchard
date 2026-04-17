import SwiftUI

/// A single cartoon die. Renders 1–6 as pip patterns. Supports a
/// `rolling` mode that cycles through random faces for visual excitement.
struct DiceView: View {
    let face: Int             // 1-6, displayed when not rolling
    let rolling: Bool         // when true, cycle faces rapidly
    var size: CGFloat = 96

    @State private var displayFace: Int = 1
    @State private var rollerTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(CartoonColor.ink.opacity(0.9))
                .frame(width: size, height: size)
                .offset(y: 4)
            // Face
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color.white)
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: size * 0.22)
                .stroke(CartoonColor.ink.opacity(0.85), lineWidth: size * 0.04)
                .frame(width: size, height: size)

            // Pips — drawn in a 3x3 grid whose cells are used per face.
            pipsLayer(face: rolling ? displayFace : face, size: size)
        }
        .rotationEffect(.degrees(rolling ? 8 : 0))
        .animation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true),
                   value: rolling)
        .onChange(of: rolling, initial: true) { _, newValue in
            rollerTask?.cancel()
            if newValue {
                rollerTask = Task { @MainActor in
                    while !Task.isCancelled {
                        displayFace = Int.random(in: 1...6)
                        try? await Task.sleep(nanoseconds: 80_000_000)
                    }
                }
            } else {
                rollerTask = nil
                displayFace = face
            }
        }
    }

    @ViewBuilder
    private func pipsLayer(face: Int, size: CGFloat) -> some View {
        let positions = pipPositions(for: face)
        let pipRadius = size * 0.09
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(CartoonColor.ink)
                    .frame(width: pipRadius * 2, height: pipRadius * 2)
                    .offset(x: pos.x * size * 0.26, y: pos.y * size * 0.26)
            }
        }
    }

    /// Unit-cell positions for each die face, in (-1, 0, 1) grid units.
    private func pipPositions(for face: Int) -> [CGPoint] {
        let tl = CGPoint(x: -1, y: -1), tr = CGPoint(x: 1, y: -1)
        let ml = CGPoint(x: -1, y: 0), mr = CGPoint(x: 1, y: 0)
        let bl = CGPoint(x: -1, y: 1), br = CGPoint(x: 1, y: 1)
        let center = CGPoint.zero
        switch face {
        case 1: return [center]
        case 2: return [tl, br]
        case 3: return [tl, center, br]
        case 4: return [tl, tr, bl, br]
        case 5: return [tl, tr, center, bl, br]
        case 6: return [tl, ml, bl, tr, mr, br]
        default: return [center]
        }
    }
}
