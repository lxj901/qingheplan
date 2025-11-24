import SwiftUI

// 收支明细页面
struct AccountTransactionsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var filter: TransactionFilter = .all
    @State private var currentMonth: String = "11月"
    @State private var showMonthPicker: Bool = false
    @State private var showStats: Bool = false

    private let backgroundColor = Color(red: 240/255, green: 247/255, blue: 244/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        balanceCard
                        transactionsContainer
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(currentMonth: $currentMonth,
                             isPresented: $showMonthPicker)
                .presentationDetents([.fraction(0.4), .medium])
        }
        .sheet(isPresented: $showStats) {
            StatsSheet(currentMonth: currentMonth,
                       isPresented: $showStats)
                .presentationDetents([.medium])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .asSubView()
    }

    // 顶部栏
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                    )
            }

            Spacer()

            Text("收支明细")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            ZStack(alignment: .bottom) {
                backgroundColor.opacity(0.95)
                Divider()
            }
        )
    }

    // 资产卡片
    private var balanceCard: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Color.green.opacity(0.98), Color.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 140, height: 140)
                .offset(x: 40, y: -40)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        showMonthPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(currentMonth)结余")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.16))
                        .foregroundColor(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Spacer()

                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 14))
                            .padding(8)
                            .background(Color.white.opacity(0.16))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("¥")
                        .font(.system(size: 22, weight: .bold))
                        .opacity(0.8)
                    Text("4,285.50")
                        .font(.system(size: 34, weight: .black))
                }

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 12))
                            Text("收入")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color.white.opacity(0.8))

                        Text("¥ 5,340.00")
                            .font(.system(size: 16, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                            Text("支出")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color.white.opacity(0.8))

                        Text("¥ 1,054.50")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .padding(20)
            .foregroundColor(.white)
        }
        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 6)
    }

    // 筛选 + 列表容器
    private var transactionsContainer: some View {
        VStack(spacing: 0) {
            filterHeader
            Divider()
                .background(Color(.systemGray5))
            transactionList
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.green.opacity(0.06))
        )
    }

    private var filterHeader: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(TransactionFilter.allCases, id: \.self) { type in
                    Button {
                        filter = type
                    } label: {
                        Text(type.rawValue)
                            .font(.caption.weight(.bold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                filter == type
                                ? Color.white
                                : Color(.systemGray6)
                            )
                            .foregroundColor(
                                filter == type ? .primary : .secondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: filter == type ? Color.black.opacity(0.06) : .clear,
                                    radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(4)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()

            Button {
                showMonthPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(currentMonth)
                        .font(.caption.weight(.bold))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(.systemGray6))
                .foregroundColor(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // 交易列表
    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sampleTransactionGroups) { group in
                let items = filteredItems(for: group.items)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.date)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6).opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.leading, 16)

                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                HStack(spacing: 12) {
                                    icon(for: item.category)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(item.title)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                            amountView(for: item)
                                        }

                    HStack {
                                            Text("\(item.time) · 余额 ¥\(String(format: "%.2f", item.balanceAfter))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            statusBadge(for: item)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // 点击某条流水，可在这里跳转详情
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }

            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 1)
                Text("仅展示近半年的收支明细")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(.vertical, 16)
    }

    // 数据过滤
    private func filteredItems(for items: [Transaction]) -> [Transaction] {
        switch filter {
        case .all:
            return items
        case .income:
            return items.filter { $0.type == .income }
        case .expense:
            return items.filter { $0.type == .expense }
        }
    }

    private func icon(for category: TransactionCategory) -> some View {
        let symbol: String
        let color: Color

        switch category {
        case .member:
            symbol = "arrow.down.left"
            color = .green
        case .withdraw:
            symbol = "arrow.up.right"
            color = .orange
        case .reward:
            symbol = "chart.line.uptrend.xyaxis"
            color = .red
        case .fee:
            symbol = "chart.pie"
            color = .blue
        case .refund:
            symbol = "arrow.uturn.left"
            color = .gray
        case .other:
            symbol = "wallet.pass"
            color = .gray
        }

        return ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private func amountView(for transaction: Transaction) -> some View {
        let isIncome = transaction.type == .income
        let value = abs(transaction.amount)
        let prefix = isIncome ? "+" : "-"

        return Text("\(prefix)\(String(format: "%.2f", value))")
            .font(.system(size: 16, weight: .bold, design: .default))
            .foregroundColor(isIncome ? Color.green : Color.primary)
    }

    private func statusBadge(for transaction: Transaction) -> some View {
        let isPending = transaction.status == .pending
        let isWithdraw = transaction.category == .withdraw

        let bg: Color
               let fg: Color
        let text: String

        if isPending {
            bg = Color.orange.opacity(0.1)
            fg = .orange
            text = "审核中"
        } else if isWithdraw {
            bg = Color(.systemGray5)
            fg = .gray
            text = "交易成功"
        } else {
            bg = Color.green.opacity(0.1)
            fg = .green
            text = "交易成功"
        }

        return Text(text)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(bg)
            .foregroundColor(fg)
            .clipShape(Capsule())
    }
}

// 过滤类型
enum TransactionFilter: String, CaseIterable {
    case all = "全部"
    case income = "收入"
    case expense = "支出"
}

enum TransactionType {
    case income
    case expense
}

enum TransactionStatus {
    case success
    case pending
}

enum TransactionCategory {
    case member
    case withdraw
    case reward
    case refund
    case fee
    case other
}

struct Transaction: Identifiable {
    let id: Int
    let title: String
    let time: String
    let amount: Double
    let type: TransactionType
    let status: TransactionStatus
    let category: TransactionCategory
    let balanceAfter: Double
}

struct TransactionGroup: Identifiable {
    let id = UUID()
    let date: String
    let items: [Transaction]
}

// 示例数据
private let sampleTransactionGroups: [TransactionGroup] = [
    TransactionGroup(
        date: "今天",
        items: [
            Transaction(id: 1, title: "付费入群 - 微信用户8821", time: "14:23",
                        amount: 29.90, type: .income, status: .success,
                        category: .member, balanceAfter: 4285.50),
            Transaction(id: 2, title: "余额提现", time: "10:00",
                        amount: 500.00, type: .expense, status: .pending,
                        category: .withdraw, balanceAfter: 3785.50)
        ]
    ),
    TransactionGroup(
        date: "昨天",
        items: [
            Transaction(id: 3, title: "内容打赏 - 《秋日露营...》", time: "19:45",
                        amount: 5.00, type: .income, status: .success,
                        category: .reward, balanceAfter: 4290.50),
            Transaction(id: 4, title: "付费入群 - 没头脑的不高兴", time: "09:12",
                        amount: 29.90, type: .income, status: .success,
                        category: .member, balanceAfter: 4285.50),
            Transaction(id: 5, title: "活动报名费退款", time: "08:30",
                        amount: 99.00, type: .expense, status: .success,
                        category: .refund, balanceAfter: 4255.60)
        ]
    ),
    TransactionGroup(
        date: "11月10日",
        items: [
            Transaction(id: 6, title: "平台技术服务费", time: "00:00",
                        amount: 2.50, type: .expense, status: .success,
                        category: .fee, balanceAfter: 4253.10)
        ]
    )
]

struct TransactionCategoryStat: Identifiable {
    let id = UUID()
    let label: String
    let percent: Double
    let amount: String
    let color: Color
}

private let sampleCategoryStats: [TransactionCategoryStat] = [
    TransactionCategoryStat(label: "付费入群", percent: 0.65, amount: "3,471.00", color: .green),
    TransactionCategoryStat(label: "内容打赏", percent: 0.25, amount: "1,335.00", color: .teal),
    TransactionCategoryStat(label: "活动收入", percent: 0.10, amount: "534.00", color: .cyan)
]

// 月份选择器
struct MonthPickerSheet: View {
    @Binding var currentMonth: String
    @Binding var isPresented: Bool

    private let months = ["12月", "11月", "10月", "9月", "8月", "7月", "6月", "5月"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择时间")
                    .font(.headline.weight(.bold))
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                      spacing: 12) {
                ForEach(months, id: \.self) { month in
                    Button {
                        currentMonth = month
                        isPresented = false
                    } label: {
                        Text(month)
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                currentMonth == month
                                ? Color.green
                                : Color(.systemGray6)
                            )
                            .foregroundColor(
                                currentMonth == month ? .white : .gray
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: currentMonth == month ? Color.green.opacity(0.2) : .clear,
                                    radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding()

            Spacer()
        }
    }
}

// 收支统计弹窗
struct StatsSheet: View {
    let currentMonth: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentMonth)收支分析")
                        .font(.headline.weight(.bold))
                    Text("总收入占比分析")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: 0.65, to: 0.9)
                        .stroke(Color.teal, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: 0.9, to: 1.0)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("总收入")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("¥5.3k")
                            .font(.title3.weight(.black))
                    }
                }
                .frame(width: 120, height: 120)
                Spacer()
            }
            .padding(.vertical, 12)

            VStack(spacing: 12) {
                ForEach(sampleCategoryStats, id: \.id) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(stat.color)
                                    .frame(width: 6, height: 6)
                                Text(stat.label)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("¥\(stat.amount)")
                                .font(.caption.weight(.bold))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                Capsule()
                                    .fill(stat.color)
                                    .frame(width: geo.size.width * stat.percent)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }

            Button {
                isPresented = false
            } label: {
                Text("知道了")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundColor(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        AccountTransactionsView()
    }
}
