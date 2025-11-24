import SwiftUI
import HealthKit

/// HealthKit运动记录导入视图
struct HealthKitWorkoutImportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HealthKitWorkoutImportViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.workouts.isEmpty {
                        emptyView
                    } else {
                        newDesignView
                    }
                }
            }
            .navigationTitle("运动数据同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadWorkouts()
                }
            }
            .alert("导入成功", isPresented: $viewModel.showSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("成功导入 \(viewModel.uploadedCount) 条运动记录")
            }
            .alert("导入失败", isPresented: $viewModel.showErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.uploadErrorMessage ?? "未知错误")
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载运动记录...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.system(size: 20, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("重试") {
                Task {
                    await viewModel.loadWorkouts()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("暂无运动记录")
                .font(.system(size: 20, weight: .semibold))

            VStack(spacing: 12) {
                Text("最近90天内没有找到运动记录")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("可能的原因：")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("Apple健康中没有运动记录")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("运动记录不在最近90天内")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("未授权访问健康数据")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }

            Button("重新加载") {
                Task {
                    await viewModel.loadWorkouts()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 76/255, green: 175/255, blue: 80/255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
    
    // MARK: - New Design View
    private var newDesignView: some View {
        VStack(spacing: 0) {
            // 标签页
            tabBar

            // 内容区域
            if viewModel.showOnlyNotUploaded {
                notUploadedListView
            } else {
                uploadedListView
            }

            // 底部上传按钮
            if viewModel.showOnlyNotUploaded && !viewModel.filteredWorkouts.isEmpty {
                uploadAllButton
            }
        }
    }

    // 标签页
    private var tabBar: some View {
        HStack(spacing: 0) {
            // 待上传标签
            Button(action: {
                viewModel.showOnlyNotUploaded = true
            }) {
                VStack(spacing: 8) {
                    Text("待上传 (\(viewModel.notUploadedCount))")
                        .font(.system(size: 15, weight: viewModel.showOnlyNotUploaded ? .semibold : .regular))
                        .foregroundColor(viewModel.showOnlyNotUploaded ? Color(red: 76/255, green: 175/255, blue: 80/255) : .gray)

                    Rectangle()
                        .fill(viewModel.showOnlyNotUploaded ? Color(red: 76/255, green: 175/255, blue: 80/255) : Color.clear)
                        .frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity)

            // 已上传标签
            Button(action: {
                viewModel.showOnlyNotUploaded = false
            }) {
                VStack(spacing: 8) {
                    Text("已上传 (\(viewModel.totalUploadedCount))")
                        .font(.system(size: 15, weight: !viewModel.showOnlyNotUploaded ? .semibold : .regular))
                        .foregroundColor(!viewModel.showOnlyNotUploaded ? Color(red: 76/255, green: 175/255, blue: 80/255) : .gray)

                    Rectangle()
                        .fill(!viewModel.showOnlyNotUploaded ? Color(red: 76/255, green: 175/255, blue: 80/255) : Color.clear)
                        .frame(height: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .background(Color.white)
    }

    // 待上传列表
    private var notUploadedListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedNotUploadedWorkouts.keys.sorted(by: >), id: \.self) { date in
                    Section(header: dateHeader(date)) {
                        ForEach(viewModel.groupedNotUploadedWorkouts[date] ?? [], id: \.uuid) { workout in
                            NewWorkoutRow(workout: workout, isUploaded: false)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    // 已上传列表
    private var uploadedListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedUploadedWorkouts.keys.sorted(by: >), id: \.self) { date in
                    Section(header: dateHeader(date)) {
                        ForEach(viewModel.groupedUploadedWorkouts[date] ?? [], id: \.uuid) { workout in
                            NewWorkoutRow(workout: workout, isUploaded: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    // 日期分组头部
    private func dateHeader(_ date: String) -> some View {
        HStack {
            Text(date)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "f5f5f5"))
    }

    // 上传全部按钮
    private var uploadAllButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {
                Task {
                    await viewModel.uploadAllNotUploaded()
                }
            }) {
                HStack {
                    if viewModel.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("上传中... \(viewModel.uploadedCount)/\(viewModel.notUploadedCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text("上传全部")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 76/255, green: 175/255, blue: 80/255))
                .cornerRadius(8)
            }
            .disabled(viewModel.isUploading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    // MARK: - Old Workout List View (保留作为备用)
    private var workoutListView: some View {
        VStack(spacing: 0) {
            // 顶部提示
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("选择要导入的运动记录")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                
                if !viewModel.selectedWorkouts.isEmpty {
                    Text("已选 \(viewModel.selectedWorkouts.count) 条")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.05))
            
            // 全选按钮和筛选开关
            HStack {
                Button(action: {
                    viewModel.toggleSelectAll()
                }) {
                    HStack {
                        Image(systemName: viewModel.isAllSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(.blue)
                        Text(viewModel.isAllSelected ? "取消全选" : "全选")
                            .font(.system(size: 14, weight: .medium))
                    }
                }

                Spacer()

                // 筛选开关
                Toggle(isOn: $viewModel.showOnlyNotUploaded) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                        Text("仅未上传")
                            .font(.system(size: 14))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // 运动记录列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredWorkouts, id: \.uuid) { workout in
                        HealthKitWorkoutRow(
                            workout: workout,
                            isSelected: viewModel.selectedWorkouts.contains(workout.uuid),
                            isUploaded: viewModel.isWorkoutUploaded(workout)
                        ) {
                            viewModel.toggleSelection(workout)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            // 上传进度
            if viewModel.isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.uploadProgress)
                        .progressViewStyle(.linear)
                    
                    Text("正在上传 \(viewModel.uploadedCount)/\(viewModel.selectedWorkouts.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
            }
        }
    }
}

// MARK: - New Workout Row Component
struct NewWorkoutRow: View {
    let workout: HKWorkout
    let isUploaded: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 左侧运动图标
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: getWorkoutIcon(workout.workoutActivityType))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(getWorkoutTypeName(workout.workoutActivityType))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)

                    Spacer()

                    Text(formatTime(workout.startDate))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 12) {
                    if let distance = workout.totalDistance?.doubleValue(for: .meter()), distance > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(String(format: "%.2f km", distance / 1000))
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(formatDuration(workout.duration))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(String(format: "%.0f", calories))
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }

                // 数据来源
                Text(getDataSource(workout))
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func getDataSource(_ workout: HKWorkout) -> String {
        return "数据来源：Apple 健康"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分钟"
        }
        return "\(seconds)秒"
    }

    private func getWorkoutTypeName(_ type: HKWorkoutActivityType) -> String {
        return HealthKitManager.shared.getWorkoutTypeName(type)
    }

    private func getWorkoutIcon(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .hiking: return "figure.hiking"
        case .functionalStrengthTraining: return "dumbbell"
        default: return "figure.mixed.cardio"
        }
    }
}

// MARK: - HealthKit Workout Row (Old)
struct HealthKitWorkoutRow: View {
    let workout: HKWorkout
    let isSelected: Bool
    let isUploaded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 选择框
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)

                // 运动类型图标
                ZStack {
                    Circle()
                        .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: getWorkoutIcon(workout.workoutActivityType))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }

                // 运动信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(getWorkoutTypeName(workout.workoutActivityType))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        // 已上传标记
                        if isUploaded {
                            Text("已上传")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .cornerRadius(4)
                        }

                        Spacer()

                        Text(formatDate(workout.startDate))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        if let distance = workout.totalDistance?.doubleValue(for: .meter()), distance > 0 {
                            Label(String(format: "%.2f km", distance / 1000), systemImage: "location")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Label(formatDuration(workout.duration), systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                            Label(String(format: "%.0f 卡", calories), systemImage: "flame")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func getWorkoutIcon(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .hiking: return "figure.hiking"
        default: return "figure.mixed.cardio"
        }
    }
    
    private func getWorkoutTypeName(_ type: HKWorkoutActivityType) -> String {
        return HealthKitManager.shared.getWorkoutTypeName(type)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current

        let dateString = formatter.string(from: date)

        // 检查是否是今天
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeString = dateString.split(separator: " ").last.map(String.init) ?? ""
            return "今天 " + timeString
        } else if calendar.isDateInYesterday(date) {
            let timeString = dateString.split(separator: " ").last.map(String.init) ?? ""
            return "昨天 " + timeString
        }

        return dateString
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

