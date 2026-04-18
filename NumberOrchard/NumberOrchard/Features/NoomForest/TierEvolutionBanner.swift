import SwiftUI

/// Full-screen celebration when a pet crosses into a new skill tier
/// (none→one on first adolescence, one→two on adulthood). Surfaces *what
/// the tier upgrade means* — not just "it evolved" — so the child
/// immediately understands why raising pets matters.
///
/// Non-interactive: auto-dismisses after `autoDismissAfter` seconds or
/// when the child taps anywhere.
struct TierEvolutionBanner: View {
    let noom: Noom
    let skill: NoomSkill
    let newTier: NoomSkill.Tier
    let onDismiss: () -> Void

    var autoDismissAfter: TimeInterval = 3.5

    @State private var appeared = false

    private var title: String {
        newTier == .two ? "★★ 技能进化!" : "★ 技能觉醒!"
    }

    private var tint: Color {
        newTier == .two ? CartoonColor.coral : CartoonColor.gold
    }

    var body: some View {
        ZStack {
            CartoonColor.overlayDark.ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 18) {
                Text(title)
                    .font(CartoonFont.displayLarge)
                    .foregroundStyle(tint)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 3)

                Image(uiImage: NoomRenderer.image(
                    for: noom, expression: .happy,
                    size: CGSize(width: 200, height: 200),
                    stage: newTier == .two ? 2 : 1
                ))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(appeared ? 1.0 : 0.4)
                .rotationEffect(.degrees(appeared ? 0 : -20))

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text(skill.emoji).font(.system(size: 36))
                        Text(skill.displayName)
                            .font(CartoonFont.title)
                            .foregroundStyle(.white)
                    }
                    Text(skill.explanation(tier: newTier))
                        .font(CartoonFont.bodyLarge)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Text("点击继续")
                    .font(CartoonFont.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(tint, lineWidth: 3)
                    )
            )
            .padding(.horizontal, 40)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(CartoonAnim.bouncy) { appeared = true }
            AudioManager.shared.playSound("level_up.wav")
            Haptics.milestone()
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                onDismiss()
            }
        }
    }
}
