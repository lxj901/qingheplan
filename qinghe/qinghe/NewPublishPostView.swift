import SwiftUI
import PhotosUI

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

    @State private var navigateToLocationSelection = false
    @State private var navigateToTopicSelection = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

    // 权限管理相关状态 - 根据API文档只支持评论和分享
    @State private var allowComments = true
    @State private var allowSharing = true
    @State private var showPermissionSettings = false
    @State private var showPrivacySettings = false

    // 新增：打卡数据和运动数据相关状态
    @State private var navigateToWorkoutRecords = false
    @State private var selectedWorkoutData: WorkoutDataForPost?
    @State private var navigateToCheckinRecords = false
    @State private var selectedCheckinData: CheckinDataForPost?



    // 位置坐标信息
    @State private var latitude: Double?
    @State private var longitude: Double?

    // 用于控制页面关闭
    @Environment(\.dismiss) private var dismiss

    // 社区视图模型
    @StateObject private var communityViewModel = CommunityViewModel()

    // 发布失败提示
    @State private var showPublishErrorAlert = false
    @State private var publishErrorMessage: String = ""

    private let maxLength = 2000


    private var progressPercentage: Double {
        Double(content.count) / Double(maxLength)
    }

    private var canPost: Bool {
        (!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty) &&
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

        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotos, maxSelectionCount: 9, matching: .images)
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
                selectedPhotos.removeAll()
            }
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
                    // 相册按钮
                    FunctionButton(
                        icon: "photo",
                        title: "相册",
                        subtitle: selectedImages.isEmpty ? "添加图片" : "\(selectedImages.count)张图片",
                        isActive: !selectedImages.isEmpty,
                        action: { showImagePicker = true }
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

                    // 打卡数据按钮
                    FunctionButton(
                        icon: "checkmark.circle",
                        title: "打卡数据",
                        subtitle: selectedCheckinData != nil ? "已选择打卡" : "添加打卡数据",
                        isActive: selectedCheckinData != nil,
                        action: { navigateToCheckinRecords = true }
                    )

                    // 运动数据按钮
                    FunctionButton(
                        icon: "figure.run",
                        title: "运动数据",
                        subtitle: selectedWorkoutData != nil ? "已选择运动" : "添加运动",
                        isActive: selectedWorkoutData != nil,
                        action: { navigateToWorkoutRecords = true }
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 底部提示
            Text("发布即表示同意社区规范")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
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
                    Text("正在发布动态...")
                        .font(.system(size: 16))
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

        isPosting = true

        // 准备发布参数
        let checkinId: Int? = selectedCheckinData?.checkinId // 使用真正的打卡记录ID
        let workoutId: Int? = selectedWorkoutData?.workoutId // 使用真正的运动记录ID

        // 调用新的发布方法
        communityViewModel.publishPost(
            content: content,
            images: selectedImages,
            tags: topics,
            // 移除 category 参数，因为不再需要分类功能
            allowComments: allowComments,
            allowShares: allowSharing,
            visibility: privacy.apiValue,
            location: location.isEmpty ? nil : location,
            latitude: latitude,
            longitude: longitude,
            checkinId: checkinId,
            workoutId: workoutId,
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

