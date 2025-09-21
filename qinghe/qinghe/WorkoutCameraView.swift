import SwiftUI
import AVFoundation
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

struct WorkoutCameraView: View {
    let cameraManager: WorkoutCameraManager
    let workoutData: ExtendedWorkoutPhotoData
    let onPhotoTaken: (UIImage) -> Void
    
    @State private var capturedImage: UIImage?
    @State private var showPreview = false
    @State private var isTakingPhoto = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // 相机预览
            CameraPreviewView()
                .ignoresSafeArea(.all)
            
            // UI覆盖层
            VStack {
                // 顶部控制栏
                topControlBar
                
                Spacer()
                
                // 底部控制栏
                bottomControlBar
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            
            // 拍照预览
            if showPreview, let image = capturedImage {
                photoPreviewOverlay(image: image)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private var topControlBar: some View {
        HStack {
            // 关闭按钮
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 运动数据显示
            workoutDataOverlay
            
            Spacer()
            
            // 闪光灯切换
            Button(action: {
                cameraManager.toggleFlash()
            }) {
                Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    private var workoutDataOverlay: some View {
        VStack(spacing: 4) {
            Text("\(workoutData.workoutType)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Text(String(format: "%.2f km", workoutData.distance))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("•")
                    .foregroundColor(.white.opacity(0.5))
                
                Text(formatDuration(workoutData.duration))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
        )
    }
    
    private var bottomControlBar: some View {
        HStack {
            // 相册按钮（占位）
            Button(action: {}) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            }
            
            Spacer()
            
            // 拍照按钮
            Button(action: takePhoto) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                        .scaleEffect(isTakingPhoto ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isTakingPhoto)
                }
            }
            .disabled(isTakingPhoto)
            
            Spacer()
            
            // 前后摄像头切换
            Button(action: {
                cameraManager.switchCamera()
            }) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    private func photoPreviewOverlay(image: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                // 预览图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                    .cornerRadius(12)
                
                // 操作按钮
                HStack(spacing: 40) {
                    // 重新拍摄
                    Button(action: {
                        showPreview = false
                        capturedImage = nil
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            
                            Text("重拍")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 使用照片
                    Button(action: {
                        onPhotoTaken(image)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            Text("使用照片")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func takePhoto() {
        guard !isTakingPhoto else { return }
        
        isTakingPhoto = true
        
        // 模拟拍照延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 创建模拟照片（实际应该从相机获取）
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
            let image = renderer.image { context in
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
                
                // 添加运动数据文字
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
                ]
                
                let text = """
                \(workoutData.workoutType)
                \(String(format: "%.2f", workoutData.distance)) km
                \(formatDuration(workoutData.duration))
                """
                
                text.draw(in: CGRect(x: 20, y: 20, width: 260, height: 100), withAttributes: attributes)
            }
            
            capturedImage = image
            showPreview = true
            isTakingPhoto = false
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// 相机预览视图
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView()
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // 更新视图
    }
}

class CameraPreviewUIView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        
        // 添加模拟相机预览
        let label = UILabel()
        label.text = "相机预览"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}