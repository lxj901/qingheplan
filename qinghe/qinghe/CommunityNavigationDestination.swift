import SwiftUI

// MARK: - 社区导航目标枚举
enum CommunityNavigationDestination: Hashable {
    case postDetail(String)
    case userProfile(String)
    case tagDetail(String)
}

// MARK: - 滑动返回手势修饰符
struct SwipeBackGestureModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var initialDragLocation: CGPoint = .zero

    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .global)
                    .onChanged { value in
                        // 记录初始拖拽位置
                        if !isDragging {
                            initialDragLocation = value.startLocation
                        }

                        // 更严格的边缘检测：必须从屏幕最左边15像素内开始，且主要是水平向右滑动
                        let isFromLeftEdge = initialDragLocation.x < 15
                        let isHorizontalSwipe = abs(value.translation.width) > abs(value.translation.height) * 3
                        let isRightwardSwipe = value.translation.width > 0
                        let hasMinimumDistance = value.translation.width > 15

                        if isFromLeftEdge && isHorizontalSwipe && isRightwardSwipe && hasMinimumDistance {
                            isDragging = true
                            dragOffset = min(value.translation.width, UIScreen.main.bounds.width * 0.25)
                        }
                    }
                    .onEnded { value in
                        if isDragging {
                            let threshold: CGFloat = 100 // 适中的阈值，避免误触
                            let velocity = value.velocity.width
                            let isFromLeftEdge = initialDragLocation.x < 15
                            let isHorizontalSwipe = abs(value.translation.width) > abs(value.translation.height) * 3

                            // 更严格的触发条件
                            if isFromLeftEdge && isHorizontalSwipe && (value.translation.width > threshold || velocity > 600) {
                                // 触发返回
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = UIScreen.main.bounds.width
                                }

                                // 延迟执行dismiss，让动画完成
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            } else {
                                // 回弹到原位
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }

                        // 重置状态
                        isDragging = false
                        initialDragLocation = .zero
                    }
            )
            .background(
                // 添加阴影效果
                Color.black
                    .opacity(isDragging ? 0.05 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
            )
    }
}

// MARK: - 导航路径管理器
@MainActor
class CommunityNavigationManager: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    func navigateToPost(_ postId: String) {
        navigationPath.append(CommunityNavigationDestination.postDetail(postId))
    }
    
    func navigateToUserProfile(_ userId: String) {
        navigationPath.append(CommunityNavigationDestination.userProfile(userId))
    }
    
    func navigateToTag(_ tagName: String) {
        navigationPath.append(CommunityNavigationDestination.tagDetail(tagName))
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func popLast() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}
