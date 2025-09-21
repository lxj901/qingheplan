import SwiftUI

/// Twitter风格的图片网格
struct TwitterStyleImageGrid: View {
    let images: [String]
    let onImageTap: (Int) -> Void
    
    private let maxDisplayImages = 4
    private let maxHeight: CGFloat = 300 // 最大高度限制
    private let imageSpacing: CGFloat = 2
    
    var body: some View {
        let displayImages = Array(images.prefix(maxDisplayImages))
        let remainingCount = max(0, images.count - maxDisplayImages)
        
        switch displayImages.count {
        case 1:
            singleImageView(displayImages[0], index: 0)
        case 2:
            twoImagesView(displayImages)
        case 3:
            threeImagesView(displayImages)
        case 4:
            fourImagesView(displayImages, remainingCount: remainingCount)
        default:
            EmptyView()
        }
    }
    
    private func singleImageView(_ imageUrl: String, index: Int) -> some View {
        NetworkAwareAsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit) // 保持原始宽高比，完全自适应
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200) // 占位符固定高度
        }
        // 移除 maxHeight 限制，让图片完全自适应
        .clipped()
        .cornerRadius(12)
        .onTapGesture {
            onImageTap(index)
        }
    }
    
    private func twoImagesView(_ images: [String]) -> some View {
        HStack(spacing: imageSpacing) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                NetworkAwareAsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill) // 保持原始比例，填充容器
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200) // 占位符固定高度
                        .overlay(
                            ProgressView()
                                .tint(.gray)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: 250) // 设置最大高度避免过高
                .clipped()
                .clipShape(
                    .rect(
                        topLeadingRadius: index == 0 ? 12 : 0,
                        bottomLeadingRadius: index == 0 ? 12 : 0,
                        bottomTrailingRadius: index == 1 ? 12 : 0,
                        topTrailingRadius: index == 1 ? 12 : 0
                    )
                )
                .onTapGesture {
                    onImageTap(index)
                }
            }
        }
    }
    
    private func threeImagesView(_ images: [String]) -> some View {
        HStack(spacing: imageSpacing) {
            // 左侧大图 - 保持原始比例
            NetworkAwareAsyncImage(url: URL(string: images[0])) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: 250)
            .clipped()
            .clipShape(
                .rect(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .onTapGesture {
                onImageTap(0)
            }

            // 右侧两个小图垂直排列 - 保持原始比例
            VStack(spacing: imageSpacing) {
                ForEach(1..<3, id: \.self) { index in
                    NetworkAwareAsyncImage(url: URL(string: images[index])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 120)
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .clipped()
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: index == 2 ? 12 : 0,
                            topTrailingRadius: index == 1 ? 12 : 0
                        )
                    )
                    .onTapGesture {
                        onImageTap(index)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func fourImagesView(_ images: [String], remainingCount: Int) -> some View {
        VStack(spacing: imageSpacing) {
            HStack(spacing: imageSpacing) {
                ForEach(0..<2, id: \.self) { index in
                    imageCellWithCorners(images[index], index: index, position: .topRow)
                }
            }

            HStack(spacing: imageSpacing) {
                imageCellWithCorners(images[2], index: 2, position: .bottomLeft)

                ZStack {
                    imageCellWithCorners(images[3], index: 3, position: .bottomRight)

                    if remainingCount > 0 {
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                Text("+\(remainingCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 12,
                                    topTrailingRadius: 0
                                )
                            )
                            .onTapGesture {
                                onImageTap(3)
                            }
                    }
                }
            }
        }
    }
    
    private func imageCell(_ imageUrl: String, index: Int) -> some View {
        NetworkAwareAsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(1.0, contentMode: .fill) // 正方形比例
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1.0, contentMode: .fit) // 占位符也是正方形
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(12)
        .onTapGesture {
            onImageTap(index)
        }
    }

    // 四张图片网格的位置枚举
    private enum GridPosition {
        case topRow, bottomLeft, bottomRight
    }

    private func imageCellWithCorners(_ imageUrl: String, index: Int, position: GridPosition) -> some View {
        NetworkAwareAsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill) // 保持原始比例，填充容器
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120) // 占位符固定高度
        }
        .frame(maxWidth: .infinity, maxHeight: 120) // 设置最大高度
        .clipped()
        .clipShape(
            .rect(
                topLeadingRadius: (position == .topRow && index == 0) ? 12 : 0,
                bottomLeadingRadius: position == .bottomLeft ? 12 : 0,
                bottomTrailingRadius: position == .bottomRight ? 12 : 0,
                topTrailingRadius: (position == .topRow && index == 1) ? 12 : 0
            )
        )
        .onTapGesture {
            onImageTap(index)
        }
    }
}

#Preview {
    TwitterStyleImageGrid(
        images: [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg",
            "https://example.com/image4.jpg"
        ],
        onImageTap: { index in
            print("Tapped image at index: \(index)")
        }
    )
    .padding()
}
