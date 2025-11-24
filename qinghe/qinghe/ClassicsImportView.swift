import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件类型枚举
enum ImportFileType: String, CaseIterable {
    case pdf = "PDF"
    case word = "Word"
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .word:
            return "doc.text.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf:
            return Color.red
        case .word:
            return Color.blue
        }
    }
    
    var utType: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .word:
            return UTType(filenameExtension: "docx") ?? .data
        }
    }
    
    var fileExtensions: [String] {
        switch self {
        case .pdf:
            return ["pdf"]
        case .word:
            return ["docx", "doc"]
        }
    }
}

// MARK: - 导入状态枚举
enum ImportState {
    case selectingType      // 选择文件类型
    case selectingFile      // 选择文件
    case uploading(Double)  // 上传中（进度）
    case processing(Int, String) // 处理中（进度，消息）
    case success(ImportResult)   // 成功
    case failed(String)     // 失败
}

// MARK: - 书籍导入视图
struct ClassicsImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFileType: ImportFileType?
    @State private var showDocumentPicker = false
    @State private var importState: ImportState = .selectingType
    @State private var selectedFileURL: URL?
    
    // 可选的书籍信息
    @State private var bookId: String = ""
    @State private var category: String = "其他"
    @State private var author: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color(red: 0.95, green: 0.93, blue: 0.90)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题和说明
                        headerSection
                        
                        // 根据状态显示不同内容
                        switch importState {
                        case .selectingType:
                            fileTypeSelectionSection
                        case .selectingFile:
                            fileInfoSection
                        case .uploading(let progress):
                            uploadingSection(progress: progress)
                        case .processing(let progress, let message):
                            processingSection(progress: progress, message: message)
                        case .success(let result):
                            successSection(result: result)
                        case .failed(let error):
                            failedSection(error: error)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                if let fileType = selectedFileType {
                    DocumentPicker(
                        allowedContentTypes: [fileType.utType],
                        onDocumentPicked: { url in
                            selectedFileURL = url
                            importState = .selectingFile
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            
            Text("导入书籍")
                .font(AppFont.kangxi(size: 28))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            Text("支持 PDF 和 Word 格式的国学经典书籍")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 文件类型选择区域
    private var fileTypeSelectionSection: some View {
        VStack(spacing: 16) {
            Text("请选择文件格式")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            HStack(spacing: 16) {
                ForEach(ImportFileType.allCases, id: \.self) { fileType in
                    FileTypeCard(
                        fileType: fileType,
                        isSelected: selectedFileType == fileType,
                        action: {
                            selectedFileType = fileType
                            showDocumentPicker = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 文件信息区域
    private var fileInfoSection: some View {
        VStack(spacing: 20) {
            if let fileURL = selectedFileURL {
                // 文件信息卡片
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: selectedFileType?.icon ?? "doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(selectedFileType?.color ?? .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileURL.lastPathComponent)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            
                            if let fileSize = getFileSize(url: fileURL) {
                                Text(fileSize)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                }
                
                // 可选信息输入
                VStack(spacing: 16) {
                    Text("书籍信息（可选）")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        CustomTextField(placeholder: "书籍ID（留空自动生成）", text: $bookId)
                        CustomTextField(placeholder: "分类（如：儒家经典）", text: $category)
                        CustomTextField(placeholder: "作者", text: $author)
                    }
                }
                
                // 开始导入按钮
                Button(action: {
                    startImport()
                }) {
                    Text("开始导入")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.2),
                                    Color(red: 0.5, green: 0.3, blue: 0.1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                // 重新选择按钮
                Button(action: {
                    importState = .selectingType
                    selectedFileURL = nil
                    selectedFileType = nil
                }) {
                    Text("重新选择")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
        }
    }
    
    // MARK: - 上传中区域
    private func uploadingSection(progress: Double) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.6, green: 0.4, blue: 0.2)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("正在上传文件...")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
        }
        .padding(30)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - 处理中区域
    private func processingSection(progress: Int, message: String) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(progress), total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.6, green: 0.4, blue: 0.2)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                .multilineTextAlignment(.center)
            
            Text("\(progress)%")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
        }
        .padding(30)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - 成功区域
    private func successSection(result: ImportResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("导入成功！")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            VStack(spacing: 8) {
                ImportInfoRow(label: "书名", value: result.title)
                ImportInfoRow(label: "章节数", value: "\(result.chaptersCount)")
                ImportInfoRow(label: "句段数", value: "\(result.sectionsCount)")
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            
            Button(action: {
                dismiss()
            }) {
                Text("完成")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding(30)
    }

    // MARK: - 失败区域
    private func failedSection(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("导入失败")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Text(error)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)

            Button(action: {
                importState = .selectingType
                selectedFileURL = nil
                selectedFileType = nil
            }) {
                Text("重新尝试")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(30)
    }

    // MARK: - 辅助方法

    /// 获取文件大小
    private func getFileSize(url: URL) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("获取文件大小失败: \(error)")
        }
        return nil
    }

    /// 开始导入
    private func startImport() {
        guard let fileURL = selectedFileURL else {
            print("❌ 没有选择文件")
            return
        }

        // ⭐ 检查用户是否已登录
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            print("❌ 用户未登录")
            DispatchQueue.main.async {
                importState = .failed("请先登录后再导入书籍")
            }
            return
        }

        print("🚀 开始导入流程")
        Task {
            do {
                print("👤 用户ID: \(userId)")

                // 开始上传
                DispatchQueue.main.async {
                    importState = .uploading(0.0)
                }
                print("📤 状态: 上传中")

                // 执行导入
                let jobId = try await ClassicsImportService.shared.importBook(
                    fileURL: fileURL,
                    userId: userId,
                    bookId: bookId.isEmpty ? nil : bookId,
                    category: category.isEmpty ? nil : category,
                    author: author.isEmpty ? nil : author
                )
                print("✅ 获得任务ID: \(jobId)")

                // 轮询进度
                print("🔄 开始轮询导入进度...")
                let result = try await ClassicsImportService.shared.pollImportStatus(jobId: jobId) { progress, message in
                    print("📊 进度: \(Int(progress * 100))% - \(message)")
                    DispatchQueue.main.async {
                        importState = .processing(progress, message)
                    }
                }

                // 导入成功
                print("🎉 导入成功!")
                DispatchQueue.main.async {
                    importState = .success(result)
                }

            } catch {
                // 导入失败
                print("❌ 导入失败: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   错误域: \(nsError.domain)")
                    print("   错误代码: \(nsError.code)")
                    print("   错误信息: \(nsError.userInfo)")
                }
                DispatchQueue.main.async {
                    importState = .failed(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - 文件类型卡片
struct FileTypeCard: View {
    let fileType: ImportFileType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: fileType.icon)
                    .font(.system(size: 50))
                    .foregroundColor(fileType.color)

                Text(fileType.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? fileType.color : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 自定义文本框
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.8, green: 0.7, blue: 0.6), lineWidth: 1)
            )
    }
}

// MARK: - 导入信息行
struct ImportInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
        }
    }
}

// MARK: - 文档选择器
struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // 获取文件访问权限
            guard url.startAccessingSecurityScopedResource() else {
                print("无法访问文件")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // 复制文件到临时目录
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                // 如果临时文件已存在，先删除
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }

                // 复制文件
                try FileManager.default.copyItem(at: url, to: tempURL)

                onDocumentPicked(tempURL)
            } catch {
                print("复制文件失败: \(error)")
            }
        }
    }
}

// MARK: - 预览
struct ClassicsImportView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicsImportView()
    }
}

