import Foundation
import SwiftUI

class NoteCenterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allMarks: [TextMark] = []
    @Published var filteredMarks: [TextMark] = []
    @Published var groupedMarks: [String: [TextMark]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var currentFilter: MarkFilterType = .all
    private var currentGrouping: GroupingOption = .none
    private var currentSorting: SortingOption = .newestFirst

    private let apiService = ClassicsAPIService.shared
    private let authManager = AuthManager.shared

    // MARK: - 加载标记
    func loadMarks() {
        guard authManager.getCurrentUserId() != nil else {
            errorMessage = "请先登录"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 使用新的笔记中心 API（最新优先）
                let response = try await apiService.getNotesCenterLatest(
                    type: filterTypeToAPIType(currentFilter),
                    bookId: nil,
                    limit: 100,
                    offset: 0
                )

                // 🔍 添加详细调试
                print("📥 API返回标记数量: \(response.data.count), 总数: \(response.total)")

                for (index, mark) in response.data.enumerated() {
                    print("标记 \(index + 1):")
                    print("  id: \(mark.id)")
                    print("  sectionId: \(mark.sectionId)")
                    print("  types: \(mark.types?.joined(separator: ", ") ?? "nil")")
                    print("  isFavorite: \(mark.isFavorite)")
                    print("  highlightColor: \(mark.highlightColor ?? "nil")")
                    print("  note: \(mark.note ?? "nil")")
                    print("  bookTitle: \(mark.bookTitle ?? "nil")")
                    print("  chapterTitle: \(mark.chapterTitle ?? "nil")")
                    if let section = mark.section {
                        print("  section.original: \(section.original.prefix(20))...")
                    }
                }

                await MainActor.run {
                    // 转换新的 ClassicsMark 到 TextMark
                    self.allMarks = response.data.map { apiMark in
                        convertClassicsMarkToTextMark(apiMark)
                    }

                    self.isLoading = false
                    self.applyFilter(self.currentFilter)

                    print("✅ 成功加载标记: \(self.allMarks.count) 条")
                    print("✅ 筛选后标记: \(self.filteredMarks.count) 条")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "加载标记失败: \(error.localizedDescription)"

                    // 开发阶段：使用模拟数据
                    print("⚠️ 加载标记失败,使用模拟数据: \(error)")
                    self.loadMockData()
                }
            }
        }
    }

    // MARK: - 辅助方法

    /// 将筛选类型转换为 API 类型
    private func filterTypeToAPIType(_ filter: MarkFilterType) -> String {
        switch filter {
        case .all:
            return "all"
        case .favorite:
            return "favorite"
        case .highlight:
            return "highlight"
        case .note:
            return "note"
        }
    }

    /// 将新的 ClassicsMark 转换为 TextMark
    private func convertClassicsMarkToTextMark(_ apiMark: ClassicsMark) -> TextMark {
        // 创建 section 对象，优先使用根级别的 original 和 translation
        let section: NoteCenterMarkSection? = {
            // 如果有 original 字段（笔记中心接口返回），使用它
            if let original = apiMark.original {
                return NoteCenterMarkSection(
                    id: apiMark.sectionId,
                    bookId: apiMark.bookId ?? "",
                    chapterId: apiMark.chapterId ?? "",
                    original: original,
                    translation: apiMark.translation ?? "",
                    bookTitle: apiMark.bookTitle,
                    chapterTitle: apiMark.chapterTitle
                )
            }
            // 否则尝试使用 section 对象（兼容旧接口）
            else if let sectionObj = apiMark.section {
                return NoteCenterMarkSection(
                    id: sectionObj.id,
                    bookId: apiMark.bookId ?? "",
                    chapterId: apiMark.chapterId ?? "",
                    original: sectionObj.original,
                    translation: sectionObj.translation ?? "",
                    bookTitle: apiMark.bookTitle,
                    chapterTitle: apiMark.chapterTitle
                )
            }
            return nil
        }()

        return TextMark(
            id: apiMark.id,
            userId: authManager.getCurrentUserId() ?? 0,
            sectionId: apiMark.sectionId,
            textRange: apiMark.textRange,
            highlightColor: apiMark.highlightColor,
            note: (apiMark.note?.isEmpty ?? true) ? nil : apiMark.note,
            isFavorite: apiMark.isFavorite,
            createdAt: apiMark.createdAt,
            updatedAt: apiMark.updatedAt,
            section: section
        )
    }


    
    // MARK: - 模拟数据（开发用）
    private func loadMockData() {
        allMarks = [
            TextMark(
                id: "1",
                userId: 1,
                sectionId: "section-1",
                textRange: TextRange(startOffset: 0, endOffset: 10, text: "学而时习之，不亦说乎"),
                highlightColor: "yellow",
                note: "这句话强调了学习的重要性，温故而知新",
                isFavorite: true,
                createdAt: "2025-10-20T12:30:00.000Z",
                updatedAt: "2025-10-20T12:30:00.000Z",
                section: NoteCenterMarkSection(
                    id: "section-1",
                    bookId: "lunyu",
                    chapterId: "chapter-1",
                    original: "子曰：学而时习之，不亦说乎...",
                    translation: "孔子说：学习并时常温习...",
                    bookTitle: "《论语》",
                    chapterTitle: "学而第一"
                )
            ),
            TextMark(
                id: "2",
                userId: 1,
                sectionId: "section-2",
                textRange: TextRange(startOffset: 0, endOffset: 12, text: "有朋自远方来，不亦乐乎"),
                highlightColor: "green",
                note: nil,
                isFavorite: false,
                createdAt: "2025-10-19T15:20:00.000Z",
                updatedAt: "2025-10-19T15:20:00.000Z",
                section: NoteCenterMarkSection(
                    id: "section-2",
                    bookId: "lunyu",
                    chapterId: "chapter-1",
                    original: "有朋自远方来，不亦乐乎...",
                    translation: "有朋友从远方来...",
                    bookTitle: "《论语》",
                    chapterTitle: "学而第一"
                )
            ),
            TextMark(
                id: "3",
                userId: 1,
                sectionId: "section-3",
                textRange: TextRange(startOffset: 0, endOffset: 8, text: "道可道，非常道"),
                highlightColor: "blue",
                note: "道的本质是不可言说的，一旦说出来就不是永恒的道了",
                isFavorite: true,
                createdAt: "2025-10-18T09:15:00.000Z",
                updatedAt: "2025-10-18T09:15:00.000Z",
                section: NoteCenterMarkSection(
                    id: "section-3",
                    bookId: "daodejing",
                    chapterId: "chapter-1",
                    original: "道可道，非常道...",
                    translation: "可以说出来的道...",
                    bookTitle: "《道德经》",
                    chapterTitle: "第一章"
                )
            ),
            TextMark(
                id: "4",
                userId: 1,
                sectionId: "section-4",
                textRange: TextRange(startOffset: 0, endOffset: 8, text: "名可名，非常名"),
                highlightColor: "pink",
                note: nil,
                isFavorite: false,
                createdAt: "2025-10-17T14:30:00.000Z",
                updatedAt: "2025-10-17T14:30:00.000Z",
                section: NoteCenterMarkSection(
                    id: "section-4",
                    bookId: "daodejing",
                    chapterId: "chapter-1",
                    original: "名可名，非常名...",
                    translation: "可以命名的名...",
                    bookTitle: "《道德经》",
                    chapterTitle: "第一章"
                )
            ),
            TextMark(
                id: "5",
                userId: 1,
                sectionId: "section-5",
                textRange: TextRange(startOffset: 0, endOffset: 10, text: "温故而知新，可以为师矣"),
                highlightColor: "purple",
                note: "复习旧知识能获得新的理解和体会",
                isFavorite: true,
                createdAt: "2025-10-16T10:00:00.000Z",
                updatedAt: "2025-10-16T10:00:00.000Z",
                section: NoteCenterMarkSection(
                    id: "section-5",
                    bookId: "lunyu",
                    chapterId: "chapter-2",
                    original: "温故而知新，可以为师矣...",
                    translation: "温习旧知识...",
                    bookTitle: "《论语》",
                    chapterTitle: "为政第二"
                )
            )
        ]
        
        applyFilter(currentFilter)
    }
    
    // MARK: - 筛选
    func applyFilter(_ filter: MarkFilterType) {
        currentFilter = filter
        
        switch filter {
        case .all:
            filteredMarks = allMarks
        case .favorite:
            filteredMarks = allMarks.filter { $0.isFavorite }
        case .highlight:
            filteredMarks = allMarks.filter { $0.highlightColor != nil }
        case .note:
            filteredMarks = allMarks.filter { $0.note != nil && !$0.note!.isEmpty }
        }
        
        applySorting(currentSorting)
        applyGrouping(currentGrouping)
    }
    
    // MARK: - 分组
    func applyGrouping(_ grouping: GroupingOption) {
        currentGrouping = grouping
        groupedMarks.removeAll()
        
        switch grouping {
        case .none:
            break
        case .byBook:
            for mark in filteredMarks {
                let key = mark.section?.bookTitle ?? "未知书籍"
                groupedMarks[key, default: []].append(mark)
            }
        case .byChapter:
            for mark in filteredMarks {
                let bookTitle = mark.section?.bookTitle ?? "未知书籍"
                let chapterTitle = mark.section?.chapterTitle ?? "未知章节"
                let key = "\(bookTitle) · \(chapterTitle)"
                groupedMarks[key, default: []].append(mark)
            }
        case .byColor:
            for mark in filteredMarks {
                let key = colorName(for: mark.highlightColor)
                groupedMarks[key, default: []].append(mark)
            }
        }
    }
    
    // MARK: - 排序
    func applySorting(_ sorting: SortingOption) {
        currentSorting = sorting
        
        switch sorting {
        case .newestFirst:
            filteredMarks.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            filteredMarks.sort { $0.createdAt < $1.createdAt }
        case .recentlyUpdated:
            filteredMarks.sort { $0.updatedAt > $1.updatedAt }
        }
    }
    
    // MARK: - 获取数量
    func getCount(for filter: MarkFilterType) -> Int {
        switch filter {
        case .all:
            return allMarks.count
        case .favorite:
            return allMarks.filter { $0.isFavorite }.count
        case .highlight:
            return allMarks.filter { $0.highlightColor != nil }.count
        case .note:
            return allMarks.filter { $0.note != nil && !$0.note!.isEmpty }.count
        }
    }
    
    // MARK: - 更新笔记
    func updateNote(mark: TextMark, note: String, completion: @escaping () -> Void) {
        guard authManager.getCurrentUserId() != nil else {
            errorMessage = "请先登录"
            return
        }

        Task {
            do {
                // 使用新的更新 API
                _ = try await apiService.updateMark(
                    markId: mark.id,
                    highlightColor: nil,
                    note: note,
                    isFavorite: nil
                )

                await MainActor.run {
                    completion()
                    self.loadMarks() // 重新加载数据
                    print("✅ 笔记更新成功")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "更新笔记失败: \(error.localizedDescription)"
                    print("❌ 更新笔记失败: \(error)")
                }
            }
        }
    }

    // MARK: - 更新高亮颜色
    func updateHighlightColor(mark: TextMark, color: String?) {
        guard authManager.getCurrentUserId() != nil else {
            errorMessage = "请先登录"
            return
        }

        Task {
            do {
                // 使用新的更新 API
                _ = try await apiService.updateMark(
                    markId: mark.id,
                    highlightColor: color,
                    note: nil,
                    isFavorite: nil
                )

                await MainActor.run {
                    self.loadMarks() // 重新加载数据
                    print("✅ 高亮颜色更新成功")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "更新高亮失败: \(error.localizedDescription)"
                    print("❌ 更新高亮失败: \(error)")
                }
            }
        }
    }

    // MARK: - 删除标记
    func deleteMark(_ mark: TextMark) {
        guard authManager.getCurrentUserId() != nil else {
            errorMessage = "请先登录"
            return
        }

        Task {
            do {
                // 使用新的删除 API
                try await apiService.deleteMark(markId: mark.id)

                await MainActor.run {
                    // 从本地列表移除
                    self.allMarks.removeAll { $0.id == mark.id }
                    self.applyFilter(self.currentFilter)
                    print("✅ 标记删除成功: \(mark.id)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "删除标记失败: \(error.localizedDescription)"
                    print("❌ 删除标记失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 跳转到原文
    func navigateToOriginalText(mark: TextMark) {
        guard let section = mark.section else {
            errorMessage = "无法获取原文位置"
            return
        }

        // 发送导航通知
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToClassicsReading"),
            object: nil,
            userInfo: [
                "bookId": section.bookId,
                "chapterId": section.chapterId,
                "sectionId": mark.sectionId,
                "bookTitle": section.bookTitle ?? ""
            ]
        )

        print("🔖 跳转到原文: \(section.bookTitle ?? "") - \(section.chapterTitle ?? "")")
    }
    
    // MARK: - 搜索功能
    func searchMarks(keyword: String) {
        if keyword.isEmpty {
            // 恢复当前筛选
            applyFilter(currentFilter)
        } else {
            // 在所有标记中搜索
            filteredMarks = allMarks.filter { mark in
                // 搜索笔记内容
                if let note = mark.note, note.localizedCaseInsensitiveContains(keyword) {
                    return true
                }
                // 搜索原文内容
                if let original = mark.section?.original, original.localizedCaseInsensitiveContains(keyword) {
                    return true
                }
                // 搜索书籍名称
                if let bookTitle = mark.section?.bookTitle, bookTitle.localizedCaseInsensitiveContains(keyword) {
                    return true
                }
                return false
            }

            // 应用排序和分组
            applySorting(currentSorting)
            applyGrouping(currentGrouping)
        }
    }

    // MARK: - 导出笔记
    func exportMarks() {
        // 生成导出内容
        var exportText = "我的笔记中心\n"
        exportText += "导出时间: \(formatDate(Date()))\n"
        exportText += "总计: \(allMarks.count) 条标记\n\n"
        exportText += String(repeating: "=", count: 50) + "\n\n"

        for (index, mark) in allMarks.enumerated() {
            exportText += "[\(index + 1)] \(mark.section?.bookTitle ?? "未知") - \(mark.section?.chapterTitle ?? "未知")\n"
            exportText += "原文: \(mark.section?.original ?? "")\n"

            if let note = mark.note, !note.isEmpty {
                exportText += "笔记: \(note)\n"
            }

            if let highlight = mark.highlightColor {
                exportText += "高亮: \(colorName(for: highlight))\n"
            }

            if mark.isFavorite {
                exportText += "⭐ 收藏\n"
            }

            exportText += "时间: \(formatDate(mark.createdAt))\n"
            exportText += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }

        // 保存到文件并分享
        let activityVC = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - 清空所有笔记
    func clearAllMarks() {
        guard let userId = authManager.getCurrentUserId() else {
            errorMessage = "请先登录"
            return
        }

        // 显示确认对话框
        let alert = UIAlertController(
            title: "确认清空",
            message: "是否清空所有笔记?此操作不可恢复!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { _ in
            Task {
                // 逐个删除所有标记
                for mark in self.allMarks {
                    do {
                        // 使用新的 deleteMark API
                        try await self.apiService.deleteMark(markId: mark.id)
                    } catch {
                        print("⚠️ 删除标记失败: \(error)")
                    }
                }

                await MainActor.run {
                    // 清空本地数据
                    self.allMarks.removeAll()
                    self.filteredMarks.removeAll()
                    self.groupedMarks.removeAll()
                }
            }
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    // MARK: - 辅助方法
    private func colorName(for color: String?) -> String {
        guard let color = color else {
            return "无高亮"
        }

        switch color {
        case "yellow":
            return "黄色"
        case "green":
            return "绿色"
        case "blue":
            return "蓝色"
        case "pink":
            return "粉色"
        case "purple":
            return "紫色"
        default:
            return "其他"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
        return dateString
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

