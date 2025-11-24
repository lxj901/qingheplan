import SwiftUI
import Photos

/// 海报预览界面
struct PosterPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let posterUrl: String
    let shareUrl: String?
    let onDismiss: (() -> Void)?
    
    @State private var posterImage: UIImage?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showSaveSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 海报预览区域
                    posterPreviewArea
                    
                    // 底部操作按钮
                    bottomActionButtons
                }
            }
            .navigationTitle("海报预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showSaveSuccess {
                    saveSuccessOverlay
                }
            }
        }
        .onAppear {
            loadPosterImage()
        }
    }
    
    // MARK: - 海报预览区域
    
    private var posterPreviewArea: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if let image = posterImage {
                    posterImageView(image)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载海报...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }
    
    // MARK: - 错误视图
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                loadPosterImage()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }
    
    // MARK: - 海报图片视图
    
    private func posterImageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
    }
    
    // MARK: - 底部操作按钮
    
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            Divider()

            // 保存到相册按钮
            Button {
                saveToPhotoLibrary()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存到相册")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(posterImage == nil || isSaving)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
    
    // MARK: - 保存成功提示
    
    private var saveSuccessOverlay: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("已保存到相册")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
        }
        .transition(.scale.combined(with: .opacity))
        .zIndex(999)
    }
    
    // MARK: - Methods
    
    /// 加载海报图片
    private func loadPosterImage() {
        isLoading = true
        loadError = nil
        
        Task {
            do {
                guard let url = URL(string: posterUrl) else {
                    throw NSError(domain: "PosterPreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
                }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "PosterPreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片格式错误"])
                }
                
                await MainActor.run {
                    posterImage = image
                    isLoading = false
                }
                
                print("✅ 海报图片加载成功")
                
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    isLoading = false
                }
                print("❌ 海报图片加载失败: \(error)")
            }
        }
    }
    
    /// 保存到相册
    private func saveToPhotoLibrary() {
        guard let image = posterImage else { return }
        
        isSaving = true
        
        Task {
            do {
                // 请求相册权限
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                
                guard status == .authorized || status == .limited else {
                    throw NSError(domain: "PhotoLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有相册权限"])
                }
                
                // 保存图片
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                
                await MainActor.run {
                    isSaving = false
                    
                    // 显示成功提示
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSaveSuccess = true
                    }
                    
                    // 1.5秒后隐藏提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSaveSuccess = false
                        }
                    }
                }
                
                print("✅ 海报已保存到相册")
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ 保存到相册失败: \(error)")
            }
        }
    }
    

}

// MARK: - 预览

#if DEBUG
struct PosterPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PosterPreviewView(
            posterUrl: "https://example.com/poster.png",
            shareUrl: "https://example.com/share/123",
            onDismiss: nil
        )
    }
}
#endif

