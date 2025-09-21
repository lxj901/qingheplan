import SwiftUI

/// 图片查看器弹窗
struct ImageViewerSheet: View {
    let images: [String]?
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let images = images, !images.isEmpty {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                                .tint(.white)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .offset(y: dragOffset.height)
                .scaleEffect(1 - abs(dragOffset.height) / 1000.0)
                .opacity(1 - abs(dragOffset.height) / 500.0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            if abs(value.translation.height) > 150 {
                                dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            } else {
                Text("无图片")
                    .foregroundColor(.white)
            }
            
            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ImageViewerSheet(
        images: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
        selectedIndex: .constant(0)
    )
}
