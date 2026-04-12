import SwiftUI

// MARK: - Cartoon Color Palette

enum CartoonColor {
    /// Sky top (cream)
    static let skyTop      = Color(red: 1.00, green: 0.96, blue: 0.82)
    /// Sky bottom (peach)
    static let skyBottom   = Color(red: 1.00, green: 0.84, blue: 0.62)
    /// Grass top
    static let grassTop    = Color(red: 0.62, green: 0.84, blue: 0.45)
    /// Grass bottom
    static let grassBottom = Color(red: 0.40, green: 0.66, blue: 0.30)
    /// Dark outline (like comic-book ink)
    static let ink         = Color(red: 0.20, green: 0.12, blue: 0.08)
    /// Primary brown text
    static let text        = Color(red: 0.32, green: 0.20, blue: 0.12)
    /// Paper cream for panels
    static let paper       = Color(red: 1.00, green: 0.98, blue: 0.91)
    /// Gold accent
    static let gold        = Color(red: 1.00, green: 0.76, blue: 0.20)
    /// Coral
    static let coral       = Color(red: 1.00, green: 0.53, blue: 0.44)
    /// Sky blue
    static let sky         = Color(red: 0.42, green: 0.75, blue: 1.00)
    /// Leaf green
    static let leaf        = Color(red: 0.32, green: 0.75, blue: 0.42)
    /// Berry purple
    static let berry       = Color(red: 0.70, green: 0.40, blue: 0.90)
}

// MARK: - Shared backgrounds

struct CartoonSkyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [CartoonColor.skyTop, CartoonColor.skyBottom],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Cartoon ground with rounded hill silhouette. Use as a bottom overlay on a sky.
struct CartoonGround: View {
    var height: CGFloat = 260

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .top) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 60))
                        path.addQuadCurve(
                            to: CGPoint(x: geo.size.width, y: 60),
                            control: CGPoint(x: geo.size.width / 2, y: -20)
                        )
                        path.addLine(to: CGPoint(x: geo.size.width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [CartoonColor.grassTop, CartoonColor.grassBottom],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 60))
                            path.addQuadCurve(
                                to: CGPoint(x: geo.size.width, y: 60),
                                control: CGPoint(x: geo.size.width / 2, y: -20)
                            )
                        }
                        .stroke(CartoonColor.ink.opacity(0.25), lineWidth: 3)
                    )
                    .frame(height: height)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Panel (like a cut-out sticker)

struct CartoonPanel<Content: View>: View {
    var fill: Color = CartoonColor.paper
    var stroke: Color = CartoonColor.ink.opacity(0.8)
    var cornerRadius: CGFloat = 32
    var strokeWidth: CGFloat = 4
    let content: () -> Content

    init(
        fill: Color = CartoonColor.paper,
        stroke: Color = CartoonColor.ink.opacity(0.8),
        cornerRadius: CGFloat = 32,
        strokeWidth: CGFloat = 4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.fill = fill
        self.stroke = stroke
        self.cornerRadius = cornerRadius
        self.strokeWidth = strokeWidth
        self.content = content
    }

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(stroke, lineWidth: strokeWidth)
            )
            .shadow(color: CartoonColor.ink.opacity(0.35), radius: 0, x: 0, y: 6)
    }
}

// MARK: - Chunky cartoon button

struct CartoonButton<Content: View>: View {
    var tint: Color
    var shadowOffset: CGFloat = 6
    var cornerRadius: CGFloat = 28
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var action: () -> Void
    let content: () -> Content

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        tint: Color,
        shadowOffset: CGFloat = 6,
        cornerRadius: CGFloat = 28,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tint = tint
        self.shadowOffset = shadowOffset
        self.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.content = content
    }

    var body: some View {
        Button(action: {
            if reduceMotion {
                action()
                return
            }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    pressed = false
                }
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(tint.opacity(0.85).mix(with: CartoonColor.ink, by: 0.4))
                    .offset(y: shadowOffset)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [tint.mix(with: .white, by: 0.25), tint],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(CartoonColor.ink.opacity(0.8), lineWidth: 4)
                    )

                content()
            }
            .offset(y: pressed ? shadowOffset : 0)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? "")
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Helper

extension Color {
    /// Simple color mixing for cartoon effects.
    func mix(with color: Color, by fraction: Double) -> Color {
        let f = max(0, min(1, fraction))
        let c1 = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let c2 = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        let r = c1[0] * (1 - f) + c2[0] * f
        let g = c1[1] * (1 - f) + c2[1] * f
        let b = c1[2] * (1 - f) + c2[2] * f
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Chunky HUD pill

struct CartoonHUD: View {
    let icon: String
    let value: String
    let tint: Color
    var accessibilityLabel: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Capsule().fill(CartoonColor.ink.opacity(0.9)).offset(y: 4)
                Capsule().fill(CartoonColor.paper)
                Capsule().stroke(CartoonColor.ink.opacity(0.8), lineWidth: 3.5)
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel ?? "\(value)"))
    }
}

// MARK: - Rounded chunky text style

extension View {
    func cartoonTitle(size: CGFloat = 36) -> some View {
        self.font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(CartoonColor.text)
    }

    func cartoonBody(size: CGFloat = 20) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(CartoonColor.text)
    }
}
