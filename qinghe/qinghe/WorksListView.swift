import SwiftUI

/// 内容管理页面
struct WorksListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var activeTab: WorkTab = .all
    @State private var isSelectionMode = false
    @State private var searchText = ""
    
    enum WorkTab {
        case all, video, article
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                // 主滚动区域
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(filteredWorks) { work in
                            WorkCard(work: work, isSelectionMode: isSelectionMode)
                        }
                        
                        // 底部加载更多
                        Text("没有更多内容了")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.3))
                            .padding(.vertical, 16)
                    }
                    .padding(16)
                }
            }
            
            // 底部批量操作栏
            if isSelectionMode {
                VStack {
                    Spacer()
                    batchOperationBar
                }
            }
        }
        .navigationBarHidden(true)
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
                
                Text("内容管理")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    isSelectionMode.toggle()
                }) {
                    Text(isSelectionMode ? "完成" : "管理")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelectionMode ? AppConstants.Colors.primaryGreen : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelectionMode ? AppConstants.Colors.primaryGreen.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.6))
                
                TextField("搜索作品标题...", text: $searchText)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // 筛选栏
            HStack {
                HStack(spacing: 16) {
                    TabButton(label: "全部", isActive: activeTab == .all) {
                        activeTab = .all
                    }
                    TabButton(label: "视频", isActive: activeTab == .video) {
                        activeTab = .video
                    }
                    TabButton(label: "图文", isActive: activeTab == .article) {
                        activeTab = .article
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("按时间")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
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
    
    // MARK: - 底部批量操作栏
    private var batchOperationBar: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("批量删除")
                        .font(.system(size: 10))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: -5)
    }

    // MARK: - 数据过滤
    private var filteredWorks: [WorkItem] {
        let filtered = mockWorks.filter { work in
            switch activeTab {
            case .all:
                return true
            case .video:
                return work.type == .video
            case .article:
                return work.type == .article
            }
        }

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - 模拟数据
    private var mockWorks: [WorkItem] {
        [
            WorkItem(
                id: "1",
                title: "沉浸式整理我的书桌 | 极简主义生活 Vlog #03",
                cover: "https://images.unsplash.com/photo-1493934558415-9d19f0b2b4d2?auto=format&fit=crop&w=300&q=80",
                type: .video,
                date: "2024/11/20",
                views: "45.2w",
                likes: "3.4w",
                comments: "1,205",
                status: .published,
                duration: "05:20"
            ),
            WorkItem(
                id: "2",
                title: "立冬养生指南：这三件事千万别做！",
                cover: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=300&q=80",
                type: .article,
                date: "2024/11/18",
                views: "12.5w",
                likes: "892",
                comments: "230",
                status: .published,
                duration: nil
            ),
            WorkItem(
                id: "3",
                title: "Vlog: 周末去山里吸氧 🌲",
                cover: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=300&q=80",
                type: .video,
                date: "2024/11/15",
                views: "2,300",
                likes: "120",
                comments: "15",
                status: .audit,
                duration: "03:12"
            ),
            WorkItem(
                id: "4",
                title: "我的摄影器材大公开 (草稿)",
                cover: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=300&q=80",
                type: .article,
                date: "2024/11/10",
                views: "-",
                likes: "-",
                comments: "-",
                status: .draft,
                duration: nil
            )
        ]
    }
}

// MARK: - 数据模型

struct WorkItem: Identifiable {
    let id: String
    let title: String
    let cover: String
    let type: WorkType
    let date: String
    let views: String
    let likes: String
    let comments: String
    let status: WorkStatus
    let duration: String?
}

enum WorkType {
    case video, article
}

enum WorkStatus {
    case published, audit, draft
}

// MARK: - 子组件

/// Tab按钮
struct TabButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(label)
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

/// 作品卡片
struct WorkCard: View {
    let work: WorkItem
    let isSelectionMode: Bool
    @State private var isSelected = false

    var body: some View {
        HStack(spacing: 12) {
            // 批量选择 Checkbox
            if isSelectionMode {
                Button(action: {
                    isSelected.toggle()
                }) {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Circle()
                                .fill(AppConstants.Colors.primaryGreen)
                                .frame(width: 20, height: 20)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // 封面
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: work.cover)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 96, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(work.status == .draft ? 0.6 : 1.0)

                // 类型角标
                HStack(spacing: 0) {
                    Image(systemName: work.type == .video ? "play.fill" : "photo.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .padding(4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(4)

                // 视频时长
                if let duration = work.duration {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(duration)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(4)
                                .padding(4)
                        }
                    }
                }

                // 状态遮罩
                if work.status != .published {
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.1))

                        HStack(spacing: 4) {
                            if work.status == .audit {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                            }
                            Text(work.status == .draft ? "草稿" : "审核中")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .frame(width: 96, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(width: 96, height: 128)

            // 内容信息
            VStack(alignment: .leading, spacing: 0) {
                Text(work.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(work.status == .draft ? .secondary : .primary)
                    .lineLimit(2)
                    .padding(.bottom, 4)

                HStack(spacing: 8) {
                    Text(work.date)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))

                    if work.status == .audit {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 10))
                            Text("预计2小时内完成")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 8)

                Spacer()

                // 底部数据栏或操作按钮
                if work.status == .published {
                    publishedWorkActions
                } else {
                    draftWorkActions
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }

    // 已发布作品的操作区域
    private var publishedWorkActions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                    Text(work.views)
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                    Text(work.likes)
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 12))
                    Text(work.comments)
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                NavigationLink(destination: SingleWorkAnalysisView().asSubView()) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 12))
                        Text("数据分析")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                    .cornerRadius(8)
                }

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 32)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
    }

    // 草稿/审核中作品的操作区域
    private var draftWorkActions: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("删除作品")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    WorksListView()
}

