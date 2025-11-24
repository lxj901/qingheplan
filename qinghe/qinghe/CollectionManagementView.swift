import SwiftUI

/// 合集管理视图
struct CollectionManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentView: ViewType = .list
    @State private var selectedCollection: CreatorAPIService.CollectionItem?

    enum ViewType {
        case list, editor
    }

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()

            if currentView == .list {
                CollectionListView(
                    onNavigateToEditor: {
                        currentView = .editor
                    },
                    onEditCollection: { collection in
                        selectedCollection = collection
                        currentView = .editor
                    }
                )
            } else {
                CollectionEditorView(
                    collection: selectedCollection,
                    onBack: {
                        currentView = .list
                        selectedCollection = nil
                    }
                )
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 合集列表视图
struct CollectionListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var filter: FilterType = .all
    let onNavigateToEditor: () -> Void
    let onEditCollection: (CreatorAPIService.CollectionItem) -> Void

    enum FilterType {
        case all, updating, finished
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            topNavigationBar

            // 列表内容
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 创建入口
                    createButton

                    // 合集列表
                    ForEach(filteredCollections) { collection in
                        CollectionCardView(
                            collection: collection,
                            onTap: {
                                onEditCollection(collection)
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("合集管理")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 占位
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // 筛选 Tabs
            HStack(spacing: 24) {
                CollectionFilterTabButton(title: "全部", isActive: filter == .all) {
                    filter = .all
                }
                CollectionFilterTabButton(title: "连载中", isActive: filter == .updating) {
                    filter = .updating
                }
                CollectionFilterTabButton(title: "已完结", isActive: filter == .finished) {
                    filter = .finished
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white.opacity(0.9))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 创建按钮
    private var createButton: some View {
        Button(action: onNavigateToEditor) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppConstants.Colors.primaryGreen.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }

                Text("创建新合集")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(AppConstants.Colors.primaryGreen.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            )
            .cornerRadius(12)
        }
    }

    // MARK: - 数据过滤
    private var filteredCollections: [CreatorAPIService.CollectionItem] {
        mockCollections.filter { collection in
            switch filter {
            case .all:
                return true
            case .updating:
                return collection.status == "updating"
            case .finished:
                return collection.status == "finished"
            }
        }
    }

    // MARK: - 模拟数据
    private var mockCollections: [CreatorAPIService.CollectionItem] {
        [
            CreatorAPIService.CollectionItem(
                id: "1",
                type: "collection",
                title: "零基础剪辑入门课",
                description: nil,
                coverImage: "https://images.unsplash.com/photo-1574717024653-61fd2cf4d44c?auto=format&fit=crop&w=300&q=80",
                postsCount: 12,
                worksCount: 12,
                viewsCount: 452000,
                likesCount: nil,
                subscribersCount: nil,
                status: "updating",
                visibility: "public",
                createdAt: "2小时前更新"
            ),
            CreatorAPIService.CollectionItem(
                id: "2",
                type: "collection",
                title: "2024 环球旅行 Vlog",
                description: nil,
                coverImage: "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=300&q=80",
                postsCount: 8,
                worksCount: 8,
                viewsCount: 125000,
                likesCount: nil,
                subscribersCount: nil,
                status: "finished",
                visibility: "public",
                createdAt: "2023/12/20"
            ),
            CreatorAPIService.CollectionItem(
                id: "3",
                type: "collection",
                title: "我的猫咪日记",
                description: nil,
                coverImage: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=300&q=80",
                postsCount: 56,
                worksCount: 56,
                viewsCount: 892000,
                likesCount: nil,
                subscribersCount: nil,
                status: "updating",
                visibility: "public",
                createdAt: "昨天 14:00"
            )
        ]
    }
}

// MARK: - 筛选标签按钮（合集管理专用）
struct CollectionFilterTabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .primary : .secondary.opacity(0.6))

                if isActive {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppConstants.Colors.primaryGreen)
                        .frame(width: 12, height: 2)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.clear)
                        .frame(width: 12, height: 2)
                }
            }
        }
    }
}

// MARK: - 合集卡片视图
struct CollectionCardView: View {
    let collection: CreatorAPIService.CollectionItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 封面
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: collection.coverImage ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // 集数标签
                    HStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                        Text("\(collection.worksCount ?? 0)集")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
                    .padding(4)
                }
                .frame(width: 80, height: 112)

                // 内容信息
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text(collection.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }

                    Text(collection.createdAt)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 4)

                    Spacer()

                    HStack {
                        // 状态标签
                        HStack(spacing: 0) {
                            Text(collection.status == "updating" ? "连载中" : "已完结")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(collection.status == "updating" ? AppConstants.Colors.primaryGreen : .secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(collection.status == "updating" ? AppConstants.Colors.primaryGreen.opacity(0.1) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(collection.status == "updating" ? AppConstants.Colors.primaryGreen.opacity(0.2) : Color.clear, lineWidth: 1)
                                )
                                .cornerRadius(4)
                        }

                        Spacer()

                        // 播放量
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                            Text(formatViewCount(collection.viewsCount ?? 0))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatViewCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - 合集编辑器视图
struct CollectionEditorView: View {
    let collection: CreatorAPIService.CollectionItem?
    let onBack: () -> Void

    @State private var showPicker = false
    @State private var title = "零基础剪辑入门课"
    @State private var description = "本合集专为新手打造，从软件安装到成片导出，手把手教你剪视频。"
    @State private var episodes: [Episode] = [
        Episode(id: 101, title: "第一集：剪辑软件的基础设置与界面介绍", duration: "10:20", views: "1.2w"),
        Episode(id: 102, title: "第二集：如何快速粗剪一条视频？", duration: "08:45", views: "8.5k"),
        Episode(id: 103, title: "第三集：添加字幕与音效的技巧", duration: "12:10", views: "5.6k")
    ]
    @State private var isUpdating = true
    @State private var isPrivate = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            topNavigationBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 基本信息区
                    basicInfoSection

                    // 分集管理区
                    episodesSection

                    // 底部设置区
                    settingsSection
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)

        // 作品选择弹窗
        if showPicker {
            workPickerSheet
        }
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("编辑合集")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {}) {
                Text("保存")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.05))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 基本信息区
    private var basicInfoSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // 封面上传
                Button(action: {}) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 96, height: 128)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            )

                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("更换封面")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }

                // 信息输入
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("合集标题 (必填)", text: $title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: $description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(height: 48)
                            .scrollContentBackground(.hidden)

                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - 分集管理区
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("分集管理")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(episodes.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()

                Text("长按拖拽排序")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.bottom, 4)

            // 分集列表
            ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
                EpisodeRow(episode: episode, index: index + 1)
            }

            // 添加分集按钮
            Button(action: { showPicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                    Text("添加分集")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.secondary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
    }

    // MARK: - 底部设置区
    private var settingsSection: some View {
        VStack(spacing: 16) {
            // 连载状态
            HStack {
                Text("连载状态")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 0) {
                    Button(action: { isUpdating = true }) {
                        Text("连载中")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isUpdating ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(isUpdating ? Color.white : Color.clear)
                            .cornerRadius(6)
                            .shadow(color: isUpdating ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                    }

                    Button(action: { isUpdating = false }) {
                        Text("已完结")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(!isUpdating ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(!isUpdating ? Color.white : Color.clear)
                            .cornerRadius(6)
                            .shadow(color: !isUpdating ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                    }
                }
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            // 仅自己可见
            HStack {
                Text("仅自己可见")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $isPrivate)
                    .labelsHidden()
                    .tint(AppConstants.Colors.primaryGreen)
            }
        }
        .padding(16)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - 作品选择弹窗
    private var workPickerSheet: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    showPicker = false
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // 标题栏
                    HStack {
                        Text("选择作品")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { showPicker = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                    .padding(16)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // 搜索框
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.6))

                        TextField("搜索作品...", text: .constant(""))
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    // 作品列表
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { i in
                                WorkPickerRow()
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.8)
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
            }
        }
    }
}

// MARK: - 分集行组件
struct EpisodeRow: View {
    let episode: Episode
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(.secondary.opacity(0.3))

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("\(index)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(episode.duration)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("\(episode.views)播放")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.3))
                    .padding(8)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 作品选择行组件
struct WorkPickerRow: View {
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1616486338812-3dadae4b4f9d?auto=format&fit=crop&w=200&q=80")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("如何用手机拍出电影感大片？")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("2024-11-20 · 12.5w播放")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            Button(action: {}) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 分集数据模型
struct Episode: Identifiable {
    let id: Int
    let title: String
    let duration: String
    let views: String
}

// MARK: - 预览
#Preview {
    NavigationStack {
        CollectionManagementView()
    }
}