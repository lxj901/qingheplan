import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers
import UIKit

// MARK: - Window 工具（本文件使用）
@inline(__always)
private func getKeyWindow() -> UIWindow? {
    for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene {
            if let key = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
        }
    }
    return UIApplication.shared.windows.first { $0.isKeyWindow }
}

// MARK: - Twitter Style Design System
struct TwitterStyleDesignSystem {
    struct Colors {
        static let counterOverlay = Color.black.opacity(0.6)
        static let counterText = Color.white
        static let deleteButtonBackground = Color.black.opacity(0.6)
        static let deleteButtonIcon = Color.white
    }

    struct Typography {
        static let counterFont = Font.system(size: 12, weight: .medium)
        static let deleteButtonFont = Font.system(size: 12, weight: .bold)
    }

    struct Sizes {
        static let deleteButtonSize: CGFloat = 24
        static let deleteButtonPadding: CGFloat = 4
    }

    struct ImageGrid {
        static let cornerRadius: CGFloat = 12
        static let singleImageMaxHeight: CGFloat = 400
        static let spacing: CGFloat = 4
    }

    struct AspectRatios {
        static let twoImages: CGFloat = 16/9
        static let threeImages: CGFloat = 16/9
        static let fourImages: CGFloat = 1.0
        static let multipleImages: CGFloat = 16/9
    }

    // MARK: - Size calculation methods
    static func singleImageSize(maxWidth: CGFloat) -> CGSize {
        let width = min(maxWidth - 32, 350)
        let height = min(width * 0.75, ImageGrid.singleImageMaxHeight)
        return CGSize(width: width, height: height)
    }

    static func twoImagesSize(totalWidth: CGFloat) -> CGSize {
        let spacing: CGFloat = 4
        let width = (totalWidth - spacing) / 2
        let height = width / AspectRatios.twoImages
        return CGSize(width: width, height: height)
    }

    static func threeImagesSize(totalWidth: CGFloat) -> (large: CGSize, small: CGSize) {
        let spacing: CGFloat = 4
        let largeWidth = totalWidth * 0.6
        let smallWidth = totalWidth * 0.4 - spacing
        let height = largeWidth / AspectRatios.threeImages

        return (
            large: CGSize(width: largeWidth, height: height),
            small: CGSize(width: smallWidth, height: height / 2 - spacing / 2)
        )
    }

    static func fourImagesSize(totalWidth: CGFloat) -> CGSize {
        let spacing: CGFloat = 4
        let width = (totalWidth - spacing) / 2
        let height = width
        return CGSize(width: width, height: height)
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct NewPublishPostView: View {
    @State private var content = ""
    @State private var selectedImages: [UIImage] = []
    @State private var privacy: PrivacyOption = .public
    @State private var location = ""
    @State private var topics: [String] = []

    @State private var isPosting = false
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showCustomMediaPicker = false // 新增：显示自定义媒体选择器

    @State private var navigateToLocationSelection = false
    @State private var navigateToTopicSelection = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var selectedVideoURLs: [URL] = []

    // 权限管理相关状态 - 根据API文档只支持评论和分享
    @State private var allowComments = true
    @State private var allowSharing = true
    @State private var showPermissionSettings = false
    @State private var showPrivacySettings = false

    // AI生成内容声明
    @State private var isAIGenerated = false

    // 新增：打卡数据和运动数据相关状态
    @State private var navigateToWorkoutRecords = false
    @State private var selectedWorkoutData: WorkoutDataForPost?
    @State private var navigateToCheckinRecords = false
    @State private var selectedCheckinData: CheckinDataForPost?

    // 视频上传相关状态
    @State private var uploadingVideoId: String? // 正在上传的视频ID
    @State private var videoUploadProgress: Double = 0 // 上传进度 0-1
    @State private var videoModerationStatus: String? // 审核状态
    @State private var videoModerationAttempt: Int = 0 // 当前轮询次数
    @State private var showVideoPublishConfirm = false // 显示发布确认弹窗
    @State private var videoTitle: String = "" // 视频标题

    // 位置坐标信息
    @State private var latitude: Double?
    @State private var longitude: Double?

    // 用于控制页面关闭
    @Environment(\.dismiss) private var dismiss

    // 社区视图模型
    @ObservedObject private var communityViewModel = CommunityViewModel.shared

    // 发布失败提示
    @State private var showPublishErrorAlert = false
    @State private var publishErrorMessage: String = ""

    // 上传成功提示（审核中）
    @State private var showVideoUploadInfoAlert = false
    @State private var videoUploadInfoMessage: String = ""

    private let maxLength = 2000


    private var progressPercentage: Double {
        Double(content.count) / Double(maxLength)
    }

    private var canPost: Bool {
        (!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty || !selectedVideoURLs.isEmpty) &&
        content.count <= maxLength && !isPosting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 进度条
                    if !content.isEmpty {
                        ProgressView(value: progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressPercentage > 0.9 ? .red : .blue))
                            .scaleEffect(x: 1, y: 0.5)
                            .padding(.horizontal)
                    }

                    // 主要内容区域
                    ScrollView {
                        VStack(spacing: 20) {
                            // 文本输入区域
                            textInputSection

                            // 图片预览
                            if !selectedImages.isEmpty {
                                selectedContentSection
                            }

                            // 视频预览
                            if !selectedVideoURLs.isEmpty {
                                videoPreviewSection
                            }

                            // 话题、位置、打卡和运动信息
                            if !topics.isEmpty || !location.isEmpty || selectedCheckinData != nil || selectedWorkoutData != nil {
                                selectedInfoSection
                            }
                        }
                        .padding()
                        .padding(.bottom, 120) // 为底部固定模块预留空间
                    }

                    // 固定在底部的功能模块
                    functionsSection
                        .background(Color(.systemBackground))
                }

                // 发布中遮罩
                if isPosting {
                    postingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .asSubView()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("发布帖子")
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isPosting ? "发布中..." : "发布") {
                        handlePost()
                    }
                    .disabled(!canPost)
                    .fontWeight(.semibold)
                }
            }
            .navigationDestination(isPresented: $navigateToLocationSelection) {
                LocationSelectionView { selectedLocation, selectedLatitude, selectedLongitude in
                    location = selectedLocation
                    latitude = selectedLatitude
                    longitude = selectedLongitude
                    navigateToLocationSelection = false
                }
            }
            .navigationDestination(isPresented: $navigateToTopicSelection) {
                TopicSelectionView(selectedTopics: topics) { selectedTopics in
                    topics = selectedTopics
                    navigateToTopicSelection = false
                }
            }
            .navigationDestination(isPresented: $navigateToWorkoutRecords) {
                WorkoutRecordsSelectionView { workoutRecord in
                    selectedWorkoutData = workoutRecord.map { record in
                        WorkoutDataForPost(
                            workoutId: Int(record.id) ?? 0,
                            workoutType: record.type,
                            date: record.startTime,
                            duration: Int(record.duration),
                            distance: record.distance,
                            calories: record.calories,
                            notes: nil
                        )
                    }
                    navigateToWorkoutRecords = false
                }
            }
            .navigationDestination(isPresented: $navigateToCheckinRecords) {
                SelectablePersistenceDetailView { checkinRecord in
                    selectedCheckinData = checkinRecord
                    navigateToCheckinRecords = false
                }
                .asSubView()
            }
            .sheet(isPresented: $showPermissionSettings) {
                PostPermissionSettingsView(
                    allowComments: $allowComments,
                    allowShares: $allowSharing,
                    visibility: $privacy
                )
            }
        }
            .alert("发布失败", isPresented: $showPublishErrorAlert) {
                Button("确定", role: .cancel) {
                    showPublishErrorAlert = false
                }
            } message: {
                Text(publishErrorMessage)
            }
            .alert("视频审核通过", isPresented: $showVideoPublishConfirm) {
                Button("取消", role: .cancel) {
                    showVideoPublishConfirm = false
                }
                Button("确认发布") {
                    confirmPublishVideo()
                }
            } message: {
                Text("视频已通过审核，是否立即发布？\n发布后将触发转码，完成后即可播放。")
            }
            .alert("上传成功", isPresented: $showVideoUploadInfoAlert) {
                Button("确定") {
                    showVideoUploadInfoAlert = false
                    dismiss()
                }
            } message: {
                Text(videoUploadInfoMessage)
            }

        .fullScreenCover(isPresented: $showCustomMediaPicker) {
            CustomMediaPickerView(
                selectedImages: $selectedImages,
                selectedVideoURLs: $selectedVideoURLs,
                maxImageSelection: 9,
                maxVideoSelection: 1
            )
        }
    }

    // MARK: - View Components



    private var textInputSection: some View {
        VStack(spacing: 12) {
            // 文本输入框
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("分享你的想法...")
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 8)
                }

                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
            }

            // 底部工具栏
            HStack {
                Spacer()

                // 字数统计
                Text("\(content.count)/\(maxLength)")
                    .font(.system(size: 14))
                    .foregroundColor(content.count > Int(Double(maxLength) * 0.9) ?
                                   (content.count > maxLength ? .red : .orange) : .secondary)
            }
        }
    }

    private var selectedContentSection: some View {
        VStack(spacing: 16) {
            // 横向滑动图片布局
            HorizontalImageGrid(images: selectedImages, onRemove: removeImage)
        }
        .padding(16)
    }

    private var videoPreviewSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(selectedVideoURLs.enumerated()), id: \.offset) { index, url in
                ZStack(alignment: .topTrailing) {
                    VideoPlayerView(url: url)
                        .frame(height: 200)
                        .cornerRadius(12)

                    Button(action: { removeVideo(at: index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 24, height: 24)
                            )
                    }
                    .padding(8)
                }
            }
        }
        .padding(16)
    }

    private var selectedInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("附加信息")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }

            VStack(spacing: 8) {
                // 话题标签
                if !topics.isEmpty {
                    HStack {
                        Image(systemName: "number")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(topics, id: \.self) { topic in
                                    HStack(spacing: 4) {
                                        Text(topic)
                                            .font(.system(size: 12))
                                        Button(action: { removeTopic(topic) }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8))
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }

                // 位置信息
                if !location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .frame(width: 20)

                        Text(location)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { location = "" }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 打卡数据
                if let checkinData = selectedCheckinData {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .frame(width: 20)

                        Text(checkinData.displayText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { selectedCheckinData = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 运动数据
                if let workoutData = selectedWorkoutData {
                    HStack {
                        Image(systemName: "figure.run")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Text(workoutData.displayText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { selectedWorkoutData = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var imagePreviewSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: imageHeight)
                        .clipped()
                        .cornerRadius(12)

                    Button(action: { removeImage(at: index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
        }
    }

    private var topicTagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(topics, id: \.self) { topic in
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 12))
                        Text(topic)
                            .font(.system(size: 14))
                        Button(action: { removeTopic(topic) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
        }
    }

    private var locationSection: some View {
        HStack {
            Image(systemName: "location")
                .foregroundColor(.secondary)
            Text(location)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { location = "" }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var functionsSection: some View {
        VStack(spacing: 0) {
            // 顶部分割线
            Divider()

            // 功能按钮 - 单行水平滑动布局
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 图片按钮
                    FunctionButton(
                        icon: "photo",
                        title: "图片",
                        subtitle: selectedImages.isEmpty ? "添加图片" : "\(selectedImages.count)张图片",
                        isActive: !selectedImages.isEmpty,
                        action: {
                            // 使用自定义媒体选择器
                            showCustomMediaPicker = true
                        }
                    )

                    // 位置按钮
                    FunctionButton(
                        icon: "location",
                        title: "位置",
                        subtitle: location.isEmpty ? "添加位置" : location,
                        isActive: !location.isEmpty,
                        action: { navigateToLocationSelection = true }
                    )

                    // 话题按钮
                    FunctionButton(
                        icon: "number",
                        title: "话题",
                        subtitle: topics.isEmpty ? "添加话题" : "\(topics.count)个话题",
                        isActive: !topics.isEmpty,
                        action: { navigateToTopicSelection = true }
                    )

                    // 可见性设置按钮 - 根据API文档只支持public，暂时隐藏此功能
                    // FunctionButton(
                    //     icon: privacy.iconName,
                    //     title: "可见性",
                    //     subtitle: privacy.title,
                    //     isActive: privacy != .public,
                    //     action: {
                    //         // API暂不支持好友和私密可见性
                    //     }
                    // )

                    // 权限管理按钮 - 根据API文档只支持评论和分享
                    FunctionButton(
                        icon: "lock.shield",
                        title: "权限",
                        subtitle: getPermissionSummary(),
                        isActive: !allowComments || !allowSharing,
                        action: {
                            showPermissionSettings = true
                        }
                    )

                    
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // AI生成内容声明
            HStack(spacing: 8) {
                Toggle(isOn: $isAIGenerated) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(isAIGenerated ? AppConstants.Colors.primaryGreen : .secondary)

                        Text("AI生成内容")
                            .font(.system(size: 14))
                            .foregroundColor(isAIGenerated ? .primary : .secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppConstants.Colors.primaryGreen))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 底部提示
            VStack(spacing: 4) {
                if isAIGenerated {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("此内容由AI生成，仅供参考")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))

    }





    private var postingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    if !selectedVideoURLs.isEmpty {
                        // 视频上传进度
                        if videoUploadProgress < 1.0 {
                            Text("正在上传视频...")
                                .font(.system(size: 16))

                            // 进度条
                            ProgressView(value: videoUploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)

                            Text("\(Int(videoUploadProgress * 100))%")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else if videoModerationStatus == "pending" || videoModerationStatus == "reviewing" {
                            Text("视频审核中...")
                                .font(.system(size: 16))
                            Text("请稍候，审核通过后可发布")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            // 显示轮询进度
                            if videoModerationAttempt > 0 {
                                Text("已等待 \(videoModerationAttempt * 5) 秒")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        } else {
                            Text("正在发布视频...")
                                .font(.system(size: 16))
                        }
                    } else {
                        Text("正在发布动态...")
                            .font(.system(size: 16))
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            )
    }

    // MARK: - Computed Properties

    private var gridColumns: [GridItem] {
        let count = selectedImages.count
        if count == 1 {
            return [GridItem(.flexible())]
        } else if count == 2 {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else if count <= 4 {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else {
            return Array(repeating: GridItem(.flexible()), count: 3)
        }
    }

    private var imageHeight: CGFloat {
        let count = selectedImages.count
        if count == 1 {
            return 200
        } else {
            return 120
        }
    }

    // MARK: - Methods

    private func getPermissionSummary() -> String {
        // 显示当前被禁用的具体权限 - 根据API文档只支持评论和分享
        var disabledPermissions: [String] = []

        if !allowComments {
            disabledPermissions.append("评论")
        }
        if !allowSharing {
            disabledPermissions.append("分享")
        }

        if disabledPermissions.isEmpty {
            return "全部开启"
        } else if disabledPermissions.count == 2 {
            return "全部禁用"
        } else {
            return "禁用" + disabledPermissions.joined(separator: "、")
        }
    }

    private func cyclePermissionSettings() {
        // 简化的权限切换逻辑 - 根据API文档只支持评论和分享
        // 顺序：全部开启 -> 禁用评论 -> 禁用分享 -> 全部禁用 -> 全部开启

        if allowComments && allowSharing {
            // 全部开启 -> 禁用评论（最常见的限制）
            allowComments = false
            allowSharing = true
        } else if !allowComments && allowSharing {
            // 禁用评论 -> 禁用分享
            allowComments = false
            allowSharing = false
        } else if !allowComments && !allowSharing {
            // 全部禁用 -> 全部开启
            allowComments = true
            allowSharing = true
        } else {
            // 其他状态 -> 重置为全部开启
            allowComments = true
            allowSharing = true
        }
    }



    private func handlePost() {
        guard canPost else { return }

        // 如果有视频，先上传视频
        if !selectedVideoURLs.isEmpty {
            handleVideoPost()
        } else {
            // 没有视频，直接发布帖子
            handleTextImagePost()
        }
    }

    /// 处理视频发布
    private func handleVideoPost() {
        guard let videoURL = selectedVideoURLs.first else { return }

        // 检查视频文件大小
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                let fileSizeMB = Double(fileSize) / 1024 / 1024
                print("📹 视频文件大小: \(String(format: "%.2f", fileSizeMB))MB")

                // 检查文件大小限制（最大1GB）
                if fileSizeMB > 1024 {
                    publishErrorMessage = "视频文件过大（\(String(format: "%.1f", fileSizeMB))MB），最大支持1GB"
                    showPublishErrorAlert = true
                    return
                }
            }
        } catch {
            print("❌ 无法获取视频文件大小: \(error)")
        }

        // 检查是否填写了内容（视频标题必填）
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.isEmpty {
            publishErrorMessage = "请填写视频描述"
            showPublishErrorAlert = true
            return
        }

        // 使用内容作为视频标题
        let title = String(trimmedContent.prefix(100))

        isPosting = true
        videoUploadProgress = 0

        VideoService.shared.uploadVideo(
            videoURL: videoURL,
            title: title,
            description: content,
            category: nil,
            tags: topics.isEmpty ? nil : topics,
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.videoUploadProgress = progress
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        // 上传成功：提示正在审核中并退出发布页面，不再持续显示上传中
                        self.isPosting = false
                        self.videoUploadInfoMessage = response.message ?? response.data.message ?? "视频上传成功，正在审核中，请稍后在我的视频查看进度"
                        self.showVideoUploadInfoAlert = true

                    case .failure(let error):
                        self.isPosting = false
                        self.publishErrorMessage = "视频上传失败：\(error.localizedDescription)"
                        self.showPublishErrorAlert = true
                    }
                }
            }
        )
    }

    /// 轮询视频审核状态
    private func pollVideoStatus(videoId: String, attempt: Int = 1) {
        let maxAttempts = 24 // 约2分钟（24 * 5s）

        // 更新轮询次数
        self.videoModerationAttempt = attempt

        VideoService.shared.getVideoStatus(videoId: videoId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let status = response.data
                    self.videoModerationStatus = status.moderationStatus

                    if status.moderationStatus == "approved" && status.canPublish {
                        // 审核通过，显示发布确认弹窗
                        self.isPosting = false
                        self.showVideoPublishConfirm = true

                    } else if status.moderationStatus == "rejected" {
                        // 审核被拒绝
                        self.isPosting = false
                        self.publishErrorMessage = "视频审核未通过：\(status.message ?? "请检查视频内容")"
                        self.showPublishErrorAlert = true

                    } else if attempt >= maxAttempts {
                        // 超时：审核时间过长
                        self.isPosting = false
                        self.publishErrorMessage = """
                        视频审核时间较长，已在后台继续处理

                        视频ID: \(videoId)
                        当前状态: 审核中

                        您可以：
                        1. 稍后在"我的视频"中查看审核结果
                        2. 审核通过后可手动发布
                        """
                        self.showPublishErrorAlert = true

                    } else {
                        // 继续轮询（每5秒查询一次）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.pollVideoStatus(videoId: videoId, attempt: attempt + 1)
                        }
                    }

                case .failure(let error):
                    // 可能是短暂性错误（状态未就绪/网络波动/404），重试一段时间
                    if attempt < maxAttempts {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.pollVideoStatus(videoId: videoId, attempt: attempt + 1)
                        }
                    } else {
                        self.isPosting = false
                        self.publishErrorMessage = "查询视频状态失败：\(error.localizedDescription)"
                        self.showPublishErrorAlert = true
                    }
                }
            }
        }
    }

    /// 确认发布视频
    private func confirmPublishVideo() {
        guard let videoId = uploadingVideoId else { return }

        isPosting = true
        showVideoPublishConfirm = false

        VideoService.shared.publishVideo(videoId: videoId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 视频发布成功，关闭页面
                    self.isPosting = false
                    self.dismiss()

                case .failure(let error):
                    self.isPosting = false
                    self.publishErrorMessage = "视频发布失败：\(error.localizedDescription)"
                    self.showPublishErrorAlert = true
                }
            }
        }
    }

    /// 处理文本+图片发布
    private func handleTextImagePost() {
        isPosting = true

        // 准备发布参数
        let checkinId: Int? = selectedCheckinData?.checkinId
        let workoutId: Int? = selectedWorkoutData?.workoutId

        // 调用新的发布方法
        communityViewModel.publishPost(
            content: content,
            images: selectedImages,
            tags: topics,
            allowComments: allowComments,
            allowShares: allowSharing,
            visibility: privacy.apiValue,
            location: location.isEmpty ? nil : location,
            latitude: latitude,
            longitude: longitude,
            checkinId: checkinId,
            workoutId: workoutId,
            isAIGenerated: isAIGenerated,
            onSuccess: {
                // 发布成功，关闭页面
                DispatchQueue.main.async {
                    self.isPosting = false
                    self.dismiss()
                }
            },
            onFailure: { errorMessage in
                // 发布失败，显示错误信息
                DispatchQueue.main.async {
                    self.isPosting = false
                    self.publishErrorMessage = errorMessage
                    self.showPublishErrorAlert = true
                }
            }
        )
    }

    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }

    private func removeVideo(at index: Int) {
        selectedVideoURLs.remove(at: index)
    }

    private func removeTopic(_ topic: String) {
        topics.removeAll { $0 == topic }
    }


}

// MARK: - Smart Image Grid (Twitter Style)

struct SmartImageGrid: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void

    var body: some View {
        let count = images.count

        if count == 0 {
            EmptyView()
        } else {
            switch count {
            case 1:
                singleImageLayout
            case 2:
                twoImagesLayout
            case 3:
                threeImagesLayout
            case 4:
                fourImagesLayout
            default:
                multipleImagesLayout
            }
        }
    }

    // 单张图片 - 16:9比例，居中显示
    private var singleImageLayout: some View {
        GeometryReader { geometry in
            let size = TwitterStyleDesignSystem.singleImageSize(maxWidth: geometry.size.width)

            HStack {
                Spacer()
                ImageCard(
                    image: images[0],
                    index: 0,
                    width: size.width,
                    height: size.height,
                    onRemove: onRemove
                )
                Spacer()
            }
        }
        .frame(height: TwitterStyleDesignSystem.ImageGrid.singleImageMaxHeight)
    }

    // 两张图片 - 水平并排，1:1比例
    private var twoImagesLayout: some View {
        GeometryReader { geometry in
            let size = TwitterStyleDesignSystem.twoImagesSize(totalWidth: geometry.size.width)

            HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                ImageCard(
                    image: images[0],
                    index: 0,
                    width: size.width,
                    height: size.height,
                    onRemove: onRemove,
                    corners: [.topLeft, .bottomLeft]
                )

                ImageCard(
                    image: images[1],
                    index: 1,
                    width: size.width,
                    height: size.height,
                    onRemove: onRemove,
                    corners: [.topRight, .bottomRight]
                )
            }
        }
        .aspectRatio(TwitterStyleDesignSystem.AspectRatios.twoImages, contentMode: .fit)
    }

    // 三张图片 - 左大右小布局
    private var threeImagesLayout: some View {
        GeometryReader { geometry in
            let sizes = TwitterStyleDesignSystem.threeImagesSize(totalWidth: geometry.size.width)

            HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                // 左侧大图
                ImageCard(
                    image: images[0],
                    index: 0,
                    width: sizes.large.width,
                    height: sizes.large.height,
                    onRemove: onRemove,
                    corners: [.topLeft, .bottomLeft]
                )

                // 右侧两张小图
                VStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                    ImageCard(
                        image: images[1],
                        index: 1,
                        width: sizes.small.width,
                        height: sizes.small.height,
                        onRemove: onRemove,
                        corners: [.topRight]
                    )

                    ImageCard(
                        image: images[2],
                        index: 2,
                        width: sizes.small.width,
                        height: sizes.small.height,
                        onRemove: onRemove,
                        corners: [.bottomRight]
                    )
                }
            }
        }
        .aspectRatio(TwitterStyleDesignSystem.AspectRatios.threeImages, contentMode: .fit)
    }

    // 四张图片 - 2x2网格布局
    private var fourImagesLayout: some View {
        GeometryReader { geometry in
            let size = TwitterStyleDesignSystem.fourImagesSize(totalWidth: geometry.size.width)

            VStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                // 第一行
                HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                    ImageCard(
                        image: images[0],
                        index: 0,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.topLeft]
                    )

                    ImageCard(
                        image: images[1],
                        index: 1,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.topRight]
                    )
                }

                // 第二行
                HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                    ImageCard(
                        image: images[2],
                        index: 2,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.bottomLeft]
                    )

                    ImageCard(
                        image: images[3],
                        index: 3,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.bottomRight]
                    )
                }
            }
        }
        .aspectRatio(TwitterStyleDesignSystem.AspectRatios.fourImages, contentMode: .fit)
    }

    // 多张图片 - 显示前4张，第4张显示"+更多"
    private var multipleImagesLayout: some View {
        GeometryReader { geometry in
            let size = TwitterStyleDesignSystem.fourImagesSize(totalWidth: geometry.size.width)
            let remainingCount = images.count - 3

            VStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                // 第一行
                HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                    ImageCard(
                        image: images[0],
                        index: 0,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.topLeft]
                    )

                    ImageCard(
                        image: images[1],
                        index: 1,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.topRight]
                    )
                }

                // 第二行
                HStack(spacing: TwitterStyleDesignSystem.ImageGrid.spacing) {
                    ImageCard(
                        image: images[2],
                        index: 2,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        corners: [.bottomLeft]
                    )

                    ImageCard(
                        image: images[3],
                        index: 3,
                        width: size.width,
                        height: size.height,
                        onRemove: onRemove,
                        showCounter: remainingCount,
                        corners: [.bottomRight]
                    )
                }
            }
        }
        .aspectRatio(TwitterStyleDesignSystem.AspectRatios.multipleImages, contentMode: .fit)
    }
}

// MARK: - Image Card Component

struct ImageCard: View {
    let image: UIImage
    let index: Int
    let width: CGFloat
    let height: CGFloat
    let onRemove: (Int) -> Void
    let showCounter: Int?
    let corners: UIRectCorner

    init(image: UIImage, index: Int, width: CGFloat, height: CGFloat, onRemove: @escaping (Int) -> Void, showCounter: Int? = nil, corners: UIRectCorner = .allCorners) {
        self.image = image
        self.index = index
        self.width = width
        self.height = height
        self.onRemove = onRemove
        self.showCounter = showCounter
        self.corners = corners
    }

    var body: some View {
        ZStack {
            // 图片内容
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedCorner(radius: TwitterStyleDesignSystem.ImageGrid.cornerRadius, corners: corners))

            // 多图计数覆盖层
            if let counter = showCounter {
                Rectangle()
                    .fill(TwitterStyleDesignSystem.Colors.counterOverlay)
                    .clipShape(RoundedCorner(radius: TwitterStyleDesignSystem.ImageGrid.cornerRadius, corners: corners))

                Text("+\(counter)")
                    .font(TwitterStyleDesignSystem.Typography.counterFont)
                    .foregroundColor(TwitterStyleDesignSystem.Colors.counterText)
            }

            // 删除按钮 - 推特风格，右上角
            VStack {
                HStack {
                    Spacer()
                    Button(action: { onRemove(index) }) {
                        ZStack {
                            Circle()
                                .fill(TwitterStyleDesignSystem.Colors.deleteButtonBackground)
                                .frame(width: TwitterStyleDesignSystem.Sizes.deleteButtonSize, height: TwitterStyleDesignSystem.Sizes.deleteButtonSize)

                            Image(systemName: "xmark")
                                .font(TwitterStyleDesignSystem.Typography.deleteButtonFont)
                                .foregroundColor(TwitterStyleDesignSystem.Colors.deleteButtonIcon)
                        }
                    }
                    .padding(TwitterStyleDesignSystem.Sizes.deleteButtonPadding)
                }
                Spacer()
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Supporting Views

struct FunctionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 图标容器
                ZStack {
                    Circle()
                        .fill(isActive ? Color.blue.opacity(0.15) : Color(.systemGray6))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isActive ? .blue : .secondary)
                }

                // 文字信息
                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(width: 80)
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

struct PostPermissions {
    let allowComments: Bool
    let allowSharing: Bool

    init(allowComments: Bool = true, allowSharing: Bool = true) {
        self.allowComments = allowComments
        self.allowSharing = allowSharing
    }
}

enum PrivacyOption: CaseIterable, Hashable {
    case `public`
    // 暂时注释掉API尚未支持的选项
    // case friends, `private`

    var title: String {
        switch self {
        case .public: return "公开"
        // case .friends: return "好友"
        // case .private: return "私密"
        }
    }

    var iconName: String {
        switch self {
        case .public: return "globe"
        // case .friends: return "person.2"
        // case .private: return "lock"
        }
    }

    var description: String {
        switch self {
        case .public: return "所有人都可以看到此帖子"
        // case .friends: return "只有你的好友可以看到此帖子"
        // case .private: return "只有你自己可以看到此帖子"
        }
    }

    var iconColor: Color {
        switch self {
        case .public: return .blue
        // case .friends: return .green
        // case .private: return .orange
        }
    }

    var apiValue: String {
        switch self {
        case .public: return "public"
        // case .friends: return "friends"
        // case .private: return "private"
        }
    }
}

// MARK: - Permission Toggle Row

struct PermissionToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isEnabled ? .blue : .secondary)
                .frame(width: 24, height: 24)

            // 文字信息
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // 开关
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Horizontal Image Grid

struct HorizontalImageGrid: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void

    var body: some View {
        if images.isEmpty {
            EmptyView()
        } else if images.count == 1 {
            // 单张图片 - 9:16比例，居中显示
            singleImageLayout
        } else {
            // 多张图片 - 横向滑动，1:1比例
            horizontalScrollLayout
        }
    }

    // 单张图片布局
    private var singleImageLayout: some View {
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.5 // 占半个屏幕宽度
            let imageHeight = imageWidth * (16.0 / 9.0) // 9:16比例 (高:宽)

            HStack {
                Spacer()
                HorizontalImageCard(
                    image: images[0],
                    index: 0,
                    width: imageWidth,
                    height: imageHeight,
                    onRemove: onRemove
                )
                Spacer()
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.5 * (16.0 / 9.0) + 20) // 动态计算容器高度
    }

    // 横向滑动布局
    private var horizontalScrollLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    HorizontalImageCard(
                        image: image,
                        index: index,
                        width: 240, // 增大宽度到240
                        height: 240, // 1:1比例，增大高度到240
                        onRemove: onRemove
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 260) // 增大容器高度到260
    }
}

// MARK: - Horizontal Image Card

struct HorizontalImageCard: View {
    let image: UIImage
    let index: Int
    let width: CGFloat
    let height: CGFloat
    let onRemove: (Int) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(TwitterStyleDesignSystem.ImageGrid.cornerRadius)

            // 删除按钮
            Button(action: { onRemove(index) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 24, height: 24)
                    )
            }
            .padding(8)
        }
    }


}





// MARK: - 数据模型

/// 发布帖子用的打卡数据
struct CheckinDataForPost: Identifiable {
    let id = UUID()
    let checkinId: Int // 真正的打卡记录ID，用于发布帖子
    let date: Date
    let location: String?
    let note: String?
    let consecutiveDays: Int
    let totalDays: Int

    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        let dateStr = formatter.string(from: date)
        return "\(dateStr) 打卡 · 连续\(consecutiveDays)天"
    }

    /// 从API返回的SimpleCheckin创建CheckinDataForPost
    static func from(simpleCheckin: SimpleCheckin, stats: NewCheckinStatsData?) -> CheckinDataForPost {
        // 解析日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: simpleCheckin.date) ?? Date()

        // 构建位置信息
        let location = simpleCheckin.locationAddress?.isEmpty == false ? simpleCheckin.locationAddress : nil

        // 获取统计数据
        let consecutiveDays = stats?.currentStreak ?? 0
        let totalDays = stats?.totalDays ?? 0

        return CheckinDataForPost(
            checkinId: simpleCheckin.id, // 使用真正的打卡记录ID
            date: date,
            location: location,
            note: simpleCheckin.note?.isEmpty == false ? simpleCheckin.note : nil,
            consecutiveDays: consecutiveDays,
            totalDays: totalDays
        )
    }
}

/// 发布帖子用的运动数据
struct WorkoutDataForPost: Identifiable {
    let id = UUID()
    let workoutId: Int // 真正的运动记录ID
    let workoutType: String
    let date: Date
    let duration: Int // 秒
    let distance: Double? // 公里
    let calories: Int
    let notes: String?

    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        let dateStr = formatter.string(from: date)

        let durationStr = formatDuration(duration)
        let chineseWorkoutType = WorkoutDataForPost.convertWorkoutTypeToChineseName(workoutType) // 显示时转换为中文
        if let distance = distance {
            // 即使距离是0也显示距离
            return "\(dateStr) \(chineseWorkoutType) · \(String(format: "%.1f", distance))km · \(durationStr)"
        } else {
            return "\(dateStr) \(chineseWorkoutType) · \(durationStr) · \(calories)卡"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    /// 从API返回的QingheWorkout创建WorkoutDataForPost
    static func from(qingheWorkout: QingheWorkout) -> WorkoutDataForPost {
        // 使用更完善的日期解析逻辑
        let date = parseDate(qingheWorkout.startTime) ?? Date()
        print("📅 QingheWorkout日期转换: \(qingheWorkout.startTime) -> \(date)")

        // 获取距离（已经是公里单位），即使是0也保留
        let distance = qingheWorkout.basicMetrics.totalDistance

        return WorkoutDataForPost(
            workoutId: qingheWorkout.workoutId,
            workoutType: qingheWorkout.workoutType, // 保持原始英文类型，不转换为中文
            date: date,
            duration: qingheWorkout.duration,
            distance: distance,
            calories: qingheWorkout.basicMetrics.calories,
            notes: qingheWorkout.notes
        )
    }

    /// 从API返回的Workout创建WorkoutDataForPost
    static func from(workout: Workout) -> WorkoutDataForPost {
        // 使用更完善的日期解析逻辑
        let date = parseDate(workout.startTime) ?? Date()
        print("📅 Workout日期转换: \(workout.startTime) -> \(date)")

        // 获取距离（已经是公里单位），即使是0也保留
        let distance = workout.basicMetrics.totalDistance

        return WorkoutDataForPost(
            workoutId: workout.workoutId,
            workoutType: workout.workoutType, // 保持原始英文类型，不转换为中文
            date: date,
            duration: workout.duration,
            distance: distance,
            calories: workout.basicMetrics.calories,
            notes: workout.notes
        )
    }

    /// 解析API日期字符串 - 复用WorkoutRecordsViewModel的逻辑
    private static func parseDate(_ dateString: String) -> Date? {
        print("🔍 尝试解析日期字符串: \(dateString)")

        // 尝试ISO8601格式
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso8601Formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 设置为中国时区
        if let date = iso8601Formatter.date(from: dateString) {
            print("✅ ISO8601格式解析成功: \(dateString) -> \(date)")
            return date
        }

        // 尝试简单日期时间格式 "2025-07-12 01:37:32"
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 设置为中国时区
        if let date = dateTimeFormatter.date(from: dateString) {
            print("✅ 日期时间格式解析成功: \(dateString) -> \(date)")
            return date
        }

        // 尝试只有日期格式 "2025-07-12"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 设置为中国时区
        if let date = dateFormatter.date(from: dateString) {
            print("✅ 日期格式解析成功: \(dateString) -> \(date)")
            return date
        }

        print("⚠️ 无法解析日期字符串: \(dateString)")
        return nil // 现在如果解析失败，返回nil而不是当前日期
    }

    /// 将英文运动类型转换为中文名称
    static func convertWorkoutTypeToChineseName(_ workoutType: String) -> String {
        switch workoutType.lowercased() {
        case "running", "户外跑步", "跑步机", "treadmill":
            return "跑步"
        case "walking", "户外行走", "步行":
            return "行走"
        case "cycling", "户外骑行", "骑行":
            return "骑行"
        case "hiking", "徒步", "登山":
            return "徒步"
        case "swimming", "游泳", "泳池游泳":
            return "游泳"
        case "yoga", "瑜伽":
            return "瑜伽"
        case "strength", "力量训练", "举重":
            return "力量训练"
        case "elliptical", "椭圆机":
            return "椭圆机"
        case "rowing", "划船":
            return "划船"
        default:
            return "运动" // 默认为运动
        }
    }
}

#Preview {
    NewPublishPostView()
}

// MARK: - 使用示例
/*
 // 示例1: 单一视频URL（本地上传的视频）
 VideoPlayerView(url: videoURL)

 // 示例2: 多清晰度视频（从API获取的视频详情）
 let qualities = [
     VideoQuality.fromAPIVersion(quality: "hd", url: "https://example.com/video-hd.m3u8", bitrate: 5000, isDefault: false),
     VideoQuality.fromAPIVersion(quality: "sd", url: "https://example.com/video-sd.m3u8", bitrate: 2500, isDefault: true),
     VideoQuality.fromAPIVersion(quality: "ld", url: "https://example.com/video-ld.m3u8", bitrate: 1200, isDefault: false)
 ].compactMap { $0 }

 VideoPlayerView(url: qualities.first!.url, qualities: qualities)

 // 示例3: 从API VideoDetail响应创建画质列表
 func createQualities(from videoDetail: VideoDetail) -> [VideoQuality] {
     var qualities: [VideoQuality] = []

     if let hd = videoDetail.versions.hd {
         qualities.append(VideoQuality.fromAPIVersion(quality: "hd", url: hd.url, bitrate: hd.bitrate)!)
     }
     if let sd = videoDetail.versions.sd {
         qualities.append(VideoQuality.fromAPIVersion(quality: "sd", url: sd.url, bitrate: sd.bitrate, isDefault: true)!)
     }
     if let ld = videoDetail.versions.ld {
         qualities.append(VideoQuality.fromAPIVersion(quality: "ld", url: ld.url, bitrate: ld.bitrate)!)
     }

     return qualities
 }
*/

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "video-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Video Quality Model
struct VideoQuality: Identifiable {
    let id: String
    let url: URL
    let displayName: String
    let description: String?
    let bitrate: Int?
    let isDefault: Bool

    // 便捷初始化方法，匹配API返回格式
    static func fromAPIVersion(quality: String, url: String, bitrate: Int? = nil, isDefault: Bool = false) -> VideoQuality? {
        guard let videoURL = URL(string: url) else { return nil }

        let displayName: String
        let description: String?

        switch quality.lowercased() {
        case "hd", "1080p":
            displayName = "高清"
            description = "1080P"
        case "sd", "720p":
            displayName = "标清"
            description = "720P"
        case "ld", "480p":
            displayName = "流畅"
            description = "480P"
        default:
            displayName = quality
            description = nil
        }

        return VideoQuality(
            id: quality,
            url: videoURL,
            displayName: displayName,
            description: description,
            bitrate: bitrate,
            isDefault: isDefault
        )
    }
}

// MARK: - Enhanced Video Player View
struct VideoPlayerView: View {
    let url: URL
    var qualities: [VideoQuality]? = nil // 可选的多清晰度
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var showQualitySelector = false
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var isFullscreen = false

    // 便捷初始化 - 只有URL
    init(url: URL) {
        self.url = url
        self.qualities = nil
    }

    // 完整初始化 - 带画质选项
    init(url: URL, qualities: [VideoQuality]) {
        self.url = url
        self.qualities = qualities
    }

    var body: some View {
        ZStack {
            // 视频播放器层
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .allowsHitTesting(false) // 允许上层自定义控件接管点击
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }

            // 点击手势覆盖层（位于视频之上、控件之下）
            Color.clear
                .contentShape(Rectangle())
                // 双击：播放/暂停
                .highPriorityGesture(
                    TapGesture(count: 2).onEnded {
                        viewModel.togglePlayPause()
                        scheduleHideControls()
                    }
                )
                .onTapGesture {
                    // 点击视频切换控制栏显示/隐藏
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                    if showControls {
                        scheduleHideControls()
                    }
                }

            // 自定义控制层
            if showControls {
                VStack {
                    Spacer()

                    // 播放控制栏
                    VStack(spacing: 12) {
                        // 进度条
                        VideoProgressBar(
                            currentTime: viewModel.currentTime,
                            duration: viewModel.duration,
                            onSeek: { time in
                                viewModel.seek(to: time)
                            },
                            onDragStart: {
                                // 拖动时取消自动隐藏
                                hideControlsTask?.cancel()
                            },
                            onDragEnd: {
                                // 拖动结束后重新计时隐藏
                                scheduleHideControls()
                            }
                        )

                        // 控制按钮
                        HStack(spacing: 20) {
                            // 播放/暂停按钮
                            Button(action: {
                                viewModel.togglePlayPause()
                                scheduleHideControls()
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            // 时间显示
                            Text("\(formatTime(viewModel.currentTime)) / \(formatTime(viewModel.duration))")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Spacer()

                            // 画质切换按钮（如果有多清晰度）
                            if let qualities = qualities, !qualities.isEmpty {
                                Button(action: {
                                    hideControlsTask?.cancel()
                                    showQualitySelector.toggle()
                                }) {
                                    HStack(spacing: 4) {
                                        Text(viewModel.currentQuality?.displayName ?? "画质")
                                            .font(.system(size: 14))
                                        Image(systemName: "chevron.up")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(4)
                                }
                            }

                            // 全屏按钮
                            Button(action: {
                                hideControlsTask?.cancel()
                                isFullscreen = true
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .disabled(viewModel.player == nil)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }

            // 中央播放/暂停按钮（仅在暂停且显示控制栏时显示）
            if !viewModel.isPlaying && showControls {
                Button(action: {
                    viewModel.togglePlayPause()
                    scheduleHideControls()
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
            }

            // 加载指示器
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }

            // 画质选择器
            if showQualitySelector, let qualities = qualities {
                VStack {
                    Spacer()
                    QualitySelector(
                        qualities: qualities,
                        currentQuality: viewModel.currentQuality,
                        onSelect: { quality in
                            viewModel.switchQuality(to: quality)
                            showQualitySelector = false
                            scheduleHideControls()
                        }
                    )
                    .padding(.bottom, 80)
                }
                .background(Color.black.opacity(0.3))
                .onTapGesture {
                    showQualitySelector = false
                    scheduleHideControls()
                }
            }
        }
        .onAppear {
            if let qualities = qualities, !qualities.isEmpty {
                // 有多清晰度，使用默认清晰度
                let defaultQuality = qualities.first { $0.isDefault } ?? qualities.first!
                viewModel.setupPlayer(quality: defaultQuality, availableQualities: qualities)
            } else {
                // 单一视频URL
                viewModel.setupPlayer(url: url)
            }
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
            viewModel.cleanup()
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if !isPlaying {
                // 暂停时显示控制栏
                hideControlsTask?.cancel()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = true
                }
            } else {
                // 播放时自动隐藏
                scheduleHideControls()
            }
        }
        // 全屏播放器
        .fullScreenCover(isPresented: $isFullscreen) {
            if let _ = viewModel.player {
                LandscapeHosting(content:
                    FullscreenVideoView(viewModel: viewModel, qualities: qualities) {
                        isFullscreen = false
                        scheduleHideControls()
                    }
                )
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled && viewModel.isPlaying {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
}

// MARK: - Quality Selector
struct QualitySelector: View {
    let qualities: [VideoQuality]
    let currentQuality: VideoQuality?
    let onSelect: (VideoQuality) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(qualities) { quality in
                Button(action: { onSelect(quality) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quality.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)

                            if let description = quality.description {
                                Text(description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        Spacer()

                        if currentQuality?.id == quality.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(currentQuality?.id == quality.id ? Color.white.opacity(0.2) : Color.clear)
                }

                if quality.id != qualities.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }
}

// MARK: - Video Progress Bar
struct VideoProgressBar: View {
    let currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void
    var onDragStart: (() -> Void)? = nil
    var onDragEnd: (() -> Void)? = nil

    @State private var isDragging = false
    @State private var dragValue: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // 已播放进度
                Rectangle()
                    .fill(Color.white)
                    .frame(width: progressWidth(geometry: geometry), height: 4)

                // 拖动滑块
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: progressWidth(geometry: geometry) - 6)
            }
            .contentShape(Rectangle()) // 扩大点击区域
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onDragStart?()
                        }
                        let progress = min(max(0, value.location.x / geometry.size.width), 1)
                        dragValue = progress * duration
                    }
                    .onEnded { _ in
                        isDragging = false
                        onSeek(dragValue)
                        onDragEnd?()
                    }
            )
        }
        .frame(height: 30) // 增大触摸区域
        .padding(.horizontal, 16)
    }

    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        let progress = isDragging ? dragValue / duration : currentTime / duration
        return geometry.size.width * CGFloat(progress)
    }
}

// MARK: - Video Player ViewModel
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentQuality: VideoQuality?

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var availableQualities: [VideoQuality] = []

    func setupPlayer(url: URL) {
        createPlayer(with: url)
    }

    func setupPlayer(quality: VideoQuality, availableQualities: [VideoQuality]) {
        self.currentQuality = quality
        self.availableQualities = availableQualities
        createPlayer(with: quality.url)
    }

    private func createPlayer(with url: URL) {
        player = AVPlayer(url: url)

        // 观察播放状态
        statusObserver = player?.currentItem?.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.isLoading = false
                    self?.duration = item.duration.seconds
                } else if item.status == .failed {
                    self?.isLoading = false
                    print("视频加载失败: \(item.error?.localizedDescription ?? "未知错误")")
                }
            }
        }

        // 观察播放进度
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // 自动播放
        player?.play()
        isPlaying = true
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func switchQuality(to quality: VideoQuality) {
        guard quality.id != currentQuality?.id else { return }

        // 保存当前播放进度
        let currentTime = self.currentTime
        let wasPlaying = self.isPlaying

        // 清理旧的观察者
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()

        // 切换到新清晰度
        currentQuality = quality
        isLoading = true

        createPlayer(with: quality.url)

        // 跳转到之前的播放位置
        if currentTime > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.seek(to: currentTime)
                if wasPlaying {
                    self?.player?.play()
                    self?.isPlaying = true
                }
            }
        }
    }

    func cleanup() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
        player = nil
    }
}

// MARK: - Fullscreen Video View
private struct FullscreenVideoView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let qualities: [VideoQuality]?
    let onClose: () -> Void

    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var showQualitySelector = false

    var body: some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            } else {
                Color.black.ignoresSafeArea()
            }

            // 点击层：双击播放/暂停，单击切换控制显示
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture(count: 2).onEnded {
                        viewModel.togglePlayPause()
                        showControls = true
                        scheduleAutoHide()
                    }
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) { showControls.toggle() }
                    if showControls { scheduleAutoHide() }
                }

            if showControls {
                VStack {
                    // 顶部：关闭按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            restorePortrait()
                            onClose()
                        }) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 12)
                        .padding(.top, 10)
                    }

                    Spacer()

                    // 底部：控制条（复用进度与播放/暂停）
                    VStack(spacing: 12) {
                        VideoProgressBar(
                            currentTime: viewModel.currentTime,
                            duration: viewModel.duration,
                            onSeek: { t in viewModel.seek(to: t) },
                            onDragStart: { hideControlsTask?.cancel() },
                            onDragEnd: { scheduleAutoHide() }
                        )

                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.togglePlayPause()
                                scheduleAutoHide()
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            Text("\(formatTime(viewModel.currentTime)) / \(formatTime(viewModel.duration))")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Spacer()

                            // 清晰度按钮（如有多清晰度）
                            if let qualities = qualities, !qualities.isEmpty {
                                Button(action: {
                                    hideControlsTask?.cancel()
                                    showQualitySelector.toggle()
                                }) {
                                    HStack(spacing: 4) {
                                        Text(viewModel.currentQuality?.displayName ?? "画质")
                                            .font(.system(size: 14))
                                        Image(systemName: "chevron.up")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }

            // 全屏下的清晰度选择浮层
            if showQualitySelector, let qualities = qualities {
                VStack {
                    Spacer()
                    QualitySelector(
                        qualities: qualities,
                        currentQuality: viewModel.currentQuality,
                        onSelect: { quality in
                            viewModel.switchQuality(to: quality)
                            showQualitySelector = false
                            scheduleAutoHide()
                        }
                    )
                    .padding(.bottom, 80)
                }
                .ignoresSafeArea()
                .background(Color.black.opacity(0.3))
                .onTapGesture {
                    showQualitySelector = false
                    scheduleAutoHide()
                }
            }
        }
        .onAppear {
            forceLandscape()
            scheduleAutoHide()
        }
        .onDisappear {
            hideControlsTask?.cancel()
            restorePortrait()
        }
    }

    private func scheduleAutoHide() {
        hideControlsTask?.cancel()
        guard viewModel.isPlaying else { return }
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled && viewModel.isPlaying {
                withAnimation(.easeInOut(duration: 0.3)) { showControls = false }
            }
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func forceLandscape() {
        if let appDelegate = AppDelegate.shared {
            appDelegate.orientationMask = [.landscapeLeft, .landscapeRight]
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                try? scene.requestGeometryUpdate(prefs)
                // iOS 16+ 使用新的 API
                if let rootViewController = scene.windows.first?.rootViewController {
                    rootViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    private func restorePortrait() {
        if let appDelegate = AppDelegate.shared {
            appDelegate.orientationMask = [.portrait]
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                try? scene.requestGeometryUpdate(prefs)
                // iOS 16+ 使用新的 API
                if let rootViewController = scene.windows.first?.rootViewController {
                    rootViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

// MARK: - Landscape-only Hosting Wrapper
private struct LandscapeHosting<Content: View>: UIViewControllerRepresentable {
    let content: Content

    func makeUIViewController(context: Context) -> UIViewController {
        Controller(rootView: content)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    private class Controller: UIHostingController<Content> {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            view.isOpaque = true
        }
        override var prefersHomeIndicatorAutoHidden: Bool { true }
        override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask { [.portrait, .landscapeLeft, .landscapeRight] }
        override var shouldAutorotate: Bool { false }
        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if let keyWindow = getKeyWindow(), let scene = keyWindow.windowScene {
                if #available(iOS 16.0, *) {
                    let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                    try? scene.requestGeometryUpdate(prefs)
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
}
