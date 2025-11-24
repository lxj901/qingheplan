import SwiftUI
import PhotosUI

/// 创建专栏/合集视图
struct CreateCollectionView: View {
    @StateObject private var viewModel = CreateCollectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    let initialType: CollectionType
    
    init(type: CollectionType = .column) {
        self.initialType = type
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 类型选择
                    typeSelectionSection
                    
                    // 基本信息
                    basicInfoSection
                    
                    // 封面图
                    coverImageSection
                    
                    // 可见性设置
                    visibilitySection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("创建\(viewModel.type.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task {
                            await handleCreate()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView("创建中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }
            }
        )
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                selectedImage = image
                Task {
                    await viewModel.uploadCoverImage(image)
                }
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .onAppear {
            viewModel.type = initialType
        }
    }
    
    // MARK: - 类型选择
    private var typeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("类型")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(CollectionType.allCases, id: \.self) { type in
                    typeButton(type)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func typeButton(_ type: CollectionType) -> some View {
        Button(action: {
            viewModel.type = type
        }) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(viewModel.type == type ? .white : AppConstants.Colors.primaryGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.type == type ? AppConstants.Colors.primaryGreen : Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 基本信息
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // 标题
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("标题")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("*")
                        .foregroundColor(.red)
                    Spacer()
                    Text("\(viewModel.titleCharacterCount)/200")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.isTitleOverLimit ? .red : .secondary)
                }
                
                TextField("输入\(viewModel.type.displayName)标题", text: $viewModel.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
            }
            
            // 描述
            VStack(alignment: .leading, spacing: 8) {
                Text("描述")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("输入描述（可选）", text: $viewModel.description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
                    .lineLimit(3...6)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - 封面图
    private var coverImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("封面图")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Button(action: {
                showingImagePicker = true
            }) {
                if viewModel.isUploadingImage {
                    // 上传中
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("上传中...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else if !viewModel.coverImage.isEmpty {
                    // 已上传
                    AsyncImage(url: URL(string: viewModel.coverImage)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            placeholderImageView
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                        @unknown default:
                            placeholderImageView
                        }
                    }
                } else {
                    // 未上传
                    placeholderImageView
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var placeholderImageView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("点击上传封面图")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 可见性设置
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可见性")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(CollectionVisibility.allCases, id: \.self) { visibility in
                    visibilityButton(visibility)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func visibilityButton(_ visibility: CollectionVisibility) -> some View {
        Button(action: {
            viewModel.visibility = visibility
        }) {
            HStack(spacing: 8) {
                Image(systemName: visibility == .public ? "globe" : "lock.fill")
                    .font(.system(size: 14))
                Text(visibility.displayName)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(viewModel.visibility == visibility ? .white : AppConstants.Colors.primaryGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.visibility == visibility ? AppConstants.Colors.primaryGreen : Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    // MARK: - 处理创建
    private func handleCreate() async {
        guard viewModel.validateForm() else {
            return
        }

        let success = await viewModel.createCollection()
        if success {
            dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    CreateCollectionView(type: .column)
}
