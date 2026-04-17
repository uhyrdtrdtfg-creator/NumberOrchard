import SwiftUI

/// Typography tokens — every text style in the app should pick from here so
/// type hierarchy stays consistent. Designed to compose with `.foregroundStyle`
/// and friends on the call-site.
enum CartoonFont {
    /// 56pt black — splash titles, "🎉 太棒啦！"
    static let displayHuge   = Font.system(size: CartoonDimensions.fontTitleHuge, weight: .black, design: .rounded)
    /// 42pt black — main page titles
    static let displayLarge  = Font.system(size: CartoonDimensions.fontTitleLarge, weight: .black, design: .rounded)
    /// 32pt black — section titles
    static let title         = Font.system(size: CartoonDimensions.fontTitle, weight: .black, design: .rounded)
    /// 26pt black — sub-section titles
    static let titleSmall    = Font.system(size: CartoonDimensions.fontTitleSmall, weight: .black, design: .rounded)
    /// 22pt bold — speech bubbles, prominent body text
    static let bodyLarge     = Font.system(size: CartoonDimensions.fontBodyLarge, weight: .bold, design: .rounded)
    /// 20pt bold — default body
    static let body          = Font.system(size: CartoonDimensions.fontBody, weight: .bold, design: .rounded)
    /// 18pt bold — secondary body
    static let bodySmall     = Font.system(size: CartoonDimensions.fontBodySmall, weight: .bold, design: .rounded)
    /// 15pt semibold — captions, helper text
    static let caption       = Font.system(size: CartoonDimensions.fontCaption, weight: .semibold, design: .rounded)
    /// 36pt black — number-pad / input display digits
    static let numericLarge  = Font.system(size: 36, weight: .black, design: .rounded)
}

/// Animation presets — keep the app's motion language coherent. Spring-based
/// for child-friendly bounciness; eased only for non-physical fades.
enum CartoonAnim {
    /// Quick interactive feedback (button press, tap response). Snappy.
    static let snappy   = Animation.spring(response: 0.22, dampingFraction: 0.55)
    /// Default UI transitions (panel show/hide, value swap). Bouncy but settled.
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.7)
    /// Big celebratory motion (correct answer, evolution). Pronounced bounce.
    static let bouncy   = Animation.spring(response: 0.45, dampingFraction: 0.55)
    /// Slow gentle motion (background drift, idle breathing).
    static let breathe  = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
    /// Linear fade — for opacity-only transitions.
    static let fadeFast = Animation.easeOut(duration: 0.25)
    /// Falling particles / fruit rain.
    static let fall     = Animation.easeOut(duration: 1.0)
}
