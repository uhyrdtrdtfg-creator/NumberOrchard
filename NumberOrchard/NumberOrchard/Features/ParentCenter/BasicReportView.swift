import SwiftUI
import SwiftData
import Charts

struct BasicReportView: View {
    let profile: ChildProfile

    private var todaySessions: [LearningSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return profile.sessions.filter { calendar.startOfDay(for: $0.date) == today }
    }

    private var todayQuestionCount: Int {
        todaySessions.reduce(0) { $0 + $1.records.count }
    }

    private var todayCorrectCount: Int {
        todaySessions.reduce(0) { $0 + $1.correctCount }
    }

    private var todayAccuracy: Double {
        guard todayQuestionCount > 0 else { return 0 }
        return Double(todayCorrectCount) / Double(todayQuestionCount)
    }

    private var todayDurationMinutes: Double {
        todaySessions.reduce(0) { $0 + $1.durationSeconds } / 60.0
    }

    private var last7DaysData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let day = calendar.startOfDay(for: date)
            let count = profile.sessions
                .filter { calendar.startOfDay(for: $0.date) == day }
                .reduce(0) { $0 + $1.records.count }
            return (date: day, count: count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                section(title: "📅 今日学习") {
                    HStack(spacing: 40) {
                        statItem(value: "\(todayQuestionCount)", label: "做题数")
                        statItem(value: "\(Int(todayAccuracy * 100))%", label: "正确率")
                        statItem(value: String(format: "%.0f 分", todayDurationMinutes), label: "用时")
                    }
                    .padding(.vertical, 8)
                }

                section(title: "📈 本周趋势") {
                    Chart(last7DaysData, id: \.date) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("题数", item.count)
                        )
                        .foregroundStyle(CartoonColor.leaf)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .padding(.top, 8)
                }

                section(title: "🏆 总体进度") {
                    HStack(spacing: 40) {
                        statItem(value: "\(profile.totalQuestions)", label: "总题量")
                        statItem(value: "\(profile.consecutiveLoginDays) 天", label: "连续学习")
                        statItem(value: profile.difficultyLevel.displayName, label: "当前级别")
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
    }

    /// Cartoon-themed replacement for the native GroupBox — title floats
    /// as a CartoonFont.titleSmall label, contents sit inside a
    /// CartoonPanel. Keeps the parent-center report visually aligned
    /// with the rest of the app.
    @ViewBuilder
    private func section<Content: View>(title: String,
                                        @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(CartoonFont.titleSmall)
                .foregroundStyle(CartoonColor.text)
            CartoonPanel(cornerRadius: 22) {
                content().padding(16)
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(CartoonFont.title)
                .foregroundStyle(CartoonColor.text)
            Text(label)
                .font(CartoonFont.caption)
                .foregroundStyle(CartoonColor.text.opacity(0.65))
        }
    }
}
