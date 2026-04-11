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
            VStack(spacing: 24) {
                GroupBox("今日学习") {
                    HStack(spacing: 40) {
                        statItem(value: "\(todayQuestionCount)", label: "做题数")
                        statItem(value: "\(Int(todayAccuracy * 100))%", label: "正确率")
                        statItem(value: String(format: "%.0f 分钟", todayDurationMinutes), label: "用时")
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("本周趋势") {
                    Chart(last7DaysData, id: \.date) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("题数", item.count)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                }

                GroupBox("总体进度") {
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

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
