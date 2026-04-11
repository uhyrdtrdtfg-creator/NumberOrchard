import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: ChildProfile
    @State private var musicEnabled = true
    @State private var soundEnabled = true
    @State private var voiceEnabled = true

    var body: some View {
        Form {
            Section("用眼管理") {
                Stepper(
                    "每日使用时长上限: \(profile.dailyTimeLimitMinutes) 分钟",
                    value: $profile.dailyTimeLimitMinutes,
                    in: 10...60,
                    step: 5
                )
            }

            Section("难度设置") {
                HStack {
                    Text("当前级别")
                    Spacer()
                    Text(profile.difficultyLevel.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("运算范围")
                    Spacer()
                    Text("\(profile.difficultyLevel.maxNumber) 以内")
                        .foregroundStyle(.secondary)
                }
            }

            Section("音频") {
                Toggle("背景音乐", isOn: $musicEnabled)
                Toggle("音效", isOn: $soundEnabled)
                Toggle("语音提示", isOn: $voiceEnabled)
            }
            .onChange(of: musicEnabled) { _, new in
                AudioManager.shared.isMusicEnabled = new
            }
            .onChange(of: soundEnabled) { _, new in
                AudioManager.shared.isSoundEnabled = new
            }
            .onChange(of: voiceEnabled) { _, new in
                AudioManager.shared.isVoiceEnabled = new
            }

            Section("档案") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(profile.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("创建日期")
                    Spacer()
                    Text(profile.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
