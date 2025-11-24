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
            // 真实相机预览
            CameraPreviewView(session: cameraManager.session)
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
            // 确保关闭手电筒
            if cameraManager.isFlashOn {
                cameraManager.toggleFlash()
            }
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
            // 左侧占位（保持布局平衡）
            Color.clear
                .frame(width: 44, height: 44)

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

        // 使用真实相机拍照
        cameraManager.takePhoto { [self] image in
            DispatchQueue.main.async {
                if let image = image {
                    // 在照片上添加运动数据水印
                    let watermarkedImage = addWorkoutDataWatermark(to: image)
                    self.capturedImage = watermarkedImage
                    self.showPreview = true
                } else {
                    print("📸 拍照失败")
                }
                self.isTakingPhoto = false
            }
        }
    }

    // 在照片上添加运动数据水印
    private func addWorkoutDataWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // 绘制原始照片
            image.draw(at: .zero)

            // 添加半透明背景
            let padding: CGFloat = 20
            let textHeight: CGFloat = 100
            let rect = CGRect(
                x: padding,
                y: image.size.height - textHeight - padding,
                width: image.size.width - padding * 2,
                height: textHeight
            )

            UIColor.black.withAlphaComponent(0.6).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()

            // 添加运动数据文字
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .paragraphStyle: paragraphStyle
            ]

            let text = """
            \(workoutData.workoutType)
            距离: \(String(format: "%.2f", workoutData.distance)) km
            时长: \(formatDuration(workoutData.duration))
            """

            let textRect = CGRect(
                x: rect.origin.x + 15,
                y: rect.origin.y + 15,
                width: rect.width - 30,
                height: rect.height - 30
            )

            text.draw(in: textRect, withAttributes: attributes)
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

// MARK: - 真实相机预览视图
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView(session: session)
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // 更新视图（如果需要）
    }
}

class CameraPreviewUIView: UIView {
    private let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)

        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}