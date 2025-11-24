import AVFoundation
import UIKit
import SwiftUI

// MARK: - OCR 相机管理器
final class OCRCameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "ocr.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    
    @Published var isSessionActive = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    private var currentDevice: AVCaptureDevice?
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        configureSession()
    }
    
    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionActive = true
                }
                print("📸 OCR相机会话已启动")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionActive = false
                }
                print("📸 OCR相机会话已停止")
            }
        }
    }
    
    // MARK: - Photo Capture
    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        
        // 设置闪光灯模式
        if flashMode == .on {
            if photoOutput.supportedFlashModes.contains(.on) {
                settings.flashMode = .on
            }
        } else {
            settings.flashMode = .off
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 开始拍照，闪光灯: \(flashMode == .on ? "开" : "关")")
    }
    
    // MARK: - Flash Control
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        flashMode = mode
        
        // 如果需要手电筒常亮效果
        if mode == .on {
            sessionQueue.async { [weak self] in
                guard let device = self?.currentDevice,
                      device.hasTorch,
                      device.isTorchAvailable else { return }
                
                do {
                    try device.lockForConfiguration()
                    try device.setTorchModeOn(level: 1.0)
                    device.unlockForConfiguration()
                    print("📸 手电筒已打开")
                } catch {
                    print("📸 无法打开手电筒: \(error)")
                }
            }
        } else {
            sessionQueue.async { [weak self] in
                guard let device = self?.currentDevice,
                      device.hasTorch else { return }
                
                do {
                    try device.lockForConfiguration()
                    device.torchMode = .off
                    device.unlockForConfiguration()
                    print("📸 手电筒已关闭")
                } catch {
                    print("📸 无法关闭手电筒: \(error)")
                }
            }
        }
    }
    
    // MARK: - Camera Switch
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // 移除当前输入
            if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                self.session.removeInput(currentInput)
                
                // 切换到另一个摄像头
                let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
                
                guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                      let newInput = try? AVCaptureDeviceInput(device: newDevice),
                      self.session.canAddInput(newInput) else {
                    self.session.addInput(currentInput)
                    self.session.commitConfiguration()
                    return
                }
                
                self.session.addInput(newInput)
                self.currentDevice = newDevice
            }
            
            self.session.commitConfiguration()
            print("📸 摄像头已切换")
        }
    }
    
    // MARK: - Private Configuration
    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // 默认使用后置摄像头
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                print("📸 无法配置OCR相机输入")
                return
            }
            
            self.session.addInput(input)
            self.currentDevice = device
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            print("📸 OCR相机配置完成")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension OCRCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("📸 拍照失败: \(error)")
            photoCaptureCompletion?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("📸 无法获取图片数据")
            photoCaptureCompletion?(nil)
            return
        }
        
        print("📸 拍照成功")
        photoCaptureCompletion?(image)
    }
}

// MARK: - OCR 相机预览视图
struct OCRCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> OCRCameraPreviewUIView {
        let view = OCRCameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: OCRCameraPreviewUIView, context: Context) {}
}

// MARK: - OCR 相机预览 UIView
class OCRCameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
        }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

