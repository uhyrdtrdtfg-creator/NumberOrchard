import SwiftUI

struct PetGardenView: View {
    let profile: ChildProfile

    var body: some View {
        VStack {
            Spacer()
            Text("🌻 宠物花园")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(CartoonColor.text)
            Text("(即将到来 — Phase 5/6/7)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(CartoonColor.text.opacity(0.5))
            Spacer()
        }
    }
}
