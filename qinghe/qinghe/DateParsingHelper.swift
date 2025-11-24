import Foundation

struct DateParsingHelper {
    /// 解析后端/本地的运动时间字符串为 Date
    /// - Strategy:
    ///   1. 优先 ISO8601（含/不含毫秒）
    ///   2. 再尝试常见的非 ISO 格式
    ///   3. 含 'Z' 统一按 UTC 解析；不含时区的按亚洲/上海解析
    static func parseWorkoutDate(_ s: String) -> Date? {
        let zhLocale = Locale(identifier: "zh_CN")
        let shanghai = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let isUTC = s.contains("Z")

        // ISO8601（带毫秒）
        if #available(iOS 10.0, *) {
            let isoMs = ISO8601DateFormatter()
            isoMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoMs.date(from: s) { return d }

            // ISO8601（不带毫秒）
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: s) { return d }
        }

        // 常见格式列表（含/不含 'T'、含/不含秒、斜杠/短横线）
        let patterns = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "HH:mm:ss"
        ]

        for p in patterns {
            let df = DateFormatter()
            df.locale = zhLocale
            df.timeZone = isUTC ? TimeZone(secondsFromGMT: 0) : shanghai
            df.dateFormat = p
            if let d = df.date(from: s) { return d }
        }
        return nil
    }

    /// 将 start/end 时间字符串格式化为时间段展示
    /// - Parameters:
    ///   - sameDayMerge: 同一天是否合并显示日期
    ///   - dateFormat: 日期部分格式（例如 "yyyy-MM-dd"）
    ///   - timeFormat: 时间部分格式（例如 "HH:mm"）
    ///   - timeZone: 展示时区（建议 Asia/Shanghai）
    ///   - locale: 展示语言（建议 zh_CN）
    static func formatTimeRange(
        startTime: String,
        endTime: String,
        sameDayMerge: Bool = true,
        dateFormat: String = "yyyy-MM-dd",
        timeFormat: String = "HH:mm",
        timeZone: TimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current,
        locale: Locale = Locale(identifier: "zh_CN")
    ) -> String {
        guard let start = parseWorkoutDate(startTime),
              let end = parseWorkoutDate(endTime) else {
            return ""
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let dateDF = DateFormatter()
        dateDF.locale = locale
        dateDF.timeZone = timeZone
        dateDF.dateFormat = dateFormat

        let timeDF = DateFormatter()
        timeDF.locale = locale
        timeDF.timeZone = timeZone
        timeDF.dateFormat = timeFormat

        let startDateStr = dateDF.string(from: start)
        let endDateStr = dateDF.string(from: end)
        let startTimeStr = timeDF.string(from: start)
        let endTimeStr = timeDF.string(from: end)

        if sameDayMerge && calendar.isDate(start, inSameDayAs: end) {
            return "\(startDateStr) \(startTimeStr) - \(endTimeStr)"
        } else {
            return "\(startDateStr) \(startTimeStr) - \(endDateStr) \(endTimeStr)"
        }
    }
}

