import SwiftUI

struct ParentalGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var sliderValue: CGFloat = 0
    @State private var holdCompleted = false
    @State private var timer: Timer?
    @State private var timeRemaining = 30

    var body: some View {
        ZStack {
            CartoonColor.overlayMedium
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("家长验证")
                    .font(.title2)
                    .foregroundStyle(.white)

                if !holdCompleted {
                    holdPhase
                } else {
                    slidePhase
                }

                Button("取消") {
                    onCancel()
                }
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .accessibilityLabel("取消")

                Text("剩余时间: \(timeRemaining)秒")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .onAppear { startTimeout() }
        .onDisappear { timer?.invalidate() }
    }

    private var holdPhase: some View {
        VStack(spacing: 16) {
            Text("请长按圆圈 3 秒")
                .foregroundStyle(.white.opacity(0.8))

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 88, height: 88)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if holdProgress == 0 {
                            withAnimation(.linear(duration: 3)) {
                                holdProgress = 1.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                if holdProgress >= 0.95 {
                                    holdCompleted = true
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        if !holdCompleted {
                            withAnimation { holdProgress = 0 }
                        }
                    }
            )
        }
    }

    private var slidePhase: some View {
        VStack(spacing: 16) {
            Text("向右滑动解锁")
                .foregroundStyle(.white.opacity(0.8))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 50)

                    Capsule()
                        .fill(.green.opacity(0.3))
                        .frame(width: max(50, sliderValue * geo.size.width), height: 50)

                    Circle()
                        .fill(.white)
                        .frame(width: 46, height: 46)
                        .offset(x: sliderValue * (geo.size.width - 50))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    sliderValue = max(0, min(1, value.location.x / geo.size.width))
                                }
                                .onEnded { _ in
                                    if sliderValue > 0.9 {
                                        onSuccess()
                                    } else {
                                        withAnimation { sliderValue = 0 }
                                    }
                                }
                        )
                }
            }
            .frame(height: 50)
            .frame(maxWidth: 300)
        }
    }

    private func startTimeout() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    timer?.invalidate()
                    onCancel()
                }
            }
        }
    }
}
