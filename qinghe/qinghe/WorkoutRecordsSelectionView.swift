import SwiftUI

struct WorkoutRecordsSelectionView: View {
    let onSelection: (WorkoutRecord?) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedWorkout: WorkoutRecord?

    // 从 API 获取的运动历史数据
    @State private var workoutRecords: [WorkoutRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentPage = 1
    @State private var hasMoreData = true
    @State private var isLoadingMore = false

    // 运动数据服务
    private let workoutService = NewWorkoutAPIService.shared
    private let pageSize = 20
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            if isLoading && workoutRecords.isEmpty {
                loadingView
            } else if let errorMessage = errorMessage, workoutRecords.isEmpty {
                errorView(errorMessage)
            } else if workoutRecords.isEmpty {
                emptyView
            } else {
                workoutHistoryList
            }
        }
        .navigationBarHidden(true) // 隐藏导航栏，因为我们有自定义的取消/确定按钮
        .asSubView() // 隐藏底部Tab栏
        .onAppear {
            if workoutRecords.isEmpty {
                loadWorkoutRecords()
            }
        }
        .refreshable {
            refreshWorkoutRecords()
        }
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        HStack {
            // 取消按钮
            Button(action: {
                onSelection(nil)
            }) {
                Text("取消")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            // 标题
            Text("运动历史")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // 确定按钮
            Button(action: {
                onSelection(selectedWorkout)
            }) {
                Text("确定")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedWorkout != nil ? .green : .gray)
            }
            .disabled(selectedWorkout == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - View Components

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载运动历史...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("加载失败")
                .font(.headline)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                loadWorkoutRecords()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("暂无运动记录")
                .font(.headline)
            Text("完成运动后，记录会显示在这里")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var workoutHistoryList: some View {
        List {
            ForEach(workoutRecords, id: \.id) { workout in
                WorkoutHistoryRow(
                    workout: workout,
                    isSelected: selectedWorkout?.id == workout.id
                ) {
                    selectedWorkout = workout
                }
                .onAppear {
                    // 当滚动到最后几个项目时加载更多数据
                    if workout.id == workoutRecords.last?.id && hasMoreData && !isLoadingMore {
                        loadMoreWorkouts()
                    }
                }
            }

            // 加载更多指示器
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("加载更多...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Methods

    private func loadWorkoutRecords() {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMoreData = true

        Task {
            do {
                // 获取运动历史数据
                let historyResponse = try await workoutService.getWorkouts(
                    page: currentPage,
                    limit: pageSize,
                    sortBy: "startTime",
                    sortOrder: "desc"
                )

                // 转换为 WorkoutRecord 格式
                let records = historyResponse.map { workout in
                    WorkoutRecord(
                        id: String(workout.workoutId),
                        type: workout.workoutType,
                        startTime: parseDate(workout.startTime) ?? Date(),
                        endTime: parseDate(workout.endTime) ?? Date(),
                        distance: workout.basicMetrics.totalDistance,
                        duration: TimeInterval(workout.duration),
                        calories: workout.basicMetrics.calories,
                        averageSpeed: workout.basicMetrics.maxSpeed,
                        workoutId: workout.workoutId
                    )
                }

                await MainActor.run {
                    self.workoutRecords = records
                    self.hasMoreData = records.count == self.pageSize
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func refreshWorkoutRecords() {
        currentPage = 1
        hasMoreData = true

        Task {
            do {
                let historyResponse = try await workoutService.getWorkouts(
                    page: currentPage,
                    limit: pageSize,
                    sortBy: "startTime",
                    sortOrder: "desc"
                )

                let records = historyResponse.map { workout in
                    WorkoutRecord(
                        id: String(workout.workoutId),
                        type: workout.workoutType,
                        startTime: parseDate(workout.startTime) ?? Date(),
                        endTime: parseDate(workout.endTime) ?? Date(),
                        distance: workout.basicMetrics.totalDistance,
                        duration: TimeInterval(workout.duration),
                        calories: workout.basicMetrics.calories,
                        averageSpeed: workout.basicMetrics.maxSpeed,
                        workoutId: workout.workoutId
                    )
                }

                await MainActor.run {
                    self.workoutRecords = records
                    self.hasMoreData = records.count == self.pageSize
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadMoreWorkouts() {
        guard hasMoreData && !isLoadingMore else { return }

        isLoadingMore = true
        currentPage += 1

        Task {
            do {
                let historyResponse = try await workoutService.getWorkouts(
                    page: currentPage,
                    limit: pageSize,
                    sortBy: "startTime",
                    sortOrder: "desc"
                )

                let newRecords = historyResponse.map { workout in
                    WorkoutRecord(
                        id: String(workout.workoutId),
                        type: workout.workoutType,
                        startTime: parseDate(workout.startTime) ?? Date(),
                        endTime: parseDate(workout.endTime) ?? Date(),
                        distance: workout.basicMetrics.totalDistance,
                        duration: TimeInterval(workout.duration),
                        calories: workout.basicMetrics.calories,
                        averageSpeed: workout.basicMetrics.maxSpeed,
                        workoutId: workout.workoutId
                    )
                }

                await MainActor.run {
                    self.workoutRecords.append(contentsOf: newRecords)
                    self.hasMoreData = newRecords.count == self.pageSize
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.currentPage -= 1 // 回退页码
                    self.isLoadingMore = false
                }
            }
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()

        // 首先尝试 API 返回的格式: "2025-09-17 07:02:47"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        // 尝试 ISO8601 格式
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // 尝试带毫秒的格式
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        // 尝试不带毫秒的格式
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - WorkoutHistoryRow
struct WorkoutHistoryRow: View {
    let workout: WorkoutRecord
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 运动类型图标
                ZStack {
                    Circle()
                        .fill(getWorkoutTypeColor(workout.type).opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: getWorkoutTypeIcon(workout.type))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(getWorkoutTypeColor(workout.type))
                }

                // 运动信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(getWorkoutTypeName(workout.type))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(formatDate(workout.startTime))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    // 运动数据
                    HStack(spacing: 16) {
                        if workout.distance > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", workout.distance))km")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(formatDuration(workout.duration))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(workout.calories)卡")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }

                // 选择状态
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getWorkoutTypeName(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "跑步"
        case "cycling": return "骑行"
        case "walking": return "步行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiit": return "HIIT"
        case "cardio": return "有氧运动"
        default: return "运动"
        }
    }

    private func getWorkoutTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "walking": return "figure.walk"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "strength": return "dumbbell"
        case "hiit": return "bolt"
        case "cardio": return "heart"
        default: return "figure.run"
        }
    }

    private func getWorkoutTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "running": return .blue
        case "cycling": return .green
        case "walking": return .orange
        case "swimming": return .cyan
        case "yoga": return .purple
        case "strength": return .red
        case "hiit": return .pink
        case "cardio": return .mint
        default: return .blue
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct WorkoutRecordRow: View {
    let workout: WorkoutRecord
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(getWorkoutTypeName(workout.type))
                    .font(.headline)
                
                Text(formatDate(workout.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(String(format: "%.1f", workout.distance))km", systemImage: "location")
                    Spacer()
                    Label("\(workout.calories)卡", systemImage: "flame")
                    Spacer()  
                    Label(formatDuration(workout.duration), systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getWorkoutTypeName(_ type: String) -> String {
        switch type {
        case "running": return "跑步"
        case "cycling": return "骑行"
        case "walking": return "步行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        default: return "运动"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// 运动数据模型
struct WorkoutRecord: Codable {
    let id: String
    let type: String
    let startTime: Date
    let endTime: Date
    let distance: Double
    let duration: TimeInterval
    let calories: Int
    let averageSpeed: Double
    let workoutId: Int
}

#Preview {
    WorkoutRecordsSelectionView { workoutData in
        print("Selected workout: \(workoutData?.type ?? "none")")
    }
}