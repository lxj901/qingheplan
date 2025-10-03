import SwiftUI

struct GongGuoRecordEditorView: View {
    enum Kind: String, CaseIterable { case merit = "功", demerit = "过" }

    let date: Date
    var onSave: (Kind, String, Int) -> Void = { _,_,_ in }

    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind = .merit
    @State private var selectedItem: GongGuoStandardBook.Item? = nil
    @State private var points: Int = 1
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var recentTitles: [String] = []
    @State private var cachedCategories: [String] = []
    @State private var itemsFiltered: [GongGuoStandardBook.Item] = []
    @State private var itemsDeduped: [GongGuoStandardBook.Item] = []

    private var sourceItems: [GongGuoStandardBook.Item] {
        (kind == .merit) ? GongGuoStandardBook.merits : GongGuoStandardBook.demerits
    }

    private var categories: [String] { cachedCategories }

    private var filteredItems: [GongGuoStandardBook.Item] { itemsFiltered }
    private var dedupedFilteredItems: [GongGuoStandardBook.Item] { itemsDeduped }

    private var recentItemsForCurrentKind: [GongGuoStandardBook.Item] {
        // 允许源数据存在相同标题，优先保留首次出现
        let map = Dictionary(sourceItems.map { ($0.title, $0) }, uniquingKeysWith: { first, _ in first })
        return recentTitles.compactMap { map[$0] }
    }

    private var accentColor: Color {
        kind == .merit ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed
    }

    var body: some View {
        ZStack {
            ModernDesignSystem.Colors.paperIvory
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // 类型胶囊切换
                    kindSegment

                    // 搜索框
                    searchBar

                    // 最近使用
                    if !recentItemsForCurrentKind.isEmpty {
                        Text("最近使用")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentItemsForCurrentKind, id: \.title) { item in
                                    chip(text: item.title, selected: selectedItem == item, color: accentColor) {
                                        selectedItem = item
                                        points = item.points
                                        selectedCategory = category(from: item.title)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // 分类 Chips
                    if !categories.isEmpty {
                        Text("分类")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                chip(text: "全部", selected: selectedCategory == nil, color: .secondary) {
                                    selectedCategory = nil
                                }
                                ForEach(categories, id: \.self) { cat in
                                    chip(text: cat, selected: selectedCategory == cat, color: accentColor) {
                                        selectedCategory = (selectedCategory == cat ? nil : cat)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // 条目列表
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(dedupedFilteredItems, id: \.title) { item in
                            itemRow(item)
                                .padding(.horizontal, 12)
                        }
                    }

                    // 已移除底部日期显示
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("添加记录")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    if let s = selectedItem {
                        saveRecentTitle(s.title)
                        onSave(kind, s.title, points)
                    }
                    dismiss()
                }) {
                    Text("保存")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(selectedItem == nil ? Color.black.opacity(0.3) : .black)
                }
                .disabled(selectedItem == nil)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(ModernDesignSystem.Colors.paperIvory, for: .navigationBar)
        .onAppear {
            loadRecents()
            recomputeCategories()
            recomputeFilter()
        }
        .onChange(of: kind) { _, _ in
            // 关闭动画，避免切换卡顿
            withAnimation(.none) {
                selectedItem = nil
                points = 1
                selectedCategory = nil
                recomputeCategories()
                recomputeFilter()
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            withAnimation(.none) { recomputeFilter() }
        }
        .onChange(of: searchText) { _, _ in
            // 简单防抖：主线程下一轮再计算，避免每击键多次渲染
            DispatchQueue.main.async { recomputeFilter() }
        }
        .animation(nil, value: kind)
        .animation(nil, value: selectedCategory)
    }
}

// 已移除日期格式化函数（不再在页面底部显示日期）

    #Preview {
        GongGuoRecordEditorView(date: Date())
    }

// MARK: - UI Helpers
private extension GongGuoRecordEditorView {
    // 预计算分类与筛选，减少每次渲染的计算量
    func recomputeCategories() {
        let set = Set(sourceItems.compactMap { category(from: $0.title) })
        cachedCategories = Array(set).sorted()
    }

    func recomputeFilter() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        // 先筛选
        let filtered = sourceItems.filter { item in
            let matchText = q.isEmpty || item.title.localizedStandardContains(q)
            let cat = category(from: item.title)
            let matchCat = selectedCategory == nil || selectedCategory == cat
            return matchText && matchCat
        }
        itemsFiltered = filtered
        // 再按标题去重，保持顺序
        var seen = Set<String>()
        var deduped: [GongGuoStandardBook.Item] = []
        for it in filtered {
            if seen.insert(it.title).inserted { deduped.append(it) }
        }
        itemsDeduped = deduped
    }
    var kindSegment: some View {
        HStack(spacing: 0) {
            segmentButton(title: Kind.merit.rawValue, isSelected: kind == .merit, selectedColor: ModernDesignSystem.Colors.primaryGreen) {
                kind = .merit
                selectedItem = nil
                points = 1
                selectedCategory = nil
            }
            segmentButton(title: Kind.demerit.rawValue, isSelected: kind == .demerit, selectedColor: ModernDesignSystem.Colors.errorRed) {
                kind = .demerit
                selectedItem = nil
                points = 1
                selectedCategory = nil
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.06))
        .clipShape(Capsule())
        .padding(.horizontal, 16)
    }

    func segmentButton(title: String, isSelected: Bool, selectedColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? selectedColor : Color.clear)
                )
        }
    }

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("搜索条目", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    func itemRow(_ item: GongGuoStandardBook.Item) -> some View {
        let isSel = (selectedItem == item)
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text((kind == .merit ? "加分" : "减分"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            // 选中条目显示当前待保存分值；未选中显示条目默认分值
            Text((kind == .merit ? "+" : "-") + "\(isSel ? points : item.points)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(accentColor.opacity(0.12)))

            if isSel {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(accentColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isSel {
                selectedItem = nil
            } else {
                selectedItem = item
                points = item.points
                selectedCategory = category(from: item.title)
            }
        }
    }

    func chip(text: String, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? color : Color.black.opacity(0.06))
                )
        }
    }
}

// MARK: - Category & Recents
private extension GongGuoRecordEditorView {
    func category(from title: String) -> String? {
        if let idx = title.firstIndex(of: "·") {
            return String(title[..<idx])
        }
        return nil
    }

    var recentsKey: String { kind == .merit ? "GongGuoRecentMerit" : "GongGuoRecentDemerit" }

    func loadRecents() {
        let arr = UserDefaults.standard.array(forKey: recentsKey) as? [String] ?? []
        recentTitles = arr
    }

    func saveRecentTitle(_ title: String) {
        var arr = UserDefaults.standard.array(forKey: recentsKey) as? [String] ?? []
        // 去重并将最新的放前面
        arr.removeAll { $0 == title }
        arr.insert(title, at: 0)
        if arr.count > 8 { arr = Array(arr.prefix(8)) }
        UserDefaults.standard.set(arr, forKey: recentsKey)
        recentTitles = arr
    }
}
