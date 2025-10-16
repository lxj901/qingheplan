import SwiftUI
import AVFoundation

struct WhiteNoisePageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = WhiteNoisePlayer.shared
    
    @State private var selectedCategory: String? = nil
    @State private var categories: [WhiteNoiseCategory] = []
    @State private var whiteNoiseList: [WhiteNoise] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var showSleepTimerSheet = false

    var body: some View {
        ZStack {
            // 深色背景 - 与睡眠管理页面一致
            Color(red: 0.08, green: 0.12, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // 分类选择
                        categoryChips
                            .padding(.top, 20)

                        // 总时长显示
                        if !whiteNoiseList.isEmpty {
                            totalDurationView
                                .padding(.horizontal, 20)
                        }

                        // 白噪音网格
                        if isLoading && whiteNoiseList.isEmpty {
                            loadingView
                        } else if let error = errorMessage {
                            errorView(message: error)
                        } else {
                            grid
                        }
                    }
                    .padding(.bottom, player.currentWhiteNoise != nil ? 200 : 120)
                }
            }

            // 底部播放器
            if let whiteNoise = player.currentWhiteNoise {
                VStack {
                    Spacer()
                    bottomPlayer(for: whiteNoise)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSleepTimerSheet) {
            SleepTimerSheet(player: player, isPresented: $showSleepTimerSheet)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadCategories()
            loadWhiteNoiseList()
        }
    }
}

// MARK: - Components
private extension WhiteNoisePageView {

    var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }

            Spacer()

            Text("白噪音")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 占位符保持平衡
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // API 分类
                ForEach(categories) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category.category
                            currentPage = 1
                            loadWhiteNoiseList()
                        }
                    }) {
                        Text(category.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedCategory == category.category ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category.category ?
                                          Color(red: 0.6, green: 0.4, blue: 1.0) :
                                          Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    var totalDurationView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("共 \(whiteNoiseList.count) 首")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text("•")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            
            Text("总时长 \(formatTotalDuration())")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
            ForEach(whiteNoiseList) { whiteNoise in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        player.play(whiteNoise: whiteNoise)
                    }
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 封面图片
                        CachedAsyncImage(url: URL(string: whiteNoise.coverUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(1.2, contentMode: .fill)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 140)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .overlay(
                            // 播放指示器
                            Group {
                                if player.currentWhiteNoise?.id == whiteNoise.id && player.isPlaying {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        AnimatedWaveformIcon()
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                            }
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(whiteNoise.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text(formatDuration(whiteNoise.duration))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text("加载中...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("重试") {
                loadWhiteNoiseList()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(red: 0.6, green: 0.4, blue: 1.0))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    func bottomPlayer(for whiteNoise: WhiteNoise) -> some View {
        VStack(spacing: 0) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color(red: 0.6, green: 0.4, blue: 1.0))
                        .frame(width: geometry.size.width * player.progress, height: 2)
                }
            }
            .frame(height: 2)
            
            // 播放器主体
            HStack(spacing: 16) {
                // 封面图片
                CachedAsyncImage(url: URL(string: whiteNoise.coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                }

                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(whiteNoise.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(formatDuration(Int(player.currentTime)))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("/")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(formatDuration(whiteNoise.duration))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // 播放控制
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if player.isPlaying {
                                player.pause()
                            } else {
                                player.resume()
                            }
                        }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.3))
                            )
                    }

                    // 定时器按钮
                    Button(action: {
                        showSleepTimerSheet = true
                    }) {
                        ZStack {
                            if let timer = player.sleepTimer {
                                // 显示剩余时间
                                VStack(spacing: 2) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 1.0))
                                    Text(formatTimerRemaining(player.remainingTime))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 1.0))
                                }
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.15))
                                        .overlay(
                                            Circle()
                                                .stroke(Color(red: 0.6, green: 0.4, blue: 1.0), lineWidth: 2)
                                        )
                                )
                            } else {
                                Image(systemName: "moon.zzz")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(Color(red: 0.08, green: 0.12, blue: 0.25))
        }
        .background(Color(red: 0.08, green: 0.12, blue: 0.25))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    func formatTimerRemaining(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    func formatTotalDuration() -> String {
        let totalSeconds = whiteNoiseList.reduce(0) { $0 + $1.duration }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else {
            return String(format: "%d分钟", minutes)
        }
    }
}

// MARK: - API Methods
private extension WhiteNoisePageView {
    func loadCategories() {
        WhiteNoiseAPIService.shared.getCategories { result in
            switch result {
            case .success(let categories):
                self.categories = categories
                // 默认选中第一个分类
                if self.selectedCategory == nil, let firstCategory = categories.first {
                    self.selectedCategory = firstCategory.category
                }
            case .failure(let error):
                print("Failed to load categories: \(error)")
            }
        }
    }
    
    func loadWhiteNoiseList() {
        isLoading = true
        errorMessage = nil
        
        WhiteNoiseAPIService.shared.getWhiteNoiseList(
            category: selectedCategory,
            page: currentPage,
            limit: 20
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                if currentPage == 1 {
                    whiteNoiseList = response.list
                } else {
                    whiteNoiseList.append(contentsOf: response.list)
                }
                totalPages = response.pagination.pages
                
            case .failure(let error):
                errorMessage = "加载失败: \(error.localizedDescription)"
                print("Failed to load white noise list: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack { WhiteNoisePageView() }
}

// MARK: - Animated Waveform Icon
struct AnimatedWaveformIcon: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3)
                    .frame(height: waveHeight(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 24)
        .onAppear {
            isAnimating = true
        }
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeights: [CGFloat] = [12, 20, 24, 20, 12]
        let animatedHeights: [CGFloat] = [20, 24, 12, 24, 20]
        return isAnimating ? animatedHeights[index] : baseHeights[index]
    }
}

// MARK: - Sleep Timer Sheet
struct SleepTimerSheet: View {
    @ObservedObject var player: WhiteNoisePlayer
    @Binding var isPresented: Bool
    
    let timerOptions = [10, 15, 20, 30, 45, 60, 90, 120]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("睡眠定时")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if player.sleepTimer != nil {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            player.cancelSleepTimer()
                        }
                    }) {
                        Text("取消定时")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // 定时器选项
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(timerOptions, id: \.self) { minutes in
                        TimerOptionButton(
                            minutes: minutes,
                            isSelected: player.sleepTimer == minutes,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    player.setSleepTimer(minutes: minutes)
                                    isPresented = false
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .background(Color(red: 0.08, green: 0.12, blue: 0.25))
    }
}

// MARK: - Timer Option Button
struct TimerOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(minutes) 分钟")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if minutes >= 60 {
                        Text("\(minutes / 60) 小时\(minutes % 60 > 0 ? " \(minutes % 60) 分钟" : "")")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 1.0))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ?
                          Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.15) :
                            Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ?
                                Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.5) :
                                    Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

