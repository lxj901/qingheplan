import SwiftUI

// MARK: - OCR 图片预览视图
struct OCRImagePreviewView: View {
    let images: [UIImage]
    let onConfirm: ([UIImage]) -> Void
    let onRetake: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 图片预览区域
                    TabView(selection: $currentIndex) {
                        ForEach(images.indices, id: \.self) { index in
                            ImagePreviewCard(image: images[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(maxHeight: .infinity)
                    
                    // 底部操作栏
                    bottomActionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        onRetake()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("重拍")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: 编辑功能
                    }) {
                        Text("编辑")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
        }
    }
    
    // MARK: - 底部操作栏
    private var bottomActionBar: some View {
        VStack(spacing: 16) {
            // 图片缩略图列表
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            ThumbnailView(
                                image: images[index],
                                isSelected: index == currentIndex,
                                action: {
                                    currentIndex = index
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 80)
            }
            
            // 操作按钮
            HStack(spacing: 20) {
                // 继续拍摄
                Button(action: {
                    dismiss()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("继续拍摄")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 开始识别
                Button(action: {
                    dismiss()
                    onConfirm(images)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Text("开始识别")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - 图片预览卡片
struct ImagePreviewCard: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            // 限制缩放范围
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            } else if scale > 5.0 {
                                withAnimation {
                                    scale = 5.0
                                    lastScale = 5.0
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    // 双击重置
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
        }
    }
}

// MARK: - 缩略图视图
struct ThumbnailView: View {
    let image: UIImage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
        }
    }
}

// MARK: - 预览
#Preview {
    OCRImagePreviewView(
        images: [UIImage(systemName: "photo")!],
        onConfirm: { _ in },
        onRetake: {}
    )
}

