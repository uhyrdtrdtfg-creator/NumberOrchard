import UIKit
import SpriteKit

enum NoomExpression: Sendable {
    case neutral
    case happy
    case surprised
}

/// Renders a Noom creature image. Each Noom's appearance combines:
///   - body color (from `Noom.bodyColor`)
///   - personality face traits (from `NoomPersonality.forNoom(_:)`)
///   - life-stage decoration (bow / crown+cape)
/// The same Noom always renders identically (no per-frame randomness).
enum NoomRenderer {
    /// Render a Noom. `skin` remains the single-hat convenience argument
    /// for callers that only care about hats; `skins` is the new
    /// multi-slot API that lets a hat + collar render together. When
    /// a non-empty `skins` is provided it takes precedence over `skin`.
    /// A non-nil hat skin still suppresses the default stage crown so
    /// the wardrobe glyph doesn't fight the auto-crown.
    static func image(
        for noom: Noom,
        expression: NoomExpression,
        size: CGSize,
        stage: Int = 0,
        skin: NoomSkin? = nil,
        skins: [NoomSkin] = []
    ) -> UIImage {
        let effective = skins.isEmpty ? [skin].compactMap { $0 } : skins
        let hat = effective.first(where: { $0.slot == .hat })
        let collar = effective.first(where: { $0.slot == .collar })

        let renderer = UIGraphicsImageRenderer(size: size)
        let personality = NoomPersonality.forNoom(noom.number)
        return renderer.image { ctx in
            drawShadow(in: ctx.cgContext, size: size)
            drawBody(in: ctx.cgContext, size: size, color: noom.bodyColor)
            drawAccessory(in: ctx.cgContext, size: size, accessory: personality.accessory, bodyColor: noom.bodyColor)
            drawBlush(in: ctx.cgContext, size: size, personality: personality)
            drawFace(in: ctx.cgContext, size: size, expression: expression, personality: personality)
            drawNameBadge(in: ctx.cgContext, size: size, number: noom.number, bodyColor: noom.bodyColor)
            if let collar {
                drawSkinCollar(in: ctx.cgContext, size: size, glyph: collar.glyph)
            }
            if let hat {
                drawSkinHat(in: ctx.cgContext, size: size, glyph: hat.glyph)
            } else {
                drawStageDecoration(in: ctx.cgContext, size: size, stage: stage)
            }
        }
    }

    /// Equipped cosmetic hat, drawn in the crown slot (on top of head).
    private static func drawSkinHat(in ctx: CGContext, size: CGSize, glyph: String) {
        drawIcon(glyph,
                 at: CGPoint(x: size.width / 2, y: -size.height * 0.02),
                 fontSize: size.width * 0.30, color: nil)
    }

    /// Collar slot — drawn slightly above the chest badge, below the face.
    private static func drawSkinCollar(in ctx: CGContext, size: CGSize, glyph: String) {
        drawIcon(glyph,
                 at: CGPoint(x: size.width / 2, y: size.height * 0.62),
                 fontSize: size.width * 0.18, color: nil)
    }

    // MARK: - Body

    private static func drawShadow(in ctx: CGContext, size: CGSize) {
        let rect = CGRect(x: 8, y: 14, width: size.width - 16, height: size.height - 16)
        UIColor.black.withAlphaComponent(0.4).setFill()
        UIBezierPath(ovalIn: rect).fill()
    }

    private static func drawBody(in ctx: CGContext, size: CGSize, color: UIColor) {
        let bodyRect = CGRect(x: 8, y: 4, width: size.width - 16, height: size.height - 16)
        let body = UIBezierPath(ovalIn: bodyRect)

        ctx.saveGState()
        body.addClip()
        let lighter = color.lighter(by: 0.18)
        let colors = [lighter.cgColor, color.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient,
                start: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                end: CGPoint(x: bodyRect.midX, y: bodyRect.maxY),
                options: [])
        }
        ctx.restoreGState()

        UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.85).setStroke()
        body.lineWidth = 4
        body.stroke()

        // Soft highlight on upper-left.
        let highlight = UIBezierPath(ovalIn: CGRect(
            x: bodyRect.minX + bodyRect.width * 0.18,
            y: bodyRect.minY + bodyRect.height * 0.12,
            width: bodyRect.width * 0.22,
            height: bodyRect.height * 0.10
        ))
        UIColor.white.withAlphaComponent(0.45).setFill()
        highlight.fill()
    }

    // MARK: - Accessory (replaces the old random white spots)

    private static func drawAccessory(
        in ctx: CGContext, size: CGSize,
        accessory: NoomPersonality.Accessory, bodyColor: UIColor
    ) {
        switch accessory {
        case .none:
            return
        case .freckles:
            UIColor.black.withAlphaComponent(0.25).setFill()
            let cx = size.width / 2, cy = size.height * 0.55
            let r: CGFloat = 1.6
            for offset in [CGPoint(x: -22, y: 4), CGPoint(x: -16, y: 8),
                           CGPoint(x: 16, y: 8), CGPoint(x: 22, y: 4)] {
                UIBezierPath(ovalIn: CGRect(
                    x: cx + offset.x - r, y: cy + offset.y - r,
                    width: r * 2, height: r * 2
                )).fill()
            }
        case .star:
            drawIcon("✦", at: CGPoint(x: size.width * 0.30, y: size.height * 0.30),
                     fontSize: size.width * 0.14, color: .white)
            drawIcon("✦", at: CGPoint(x: size.width * 0.70, y: size.height * 0.32),
                     fontSize: size.width * 0.10, color: .white.withAlphaComponent(0.8))
        case .heart:
            drawIcon("♥︎", at: CGPoint(x: size.width * 0.30, y: size.height * 0.32),
                     fontSize: size.width * 0.10,
                     color: UIColor.white.withAlphaComponent(0.7))
        }
    }

    // MARK: - Blush

    private static func drawBlush(in ctx: CGContext, size: CGSize, personality: NoomPersonality) {
        let cy = size.height * (personality.eyeY + 0.10)
        let dx = size.width * (personality.eyeSpacing + 0.10)
        let blushRadius = CGSize(width: size.width * 0.10, height: size.width * 0.07)
        UIColor(red: 1.0, green: 0.55, blue: 0.65, alpha: 0.55).setFill()
        for offset in [-dx, dx] {
            let rect = CGRect(
                x: size.width / 2 + offset - blushRadius.width / 2,
                y: cy - blushRadius.height / 2,
                width: blushRadius.width, height: blushRadius.height
            )
            UIBezierPath(ovalIn: rect).fill()
        }
    }

    // MARK: - Face

    private static func drawFace(
        in ctx: CGContext, size: CGSize,
        expression: NoomExpression, personality: NoomPersonality
    ) {
        let cy = size.height * personality.eyeY
        let dx = size.width * personality.eyeSpacing
        let leftCenter = CGPoint(x: size.width / 2 - dx, y: cy)
        let rightCenter = CGPoint(x: size.width / 2 + dx, y: cy)

        drawEyebrow(in: ctx, side: -1, eyeCenter: leftCenter, size: size, brow: personality.brow)
        drawEyebrow(in: ctx, side: 1, eyeCenter: rightCenter, size: size, brow: personality.brow)

        drawEye(in: ctx, center: leftCenter, size: size, shape: personality.eye, expression: expression)
        drawEye(in: ctx, center: rightCenter, size: size, shape: personality.eye, expression: expression)

        drawMouth(in: ctx, size: size, expression: expression, eyeY: cy)
    }

    private static func drawEye(
        in ctx: CGContext, center: CGPoint, size: CGSize,
        shape: NoomPersonality.EyeShape, expression: NoomExpression
    ) {
        let scale = size.width / 140  // baseline 140pt body
        let scleraSize: CGSize
        let irisRadius: CGFloat
        switch shape {
        case .round:
            scleraSize = CGSize(width: 18 * scale, height: 18 * scale)
            irisRadius = 7 * scale
        case .sparkle:
            scleraSize = CGSize(width: 20 * scale, height: 22 * scale)
            irisRadius = 8 * scale
        case .sleepy:
            scleraSize = CGSize(width: 18 * scale, height: 12 * scale)
            irisRadius = 5 * scale
        case .sharp:
            scleraSize = CGSize(width: 14 * scale, height: 20 * scale)
            irisRadius = 6 * scale
        }

        // Sclera (white).
        let scleraRect = CGRect(
            x: center.x - scleraSize.width / 2,
            y: center.y - scleraSize.height / 2,
            width: scleraSize.width, height: scleraSize.height
        )
        UIColor.white.setFill()
        UIBezierPath(ovalIn: scleraRect).fill()
        UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.85).setStroke()
        let scleraPath = UIBezierPath(ovalIn: scleraRect)
        scleraPath.lineWidth = 1.5 * scale
        scleraPath.stroke()

        // Iris (dark navy).
        let iris = CGRect(
            x: center.x - irisRadius,
            y: center.y - irisRadius + (expression == .surprised ? -1 : 1) * scale,
            width: irisRadius * 2, height: irisRadius * 2
        )
        UIColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1.0).setFill()
        UIBezierPath(ovalIn: iris).fill()

        // Primary glint.
        let glintR = irisRadius * 0.42
        let glintRect = CGRect(
            x: iris.minX + irisRadius * 0.45,
            y: iris.minY + irisRadius * 0.35,
            width: glintR * 2, height: glintR * 2
        )
        UIColor.white.setFill()
        UIBezierPath(ovalIn: glintRect).fill()

        // Sparkle: secondary smaller glint.
        if shape == .sparkle {
            let g2 = glintR * 0.55
            UIBezierPath(ovalIn: CGRect(
                x: iris.minX + irisRadius * 0.30,
                y: iris.minY + irisRadius * 0.95,
                width: g2 * 2, height: g2 * 2
            )).fill()
        }

        // Sleepy: top half eyelid (arc covering top of sclera).
        if shape == .sleepy {
            UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.85).setFill()
            let lid = UIBezierPath()
            lid.move(to: CGPoint(x: scleraRect.minX, y: scleraRect.midY))
            lid.addQuadCurve(
                to: CGPoint(x: scleraRect.maxX, y: scleraRect.midY),
                controlPoint: CGPoint(x: scleraRect.midX, y: scleraRect.minY - 2)
            )
            lid.addLine(to: CGPoint(x: scleraRect.maxX, y: scleraRect.minY))
            lid.addLine(to: CGPoint(x: scleraRect.minX, y: scleraRect.minY))
            lid.close()
            ctx.saveGState()
            UIBezierPath(ovalIn: scleraRect).addClip()
            lid.fill()
            ctx.restoreGState()
        }
    }

    private static func drawEyebrow(
        in ctx: CGContext, side: CGFloat, eyeCenter: CGPoint, size: CGSize,
        brow: NoomPersonality.BrowShape
    ) {
        guard brow != .none else { return }
        let scale = size.width / 140
        let browWidth: CGFloat = 16 * scale
        let browY = eyeCenter.y - 16 * scale
        let path = UIBezierPath()

        switch brow {
        case .none:
            return
        case .soft:
            path.move(to: CGPoint(x: eyeCenter.x - browWidth / 2, y: browY + 2 * scale))
            path.addQuadCurve(
                to: CGPoint(x: eyeCenter.x + browWidth / 2, y: browY + 2 * scale),
                controlPoint: CGPoint(x: eyeCenter.x, y: browY - 3 * scale)
            )
        case .arched:
            path.move(to: CGPoint(x: eyeCenter.x - browWidth / 2, y: browY + 4 * scale))
            path.addQuadCurve(
                to: CGPoint(x: eyeCenter.x + browWidth / 2, y: browY + 4 * scale),
                controlPoint: CGPoint(x: eyeCenter.x, y: browY - 6 * scale)
            )
        case .stern:
            // Angled toward forehead center.
            let inner = CGPoint(x: eyeCenter.x + side * (-browWidth / 2), y: browY - 2 * scale)
            let outer = CGPoint(x: eyeCenter.x + side * (browWidth / 2), y: browY + 4 * scale)
            path.move(to: inner)
            path.addLine(to: outer)
        }

        UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.95).setStroke()
        path.lineWidth = 3.5 * scale
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawMouth(
        in ctx: CGContext, size: CGSize,
        expression: NoomExpression, eyeY: CGFloat
    ) {
        let scale = size.width / 140
        let center = CGPoint(x: size.width / 2, y: eyeY + 24 * scale)

        switch expression {
        case .neutral:
            let mouth = UIBezierPath()
            mouth.move(to: CGPoint(x: center.x - 8 * scale, y: center.y))
            mouth.addQuadCurve(
                to: CGPoint(x: center.x + 8 * scale, y: center.y),
                controlPoint: CGPoint(x: center.x, y: center.y + 5 * scale)
            )
            UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.95).setStroke()
            mouth.lineWidth = 3 * scale
            mouth.lineCapStyle = .round
            mouth.stroke()

        case .happy:
            // Filled smile with tongue.
            let smile = UIBezierPath()
            let halfW: CGFloat = 18 * scale
            smile.move(to: CGPoint(x: center.x - halfW, y: center.y))
            smile.addQuadCurve(
                to: CGPoint(x: center.x + halfW, y: center.y),
                controlPoint: CGPoint(x: center.x, y: center.y + 18 * scale)
            )
            smile.addLine(to: CGPoint(x: center.x - halfW, y: center.y))
            smile.close()
            UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.95).setFill()
            smile.fill()

            // Pink tongue.
            UIColor(red: 1.0, green: 0.50, blue: 0.55, alpha: 1.0).setFill()
            let tongueRect = CGRect(
                x: center.x - 6 * scale,
                y: center.y + 4 * scale,
                width: 12 * scale, height: 8 * scale
            )
            UIBezierPath(ovalIn: tongueRect).fill()

        case .surprised:
            UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 0.95).setFill()
            UIBezierPath(ovalIn: CGRect(
                x: center.x - 7 * scale, y: center.y - 4 * scale,
                width: 14 * scale, height: 18 * scale
            )).fill()
        }
    }

    // MARK: - Name badge (was "number badge")

    private static func drawNameBadge(
        in ctx: CGContext, size: CGSize,
        number: Int, bodyColor: UIColor
    ) {
        let badgeRadius: CGFloat = size.width * 0.13
        let cx = size.width / 2
        let cy = size.height * 0.78
        let badgeRect = CGRect(
            x: cx - badgeRadius, y: cy - badgeRadius,
            width: badgeRadius * 2, height: badgeRadius * 2
        )

        // Drop shadow.
        UIColor.black.withAlphaComponent(0.25).setFill()
        UIBezierPath(ovalIn: badgeRect.offsetBy(dx: 0, dy: 2)).fill()

        // White face.
        UIColor.white.setFill()
        UIBezierPath(ovalIn: badgeRect).fill()

        // Colored ring (matches body).
        bodyColor.setStroke()
        let ring = UIBezierPath(ovalIn: badgeRect.insetBy(dx: 1.5, dy: 1.5))
        ring.lineWidth = 2.5
        ring.stroke()

        // Number text.
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Heavy", size: badgeRadius * 1.3)
                ?? UIFont.systemFont(ofSize: badgeRadius * 1.3, weight: .heavy),
            .foregroundColor: UIColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 1.0)
        ]
        let text = "\(number)"
        let textSize = text.size(withAttributes: attrs)
        text.draw(in: CGRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width, height: textSize.height
        ), withAttributes: attrs)
    }

    // MARK: - Stage decorations (unchanged from previous version)

    private static func drawStageDecoration(in ctx: CGContext, size: CGSize, stage: Int) {
        guard stage >= 1 else { return }

        if stage == 1 {
            drawIcon("🎀", at: CGPoint(x: size.width / 2, y: size.height * 0.06),
                     fontSize: size.width * 0.28, color: nil)
        }
        if stage == 2 {
            drawIcon("👑", at: CGPoint(x: size.width / 2, y: size.height * 0.0),
                     fontSize: size.width * 0.30, color: nil)
            drawIcon("🎽", at: CGPoint(x: size.width / 2, y: size.height * 0.93),
                     fontSize: size.width * 0.22, color: nil)
        }
    }

    /// Draw a centered text glyph (emoji or symbol) at `center`.
    private static func drawIcon(
        _ glyph: String, at center: CGPoint, fontSize: CGFloat, color: UIColor?
    ) {
        let nsGlyph = glyph as NSString
        var attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize)]
        if let color { attrs[.foregroundColor] = color }
        let textSize = nsGlyph.size(withAttributes: attrs)
        nsGlyph.draw(in: CGRect(
            x: center.x - textSize.width / 2,
            y: center.y,
            width: textSize.width, height: textSize.height
        ), withAttributes: attrs)
    }
}

