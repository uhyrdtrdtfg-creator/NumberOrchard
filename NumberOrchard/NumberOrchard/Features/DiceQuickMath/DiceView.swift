import SwiftUI

/// A single cartoon die. Renders 1–6 as pip patterns. Supports a
/// `rolling` mode that cycles through random faces for visual excitement.
struct DiceView: View {
    let face: Int             // 1-6, displayed when not rolling
    let rolling: Bool         // when true, cycle faces rapidly
    var size: CGFloat = 96

    @State private var displayFace: Int = 1
    @State private var rollerTask: Task<Void, Never>? = nil

    // Per-axis accumulated rotation in degrees. When `rolling` flips on, a
    // Task drives these up by random increments every frame, giving the
    // die a 3D tumble look via `rotation3DEffect`. SwiftUI smoothly
    // interpolates each step, so the cube really appears to spin.
    @State private var rotX: Double = 0
    @State private var rotY: Double = 0
    @State private var rotZ: Double = 0

    var body: some View {
        ZStack {
            // Shadow — stays flat on the ground, doesn't rotate with die.
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(CartoonColor.ink.opacity(0.85))
                .frame(width: size, height: size * 0.35)
                .blur(radius: 2)
                .offset(y: size * 0.55)
                .opacity(rolling ? 0.35 : 0.6)

            // Cube face — the content that tumbles.
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(Color.white)
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: size * 0.22)
                    .stroke(CartoonColor.ink.opacity(0.85), lineWidth: size * 0.04)
                    .frame(width: size, height: size)
                pipsLayer(face: rolling ? displayFace : face, size: size)
            }
            .rotation3DEffect(.degrees(rotX), axis: (1, 0, 0))
            .rotation3DEffect(.degrees(rotY), axis: (0, 1, 0))
            .rotation3DEffect(.degrees(rotZ), axis: (0, 0, 1))
            .offset(y: rolling ? -size * 0.05 : 0)
        }
        .animation(.linear(duration: 0.08), value: rotX)
        .animation(.linear(duration: 0.08), value: rotY)
        .animation(.linear(duration: 0.08), value: rotZ)
        .onChange(of: rolling, initial: true) { _, newValue in
            rollerTask?.cancel()
            if newValue {
                rollerTask = Task { @MainActor in
                    while !Task.isCancelled {
                        // Tumble on all three axes at different rates so the
                        // rotation never falls into a visually flat loop.
                        rotX += Double.random(in: 40...90)
                        rotY += Double.random(in: 40...90)
                        rotZ += Double.random(in: 20...40)
                        displayFace = Int.random(in: 1...6)
                        try? await Task.sleep(nanoseconds: 80_000_000)
                    }
                }
            } else {
                rollerTask = nil
                displayFace = face
                // Settle back to upright so the final face reads cleanly.
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    rotX = 0
                    rotY = 0
                    rotZ = 0
                }
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
