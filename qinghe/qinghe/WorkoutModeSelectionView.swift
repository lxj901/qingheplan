import SwiftUI

struct WorkoutModeSelectionView: View {
    @State private var selectedType: WorkoutType = .walking  // 改为更中性的默认值
    @State private var showCountdownAnimation = false
    @State private var navigateToWorkout = false
    @State private var currentTime = Date()

    // 控制更多选择区域的显示/隐藏 - 设为 false 隐藏，设为 true 恢复显示
    private let showMoreOptionsSection = false

    // 定时器用于更新时间
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 现代化渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "F0F9FF"),
                    Color(hex: "E0F7FA"),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 个性化问候区域
                    personalizedGreeting

                    // 运动类型选择 - 重新设计
                    modernWorkoutTypeSection

                    // 智能推荐区域
                    smartRecommendationSection

                    // 快速操作区域 - 根据控制变量决定是否显示
                    if showMoreOptionsSection {
                        quickActionSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("AI智能教练")
            .navigationBarTitleDisplayMode(.large)

            // 321GO倒计时动画
            if showCountdownAnimation {
                WorkoutCountdownView(
                    workoutType: selectedType,
                    workoutMode: .free
                ) {
                    // 动画完成后的回调
                    showCountdownAnimation = false
                    navigateToWorkout = true
                }
            }
        }
        .background(
            NavigationLink(
                destination: KeepStyleWorkoutLiveView(
                    workoutType: selectedType,
                    workoutMode: WorkoutMode.free
                ),
                isActive: $navigateToWorkout
            ) {
                EmptyView()
            }
            .hidden()
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .toolbar(.hidden, for: .tabBar)
    }



    // MARK: - 个性化问候
    private var personalizedGreeting: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getGreetingText())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("今天想要挑战什么运动？")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // 时间显示
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentTime, style: .time)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryGradientEnd)

                    Text(getWeatherIcon())
                        .font(.title2)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.primaryGradientStart.opacity(0.1),
                    AppTheme.primaryGradientEnd.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.primaryGradientStart.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 现代化运动类型选择
    private var modernWorkoutTypeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("选择运动类型")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach([WorkoutType.running, .walking, .cycling, .hiking], id: \.self) { type in
                    ModernWorkoutTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
    }

    // MARK: - 立即开始区域
    private var smartRecommendationSection: some View {
        // 自由运动 - 重新设计，移除智能推荐标题和AI推荐UI
        Button(action: {
            startFreeWorkoutWithAnimation()
        }) {
            HStack(spacing: 16) {
                // 动态图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("立即开始\(selectedType.displayName)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("开始您的健康之旅")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primaryGradientEnd)

                    Text("开始")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primaryGradientEnd)
                }
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
    }

    // MARK: - 快速操作区域 (已隐藏 - 可通过修改 showMoreOptionsSection 为 true 来恢复显示)
    private var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("更多选择")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ModernActionCard(
                    icon: "location.magnifyingglass",
                    title: "探索新路线",
                    subtitle: "发现周边精彩\(selectedType.displayName)路线",
                    color: AppTheme.accentBlue,
                    badge: "路书推荐"
                ) {
                    exploreNewRoutes()
                }

                ModernActionCard(
                    icon: "map.circle.fill",
                    title: "自定义路线",
                    subtitle: "创建专属\(selectedType.displayName)路线",
                    color: AppTheme.accentOrange,
                    badge: "个性化"
                ) {
                    createCustomRoute()
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 6)
    }

    // MARK: - 辅助方法
    private func getGreetingText() -> String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "早上好！"
        case 12..<17:
            return "下午好！"
        case 17..<22:
            return "晚上好！"
        default:
            return "夜深了"
        }
    }

    private func getWeatherIcon() -> String {
        // 这里可以集成真实天气API，现在返回随机图标
        let icons = ["☀️", "⛅️", "🌤", "🌦", "❄️"]
        return icons.randomElement() ?? "☀️"
    }

    // MARK: - 功能方法
    private func startFreeWorkout() {
        // 开始自由运动 - 跳转到Keep风格运动实况页面
        print("开始自由\(selectedType.rawValue)")
        // 这里应该通过NavigationLink跳转到KeepStyleWorkoutLiveView
    }

    private func startFreeWorkoutWithAnimation() {
        showCountdownAnimation = true
        print("开始自由\(selectedType.rawValue)运动倒计时")
    }

    private func exploreNewRoutes() {
        // 跳转到路书推荐页面
        // 路书推荐功能已移除
        print("探索新的\(selectedType.rawValue)路线 - 跳转到路书推荐页面")
    }

    private func createCustomRoute() {
        // 自定义路线功能已移除
    }
}

// 临时测试视图
struct TestWorkoutView: View {
    let workoutType: WorkoutType
    let workoutMode: WorkoutMode

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // 深色背景
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // 顶部信息
                VStack(spacing: 10) {
                    Text(workoutType.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(workoutMode.rawValue)
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                // 地图占位区域
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))

                            Text("高德地图加载中...")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )

                // 数据显示区域
                HStack(spacing: 40) {
                    VStack {
                        Text("0.00")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("公里")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text("00:00")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("时间")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text("0")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("千卡")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // 控制按钮
                HStack(spacing: 30) {
                    Button("结束") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 25))

                    Button("暂停") {
                        // 暂停功能
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.green)
                    .clipShape(Circle())
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .navigationTitle("运动实况")
    }
}

// MARK: - 现代化UI组件

struct ModernWorkoutTypeCard: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: type.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)

                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? AppTheme.primaryGradientEnd : AppTheme.textPrimary)

                    Text(getTypeDescription(type))
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppTheme.primaryGradientEnd : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? AppTheme.primaryGradientEnd.opacity(0.3) : AppTheme.cardShadow,
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getTypeDescription(_ type: WorkoutType) -> String {
        switch type {
        case .running:
            return "燃烧卡路里"
        case .walking:
            return "轻松健步"
        case .cycling:
            return "骑行探索"
        case .hiking:
            return "登山挑战"
        default:
            return "开始运动"
        }
    }
}

struct ModernActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void

    init(icon: String, title: String, subtitle: String, color: Color, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // 顶部徽章
                HStack {
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }

                // 图标
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.cardShadow, radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        WorkoutModeSelectionView()
    }
}