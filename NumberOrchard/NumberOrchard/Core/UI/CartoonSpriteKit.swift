import SpriteKit
import UIKit

// MARK: - Cartoon palette for SpriteKit

enum CartoonSK {
    static let skyTop      = UIColor(red: 1.00, green: 0.96, blue: 0.82, alpha: 1.0)
    static let skyBottom   = UIColor(red: 1.00, green: 0.84, blue: 0.62, alpha: 1.0)
    static let ink         = UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.9)
    static let text        = UIColor(red: 0.32, green: 0.20, blue: 0.12, alpha: 1.0)
    static let paper       = UIColor(red: 1.00, green: 0.98, blue: 0.91, alpha: 1.0)
    static let gold        = UIColor(red: 1.00, green: 0.76, blue: 0.20, alpha: 1.0)
    static let coral       = UIColor(red: 1.00, green: 0.53, blue: 0.44, alpha: 1.0)
    static let sky         = UIColor(red: 0.42, green: 0.75, blue: 1.00, alpha: 1.0)
    static let leaf        = UIColor(red: 0.32, green: 0.75, blue: 0.42, alpha: 1.0)
    static let berry       = UIColor(red: 0.70, green: 0.40, blue: 0.90, alpha: 1.0)
    static let wood        = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
    static let grassTop    = UIColor(red: 0.62, green: 0.84, blue: 0.45, alpha: 1.0)
    static let grassBottom = UIColor(red: 0.40, green: 0.66, blue: 0.30, alpha: 1.0)

    static let cartoonFont = "Avenir-Black"
    static let cartoonHeavyFont = "Avenir-Black"

    /// Font name that supports Chinese with bold look. Falls back to PingFang SC Semibold if Avenir unavailable.
    static func chineseFont() -> String {
        "PingFangSC-Semibold"
    }
}

// MARK: - Shared helpers for game scenes

/// Generous touch targets for young children. Expand frames by this much when doing intersection tests.
enum CartoonSKTouch {
    /// Inset amount used with `frame.insetBy(dx: -padding, dy: -padding)` — ~50pt makes targets thumb-friendly.
    static let largeHitPadding: CGFloat = 50
}

/// Cached gradient / ground textures keyed by size — avoids re-rendering each scene setup.
@MainActor
enum CartoonSKTextureCache {
    private static var skyCache: [String: SKTexture] = [:]
    private static var groundCache: [String: SKTexture] = [:]

    private static func key(_ size: CGSize) -> String {
        "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))"
    }

    static func skyGradient(size: CGSize) -> SKTexture {
        let k = key(size)
        if let cached = skyCache[k] { return cached }
        let image = renderGradient(size: size, top: CartoonSK.skyTop, bottom: CartoonSK.skyBottom)
        let tex = SKTexture(image: image)
        skyCache[k] = tex
        return tex
    }

    static func grassGradient(size: CGSize) -> SKTexture {
        let k = key(size)
        if let cached = groundCache[k] { return cached }
        let image = renderGradient(size: size, top: CartoonSK.grassTop, bottom: CartoonSK.grassBottom)
        let tex = SKTexture(image: image)
        groundCache[k] = tex
        return tex
    }

    private static func renderGradient(size: CGSize, top: UIColor, bottom: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(gradient,
                    start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
            }
        }
    }
}

// MARK: - Chunky cartoon shapes

extension SKNode {

    /// Create a chunky rounded block with ink outline and hard drop shadow.
    /// Returns an SKNode containing the layered shapes. Touch detection: use .contains on this node's frame.
    static func cartoonBlock(size: CGSize, fill: UIColor, cornerRadius: CGFloat? = nil) -> SKSpriteNode {
        let radius = cornerRadius ?? min(size.width, size.height) * 0.25
        let texture = SKTexture(image: renderCartoonBlock(size: size, fill: fill, cornerRadius: radius))
        let node = SKSpriteNode(texture: texture, size: CGSize(width: size.width + 8, height: size.height + 12))
        node.name = "block"
        return node
    }

    /// Create a chunky cartoon circle node (for baskets, plates, etc).
    static func cartoonDisc(diameter: CGFloat, fill: UIColor) -> SKSpriteNode {
        let texture = SKTexture(image: renderCartoonDisc(diameter: diameter, fill: fill))
        let node = SKSpriteNode(texture: texture, size: CGSize(width: diameter + 8, height: diameter + 12))
        return node
    }

    /// Create a label with rounded bold font on a paper pill background.
    static func cartoonPillLabel(text: String, fontSize: CGFloat, fill: UIColor = CartoonSK.paper, textColor: UIColor = CartoonSK.text) -> SKNode {
        let container = SKNode()
        let label = SKLabelNode(fontNamed: CartoonSK.chineseFont())
        label.text = text
        label.fontSize = fontSize
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        // Calculate pill size
        let width = label.frame.width + 32
        let height = fontSize + 18

        let texture = SKTexture(image: renderCartoonPill(size: CGSize(width: width, height: height), fill: fill))
        let bg = SKSpriteNode(texture: texture, size: CGSize(width: width + 8, height: height + 10))
        bg.zPosition = 0
        label.zPosition = 1
        container.addChild(bg)
        container.addChild(label)
        return container
    }
}

// MARK: - Texture rendering helpers

/// Draw a rounded block with an ink outline and a hard offset shadow below.
private func renderCartoonBlock(size: CGSize, fill: UIColor, cornerRadius: CGFloat) -> UIImage {
    let padding: CGFloat = 4
    let shadowOffset: CGFloat = 8
    let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2 + shadowOffset)

    let renderer = UIGraphicsImageRenderer(size: totalSize)
    return renderer.image { ctx in
        // Shadow (offset down)
        let shadowRect = CGRect(x: padding, y: padding + shadowOffset, width: size.width, height: size.height)
        let shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: cornerRadius)
        CartoonSK.ink.setFill()
        shadowPath.fill()

        // Main body
        let bodyRect = CGRect(x: padding, y: padding, width: size.width, height: size.height)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: cornerRadius)

        // Gradient fill for depth
        if let cgContext = ctx.cgContext as CGContext? {
            cgContext.saveGState()
            bodyPath.addClip()
            let colors = [fill.lighter(by: 0.15).cgColor, fill.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                cgContext.drawLinearGradient(gradient,
                    start: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                    end: CGPoint(x: bodyRect.midX, y: bodyRect.maxY),
                    options: [])
            }
            cgContext.restoreGState()
        }

        // Ink outline
        CartoonSK.ink.setStroke()
        bodyPath.lineWidth = 3
        bodyPath.stroke()

        // Highlight (top shine)
        let highlight = UIBezierPath(roundedRect: CGRect(x: bodyRect.minX + 6, y: bodyRect.minY + 4, width: bodyRect.width - 12, height: 6), cornerRadius: 3)
        UIColor.white.withAlphaComponent(0.4).setFill()
        highlight.fill()
    }
}

private func renderCartoonDisc(diameter: CGFloat, fill: UIColor) -> UIImage {
    let padding: CGFloat = 4
    let shadowOffset: CGFloat = 8
    let totalSize = CGSize(width: diameter + padding * 2, height: diameter + padding * 2 + shadowOffset)

    let renderer = UIGraphicsImageRenderer(size: totalSize)
    return renderer.image { ctx in
        // Shadow
        let shadowRect = CGRect(x: padding, y: padding + shadowOffset, width: diameter, height: diameter)
        let shadowPath = UIBezierPath(ovalIn: shadowRect)
        CartoonSK.ink.setFill()
        shadowPath.fill()

        // Body
        let bodyRect = CGRect(x: padding, y: padding, width: diameter, height: diameter)
        let bodyPath = UIBezierPath(ovalIn: bodyRect)

        if let cgContext = ctx.cgContext as CGContext? {
            cgContext.saveGState()
            bodyPath.addClip()
            let colors = [fill.lighter(by: 0.2).cgColor, fill.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                cgContext.drawLinearGradient(gradient,
                    start: CGPoint(x: bodyRect.midX, y: bodyRect.minY),
                    end: CGPoint(x: bodyRect.midX, y: bodyRect.maxY),
                    options: [])
            }
            cgContext.restoreGState()
        }

        // Outline
        CartoonSK.ink.setStroke()
        bodyPath.lineWidth = 3.5
        bodyPath.stroke()
    }
}

private func renderCartoonPill(size: CGSize, fill: UIColor) -> UIImage {
    let padding: CGFloat = 4
    let shadowOffset: CGFloat = 5
    let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2 + shadowOffset)

    let renderer = UIGraphicsImageRenderer(size: totalSize)
    return renderer.image { ctx in
        let radius = size.height / 2

        // Shadow
        let shadowRect = CGRect(x: padding, y: padding + shadowOffset, width: size.width, height: size.height)
        UIBezierPath(roundedRect: shadowRect, cornerRadius: radius).apply { path in
            CartoonSK.ink.setFill()
            path.fill()
        }

        // Body
        let bodyRect = CGRect(x: padding, y: padding, width: size.width, height: size.height)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: radius)
        fill.setFill()
        bodyPath.fill()
        CartoonSK.ink.setStroke()
        bodyPath.lineWidth = 3
        bodyPath.stroke()
    }
}

// MARK: - Color helpers

extension UIColor {
    func lighter(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: min(r + amount, 1),
            green: min(g + amount, 1),
            blue: min(b + amount, 1),
            alpha: a
        )
    }

    func darker(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: max(r - amount, 0),
            green: max(g - amount, 0),
            blue: max(b - amount, 0),
            alpha: a
        )
    }
}

// UIBezierPath helper to avoid `let _ = ...` boilerplate
private extension UIBezierPath {
    func apply(_ block: (UIBezierPath) -> Void) {
        block(self)
    }
}
