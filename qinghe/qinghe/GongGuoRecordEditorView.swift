import SwiftUI

struct GongGuoRecordEditorView: View {
    enum Kind: String, CaseIterable { case merit = "功", demerit = "过" }

    let date: Date
    var onSave: (Kind, String, Int) -> Void = { _,_,_ in }

    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind = .merit
    @State private var selectedItem: GongGuoStandardBook.Item? = nil
    @State private var points: Int = 1
    @State private var searchText: String = ""

    private var filteredItems: [GongGuoStandardBook.Item] {
        let source = (kind == .merit) ? GongGuoStandardBook.merits : GongGuoStandardBook.demerits
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return source }
        return source.filter { $0.title.localizedStandardContains(q) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("类型")) {
                    Picker("类型", selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: kind) { _, _ in
                        selectedItem = nil
                        points = 1
                    }
                }

                Section(header: Text("从标准功过簿中选择")) {
                    TextField("搜索条目", text: $searchText)
                    ForEach(filteredItems, id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                Text((kind == .merit ? "+" : "-") + "\\(item.points)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedItem == item {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                            points = item.points
                        }
                    }
                }

                Section(header: Text("分值")) {
                    Stepper(value: $points, in: 1...9) {
                        HStack {
                            Text("分值")
                            Spacer()
                            Text("\\(points)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }

                Section(footer: Text(dateString(date)).foregroundColor(.secondary)) { EmptyView() }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let s = selectedItem {
                            onSave(kind, s.title, points)
                        }
                        dismiss()
                    }
                    .disabled(selectedItem == nil)
                }
            }
        }
    }
}

private func dateString(_ date: Date) -> String {
    let df = DateFormatter(); df.locale = Locale(identifier: "zh_CN"); df.dateFormat = "yyyy-MM-dd"; return df.string(from: date)
}

#Preview {
    GongGuoRecordEditorView(date: Date())
}

