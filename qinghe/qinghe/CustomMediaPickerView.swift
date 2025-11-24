import SwiftUI
import Photos
import PhotosUI

/// 媒体类型枚举
enum MediaType: String, CaseIterable {
    case all = "全部"
    case videos = "视频"
    case photos = "照片"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .videos: return "video"
        case .photos: return "photo"
        }
    }
}

/// 自定义媒体选择器视图
struct CustomMediaPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideoURLs: [URL]
    
    let maxImageSelection: Int
    let maxVideoSelection: Int
    
    @State private var selectedMediaType: MediaType = .all
    @State private var assets: [PHAsset] = []
    @State private var selectedAssets: [String] = [] // 改为数组类型以支持索引
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false

    // 相册列表
    @State private var albums: [PHAssetCollection] = []
    @State private var selectedAlbum: PHAssetCollection?
    @State private var showingAlbumPicker = false

    // 预览相关
    @State private var showingPreview = false
    @State private var previewAsset: PHAsset?
    @State private var previewThumbnail: UIImage?
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack {
            // 主内容层
            NavigationView {
                VStack(spacing: 0) {
                    // 顶部导航栏
                    topNavigationBar

                    // 媒体网格（只显示图片，不需要类型选项卡）
                    if authorizationStatus == .authorized || authorizationStatus == .limited {
                        mediaGridView
                    } else {
                        permissionView
                    }
                }
                .background(Color.black)
                .navigationBarHidden(true)
            }
            .onAppear {
                checkPhotoLibraryPermission()
            }

            // 预览层 - 放在最顶层，全屏显示
            if showingPreview, let asset = previewAsset {
                MediaPreviewView(
                    asset: asset,
                    initialThumbnail: previewThumbnail,
                    isSelected: selectedAssets.contains(asset.localIdentifier),
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingPreview = false
                        }
                    },
                    onToggleSelection: {
                        toggleAssetSelection(asset)
                    }
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: {
                showingAlbumPicker.toggle()
            }) {
                HStack(spacing: 4) {
                    Text(selectedAlbum?.localizedTitle ?? "最近项目")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Button(action: {
                confirmSelection()
            }) {
                Text("完成")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedAssets.isEmpty ? .gray : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(selectedAssets.isEmpty ? Color.white.opacity(0.2) : Color.blue)
                    .cornerRadius(16)
            }
            .disabled(selectedAssets.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
        .sheet(isPresented: $showingAlbumPicker) {
            AlbumPickerView(albums: albums, selectedAlbum: $selectedAlbum) { album in
                selectedAlbum = album
                loadAssets(from: album)
                showingAlbumPicker = false
            }
        }
    }
    
    // MARK: - 媒体类型选项卡
    private var mediaTypeTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MediaType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMediaType = type
                        filterAssets()
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(type.rawValue)
                            .font(.system(size: 15, weight: selectedMediaType == type ? .semibold : .regular))
                            .foregroundColor(selectedMediaType == type ? .white : .gray)
                        
                        if selectedMediaType == type {
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 2)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.black)
    }
    
    // MARK: - 媒体网格视图
    private var mediaGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    MediaThumbnailView(
                        asset: asset,
                        isSelected: selectedAssets.contains(asset.localIdentifier),
                        selectionIndex: selectedAssets.firstIndex(of: asset.localIdentifier).map { $0 + 1 },
                        onTap: {
                            toggleAssetSelection(asset)
                        },
                        onPreview: { thumbnail in
                            previewAsset = asset
                            previewThumbnail = thumbnail
                            showingPreview = true
                        }
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - 权限视图
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("需要访问相册权限")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("请在设置中允许访问相册")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("前往设置")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - 权限检查
    private func checkPhotoLibraryPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch authorizationStatus {
        case .authorized, .limited:
            loadAlbums()
            loadRecentAssets()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    authorizationStatus = status
                    if status == .authorized || status == .limited {
                        loadAlbums()
                        loadRecentAssets()
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    // MARK: - 加载相册列表
    private func loadAlbums() {
        var albumList: [PHAssetCollection] = []

        // 获取智能相册 - 使用 .any 子类型避免不支持的组合
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            albumList.append(collection)
        }

        // 获取用户相册 - 使用 .any 子类型
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            albumList.append(collection)
        }

        albums = albumList
    }
    
    // MARK: - 加载最近资源（只加载图片）
    private func loadRecentAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        var assetArray: [PHAsset] = []

        allAssets.enumerateObjects { asset, _, _ in
            assetArray.append(asset)
        }

        assets = assetArray
    }

    // MARK: - 从相册加载资源（只加载图片）
    private func loadAssets(from album: PHAssetCollection) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let albumAssets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        var assetArray: [PHAsset] = []

        albumAssets.enumerateObjects { asset, _, _ in
            assetArray.append(asset)
        }

        assets = assetArray
    }

    // MARK: - 过滤资源（已在加载时过滤，只显示图片）
    private func filterAssets() {
        // 已在 loadRecentAssets 和 loadAssets 中通过 predicate 过滤，只加载图片
    }
    
    // MARK: - 切换资源选择（只允许选择图片）
    private func toggleAssetSelection(_ asset: PHAsset) {
        let identifier = asset.localIdentifier

        if let index = selectedAssets.firstIndex(of: identifier) {
            selectedAssets.remove(at: index)
        } else {
            // 只检查图片选择限制
            if asset.mediaType == .image && selectedAssets.count >= maxImageSelection {
                return
            }
            selectedAssets.append(identifier)
        }
    }

    // MARK: - 确认选择（只加载图片）
    private func confirmSelection() {
        Task {
            var images: [UIImage] = []

            for identifier in selectedAssets {
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject {
                    if asset.mediaType == .image {
                        // 加载图片
                        if let image = await loadImage(from: asset) {
                            images.append(image)
                        }
                    }
                }
            }

            await MainActor.run {
                selectedImages = images
                selectedVideoURLs = [] // 清空视频URL
                dismiss()
            }
        }
    }

    // MARK: - 加载图片
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            let targetSize = CGSize(width: 1920, height: 1920)

            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - 加载视频
    private func loadVideo(from asset: PHAsset) async -> URL? {
        return await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - 媒体缩略图视图
struct MediaThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void
    let onPreview: (UIImage?) -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // 图片/视频内容 - 点击预览
                Button(action: {
                    if thumbnail == nil {
                        thumbnail = requestQuickThumbnailSync()
                    }
                    onPreview(thumbnail)
                }) {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // 视频时长标签
                if asset.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(formatDuration(asset.duration))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                                .padding(6)
                        }
                    }
                    .allowsHitTesting(false)
                }

                // 选择标记
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onTap) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.white.opacity(0.3))
                                    .frame(width: 24, height: 24)

                                if isSelected, let index = selectionIndex {
                                    Text("\(index)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        let size = CGSize(width: 200, height: 200)

        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }

    // 当用户点击但缩略图尚未到手时，使用一次极小尺寸的同步请求确保“秒显”
    private func requestQuickThumbnailSync() -> UIImage? {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        var result: UIImage?
        manager.requestImage(for: asset,
                             targetSize: CGSize(width: 300, height: 300),
                             contentMode: .aspectFill,
                             options: options) { image, _ in
            result = image
        }
        return result
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 相册选择器视图
struct AlbumPickerView: View {
    let albums: [PHAssetCollection]
    @Binding var selectedAlbum: PHAssetCollection?
    let onSelect: (PHAssetCollection) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(albums, id: \.localIdentifier) { album in
                Button(action: {
                    onSelect(album)
                }) {
                    HStack {
                        Text(album.localizedTitle ?? "未命名")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedAlbum?.localIdentifier == album.localIdentifier {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("选择相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

