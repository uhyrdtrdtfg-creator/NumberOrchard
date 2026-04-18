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
    /// Check-in / soft paper variant (slightly warmer)
    static let paperWarm   = Color(red: 1.00, green: 0.97, blue: 0.88)
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
    /// Wood brown (for pivots, tracks, barriers)
    static let wood        = Color(red: 0.55, green: 0.38, blue: 0.22)

    // MARK: Map regions
    static let regionSeed      = Color(red: 0.95, green: 0.85, blue: 0.55) // pale yellow
    static let regionSprout    = Color(red: 0.80, green: 0.92, blue: 0.55) // lime
    static let regionSmallTree = Color(red: 0.70, green: 0.90, blue: 0.80) // mint
    static let regionBigTree   = Color(red: 0.70, green: 0.85, blue: 1.00) // sky
    static let regionBloom     = Color(red: 0.90, green: 0.72, blue: 1.00) // lavender
    static let regionHarvest   = Color(red: 1.00, green: 0.70, blue: 0.70) // coral

    /// Locked path fill (desaturated tan)
    static let lockedPath    = Color(red: 0.88, green: 0.80, blue: 0.62)
    /// Locked station surface (desaturated tan)
    static let lockedStation = Color(red: 0.82, green: 0.76, blue: 0.68)

    /// Overlay dark backdrop (for modals, eye-care)
    static let overlayDark   = Color.black.opacity(0.7)
    /// Overlay medium (for parental gate)
    static let overlayMedium = Color.black.opacity(0.6)
}

// MARK: - Cartoon Dimensions

enum CartoonDimensions {
    // Spacing
    static let spacingTight: CGFloat = 8
    static let spacingSmall: CGFloat = 12
    static let spacingRegular: CGFloat = 16
    static let spacingMedium: CGFloat = 22
    static let spacingLarge: CGFloat = 30

    // Corner radii
    static let radiusSmall: CGFloat = 18
    static let radiusMedium: CGFloat = 24
    static let radiusLarge: CGFloat = 28
    static let radiusXLarge: CGFloat = 32

    // Stroke widths
    static let strokeThin: CGFloat = 2
    static let strokeRegular: CGFloat = 3
    static let strokeBold: CGFloat = 3.5
    static let strokeHeavy: CGFloat = 4

    // Shadow offsets (for "hard drop shadow" look)
    static let shadowOffsetSmall: CGFloat = 3
    static let shadowOffsetRegular: CGFloat = 4
    static let shadowOffsetLarge: CGFloat = 6

    // Icon button sizes (circle-icon buttons like back/gear)
    static let iconButtonSize: CGFloat = 68
    static let iconButtonHitSize: CGFloat = 72
    static let iconButtonIconSize: CGFloat = 28

    // Font sizes
    static let fontCaption: CGFloat = 15
    static let fontBodySmall: CGFloat = 18
    static let fontBody: CGFloat = 20
    static let fontBodyLarge: CGFloat = 22
    static let fontTitleSmall: CGFloat = 26
    static let fontTitle: CGFloat = 32
    static let fontTitleLarge: CGFloat = 42
    static let fontTitleHuge: CGFloat = 56

    // Common emoji-in-circle sizes
    static let circleBadgeSmall: CGFloat = 100
    static let circleBadgeMedium: CGFloat = 130
    static let circleBadgeLarge: CGFloat = 160
    static let circleBadgeHuge: CGFloat = 220

    static let inkOpacityShadow: Double = 0.9
    static let inkOpacityStroke: Double = 0.8
    static let inkOpacityStrokeLight: Double = 0.6
}

// MARK: - Shared backgrounds

struct CartoonSkyBackground: View {
    /// When true, adds drifting clouds and a sun accent. Defaults to true so
    /// every existing caller gets the richer background for free. Pass `false`
    /// for tight/modal contexts where decoration would compete with content.
    var decorations: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CartoonColor.skyTop, CartoonColor.skyBottom],
                startPoint: .top, endPoint: .bottom
            )
            if decorations {
                CartoonSkyDecorations()
            }
        }
        .ignoresSafeArea()
    }
}

/// Decorative sky layer: a soft sun + three drifting clouds at different
/// depths. Pure cosmetic, ignores hit-testing so it never steals taps.
private struct CartoonSkyDecorations: View {
    @State private var drift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sun — top-right, behind clouds.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.85), CartoonColor.gold.opacity(0.35), .clear],
                            center: .center, startRadius: 10, endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.12)

                cloud(size: 160, opacity: 0.85)
                    .position(x: geo.size.width * 0.18 + drift * 40,
                              y: geo.size.height * 0.14)
                cloud(size: 110, opacity: 0.75)
                    .position(x: geo.size.width * 0.70 - drift * 25,
                              y: geo.size.height * 0.22)
                // Third cloud used to sit at y=0.55, where it overlapped
                // the Home orchard decoration band. Keep all clouds in
                // the upper third so any scene with ground decor stays
                // unobscured.
                cloud(size: 140, opacity: 0.65)
                    .position(x: geo.size.width * 0.45 + drift * 30,
                              y: geo.size.height * 0.32)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    drift = 1
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Puffy cloud built from 3 overlapping circles.
    private func cloud(size: CGFloat, opacity: Double) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size * 0.70, height: size * 0.70)
                .offset(x: -size * 0.22, y: size * 0.08)
            Circle()
                .fill(.white)
                .frame(width: size * 0.85, height: size * 0.85)
            Circle()
                .fill(.white)
                .frame(width: size * 0.60, height: size * 0.60)
                .offset(x: size * 0.28, y: size * 0.06)
        }
        .frame(width: size, height: size * 0.6)
        .opacity(opacity)
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
                        .stroke(CartoonColor.ink.opacity(0.25), lineWidth: CartoonDimensions.strokeRegular)
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
    var stroke: Color = CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke)
    var cornerRadius: CGFloat = CartoonDimensions.radiusXLarge
    var strokeWidth: CGFloat = CartoonDimensions.strokeHeavy
    let content: () -> Content

    init(
        fill: Color = CartoonColor.paper,
        stroke: Color = CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke),
        cornerRadius: CGFloat = CartoonDimensions.radiusXLarge,
        strokeWidth: CGFloat = CartoonDimensions.strokeHeavy,
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
            .shadow(color: CartoonColor.ink.opacity(0.35), radius: 0, x: 0, y: CartoonDimensions.shadowOffsetLarge)
    }
}

// MARK: - Chunky cartoon button

struct CartoonButton<Content: View>: View {
    var tint: Color
    var shadowOffset: CGFloat = CartoonDimensions.shadowOffsetLarge
    var cornerRadius: CGFloat = CartoonDimensions.radiusLarge
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var action: () -> Void
    let content: () -> Content

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        tint: Color,
        shadowOffset: CGFloat = CartoonDimensions.shadowOffsetLarge,
        cornerRadius: CGFloat = CartoonDimensions.radiusLarge,
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
                            .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeHeavy)
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

// MARK: - Circle icon button (back / gear / close etc.)

struct CartoonCircleIconButton: View {
    let systemImage: String
    var diameter: CGFloat = CartoonDimensions.iconButtonSize
    var iconSize: CGFloat = CartoonDimensions.iconButtonIconSize
    var fill: Color = CartoonColor.paper
    var accessibilityLabel: String
    var accessibilityHint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                    .frame(width: diameter, height: diameter)
                    .offset(y: CartoonDimensions.shadowOffsetRegular)
                Circle()
                    .fill(fill)
                    .frame(width: diameter, height: diameter)
                Circle()
                    .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                    .frame(width: diameter, height: diameter)
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .black))
                    .foregroundStyle(CartoonColor.text)
            }
            .frame(width: diameter + 4, height: diameter + 8)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Capsule tab chip (rarity/category selectors)

struct CartoonTabChip: View {
    let label: String
    let selected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                    .frame(height: 52)
                    .offset(y: CartoonDimensions.shadowOffsetRegular)
                Capsule()
                    .fill(selected ? tint : CartoonColor.paper)
                    .frame(height: 52)
                Capsule()
                    .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
                    .frame(height: 52)
                Text(label)
                    .font(.system(size: CartoonDimensions.fontBodyLarge, weight: .black, design: .rounded))
                    .foregroundStyle(selected ? .white : CartoonColor.text)
                    .padding(.horizontal, CartoonDimensions.spacingMedium + 6)
            }
            .fixedSize()
            .offset(y: selected ? 0 : -2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Circle badge (emoji inside circle with ink outline + hard shadow)

struct CartoonCircleBadge: View {
    let emoji: String
    var diameter: CGFloat = CartoonDimensions.circleBadgeMedium
    var fill: Color = CartoonColor.paper
    var dimmed: Bool = false
    var emojiScale: CGFloat = 0.56

    var body: some View {
        ZStack {
            Circle()
                .fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow))
                .frame(width: diameter, height: diameter)
                .offset(y: CartoonDimensions.shadowOffsetRegular)
            Circle()
                .fill(fill)
                .frame(width: diameter, height: diameter)
            Circle()
                .stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeHeavy)
                .frame(width: diameter, height: diameter)
            Text(emoji)
                .font(.system(size: diameter * emojiScale))
                .saturation(dimmed ? 0.3 : 1)
                .opacity(dimmed ? 0.6 : 1)
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
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
        HStack(spacing: CartoonDimensions.spacingTight) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, CartoonDimensions.spacingMedium)
        .padding(.vertical, CartoonDimensions.spacingSmall)
        .background(
            ZStack {
                Capsule().fill(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityShadow)).offset(y: CartoonDimensions.shadowOffsetRegular)
                Capsule().fill(CartoonColor.paper)
                Capsule().stroke(CartoonColor.ink.opacity(CartoonDimensions.inkOpacityStroke), lineWidth: CartoonDimensions.strokeBold)
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel ?? "\(value)"))
    }
}

// MARK: - Rounded chunky text styles

extension View {
    func cartoonTitle(size: CGFloat = CartoonDimensions.fontTitle) -> some View {
        self.font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(CartoonColor.text)
    }

    func cartoonBody(size: CGFloat = CartoonDimensions.fontBody) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(CartoonColor.text)
    }

    func cartoonCaption(size: CGFloat = CartoonDimensions.fontCaption) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(CartoonColor.text.opacity(0.7))
    }
}

// MARK: - View modifiers for stroke/shadow shortcuts

extension View {
    /// Hard drop shadow in ink color — mimics the cartoon style offset block.
    func cartoonInkShadow(y: CGFloat = CartoonDimensions.shadowOffsetRegular) -> some View {
        self.shadow(color: CartoonColor.ink.opacity(0.3), radius: 0, x: 0, y: y)
    }
}
