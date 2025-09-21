import SwiftUI

enum TemptationType: String, CaseIterable {
    case smoking = "抽烟"
    case drinking = "喝酒"
    case stayingUp = "熬夜"
    case phoneScrolling = "刷手机"
    case junkFood = "垃圾食品"
    case shopping = "购物"
    case gaming = "游戏"
    case socialMedia = "社交媒体"
}

enum ResistanceResult: String, CaseIterable {
    case resisted = "已抵抗住"
    case failed = "未抵抗住"
}

struct EditTemptationView: View {
    let temptation: TemptationNew
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditTemptationViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    // 诱惑类型选择
                    Picker("诱惑类型", selection: $viewModel.selectedType) {
                        ForEach(TemptationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                    
                    // 强度滑块
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("诱惑强度")
                            Spacer()
                            Text("\(viewModel.intensity)/10")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(viewModel.intensity) },
                            set: { viewModel.intensity = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                    
                    // 抵抗结果
                    Picker("抵抗结果", selection: $viewModel.result) {
                        ForEach(ResistanceResult.allCases, id: \.self) { result in
                            Text(result.rawValue).tag(result.rawValue)
                        }
                    }
                }
                
                Section("抵抗策略") {
                    TextField("使用的抵抗策略", text: $viewModel.strategy, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("备注") {
                    TextField("记录当时的情况和想法", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑诱惑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            let success = await viewModel.updateTemptation(temptationId: temptation.id)
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            viewModel.loadTemptation(temptation)
        }
        .alert("保存失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
}

// MARK: - EditTemptationViewModel

@MainActor
class EditTemptationViewModel: ObservableObject {
    @Published var selectedType: String = ""
    @Published var intensity: Int = 5
    @Published var result: String = ""
    @Published var strategy: String = ""
    @Published var note: String = ""
    
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    private let temptationService = TemptationService.shared
    
    func loadTemptation(_ temptation: TemptationNew) {
        selectedType = temptation.type
        intensity = temptation.intensity
        result = temptation.resisted ? "已抵抗住" : "未抵抗住"
        strategy = temptation.strategy ?? ""
        note = temptation.note ?? ""
    }
    
    func updateTemptation(temptationId: Int) async -> Bool {
        isLoading = true
        
        do {
            let _ = try await temptationService.updateTemptation(
                temptationId: temptationId,
                type: selectedType,
                intensity: intensity,
                result: result,
                note: note.isEmpty ? nil : note,
                strategies: strategy.isEmpty ? nil : [strategy]
            )
            isLoading = false
            return true
        } catch {
            showErrorMessage("更新失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - 枚举定义
// TemptationType 已在 Temptation.swift 中定义，这里删除重复定义

