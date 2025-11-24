import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - OCR 相机视图
struct ClassicsOCRCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = OCRCameraManager()
    @State private var capturedImages: [UIImage] = []
    @State private var showPreview = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var showSettings = false
    @State private var captureMode: CaptureMode = .singlePage
    @State private var showPDFPicker = false
    @State private var showWordPicker = false

    enum CaptureMode {
        case singlePage
        case multiPage
    }
    
    var body: some View {
        ZStack {
            // 相机预览层
            OCRCameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            // 顶部拍摄模式切换（拍单页/拍多页）
            VStack {
                HStack(spacing: 16) {
                    Button(action: {
                        captureMode = .singlePage
                    }) {
                        Text("拍单页")
                            .font(.system(size: 16, weight: captureMode == .singlePage ? .semibold : .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                captureMode == .singlePage ? Color.blue : Color.black.opacity(0.5)
                            )
                            .cornerRadius(20)
                    }

                    Button(action: {
                        captureMode = .multiPage
                    }) {
                        Text("拍多页")
                            .font(.system(size: 16, weight: captureMode == .multiPage ? .semibold : .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                captureMode == .multiPage ? Color.blue : Color.black.opacity(0.5)
                            )
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 60)

                Spacer()
            }

            // 右侧功能按钮
            VStack {
                Spacer()
                rightSideButtons
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)

            // 底部控制栏
            VStack {
                Spacer()
                bottomControlBar
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 下滑手势退出
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showPreview) {
            OCRImagePreviewView(
                images: capturedImages,
                onConfirm: { images in
                    // 跳转到 OCR 识别结果页面
                    showPreview = false
                    // TODO: 导航到识别结果页面
                },
                onRetake: {
                    capturedImages.removeAll()
                    showPreview = false
                }
            )
        }
        .sheet(isPresented: $showPDFPicker) {
            DocumentPicker(
                allowedContentTypes: [.pdf],
                onDocumentPicked: { url in
                    handleDocumentPicked(url: url, fileType: "PDF")
                }
            )
        }
        .sheet(isPresented: $showWordPicker) {
            DocumentPicker(
                allowedContentTypes: [
                    UTType(filenameExtension: "docx") ?? .data,
                    UTType(filenameExtension: "doc") ?? .data
                ],
                onDocumentPicked: { url in
                    handleDocumentPicked(url: url, fileType: "Word")
                }
            )
        }
    }

    // MARK: - 右侧功能按钮
    private var rightSideButtons: some View {
        VStack(spacing: 24) {
            // 方向矫正
            OCRFunctionButton(
                icon: "crop.rotate",
                title: "方向矫正",
                action: {
                    // TODO: 方向矫正功能
                }
            )

            // 手电筒
            OCRFunctionButton(
                icon: flashMode == .on ? "flashlight.on.fill" : "flashlight.off.fill",
                title: "手电筒",
                action: {
                    toggleFlash()
                }
            )
        }
    }
    
    // MARK: - 底部控制栏
    private var bottomControlBar: some View {
        VStack(spacing: 16) {
            // 扫描文件模式标签
            Text("扫描文件")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(16)
                .padding(.top, 20)

            // 底部操作栏
            HStack(spacing: 60) {
                // 导入 PDF
                Button(action: {
                    showPDFPicker = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("导入PDF")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }

                // 拍照按钮
                Button(action: {
                    takePhoto()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }

                // 导入 Word
                Button(action: {
                    showWordPicker = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("导入Word")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - 拍照功能
    private func takePhoto() {
        cameraManager.takePhoto { image in
            if let image = image {
                capturedImages.append(image)
                showPreview = true
            }
        }
    }
    
    // MARK: - 切换闪光灯
    private func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
        cameraManager.setFlashMode(flashMode)
    }

    // MARK: - 处理文档选择
    private func handleDocumentPicked(url: URL, fileType: String) {
        print("📄 选择了\(fileType)文件: \(url.lastPathComponent)")
        // TODO: 处理文档导入，可以调用 ClassicsImportService 进行导入
        // 或者跳转到导入页面进行进一步处理
    }
}

// MARK: - OCR 功能按钮组件
struct OCRFunctionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
        }
    }
}

