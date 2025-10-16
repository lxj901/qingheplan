import SwiftUI

struct WakeTimeSelectionView: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
    let onConfirm: (Date) -> Void
    
    @State private var tempSelectedTime: Date
    
    init(selectedTime: Binding<Date>, onConfirm: @escaping (Date) -> Void) {
        self._selectedTime = selectedTime
        self.onConfirm = onConfirm
        self._tempSelectedTime = State(initialValue: selectedTime.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题区域
                headerSection
                
                // 时间选择器
                timePickerSection
                
                // 睡眠时长预估
                sleepDurationSection
                
                Spacer()
                
                // 确认按钮
                confirmButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.15),
                        Color(red: 0.01, green: 0.03, blue: 0.10),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 视图组件
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("设置起床时间")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // 占位保持居中
                Button("") { }
                    .disabled(true)
                    .opacity(0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Text("请选择您希望起床的时间")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 24)
        }
    }
    
    private var timePickerSection: some View {
        VStack(spacing: 24) {
            // 时间显示
            VStack(spacing: 8) {
                Text("起床时间")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(formatTime(tempSelectedTime))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)
            
            // 时间选择器
            DatePicker(
                "",
                selection: $tempSelectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .scaleEffect(1.2)
            .padding(.horizontal, 20)
        }
    }
    
    private var sleepDurationSection: some View {
        VStack(spacing: 12) {
            Text("预计睡眠时长")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text(calculateSleepDuration())
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
            
            Text("建议睡眠时长为 7-9 小时")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    private var confirmButton: some View {
        Button(action: {
            selectedTime = tempSelectedTime
            onConfirm(tempSelectedTime)
            dismiss()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                
                Text("开始睡眠追踪")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.2, green: 0.4, blue: 0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .shadow(color: Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.3), radius: 12, y: 6)
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func calculateSleepDuration() -> String {
        let now = Date()
        let sleepDuration = tempSelectedTime.timeIntervalSince(now)

        // 如果选择的时间是明天（即负数或很小的正数）
        var duration = sleepDuration
        if duration <= 0 || duration < 3600 { // 如果小于1小时，认为是明天
            duration += 24 * 3600 // 加24小时
        }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - 预览
#Preview {
    WakeTimeSelectionView(
        selectedTime: .constant(Date().addingTimeInterval(8 * 3600))
    ) { _ in
        print("确认选择时间")
    }
}