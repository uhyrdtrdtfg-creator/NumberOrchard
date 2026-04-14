import UIKit
import SpriteKit

enum NoomExpression: Sendable {
    case neutral
    case happy
    case surprised
}

enum NoomRenderer {
    /// Render a Noom creature image at the given size.
    /// Body diameter scales subtly with `noom.number` so larger Nooms look chunkier.
    static func image(for noom: Noom, expression: NoomExpression, size: CGSize, stage: Int = 0) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawShadow(in: ctx.cgContext, size: size)
            drawBody(in: ctx.cgContext, size: size, color: noom.bodyColor)
            drawSpots(in: ctx.cgContext, size: size, count: noom.number)
            drawFace(in: ctx.cgContext, size: size, expression: expression)
            drawNumberBadge(in: ctx.cgContext, size: size, number: noom.number)
            drawStageDecoration(in: ctx.cgContext, size: size, stage: stage)
        }
    }

    private static func drawShadow(in ctx: CGContext, size: CGSize) {
        let rect = CGRect(x: 8, y: 14, width: size.width - 16, height: size.height - 16)
        let shadow = UIBezierPath(ovalIn: rect)
        UIColor.black.withAlphaComponent(0.4).setFill()
        shadow.fill()
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

        UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85).setStroke()
        body.lineWidth = 4
        body.stroke()

        let highlightRect = CGRect(x: bodyRect.minX + 16, y: bodyRect.minY + 14, width: 30, height: 12)
        let highlight = UIBezierPath(ovalIn: highlightRect)
        UIColor.white.withAlphaComponent(0.45).setFill()
        highlight.fill()
    }

    private static func drawSpots(in ctx: CGContext, size: CGSize, count: Int) {
        var rng = SeededRNG(seed: UInt64(count * 31))
        let bodyRect = CGRect(x: 12, y: 8, width: size.width - 24, height: size.height - 24)
        let spotRadius: CGFloat = 5
        UIColor.white.withAlphaComponent(0.85).setFill()

        for _ in 0..<count {
            let r: CGFloat = .random(in: 0...(min(bodyRect.width, bodyRect.height) / 3 - 4), using: &rng)
            let angle: CGFloat = .random(in: 0...(.pi * 2), using: &rng)
            let cx = bodyRect.midX + cos(angle) * r
            let cy = bodyRect.midY + sin(angle) * r * 0.8 + 8
            let spot = UIBezierPath(ovalIn: CGRect(x: cx - spotRadius, y: cy - spotRadius,
                                                   width: spotRadius * 2, height: spotRadius * 2))
            spot.fill()
        }
    }

    private static func drawFace(in ctx: CGContext, size: CGSize, expression: NoomExpression) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.45)
        let eyeOffset: CGFloat = 16
        let eyeRadius: CGFloat = expression == .surprised ? 7 : 5
        UIColor.black.setFill()

        for dx in [-eyeOffset, eyeOffset] {
            let eyeRect = CGRect(x: center.x + dx - eyeRadius,
                                 y: center.y - eyeRadius,
                                 width: eyeRadius * 2, height: eyeRadius * 2)
            UIBezierPath(ovalIn: eyeRect).fill()
            let glint = UIBezierPath(ovalIn: CGRect(x: eyeRect.minX + 2, y: eyeRect.minY + 1, width: 2, height: 2))
            UIColor.white.setFill()
            glint.fill()
            UIColor.black.setFill()
        }

        let mouthY = center.y + 16
        let mouth = UIBezierPath()
        switch expression {
        case .neutral:
            mouth.move(to: CGPoint(x: center.x - 8, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: center.x + 8, y: mouthY),
                              controlPoint: CGPoint(x: center.x, y: mouthY + 4))
        case .happy:
            mouth.move(to: CGPoint(x: center.x - 14, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: center.x + 14, y: mouthY),
                              controlPoint: CGPoint(x: center.x, y: mouthY + 12))
        case .surprised:
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: center.x - 6, y: mouthY - 4, width: 12, height: 16)).fill()
            return
        }
        UIColor.black.setStroke()
        mouth.lineWidth = 3
        mouth.stroke()
    }

    private static func drawNumberBadge(in ctx: CGContext, size: CGSize, number: Int) {
        let badgeRect = CGRect(x: size.width - 32, y: size.height - 36, width: 28, height: 28)
        let badge = UIBezierPath(ovalIn: badgeRect)
        UIColor.white.setFill()
        badge.fill()
        UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.85).setStroke()
        badge.lineWidth = 2.5
        badge.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Semibold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        ]
        let text = "\(number)"
        let textSize = text.size(withAttributes: attrs)
        let textRect = CGRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width, height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attrs)
    }

    private static func drawStageDecoration(in ctx: CGContext, size: CGSize, stage: Int) {
        guard stage >= 1 else { return }

        // Teen: bow on top
        if stage == 1 {
            let emoji = "🎀" as NSString
            let font = UIFont.systemFont(ofSize: size.width * 0.28)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let textSize = emoji.size(withAttributes: attrs)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height * 0.02,
                width: textSize.width,
                height: textSize.height
            )
            emoji.draw(in: rect, withAttributes: attrs)
        }

        // Adult: crown on top + cape at bottom
        if stage == 2 {
            let crown = "👑" as NSString
            let crownFont = UIFont.systemFont(ofSize: size.width * 0.3)
            let crownAttrs: [NSAttributedString.Key: Any] = [.font: crownFont]
            let crownSize = crown.size(withAttributes: crownAttrs)
            let crownRect = CGRect(
                x: (size.width - crownSize.width) / 2,
                y: -size.height * 0.04,
                width: crownSize.width,
                height: crownSize.height
            )
            crown.draw(in: crownRect, withAttributes: crownAttrs)

            let cape = "🎽" as NSString
            let capeFont = UIFont.systemFont(ofSize: size.width * 0.22)
            let capeAttrs: [NSAttributedString.Key: Any] = [.font: capeFont]
            let capeSize = cape.size(withAttributes: capeAttrs)
            let capeRect = CGRect(
                x: (size.width - capeSize.width) / 2,
                y: size.height - capeSize.height - 4,
                width: capeSize.width,
                height: capeSize.height
            )
            cape.draw(in: capeRect, withAttributes: capeAttrs)
        }
    }
}

/// Tiny seeded RNG so spot positions are stable across renders.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 1 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
