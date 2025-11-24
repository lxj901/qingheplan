import SwiftUI

/// 专栏管理主视图 - 支持三个子视图切换
struct ColumnManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentView: ColumnViewType = .list
    @State private var selectedColumn: ColumnData?

    enum ColumnViewType {
        case list, editor, articleEditor
    }

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()

            switch currentView {
            case .list:
                ColumnListView(
                    presentationMode: presentationMode,
                    onNavigateToEditor: { column in
                        selectedColumn = column
                        currentView = .editor
                    }
                )
            case .editor:
                ColumnEditorView(
                    column: selectedColumn,
                    onBack: {
                        currentView = .list
                        selectedColumn = nil
                    },
                    onCreateArticle: {
                        currentView = .articleEditor
                    }
                )
            case .articleEditor:
                ArticleEditorView(
                    onBack: {
                        currentView = .editor
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - 1. 专栏列表视图
struct ColumnListView: View {
    @StateObject private var viewModel = ColumnListViewModel()
    @State private var filter: ColumnFilter = .all
    let presentationMode: Binding<PresentationMode>

    enum ColumnFilter: String, CaseIterable {
        case all = "全部"
        case paid = "付费专栏"
        case free = "免费专栏"
    }

    let onNavigateToEditor: (ColumnData?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar

            // 筛选 Tabs
            filterTabs

            // 列表内容
            ScrollView {
                VStack(spacing: 16) {
                    // 创建入口
                    createNewButton

                    // 专栏列表
                    ForEach(filteredColumns) { column in
                        ColumnItemCard(column: column)
                            .onTapGesture {
                                onNavigateToEditor(column)
                            }
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            viewModel.loadColumns()
        }
    }

    private var filteredColumns: [ColumnData] {
        switch filter {
        case .all:
            return viewModel.columns
        case .paid:
            return viewModel.columns.filter { $0.isPaid }
        case .free:
            return viewModel.columns.filter { !$0.isPaid }
        }
    }

    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            }

            Spacer()

            Text("专栏管理")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(height: 44)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9).opacity(0.5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var filterTabs: some View {
        HStack(spacing: 24) {
            ForEach(ColumnFilter.allCases, id: \.self) { filterOption in
                Button(action: {
                    filter = filterOption
                }) {
                    VStack(spacing: 8) {
                        Text(filterOption.rawValue)
                            .font(.system(size: 14, weight: filter == filterOption ? .semibold : .regular))
                            .foregroundColor(filter == filterOption ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.6, green: 0.6, blue: 0.6))

                        if filter == filterOption {
                            Rectangle()
                                .fill(Color(red: 0.96, green: 0.64, blue: 0.2))
                                .frame(height: 2)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var createNewButton: some View {
        Button(action: {
            onNavigateToEditor(nil)
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.96, green: 0.64, blue: 0.2))
                }

                Text("创建新专栏")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.64, blue: 0.2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.05))
                    )
            )
        }
    }
}

// MARK: - 专栏卡片组件
struct ColumnItemCard: View {
    let column: ColumnData

    var body: some View {
        HStack(spacing: 12) {
            // 封面图
            if let coverURL = column.cover, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay(
                    Group {
                        if column.isPaid {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("VIP")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(red: 0.96, green: 0.64, blue: 0.2))
                                        .cornerRadius(4, corners: [.bottomLeft])
                                }
                                Spacer()
                            }
                        }
                    }
                )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }

            // 信息区域
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(column.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .lineLimit(1)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.3))
                    }
                }

                Text(column.updateTime)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray.opacity(0.6))

                Spacer()

                HStack {
                    HStack(spacing: 12) {
                        Label("\(column.articles)", systemImage: "book.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray.opacity(0.6))

                        Label(column.readers, systemImage: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }

                    Spacer()

                    Text(column.isPaid ? column.price : "免费")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(column.isPaid ? Color(red: 0.96, green: 0.64, blue: 0.2) : Color(red: 0.2, green: 0.7, blue: 0.5))
                }
            }
            .padding(.vertical, 2)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 专栏列表 ViewModel
class ColumnListViewModel: ObservableObject {
    @Published var columns: [ColumnData] = []
    @Published var isLoading = false

    func loadColumns() {
        isLoading = true
        // 模拟数据
        columns = [
            ColumnData(
                id: "1",
                title: "前端面试核心考点：从入门到进阶",
                cover: "https://images.unsplash.com/photo-1587620962725-abab7fe55159?auto=format&fit=crop&w=300&q=80",
                articles: 24,
                readers: "8,920",
                isPaid: true,
                price: "¥29.9",
                updateTime: "2小时前更新"
            ),
            ColumnData(
                id: "2",
                title: "手机摄影审美养成",
                cover: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=300&q=80",
                articles: 10,
                readers: "12.5k",
                isPaid: false,
                price: "",
                updateTime: "2023/12/20"
            ),
            ColumnData(
                id: "3",
                title: "独立开发者实战笔记",
                cover: "https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=300&q=80",
                articles: 8,
                readers: "3,200",
                isPaid: true,
                price: "¥9.9",
                updateTime: "昨天 14:00"
            )
        ]
        isLoading = false
    }
}

// MARK: - 专栏数据模型
struct ColumnData: Identifiable {
    let id: String
    let title: String
    let cover: String?
    let articles: Int
    let readers: String
    let isPaid: Bool
    let price: String
    let updateTime: String
}

// MARK: - 2. 专栏编辑器视图
struct ColumnEditorView: View {
    let column: ColumnData?
    let onBack: () -> Void
    let onCreateArticle: () -> Void

    @State private var isPaid = true
    @State private var title = "前端面试核心考点"
    @State private var description = "包含 JS 原理、React 源码解析、性能优化等高频考点整理，助你拿到大厂 Offer。"
    @State private var price = "29.9"
    @State private var originalPrice = "99.0"
    @State private var chapters: [ChapterData] = [
        ChapterData(id: "201", title: "序言：为什么我们要学习前端性能优化？", type: .article, meta: "1580字", isFree: true),
        ChapterData(id: "202", title: "视频讲解：浏览器渲染原理深度解析", type: .video, meta: "12:30", isFree: false),
        ChapterData(id: "203", title: "第二章：React Fiber 架构通俗讲解", type: .article, meta: "3200字", isFree: false)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar

            // 内容区域
            ScrollView {
                VStack(spacing: 0) {
                    // 基本信息区
                    basicInfoSection

                    // 定价与权限
                    pricingSection

                    // 目录管理
                    chaptersSection
                }
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }

    private var topNavigationBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .padding(8)
            }

            Spacer()

            Text("编辑专栏")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

            Spacer()

            Button(action: {}) {
                Text("保存")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.64, blue: 0.2))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9).opacity(0.5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var basicInfoSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // 封面上传
                Button(action: {}) {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                        )
                        .frame(width: 96, height: 96)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.gray.opacity(0.6))
                                Text("封面图")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.gray.opacity(0.6))
                            }
                        )
                }

                // 信息输入
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("专栏名称 (必填)", text: $title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: $description)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                            .frame(height: 56)
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
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专栏设置")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

            VStack(spacing: 16) {
                // 付费开关
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("付费专栏")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        Text("开启后，用户需购买才能阅读全部内容")
                            .font(.system(size: 10))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }

                    Spacer()

                    Toggle("", isOn: $isPaid)
                        .labelsHidden()
                        .tint(Color(red: 0.96, green: 0.64, blue: 0.2))
                }

                // 定价输入
                if isPaid {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("定价 (元)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray.opacity(0.7))

                            HStack(spacing: 4) {
                                Text("¥")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray.opacity(0.7))
                                TextField("", text: $price)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .keyboardType(.decimalPad)
                            }
                            .padding(12)
                            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("划线价 (选填)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray.opacity(0.7))

                            HStack(spacing: 4) {
                                Text("¥")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray.opacity(0.4))
                                TextField("", text: $originalPrice)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray.opacity(0.6))
                                    .keyboardType(.decimalPad)
                            }
                            .padding(12)
                            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
        .padding(16)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9).opacity(0.5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目录管理")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

                Text("\(chapters.count) 节")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                Spacer()

                Text("长按拖拽排序")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray.opacity(0.6))
            }

            // 章节列表
            VStack(spacing: 8) {
                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    ChapterItemView(chapter: chapter, index: index + 1, isPaid: isPaid)
                }

                // 底部双按钮
                HStack(spacing: 12) {
                    Button(action: onCreateArticle) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("新建图文")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                    }

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 16))
                            Text("上传视频")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.96, green: 0.64, blue: 0.2))
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
    }
}

// MARK: - 章节项视图
struct ChapterItemView: View {
    let chapter: ChapterData
    let index: Int
    let isPaid: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16))
                .foregroundColor(Color.gray.opacity(0.3))

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                Text("\(index)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(chapter.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .lineLimit(1)

                    if isPaid {
                        Text(chapter.isFree ? "试读" : "付费")
                            .font(.system(size: 9))
                            .foregroundColor(chapter.isFree ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color(red: 0.96, green: 0.64, blue: 0.2))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(chapter.isFree ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.1) : Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.1))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(chapter.isFree ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.2) : Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.2), lineWidth: 0.5)
                            )
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: chapter.type == .video ? "play.circle" : "doc.text")
                            .font(.system(size: 10))
                        Text(chapter.type == .video ? "视频" : "图文")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .cornerRadius(4)

                    Text(chapter.meta)
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray.opacity(0.6))

                    HStack(spacing: 2) {
                        Image(systemName: chapter.isFree ? "lock.open" : "lock")
                            .font(.system(size: 10))
                        Text(chapter.isFree ? "公开" : "需购买")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(chapter.isFree ? Color(red: 0.2, green: 0.7, blue: 0.5) : Color.gray.opacity(0.6))
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray.opacity(0.3))
                    .padding(8)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 章节数据模型
struct ChapterData: Identifiable {
    let id: String
    let title: String
    let type: ChapterType
    let meta: String
    let isFree: Bool

    enum ChapterType {
        case article, video
    }
}

// MARK: - 3. 文章编辑器视图
struct ArticleEditorView: View {
    let onBack: () -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var isTrial = false
    @State private var showImagePicker = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            topActionBar

            // 编辑区域
            ScrollView {
                VStack(spacing: 0) {
                    // 标题输入
                    TextField("请输入标题...", text: $title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .focused($isTitleFocused)

                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // 正文输入
                    TextEditor(text: $content)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        .frame(minHeight: 400)
                        .padding(.horizontal, 20)
                        .scrollContentBackground(.hidden)

                    // 底部设置
                    bottomSettings
                }
                .padding(.bottom, 100)
            }

            // 键盘工具栏
            keyboardToolbar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .onAppear {
            isTitleFocused = true
        }
    }

    private var topActionBar: some View {
        HStack {
            Button(action: onBack) {
                Text("取消")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("存草稿")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.6))
                }

                Button(action: onBack) {
                    Text("发布")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.96, green: 0.64, blue: 0.2))
                        .cornerRadius(20)
                        .shadow(color: Color(red: 0.96, green: 0.64, blue: 0.2).opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var bottomSettings: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
                .padding(.top, 16)
                .padding(.bottom, 16)

            // 试读开关
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("设为试读")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    Text("开启后，未购买专栏的用户也可免费阅读")
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray.opacity(0.6))
                }

                Spacer()

                Toggle("", isOn: $isTrial)
                    .labelsHidden()
                    .tint(Color(red: 0.2, green: 0.7, blue: 0.5))
            }
            .padding(12)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // 添加封面
            HStack {
                Text("添加封面 (选填)")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray.opacity(0.7))

                Spacer()

                Button(action: { showImagePicker = true }) {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(Color.gray.opacity(0.3))
                        )
                }
            }
            .padding(12)
            .padding(.horizontal, 20)
        }
    }

    private var keyboardToolbar: some View {
        HStack(spacing: 24) {
            Button(action: { showImagePicker = true }) {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(Color.gray.opacity(0.7))
            }

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 16)

            Button(action: {}) {
                Image(systemName: "bold")
                    .font(.system(size: 20))
                    .foregroundColor(Color.gray.opacity(0.7))
            }

            Button(action: {}) {
                Image(systemName: "italic")
                    .font(.system(size: 20))
                    .foregroundColor(Color.gray.opacity(0.7))
            }

            Button(action: {}) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(Color.gray.opacity(0.7))
            }

            Spacer()

            Text("\(content.count) 字")
                .font(.system(size: 12))
                .foregroundColor(Color.gray.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: -2)
    }
}

// MARK: - 预览
#Preview {
    ColumnManagementView()
}
