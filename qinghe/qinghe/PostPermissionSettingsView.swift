import SwiftUI

struct PostPermissionSettingsView: View {
    @Binding var allowComments: Bool
    @Binding var allowShares: Bool
    @Binding var visibility: PrivacyOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 可见性设置
                Section {
                    ForEach(PrivacyOption.allCases, id: \.self) { option in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: option.iconName)
                                        .foregroundColor(option.iconColor)
                                        .frame(width: 20)
                                    
                                    Text(option.title)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(option.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if visibility == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            visibility = option
                        }
                    }
                } header: {
                    Text("可见性")
                } footer: {
                    Text("选择谁可以看到这条帖子")
                }
                
                // 互动权限设置
                Section {
                    PermissionToggleRow(
                        title: "允许评论",
                        subtitle: "其他用户可以对这条帖子进行评论",
                        icon: "bubble.left",
                        isEnabled: $allowComments
                    )
                    
                    PermissionToggleRow(
                        title: "允许分享",
                        subtitle: "其他用户可以分享这条帖子",
                        icon: "square.and.arrow.up",
                        isEnabled: $allowShares
                    )
                } header: {
                    Text("互动权限")
                } footer: {
                    Text("控制其他用户与这条帖子的互动方式")
                }
                
                // 权限说明
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("权限说明")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PermissionExplanationRow(
                                icon: "eye",
                                title: "可见性",
                                description: "决定谁可以看到你的帖子内容"
                            )
                            
                            PermissionExplanationRow(
                                icon: "bubble.left",
                                title: "评论权限",
                                description: "控制是否允许其他用户评论"
                            )
                            
                            PermissionExplanationRow(
                                icon: "square.and.arrow.up",
                                title: "分享权限",
                                description: "控制是否允许其他用户分享到其他平台"
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("帖子权限")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PermissionExplanationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 16)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}



#Preview {
    PostPermissionSettingsView(
        allowComments: .constant(true),
        allowShares: .constant(true),
        visibility: .constant(.public)
    )
}
