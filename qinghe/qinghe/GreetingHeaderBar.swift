import SwiftUI

struct GreetingHeaderBar: View {
    var title: String? = nil
    var subtitle: String? = nil

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7A5C2E"), Color(hex: "BDA86A")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ObservedObject private var authManager = AuthManager.shared

    // MARK: - Computed subtitle (Lunar + Meridian)
    private var dynamicSubtitle: String {
        let now = Date()
        let lunar = lunarMonthDayString(for: now)
        let period = meridianPeriod(for: now)
        return "农历\(lunar) | \(period.branch)时·\(period.meridian)经 \(period.rangeText)"
    }

    var body: some View {
        ZStack {
            // No background panel per request; content floats on page background
            HStack(alignment: .center, spacing: 12) {
                // User avatar (real avatar if available)
                Group {
                    if let urlString = authManager.currentUser?.avatar,
                       let url = URL(string: urlString),
                       !urlString.isEmpty {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle().fill(LinearGradient(colors: [Color(hex: "CF9D7A"), Color(hex: "B77E63")], startPoint: .top, endPoint: .bottom))
                        }
                    } else {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [Color(hex: "CF9D7A"), Color(hex: "B77E63")], startPoint: .top, endPoint: .bottom))
                            Image(systemName: "face.smiling")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1))

                // Text block to the right of avatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(title ?? dynamicGreeting)
                        .font(AppFont.kangxi(size: 24))
                        .foregroundColor(.black)

                    Text(subtitle ?? dynamicSubtitle)
                        .font(AppFont.kangxi(size: 16))
                        .foregroundColor(Color(hex: "7F7769").opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GreetingHeaderBar()
        .padding()
}

// MARK: - Helpers: Lunar date and meridian period
extension GreetingHeaderBar {
    private var dynamicGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好！"
        case 12..<14: return "中午好！"
        case 14..<18: return "下午好！"
        default: return "晚上好！"
        }
    }
    private func lunarMonthDayString(for date: Date) -> String {
        let cal = Calendar(identifier: .chinese)
        let comps = cal.dateComponents([.month, .day], from: date)
        let month = (comps.month ?? 1)
        let day = (comps.day ?? 1)

        let monthMap = ["正","二","三","四","五","六","七","八","九","十","冬","腊"]
        let dayMap = [
            "初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
            "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
            "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"
        ]
        let monthText = monthMap[(month - 1 + monthMap.count) % monthMap.count] + "月"
        let dayText = dayMap[max(0, min(day - 1, dayMap.count - 1))]
        return monthText + dayText
    }

    private func meridianPeriod(for date: Date) -> (branch: String, meridian: String, rangeText: String) {
        let hour = Calendar.current.component(.hour, from: date)
        // Start hours for each 2-hour block
        let starts = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21]
        let branches = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
        let meridians = ["胆","肝","肺","大肠","胃","脾","心","小肠","膀胱","肾","心包","三焦"]

        var index = 0
        for i in 0..<starts.count {
            let start = starts[i]
            let end = (start + 2) % 24
            if start == 23 { // 23-1
                if hour >= 23 || hour < 1 { index = i; break }
            } else {
                if hour >= start && hour < ((start + 2) % 24 == 0 ? 24 : start + 2) { index = i; break }
            }
        }
        let start = starts[index]
        let end = (start + 2) % 24
        let dash = "–" // en dash for nicer typography
        let rangeText = end == 1 ? "23\(dash)1点" : "\(start)\(dash)\(end)点"
        return (branches[index], meridians[index], rangeText)
    }
}
