import Foundation

// MARK: - 文字标记数据模型（用于笔记中心 UI）
struct TextMark: Identifiable, Codable {
    let id: String
    let userId: Int
    let sectionId: String
    let textRange: TextRange?
    let highlightColor: String?
    let note: String?
    let isFavorite: Bool
    let createdAt: String
    let updatedAt: String

    // 关联的章节信息
    var section: NoteCenterMarkSection?
}

// 注意：TextRange 已在 ClassicsAPIService.swift 中定义

// MARK: - 笔记中心专用的章节信息（包含书籍和章节信息）
struct NoteCenterMarkSection: Codable {
    let id: String
    let bookId: String
    let chapterId: String
    let original: String
    let translation: String

    // 扩展信息（前端添加）
    var bookTitle: String?
    var chapterTitle: String?
}

// MARK: - 筛选类型
enum MarkFilterType: String, CaseIterable {
    case all = "全部"
    case favorite = "收藏"
    case highlight = "高亮"
    case note = "笔记"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .favorite:
            return "star.fill"
        case .highlight:
            return "paintbrush.fill"
        case .note:
            return "note.text"
        }
    }
}

// MARK: - 分组选项
enum GroupingOption: String, CaseIterable {
    case none = "不分组"
    case byBook = "按书籍分组"
    case byChapter = "按章节分组"
    case byColor = "按颜色分组"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .none:
            return "list.bullet"
        case .byBook:
            return "books.vertical"
        case .byChapter:
            return "book.closed"
        case .byColor:
            return "paintpalette"
        }
    }
}

// MARK: - 排序选项
enum SortingOption: String, CaseIterable {
    case newestFirst = "最新优先"
    case oldestFirst = "最早优先"
    case recentlyUpdated = "最近更新"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .newestFirst:
            return "arrow.down.circle"
        case .oldestFirst:
            return "arrow.up.circle"
        case .recentlyUpdated:
            return "clock.arrow.circlepath"
        }
    }
}

// MARK: - API 响应模型
struct MarksResponse: Codable {
    let code: Int
    let message: String
    let data: [TextMark]
}

struct MarkResponse: Codable {
    let code: Int
    let message: String
    let data: TextMark
}

struct DeleteMarkResponse: Codable {
    let code: Int
    let message: String
    let data: DeleteMarkData
}

struct DeleteMarkData: Codable {
    let success: Bool
}

// 注意：CreateMarkRequest 和 UpdateMarkRequest 不再需要，
// 因为新的 API 直接使用字典参数

