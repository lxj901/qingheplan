import SwiftUI
import UIKit
import CoreText

/// 应用内字体助手：从 Bundle 获取自定义字体的 PostScript 名称，并提供便捷 API
enum AppFont {
    /// 缓存：康熙字典体的 PostScript 名称
    private static var cachedKangxiPSName: String?

    /// 获取康熙字典体（优先使用 UIAppFonts 已注册的字体；若未知名称，则从 Bundle 解析文件获取 PostScript 名称并缓存）
    static func kangxi(size: CGFloat, relativeTo textStyle: Font.TextStyle? = nil) -> Font {
        if let name = postScriptNameForKangxi() {
            if let textStyle { return .custom(name, size: size, relativeTo: textStyle) }
            return .custom(name, size: size)
        }
        // 兜底：使用系统字体，避免崩溃
        return .system(size: size)
    }

    /// 解析/查询康熙字典体的 PostScript 名称
    private static func postScriptNameForKangxi() -> String? {
        if let cached = cachedKangxiPSName { return cached }

        // 1) 尝试从 Bundle 中文件解析（文件名需与工程中一致）并在运行时注册字体
        let candidates: [(String, String)] = [
            ("康熙字典体完整版本(4)", "TTF"),
            ("康熙字典体完整版本(4)", "ttf"),
        ]
        for (res, ext) in candidates {
            if let url = Bundle.main.url(forResource: res, withExtension: ext) {
                // 先注册字体（无需在 Info.plist 配置 UIAppFonts）
                var cfError: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &cfError)
                // 即使注册失败（可能是已注册），也继续尝试解析 PostScript 名称
                if let dataProvider = CGDataProvider(url: url as CFURL),
                   let cgFont = CGFont(dataProvider),
                   let ps = cgFont.postScriptName as String? {
                    cachedKangxiPSName = ps
                    return ps
                }
            }
        }

        // 2) 回退：在系统已注册字体中模糊匹配（UIAppFonts 成功时通常可命中）
        for family in UIFont.familyNames {
            if family.contains("康熙") || family.localizedCaseInsensitiveContains("kangxi") {
                let names = UIFont.fontNames(forFamilyName: family)
                if let first = names.first { cachedKangxiPSName = first; return first }
            }
            for name in UIFont.fontNames(forFamilyName: family) {
                if name.localizedCaseInsensitiveContains("kangxi") {
                    cachedKangxiPSName = name
                    return name
                }
            }
        }
        return nil
    }
}

