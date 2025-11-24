import SwiftUI

// 321GO运动开始倒计时动画
struct WorkoutCountdownView: View {
    let workoutType: WorkoutType
    let workoutMode: WorkoutMode
    let onComplete: () -> Void
    
    @State private var currentCount = 3
    @State private var showGO = false
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 全屏黑色背景
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea(.all)
                .animation(.easeInOut(duration: 0.3), value: backgroundOpacity)
            
            VStack(spacing: 40) {
                // 运动类型信息
                VStack(spacing: 12) {
                    Image(systemName: getWorkoutIcon())
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(animationOpacity)
                    
                    Text(getWorkoutTypeName())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .opacity(animationOpacity)
                    
                    Text("准备开始")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(animationOpacity)
                }
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: animationOpacity)
                
                // 倒计时数字或GO
                ZStack {
                    if !showGO {
                        // 倒计时数字
                        Text("\(currentCount)")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(animationScale)
                            .opacity(animationOpacity)
                            .overlay(
                                // 脉冲效果
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 4)
                                    .scaleEffect(pulseScale)
                                    .opacity(2 - pulseScale)
                                    .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulseScale)
                            )
                    } else {
                        // GO文字
                        VStack(spacing: 8) {
                            Text("GO!")
                                .font(.system(size: 100, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .scaleEffect(animationScale)
                                .opacity(animationOpacity)
                            
                            Text("开始运动")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .opacity(animationOpacity)
                        }
                        .overlay(
                            // 爆炸效果
                            Circle()
                                .stroke(Color.green.opacity(0.6), lineWidth: 6)
                                .scaleEffect(pulseScale)
                                .opacity(2 - pulseScale)
                                .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: pulseScale)
                        )
                    }
                }
                .frame(width: 200, height: 200)
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .onAppear {
            startCountdown()
        }
    }
    
    // MARK: - 动画控制
    
    private func startCountdown() {
        // 初始动画
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0.95
            animationOpacity = 1.0
            animationScale = 1.0
        }
        
        // 开始脉冲动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pulseScale = 2.0
        }
        
        // 倒计时逻辑
        countdownStep()
    }
    
    private func countdownStep() {
        // 数字缩放动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            animationScale = 1.2
        }
        
        // 震动反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 恢复缩放
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                animationScale = 1.0
            }
        }
        
        // 下一个数字或GO
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if currentCount > 1 {
                currentCount -= 1
                countdownStep()
            } else {
                showGOAnimation()
            }
        }
    }
    
    private func showGOAnimation() {
        // 切换到GO
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOpacity = 0.0
            animationScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showGO = true
            pulseScale = 1.0
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                animationOpacity = 1.0
                animationScale = 1.0
            }
            
            // 重新开始脉冲
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulseScale = 2.5
            }
            
            // 强烈震动反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // 完成动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completeAnimation()
            }
        }
    }
    
    private func completeAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            backgroundOpacity = 0.0
            animationOpacity = 0.0
            animationScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
    
    // MARK: - 辅助方法
    
    private func getWorkoutIcon() -> String {
        return workoutType.icon
    }

    private func getWorkoutTypeName() -> String {
        switch workoutType {
        case .running:
            return "户外跑步"
        case .walking:
            return "户外步行"
        case .cycling:
            return "户外骑行"
        case .swimming:
            return "户外游泳"
        case .hiking:
            return "户外徒步"
        case .yoga:
            return "瑜伽"
        case .fitness:
            return "健身"
        case .basketball:
            return "篮球"
        case .football:
            return "足球"
        case .tennis:
            return "网球"
        case .badminton:
            return "羽毛球"
        case .pingpong:
            return "乒乓球"
        case .climbing:
            return "攀岩"
        case .dancing:
            return "舞蹈"
        case .boxing:
            return "拳击"
        case .martialArts:
            return "武术"
        case .pilates:
            return "普拉提"
        case .aerobics:
            return "有氧运动"
        case .strength:
            return "力量训练"
        case .other:
            return "其他运动"
        }
    }
}

// MARK: - 预览
struct WorkoutCountdownView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutCountdownView(
            workoutType: .running,
            workoutMode: .free
        ) {
            print("倒计时完成")
        }
    }
}
