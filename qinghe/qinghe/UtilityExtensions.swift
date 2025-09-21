import SwiftUI
import Foundation

// 注意：Color.init(hex:) 已在 SleepModels.swift 中定义

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Double Extensions
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    var formatDistance: String {
        if self >= 1.0 {
            return String(format: "%.2f km", self)
        } else {
            return String(format: "%.0f m", self * 1000)
        }
    }
    
    var formatSpeed: String {
        return String(format: "%.1f km/h", self * 3.6)
    }
}

// MARK: - Int Extensions
extension Int {
    var formatTime: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// MARK: - Array Extensions
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}