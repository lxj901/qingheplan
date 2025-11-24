import SwiftUI

// MARK: - 听书悬浮球
struct ClassicsAudioFloatingButton: View {
    @ObservedObject var manager = ClassicsAudioPlayerManager.shared
    @Binding var showPlayer: Bool

    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var expandInfo: Bool = false
    
    var body: some View {
        if manager.showFloatingButton, let book = manager.currentBook {
            ZStack {
                // 悬浮球主体
                HStack(spacing: 12) {
                    // 播放/暂停按钮（点击打开播放器）
                    Button(action: {
                        showPlayer = true
                    }) {
                        ZStack {
                            // 背景渐变 - 使用书籍颜色
                            LinearGradient(
                                gradient: Gradient(colors: book.coverColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            // 播放/暂停图标
                            Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .offset(x: manager.isPlaying ? 0 : 2)
                        }
                    }
                    
                    // 书籍信息（可选，点击展开）
                    if !isDragging {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(manager.currentChapterTitle)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 150)
                        .padding(.trailing, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.leading, 0)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            offset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            // 吸附到屏幕边缘
                            withAnimation(.spring()) {
                                let screenWidth = UIScreen.main.bounds.width
                                let screenHeight = UIScreen.main.bounds.height
                                
                                // 计算最终位置
                                var finalX = offset.width
                                var finalY = offset.height
                                
                                // 限制在屏幕范围内
                                let maxX = screenWidth / 2 - 40
                                let maxY = screenHeight / 2 - 100
                                
                                finalX = max(-maxX, min(maxX, finalX))
                                finalY = max(-maxY, min(maxY, finalY))
                                
                                // 吸附到左右边缘
                                if abs(finalX) > screenWidth / 4 {
                                    finalX = finalX > 0 ? maxX : -maxX
                                } else {
                                    finalX = 0
                                }
                                
                                offset = CGSize(width: finalX, height: finalY)
                            }
                        }
                )
                .onTapGesture {
                    // 点击悬浮球，打开播放器页面
                    showPlayer = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 16)
            .padding(.bottom, 100)
            .allowsHitTesting(true)
        }
    }
}

// MARK: - 预览
struct ClassicsAudioFloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            ClassicsAudioFloatingButton(showPlayer: .constant(false))
        }
        .onAppear {
            let manager = ClassicsAudioPlayerManager.shared
            manager.currentBook = ClassicsBook(
                title: "论语",
                author: "孔子",
                category: .confucian,
                coverColors: [Color(red: 0.8, green: 0.6, blue: 0.4), Color(red: 0.6, green: 0.4, blue: 0.2)],
                introduction: nil,
                description: nil,
                hasVernacular: true,
                isProofread: true
            )
            manager.currentChapterTitle = "学而第一"
            manager.isPlaying = true
            manager.showFloatingButton = true
        }
    }
}

