import SwiftUI
import CoreLocation

struct WorkoutLockScreenView: View {
    let lockManager: WorkoutScreenLockManager
    let cameraManager: WorkoutCameraManager
    let lockScreenData: LockScreenData
    let onUnlock: () -> Void
    let onTakePhoto: () -> Void
    
    @State private var showUnlockSlider = false
    @State private var isUnlocking = false
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 24) {
                Spacer()
                
                // 锁屏图标
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)
                
                // 运动数据展示
                lockScreenDataView
                
                Spacer()
                
                // 解锁控件
                unlockControls
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            showUnlockSlider.toggle()
        }
    }
    
    private var lockScreenDataView: some View {
        VStack(spacing: 20) {
            // 运动时长
            VStack(spacing: 4) {
                Text(formatTime(Int(lockScreenData.elapsedTime)))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("运动时长")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 距离和配速
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", lockScreenData.distance))
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("km")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 4) {
                    Text(lockScreenData.pace)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("配速")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // 心率和卡路里
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(lockScreenData.heartRate)")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text("心率")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 4) {
                    Text("\(lockScreenData.calories)")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    Text("卡路里")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var unlockControls: some View {
        VStack(spacing: 16) {
            if showUnlockSlider {
                // 滑动解锁
                Button(action: onUnlock) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("滑动解锁")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // 提示文字
            Text("轻触屏幕显示解锁")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .opacity(showUnlockSlider ? 0 : 1)
        }
        .animation(.easeInOut(duration: 0.3), value: showUnlockSlider)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}