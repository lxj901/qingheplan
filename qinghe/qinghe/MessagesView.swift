import SwiftUI

// MARK: - 多语言管理器
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "zh-Hans"

    init() {
        // 从 UserDefaults 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = savedLanguage
        }
    }

    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
        objectWillChange.send()
    }

    func localizedString(key: String) -> String {
        return LocalizedStrings.getString(key: key, language: currentLanguage)
    }
}

// MARK: - 本地化字符串
struct LocalizedStrings {
    static func getString(key: String, language: String) -> String {
        switch language {
        case "zh-Hans":
            return getChineseSimplified(key: key)
        case "zh-Hant":
            return getChineseTraditional(key: key)
        case "en":
            return getEnglish(key: key)
        case "ja":
            return getJapanese(key: key)
        case "ko":
            return getKorean(key: key)
        default:
            return getChineseSimplified(key: key)
        }
    }

    // 简体中文
    private static func getChineseSimplified(key: String) -> String {
        switch key {
        case "settings": return "设置"
        case "account_security": return "账户与安全"
        case "account_and_security": return "账号与安全"
        case "privacy_settings": return "隐私设置"
        case "personalization": return "个性化"
        case "background_settings": return "背景设置"
        case "font_size": return "字体大小"
        case "multi_language": return "多语言"
        case "storage_permissions": return "存储与权限"
        case "clear_cache": return "清理缓存"
        case "system_permissions": return "系统权限"
        case "app_permissions": return "应用权限"
        case "about_help": return "关于与帮助"
        case "about_qinghe": return "关于青禾计划"
        case "ad_info": return "了解广告推送"
        case "feedback_help": return "反馈与帮助"
        case "rules_agreements": return "规则与协议"
        case "rules_center": return "青禾规则中心"
        case "qualifications": return "资质证照"
        case "user_agreement": return "用户协议"
        case "privacy_info": return "隐私信息"
        case "personal_info_list": return "个人信息收集清单"
        case "third_party_info_list": return "第三方信息共享清单"
        case "logout": return "退出登录"
        case "loading": return "加载中..."
        case "getting_user_info": return "正在获取用户信息"
        case "not_logged_in": return "未登录"
        case "please_login": return "请先登录"
        case "unbound_phone": return "未绑定手机"
        case "qinghe_user": return "青禾用户"
        default: return key
        }
    }

    // 繁体中文
    private static func getChineseTraditional(key: String) -> String {
        switch key {
        case "settings": return "設置"
        case "account_security": return "賬戶與安全"
        case "account_and_security": return "賬號與安全"
        case "privacy_settings": return "隱私設置"
        case "personalization": return "個性化"
        case "background_settings": return "背景設置"
        case "font_size": return "字體大小"
        case "multi_language": return "多語言"
        case "storage_permissions": return "存儲與權限"
        case "clear_cache": return "清理緩存"
        case "system_permissions": return "系統權限"
        case "app_permissions": return "應用權限"
        case "about_help": return "關於與幫助"
        case "about_qinghe": return "關於青禾計劃"
        case "ad_info": return "了解廣告推送"
        case "feedback_help": return "反饋與幫助"
        case "rules_agreements": return "規則與協議"
        case "rules_center": return "青禾規則中心"
        case "qualifications": return "資質證照"
        case "user_agreement": return "用戶協議"
        case "privacy_info": return "隱私信息"
        case "personal_info_list": return "個人信息收集清單"
        case "third_party_info_list": return "第三方信息共享清單"
        case "logout": return "退出登錄"
        case "loading": return "加載中..."
        case "getting_user_info": return "正在獲取用戶信息"
        case "not_logged_in": return "未登錄"
        case "please_login": return "請先登錄"
        case "unbound_phone": return "未綁定手機"
        case "qinghe_user": return "青禾用戶"
        default: return key
        }
    }

    // 英文
    private static func getEnglish(key: String) -> String {
        switch key {
        case "settings": return "Settings"
        case "account_security": return "Account & Security"
        case "account_and_security": return "Account & Security"
        case "privacy_settings": return "Privacy Settings"
        case "personalization": return "Personalization"
        case "background_settings": return "Background Settings"
        case "font_size": return "Font Size"
        case "multi_language": return "Language"
        case "storage_permissions": return "Storage & Permissions"
        case "clear_cache": return "Clear Cache"
        case "system_permissions": return "System Permissions"
        case "app_permissions": return "App Permissions"
        case "about_help": return "About & Help"
        case "about_qinghe": return "About Qinghe Plan"
        case "ad_info": return "About Ads"
        case "feedback_help": return "Feedback & Help"
        case "rules_agreements": return "Rules & Agreements"
        case "rules_center": return "Rules Center"
        case "qualifications": return "Qualifications"
        case "user_agreement": return "User Agreement"
        case "privacy_info": return "Privacy Information"
        case "personal_info_list": return "Personal Information Collection"
        case "third_party_info_list": return "Third-party Information Sharing"
        case "logout": return "Logout"
        case "loading": return "Loading..."
        case "getting_user_info": return "Getting user information"
        case "not_logged_in": return "Not logged in"
        case "please_login": return "Please log in first"
        case "unbound_phone": return "Phone not bound"
        case "qinghe_user": return "Qinghe User"
        default: return key
        }
    }

    // 日文
    private static func getJapanese(key: String) -> String {
        switch key {
        case "settings": return "設定"
        case "account_security": return "アカウントとセキュリティ"
        case "account_and_security": return "アカウントとセキュリティ"
        case "privacy_settings": return "プライバシー設定"
        case "personalization": return "パーソナライゼーション"
        case "background_settings": return "背景設定"
        case "font_size": return "フォントサイズ"
        case "multi_language": return "言語"
        case "storage_permissions": return "ストレージと権限"
        case "clear_cache": return "キャッシュクリア"
        case "system_permissions": return "システム権限"
        case "app_permissions": return "アプリ権限"
        case "about_help": return "アプリについて・ヘルプ"
        case "about_qinghe": return "青禾計画について"
        case "ad_info": return "広告について"
        case "feedback_help": return "フィードバック・ヘルプ"
        case "rules_agreements": return "ルールと規約"
        case "rules_center": return "ルールセンター"
        case "qualifications": return "資格証明"
        case "user_agreement": return "利用規約"
        case "privacy_info": return "プライバシー情報"
        case "personal_info_list": return "個人情報収集リスト"
        case "third_party_info_list": return "第三者情報共有リスト"
        case "logout": return "ログアウト"
        case "loading": return "読み込み中..."
        case "getting_user_info": return "ユーザー情報を取得中"
        case "not_logged_in": return "ログインしていません"
        case "please_login": return "まずログインしてください"
        case "unbound_phone": return "電話番号が未登録"
        case "qinghe_user": return "青禾ユーザー"
        default: return key
        }
    }

    // 韩文
    private static func getKorean(key: String) -> String {
        switch key {
        case "settings": return "설정"
        case "account_security": return "계정 및 보안"
        case "account_and_security": return "계정 및 보안"
        case "privacy_settings": return "개인정보 설정"
        case "personalization": return "개인화"
        case "background_settings": return "배경 설정"
        case "font_size": return "글꼴 크기"
        case "multi_language": return "언어"
        case "storage_permissions": return "저장소 및 권한"
        case "clear_cache": return "캐시 지우기"
        case "system_permissions": return "시스템 권한"
        case "app_permissions": return "앱 권한"
        case "about_help": return "정보 및 도움말"
        case "about_qinghe": return "청허 계획 정보"
        case "ad_info": return "광고 정보"
        case "feedback_help": return "피드백 및 도움말"
        case "rules_agreements": return "규칙 및 약관"
        case "rules_center": return "규칙 센터"
        case "qualifications": return "자격증명"
        case "user_agreement": return "사용자 약관"
        case "privacy_info": return "개인정보"
        case "personal_info_list": return "개인정보 수집 목록"
        case "third_party_info_list": return "제3자 정보 공유 목록"
        case "logout": return "로그아웃"
        case "loading": return "로딩 중..."
        case "getting_user_info": return "사용자 정보를 가져오는 중"
        case "not_logged_in": return "로그인하지 않음"
        case "please_login": return "먼저 로그인하세요"
        case "unbound_phone": return "전화번호 미등록"
        case "qinghe_user": return "청허 사용자"
        default: return key
        }
    }
}

// MARK: - 设置页面导航目标
enum SettingsDestination: Hashable {
    case accountSecurity
    case passwordSettings
    case accountDeletion
    case privacySettings
    case backgroundSettings
    case fontSizeSettings
    case languageSettings
    case clearCache
    case systemPermissions
    case appPermissions
    case aboutApp
    case adInfo
    case feedbackHelp
    case rulesCenter
    case qualifications
    case userAgreement
    case personalInfoList
    case thirdPartyInfoList
}

// MARK: - 消息页面
struct MessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatListViewModel()
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var selectedConversation: ChatConversation?
    @State private var navigationToConversationId: String? = nil // 推送通知导航
    @State private var showingPlusMenu = false // 加号菜单弹窗
    @State private var showingNewChat = false // 显示新建聊天页面
    @State private var openActionConversationId: String? = nil // 当前打开操作按钮的会话ID

    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager

    var body: some View {
        NavigationStack {
            ZStack {
                // 主要内容
                VStack(spacing: 0) {
                    // 顶部导航栏
                    topNavigationBar

                    // 通知入口区域
                    notificationEntrySection

                    // 聊天列表
                    chatListContent
                }
                .background(ModernDesignSystem.Colors.backgroundPrimary)
                .navigationBarHidden(true)

                // 加号菜单弹窗
                if showingPlusMenu {
                    ZStack {
                        // 透明背景遮罩，点击关闭弹窗
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingPlusMenu = false
                            }

                        // 弹窗内容
                        VStack {
                            HStack {
                                Spacer()
                                plusMenuPopover
                                    .padding(.trailing, ModernDesignSystem.Spacing.md)
                                    .padding(.top, 50) // 调整弹窗位置，更靠上
                                    .onTapGesture {
                                        // 阻止点击事件传递到背景
                                    }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshConversations()
            }
            .onAppear {
                Task {
                    await viewModel.loadConversations()
                }
                // 加载通知数据（使用防抖机制，避免频繁请求）
                notificationManager.refreshNotifications()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
                // 处理推送通知导航到对话
                if let conversationId = notification.object as? String {
                    navigationToConversationId = conversationId
                }
            }
            .navigationDestination(isPresented: .constant(navigationToConversationId != nil)) {
                if let conversationId = navigationToConversationId,
                   let conversation = viewModel.conversations.first(where: { $0.id == conversationId }) {
                    ChatDetailView(conversation: conversation)
                        .onDisappear {
                            navigationToConversationId = nil
                        }
                } else {
                    // 如果找不到对话，显示错误页面或返回
                    Text("对话不存在")
                        .onAppear {
                            navigationToConversationId = nil
                        }
                }
            }
            .navigationDestination(isPresented: $showingNewChat) {
                NewChatView()
                    .asSubView() // 隐藏底部Tab栏
            }
        }
        // MARK: - 错误处理
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        // MARK: - 跨页面导航通知监听
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToUserProfile"))) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                print("🔍 MessagesView 收到用户详情导航通知，用户ID: \(userId)")
                // 在Tab架构下，可以通过通知或其他方式处理跨Tab导航
                // 这里暂时保留日志，具体实现可以后续优化
                print("🔍 MessagesView: 需要导航到用户详情页面，用户ID: \(userId)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToChat"))) { notification in
            if let userId = notification.userInfo?["userId"] as? Int {
                print("🔍 MessagesView 收到聊天导航通知，用户ID: \(userId)")
                // 这里可以添加导航到特定聊天的逻辑
                // 例如：找到对应的对话并导航到聊天详情页面
                print("🔍 MessagesView: 需要导航到聊天页面，用户ID: \(userId)")
            }
        }
        .asRootView()
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            ZStack {
                // 居中的标题
                Text("消息")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(.primary)

                // 右侧按钮
                HStack {
                    Spacer()
                    Button(action: {
                        showingPlusMenu = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }

    // MARK: - 通知入口区域
    private var notificationEntrySection: some View {
        VStack(spacing: 12) {
            // 通知入口卡片
            NavigationLink(destination: NotificationListView()) {
                NotificationEntryCardView(unreadCount: notificationManager.unreadCount)
                    .environmentObject(notificationManager)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 加号菜单弹窗
    private var plusMenuPopover: some View {
        VStack(spacing: 0) {
            // 发起群聊
            PlusMenuItemView(
                icon: "message.fill",
                title: "发起群聊"
            ) {
                showingPlusMenu = false
                showingNewChat = true
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .frame(width: 160)
    }

    // MARK: - 聊天列表内容
    private var chatListContent: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                loadingView
            } else if viewModel.conversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("加载中...")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        ChatEmptyStateView(type: .noChats)
    }

    // MARK: - 会话列表
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                        ChatListItemView(
                            conversation: conversation,
                            onTap: nil,
                            onDelete: {
                                Task {
                                    await viewModel.deleteConversation(conversationId: conversation.id)
                                }
                            },
                            isActionOpen: openActionConversationId == conversation.id,
                            onActionStateChanged: { isOpen in
                                openActionConversationId = isOpen ? conversation.id : nil
                            }
                        )
                        .background(ModernDesignSystem.Colors.backgroundCard)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 分隔线
                    if conversation.id != viewModel.conversations.last?.id {
                        Divider()
                            .padding(.leading, 68) // 对齐内容区域
                    }
                }

                // 加载更多
                if viewModel.hasMoreConversations && !viewModel.isLoading {
                    Button("加载更多") {
                        Task {
                            await viewModel.loadMoreConversations()
                        }
                    }
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .padding()
                }

                if viewModel.isLoading && !viewModel.conversations.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                // 点击空白区域关闭所有操作按钮
                if openActionConversationId != nil {
                    openActionConversationId = nil
                }
            }
        )
    }


}

// MARK: - 会员中心页面
struct MembershipView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.yellow)
                    
                    Text("会员中心")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("此功能正在开发中...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("会员中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var localizationManager = LocalizationManager()
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = false

    // 导航状态
    @State private var showingAccountSecurity = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 设置列表
                List {
                // 账户信息区域
                Section {
                    if isLoadingProfile {
                        // 加载状态
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localizedString(key: "loading"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(localizationManager.localizedString(key: "getting_user_info"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let profile = userProfile {
                        // 显示完整用户资料
                        HStack {
                            // 用户真实头像
                            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String(profile.nickname.prefix(1)))
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(profile.nickname)
                                        .font(.system(size: 16, weight: .medium))

                                    if profile.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blue)
                                    }
                                }

                                if let authUser = authManager.currentUser {
                                    Text(authUser.phone ?? localizationManager.localizedString(key: "unbound_phone"))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let user = authManager.currentUser {
                        // 降级显示基本用户信息
                        HStack {
                            // 用户真实头像
                            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String((user.nickname ?? "青禾用户").prefix(1)))
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickname ?? localizationManager.localizedString(key: "qinghe_user"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(user.phone ?? localizationManager.localizedString(key: "unbound_phone"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        // 未登录状态
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localizedString(key: "not_logged_in"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(localizationManager.localizedString(key: "please_login"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }

                // 账户与安全
                Section(localizationManager.localizedString(key: "account_security")) {
                    settingRow(icon: "shield.lefthalf.filled", iconColor: .blue, title: localizationManager.localizedString(key: "account_and_security"))
                    settingRow(icon: "lock.fill", iconColor: .orange, title: localizationManager.localizedString(key: "privacy_settings"))
                }

                // 个性化设置
                Section(localizationManager.localizedString(key: "personalization")) {
                    settingRow(icon: "photo.fill", iconColor: .green, title: localizationManager.localizedString(key: "background_settings"))
                    settingRow(icon: "textformat.size", iconColor: .purple, title: localizationManager.localizedString(key: "font_size"))
                    settingRow(icon: "globe", iconColor: .blue, title: localizationManager.localizedString(key: "multi_language"))
                }

                // 存储与权限
                Section(localizationManager.localizedString(key: "storage_permissions")) {
                    settingRow(icon: "trash.fill", iconColor: .red, title: localizationManager.localizedString(key: "clear_cache"))
                    settingRow(icon: "gear.badge", iconColor: .gray, title: localizationManager.localizedString(key: "system_permissions"))
                    settingRow(icon: "checkmark.shield.fill", iconColor: .green, title: localizationManager.localizedString(key: "app_permissions"))
                }

                // 关于与帮助
                Section(localizationManager.localizedString(key: "about_help")) {
                    settingRow(icon: "info.circle.fill", iconColor: .blue, title: localizationManager.localizedString(key: "about_qinghe"), subtitle: "v1.0.1")
                    settingRow(icon: "megaphone.fill", iconColor: .orange, title: localizationManager.localizedString(key: "ad_info"))
                    settingRow(icon: "questionmark.circle.fill", iconColor: .green, title: localizationManager.localizedString(key: "feedback_help"))
                }

                // 规则与协议
                Section(localizationManager.localizedString(key: "rules_agreements")) {
                    settingRow(icon: "doc.text.fill", iconColor: .blue, title: localizationManager.localizedString(key: "rules_center"))
                    settingRow(icon: "building.2.fill", iconColor: .gray, title: localizationManager.localizedString(key: "qualifications"))
                    settingRow(icon: "doc.plaintext.fill", iconColor: .blue, title: localizationManager.localizedString(key: "user_agreement"))
                }

                // 隐私信息
                Section(localizationManager.localizedString(key: "privacy_info")) {
                    settingRow(icon: "person.badge.shield.checkmark.fill", iconColor: .green, title: localizationManager.localizedString(key: "personal_info_list"))
                    settingRow(icon: "arrow.triangle.2.circlepath", iconColor: .orange, title: localizationManager.localizedString(key: "third_party_info_list"))
                }

                // 退出登录
                Section {
                    Button(action: {
                        authManager.logout()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text(localizationManager.localizedString(key: "logout"))
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onAppear {
                print("🧭 SettingsView onAppear - navigationPath.count = \(navigationPath.count)")
                loadUserProfile()
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                Group {
                    switch destination {
                    case .accountSecurity:
                        AccountSecurityView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView() // 标记为子页面，隐藏Tab栏
                            .onAppear {
                                print("🔍 设置页面：导航到账号与安全页面")
                            }
                    case .passwordSettings:
                        PasswordSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                            .onAppear {
                                print("🔍 设置页面：导航到密码设置页面")
                            }
                    case .accountDeletion:
                        AccountDeletionView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                            .onAppear {
                                print("🔍 设置页面：导航到注销账号页面")
                            }
                    case .privacySettings:
                        PrivacySettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .backgroundSettings:
                        BackgroundSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .fontSizeSettings:
                        FontSizeSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .languageSettings:
                        LanguageSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .clearCache:
                        ClearCacheView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .systemPermissions:
                        SystemPermissionsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .appPermissions:
                        AppPermissionsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .aboutApp:
                        AboutAppView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .adInfo:
                        AdInfoView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .feedbackHelp:
                        FeedbackHelpView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .rulesCenter:
                        RulesCenterView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .qualifications:
                        QualificationsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .userAgreement:
                        UserAgreementView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .personalInfoList:
                        PersonalInfoListView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .thirdPartyInfoList:
                        ThirdPartyInfoListView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    }
                }
                .onAppear {
                    print("🔍 设置页面：navigationDestination 被触发，目标: \(destination)")
                }
            }
        }
    }
    }

    // MARK: - 加载用户资料
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            print("⚠️ 设置页面：用户未登录")
            return
        }

        isLoadingProfile = true

        Task {
            do {
                let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                await MainActor.run {
                    isLoadingProfile = false
                    if response.success, let profile = response.data {
                        userProfile = profile
                        print("✅ 设置页面：用户资料加载成功")
                        print("  - 昵称: \(profile.nickname)")
                        print("  - 头像: \(profile.avatar ?? "无")")
                        print("  - 认证状态: \(profile.isVerified ?? false)")
                    } else {
                        print("❌ 设置页面：用户资料加载失败 - \(response.message ?? "未知错误")")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    print("❌ 设置页面：用户资料加载异常 - \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 处理设置项点击
    private func handleSettingItemTap(title: String) {
        // 通过比较本地化字符串来确定点击的是哪个设置项
        let accountAndSecurity = localizationManager.localizedString(key: "account_and_security")
        let privacySettings = localizationManager.localizedString(key: "privacy_settings")
        let backgroundSettings = localizationManager.localizedString(key: "background_settings")
        let fontSize = localizationManager.localizedString(key: "font_size")
        let multiLanguage = localizationManager.localizedString(key: "multi_language")
        let clearCache = localizationManager.localizedString(key: "clear_cache")
        let systemPermissions = localizationManager.localizedString(key: "system_permissions")
        let appPermissions = localizationManager.localizedString(key: "app_permissions")
        let aboutQinghe = localizationManager.localizedString(key: "about_qinghe")
        let adInfo = localizationManager.localizedString(key: "ad_info")
        let feedbackHelp = localizationManager.localizedString(key: "feedback_help")
        let rulesCenter = localizationManager.localizedString(key: "rules_center")
        let qualifications = localizationManager.localizedString(key: "qualifications")
        let userAgreement = localizationManager.localizedString(key: "user_agreement")
        let personalInfoList = localizationManager.localizedString(key: "personal_info_list")
        let thirdPartyInfoList = localizationManager.localizedString(key: "third_party_info_list")

        switch title {
        case accountAndSecurity:
            print("🔍 设置页面：点击账号与安全")
            navigationPath.append(SettingsDestination.accountSecurity)
        case privacySettings:
            print("🔍 设置页面：点击隐私设置")
            navigationPath.append(SettingsDestination.privacySettings)
        case backgroundSettings:
            print("🔍 设置页面：点击背景设置")
            navigationPath.append(SettingsDestination.backgroundSettings)
        case fontSize:
            print("🔍 设置页面：点击字体大小")
            navigationPath.append(SettingsDestination.fontSizeSettings)
        case multiLanguage:
            print("🔍 设置页面：点击多语言")
            navigationPath.append(SettingsDestination.languageSettings)
        case clearCache:
            print("🔍 设置页面：点击清理缓存")
            navigationPath.append(SettingsDestination.clearCache)
        case systemPermissions:
            print("🔍 设置页面：点击系统权限")
            navigationPath.append(SettingsDestination.systemPermissions)
        case appPermissions:
            print("🔍 设置页面：点击应用权限")
            navigationPath.append(SettingsDestination.appPermissions)
        case aboutQinghe:
            print("🔍 设置页面：点击关于青禾计划")
            navigationPath.append(SettingsDestination.aboutApp)
        case adInfo:
            print("🔍 设置页面：点击了解广告推送")
            navigationPath.append(SettingsDestination.adInfo)
        case feedbackHelp:
            print("🔍 设置页面：点击反馈与帮助")
            navigationPath.append(SettingsDestination.feedbackHelp)
        case rulesCenter:
            print("🔍 设置页面：点击青禾规则中心")
            navigationPath.append(SettingsDestination.rulesCenter)
        case qualifications:
            print("🔍 设置页面：点击资质证照")
            navigationPath.append(SettingsDestination.qualifications)
        case userAgreement:
            print("🔍 设置页面：点击用户协议")
            navigationPath.append(SettingsDestination.userAgreement)
        case personalInfoList:
            print("🔍 设置页面：点击个人信息收集清单")
            navigationPath.append(SettingsDestination.personalInfoList)
        case thirdPartyInfoList:
            print("🔍 设置页面：点击第三方信息共享清单")
            navigationPath.append(SettingsDestination.thirdPartyInfoList)
        default:
            print("点击了设置项: \(title)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮（优先回退导航栈）
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 页面标题
            Text(localizationManager.localizedString(key: "settings"))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 占位符，保持标题居中
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 设置行组件
    private func settingRow(icon: String, iconColor: Color, title: String, subtitle: String? = nil) -> some View {
        Button(action: {
            handleSettingItemTap(title: title)
        }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                // 标题
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                // 副标题（如果有）
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 账号与安全页面
struct AccountSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = false
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 设置列表
            List {
                // 账户信息区域
                Section {
                    if let profile = userProfile {
                        accountInfoRow(profile: profile)
                    } else if let user = authManager.currentUser {
                        basicAccountInfoRow(user: user)
                    }
                }

                // 安全设置
                Section("安全设置") {
                    // 密码设置
                    Button(action: {
                        print("🔍 账号与安全页面：点击密码设置")
                        navigationPath.append(SettingsDestination.passwordSettings)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("密码设置")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(getPasswordSubtitle())
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 危险操作
                Section("账户管理") {
                    Button(action: {
                        print("🔍 账号与安全页面：点击注销账号")
                        navigationPath.append(SettingsDestination.accountDeletion)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)

                            Text("注销账号")
                                .font(.system(size: 16))
                                .foregroundColor(.red)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            print("🧭 AccountSecurityView onAppear - navigationPath.count = \(navigationPath.count)")
            loadUserProfile()
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 页面标题
            Text("账号与安全")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 占位符，保持标题居中
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 账户信息行
    private func accountInfoRow(profile: UserProfile) -> some View {
        HStack {
            // 用户头像
            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(profile.nickname.prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.nickname)
                        .font(.system(size: 16, weight: .medium))

                    if profile.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }

                Text("ID: \(profile.displayUsername)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - 基本账户信息行
    private func basicAccountInfoRow(user: AuthUser) -> some View {
        HStack {
            // 用户头像
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String((user.nickname ?? "青禾用户").prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname ?? "青禾用户")
                    .font(.system(size: 16, weight: .medium))

                // 优先显示青禾ID，如果有userProfile的话
                if let profile = userProfile {
                    Text("ID: \(profile.displayUsername)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("ID: user\(user.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - 安全设置行
    private func securityRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        Button(action: {
            handleSecurityItemTap(title: title)
        }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                // 标题和副标题
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 处理安全设置项点击
    private func handleSecurityItemTap(title: String) {
        print("🔍 账号与安全页面：handleSecurityItemTap 被调用，title: \(title)")
        print("🔍 当前 navigationPath 计数: \(navigationPath.count)")

        switch title {
        default:
            print("🔍 点击了安全设置项: \(title)")
        }
    }

    // MARK: - 获取密码状态副标题
    private func getPasswordSubtitle() -> String {
        if let profile = userProfile {
            return (profile.hasPassword ?? false) ? "已设置" : "未设置"
        }
        return "未设置"
    }

    // MARK: - 加载用户资料
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            print("⚠️ 账号与安全页面：用户未登录")
            return
        }

        isLoadingProfile = true

        Task {
            do {
                let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                await MainActor.run {
                    isLoadingProfile = false
                    if response.success, let profile = response.data {
                        userProfile = profile
                        print("✅ 账号与安全页面：用户资料加载成功")
                    } else {
                        print("❌ 账号与安全页面：用户资料加载失败 - \(response.message ?? "未知错误")")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    print("❌ 账号与安全页面：用户资料加载异常 - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 密码设置页面
struct PasswordSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @StateObject private var authManager = AuthManager.shared
    @Binding var navigationPath: NavigationPath

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasPassword = false
    @State private var isSettingMode = true // true: 设置密码, false: 修改密码

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(spacing: 24) {
                    // 密码状态说明
                    passwordStatusSection

                    // 密码设置表单
                    passwordFormSection

                    // 提交按钮
                    submitButton

                    // 密码要求说明
                    passwordRequirementsSection

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 PasswordSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
            checkPasswordStatus()
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("密码设置")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 密码状态说明区域
    private var passwordStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("密码状态")
                .font(.system(size: 18, weight: .semibold))

            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(hasPassword ? "已设置密码" : "未设置密码")
                    .font(.system(size: 16))

                Spacer()

                Text(hasPassword ? "已设置" : "未设置")
                    .font(.system(size: 14))
                    .foregroundColor(hasPassword ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background((hasPassword ? Color.green : Color.orange).opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - 密码表单区域
    private var passwordFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isSettingMode ? "设置密码" : "修改密码")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 16) {
                // 当前密码输入（仅修改密码时显示）
                if !isSettingMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        SecureField("请输入当前密码", text: $currentPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                // 新密码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(isSettingMode ? "设置密码" : "新密码")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    SecureField(isSettingMode ? "请设置密码" : "请输入新密码", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 确认密码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("确认密码")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    SecureField("请再次输入密码", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }

    // MARK: - 提交按钮
    private var submitButton: some View {
        Button(action: submitPasswordChange) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }

                Text(isSettingMode ? "设置密码" : "修改密码")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? Color.blue : Color.gray)
            )
        }
        .disabled(!canSubmit || isLoading)
    }

    // MARK: - 密码要求说明
    private var passwordRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("密码要求")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                requirementRow(text: "长度至少8位", isValid: newPassword.count >= 8)
                requirementRow(text: "包含至少一个数字", isValid: newPassword.range(of: "\\d", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个小写字母", isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个大写字母（推荐）", isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个特殊字符（推荐）", isValid: newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func requirementRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isValid ? .primary : .secondary)

            Spacer()
        }
    }

    // MARK: - 计算属性
    private var canSubmit: Bool {
        if isSettingMode {
            return !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword && isPasswordValid
        } else {
            return !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword && isPasswordValid
        }
    }

    private var isPasswordValid: Bool {
        return newPassword.count >= 8 &&
               newPassword.range(of: "\\d", options: .regularExpression) != nil &&
               newPassword.range(of: "[a-z]", options: .regularExpression) != nil
    }

    // MARK: - 检查密码状态
    private func checkPasswordStatus() {
        // 从用户资料中检查是否已设置密码
        if let currentUser = authManager.currentUser {
            // 获取用户资料来检查密码状态
            Task {
                do {
                    let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                    await MainActor.run {
                        if response.success, let profile = response.data {
                            hasPassword = profile.hasPassword ?? false
                            isSettingMode = !hasPassword
                            print("🔍 密码设置页面：从用户资料获取密码状态 - hasPassword: \(hasPassword)")
                        } else {
                            // 如果获取失败，默认为未设置
                            hasPassword = false
                            isSettingMode = true
                            print("❌ 密码设置页面：获取用户资料失败，默认为未设置密码")
                        }
                    }
                } catch {
                    await MainActor.run {
                        hasPassword = false
                        isSettingMode = true
                        print("❌ 密码设置页面：获取用户资料出错 - \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - 提交密码更改
    private func submitPasswordChange() {
        guard canSubmit else { return }

        // 验证密码匹配
        guard newPassword == confirmPassword else {
            alertMessage = "两次输入的密码不一致"
            showingAlert = true
            return
        }

        // 验证密码强度
        guard isPasswordValid else {
            alertMessage = "密码不符合要求，请检查密码强度"
            showingAlert = true
            return
        }

        isLoading = true

        if isSettingMode {
            // 设置密码
            authService.setPassword(password: newPassword) { [self] (success: Bool, message: String) in
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = message
                    showingAlert = true

                    if success {
                        // 设置成功后更新本地状态
                        hasPassword = true
                        isSettingMode = false
                        print("✅ 密码设置成功，更新本地状态：hasPassword = true")

                        // 设置成功后返回上一页
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if navigationPath.count > 0 {
                                navigationPath.removeLast()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
            }
        } else {
            // 修改密码
            authService.changePassword(oldPassword: currentPassword, newPassword: newPassword) { [self] (success: Bool, message: String) in
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = message
                    showingAlert = true

                    if success {
                        // 修改成功后返回上一页
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if navigationPath.count > 0 {
                                navigationPath.removeLast()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}








// MARK: - 注销账号页面
struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var authService = AuthService.shared
    @Binding var navigationPath: NavigationPath
    @State private var confirmationText = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var showingFinalConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var agreedToTerms = false
    @State private var isCodeSent = false
    @State private var countdown = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let confirmationPhrase = "确认注销"

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(spacing: 24) {
                    // 警告区域
                    warningSection

                    // 注销后果说明
                    consequencesSection

                    // 确认输入
                    confirmationSection

                    // 验证码输入
                    verificationSection

                    // 同意条款
                    agreementSection

                    // 注销按钮
                    deleteButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .alert("最终确认", isPresented: $showingFinalConfirmation) {
            Button("取消", role: .cancel) { }
            Button("确认注销", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("此操作不可撤销，您确定要注销账号吗？")
        }
        .onAppear { print("🧭 AccountDeletionView onAppear - navigationPath.count = \(navigationPath.count)") }
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("注销账号")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 警告区域
    private var warningSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("账号注销警告")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)

            Text("注销账号是不可逆的操作，请仔细阅读以下说明")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 注销后果说明
    private var consequencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("注销后将发生以下情况")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                consequenceItem("🗑️", "账号信息将被永久删除，无法恢复")
                consequenceItem("💬", "所有聊天记录和消息将被清除")
                consequenceItem("📝", "发布的所有内容将被删除")
                consequenceItem("👥", "好友关系将被解除")
                consequenceItem("🏆", "积分、等级等数据将被清零")
                consequenceItem("💰", "账户余额需要提前处理")
                consequenceItem("📱", "绑定的手机号将被解绑")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func consequenceItem(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 16))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - 确认输入区域
    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("确认操作")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("请输入「\(confirmationPhrase)」以确认注销")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                TextField("请输入确认文字", text: $confirmationText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - 验证码输入区域
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("短信验证")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("为了确保账户安全，请输入手机验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack {
                    TextField("请输入验证码", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: sendDeletionCode) {
                        Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(countdown > 0 ? .secondary : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(countdown > 0 ? Color.secondary : Color.blue, lineWidth: 1)
                            )
                    }
                    .disabled(countdown > 0 || isLoading)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - 同意条款区域
    private var agreementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(agreedToTerms ? .blue : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("我已阅读并同意")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Text("• 我确认已备份重要数据")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("• 我了解注销后果且自愿承担")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 注销按钮
    private var deleteButton: some View {
        Button(action: {
            showingFinalConfirmation = true
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }

                Text("确认注销账号")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canDelete ? Color.red : Color.gray)
            )
        }
        .disabled(!canDelete || isLoading)
    }

    // MARK: - 计算属性
    private var canDelete: Bool {
        confirmationText == confirmationPhrase && agreedToTerms && !verificationCode.isEmpty && isCodeSent
    }

    // MARK: - 发送注销验证码
    private func sendDeletionCode() {
        guard let user = authManager.currentUser else {
            alertMessage = "用户信息获取失败"
            showingAlert = true
            return
        }

        isLoading = true

        authService.sendDeletionCode(phone: user.phone ?? "") { [self] (success: Bool, message: String) in
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = message
                showingAlert = true

                if success {
                    isCodeSent = true
                    countdown = 60
                }
            }
        }
    }

    // MARK: - 执行账号注销
    private func performAccountDeletion() {
        guard !verificationCode.isEmpty else {
            alertMessage = "请输入验证码"
            showingAlert = true
            return
        }

        isLoading = true

        authService.requestDeletion(code: verificationCode) { [self] (success: Bool, message: String, deletionData: [String: Any]?) in
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = message
                showingAlert = true

                if success {
                    // 注销申请成功，显示等待期信息
                    if let data = deletionData {
                        let remainingDays = data["remainingDays"] as? Int ?? 3
                        alertMessage = "账号注销申请成功，将在\(remainingDays)天后正式注销。期间可通过短信登录撤销申请。"
                    }

                    // 退出登录并返回登录页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        authManager.logout()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 隐私设置页面
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 黑名单管理
                Section {
                    NavigationLink(destination: BlacklistView(navigationPath: $navigationPath)) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)

                            Text("黑名单")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("3人")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("黑名单管理")
                } footer: {
                    Text("管理被拉黑的用户，被拉黑的用户无法向您发送消息或查看您的动态")
                }
            }
        }
        .onAppear {
            print("🧭 PrivacySettingsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("隐私设置")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 黑名单页面
struct BlacklistView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var blacklistedUsers: [BlacklistedUser] = [
        BlacklistedUser(id: 1, nickname: "用户123", avatar: nil, blockedDate: Date()),
        BlacklistedUser(id: 2, nickname: "匿名用户", avatar: nil, blockedDate: Date().addingTimeInterval(-86400)),
        BlacklistedUser(id: 3, nickname: "测试用户", avatar: nil, blockedDate: Date().addingTimeInterval(-172800))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            if blacklistedUsers.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("暂无黑名单用户")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("被拉黑的用户将无法向您发送消息")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding(.horizontal, 40)
            } else {
                List {
                    ForEach(blacklistedUsers) { user in
                        HStack(spacing: 12) {
                            // 头像
                            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String(user.nickname.prefix(1)))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickname)
                                    .font(.system(size: 16, weight: .medium))

                                Text("拉黑时间：\(formatDate(user.blockedDate))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("解除") {
                                unblockUser(user)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteUsers)
                }
            }
        }
        .onAppear {
            print("🧭 BlacklistView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("黑名单")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 辅助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func unblockUser(_ user: BlacklistedUser) {
        blacklistedUsers.removeAll { $0.id == user.id }
    }

    private func deleteUsers(at offsets: IndexSet) {
        blacklistedUsers.remove(atOffsets: offsets)
    }
}

// MARK: - 黑名单用户模型
struct BlacklistedUser: Identifiable {
    let id: Int
    let nickname: String
    let avatar: String?
    let blockedDate: Date
}

// MARK: - 背景设置页面
struct BackgroundSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var navigationPath: NavigationPath
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 主题模式
                Section("主题模式") {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        HStack(spacing: 12) {
                            Image(systemName: option.iconName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(option.iconColor)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(option.subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if themeManager.getCurrentOption() == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            applyColorScheme(option)
                        }
                    }
                }

                // 背景图片
                Section("背景图片") {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 24, height: 24)

                        Text("自定义背景")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("即将推出")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            print("🧭 BackgroundSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("背景设置")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 应用主题
    private func applyColorScheme(_ option: ColorSchemeOption) {
        print("🎨 切换主题到: \(option.title)")

        // 应用主题到整个应用
        ThemeManager.shared.setColorScheme(option)

        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - 主题选项枚举
enum ColorSchemeOption: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var title: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }

    var subtitle: String {
        switch self {
        case .light: return "始终使用浅色主题"
        case .dark: return "始终使用深色主题"
        case .system: return "根据系统设置自动切换"
        }
    }

    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }

    var iconColor: Color {
        switch self {
        case .light: return .orange
        case .dark: return .purple
        case .system: return .blue
        }
    }
}

// MARK: - 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentColorScheme: ColorScheme?
    @AppStorage("selectedColorScheme") private var selectedColorScheme: String = "system"

    private init() {
        // 初始化时应用保存的主题设置
        applyStoredTheme()
    }

    /// 设置颜色方案
    func setColorScheme(_ option: ColorSchemeOption) {
        selectedColorScheme = option.rawValue

        switch option {
        case .light:
            currentColorScheme = .light
            setAppearance(.light)
        case .dark:
            currentColorScheme = .dark
            setAppearance(.dark)
        case .system:
            currentColorScheme = nil
            setAppearance(.unspecified)
        }

        print("🎨 主题已切换到: \(option.title)")
    }

    /// 应用存储的主题设置
    private func applyStoredTheme() {
        if let option = ColorSchemeOption(rawValue: selectedColorScheme) {
            setColorScheme(option)
        }
    }

    /// 设置系统外观
    private func setAppearance(_ style: UIUserInterfaceStyle) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }

    /// 获取当前选择的主题选项
    func getCurrentOption() -> ColorSchemeOption {
        return ColorSchemeOption(rawValue: selectedColorScheme) ?? .system
    }
}

// MARK: - 字体大小设置页面
struct FontSizeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @StateObject private var fontManager = FontManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 预览区域
                Section("预览") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("青禾计划")
                            .dynamicFont(.title2)

                        Text("这是一段示例文本，用于预览当前字体大小设置的效果。您可以根据自己的阅读习惯选择合适的字体大小。")
                            .dynamicFont(.body)
                            .lineLimit(nil)

                        Text("小字提示文本")
                            .dynamicFont(.caption1)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // 字体大小选项
                Section("字体大小") {
                    ForEach(FontSizeOption.allCases, id: \.self) { option in
                        HStack(spacing: 12) {
                            Image(systemName: "textformat.size")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(option.subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if fontManager.currentFontSize == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontManager.setFontSize(option)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🧭 FontSizeSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("字体大小")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 多语言设置页面
struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "zh-Hans"
    @StateObject private var localizationManager = LocalizationManager()
    @State private var showingRestartAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 语言选项
                Section(footer: Text(getLocalizedFooterText())) {
                    ForEach(LanguageOption.allCases, id: \.self) { option in
                        HStack(spacing: 12) {
                            Text(option.flag)
                                .font(.system(size: 20))
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(option.nativeTitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedLanguage == option.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedLanguage != option.rawValue {
                                selectedLanguage = option.rawValue
                                localizationManager.setLanguage(option.rawValue)
                                showingRestartAlert = true
                            }
                        }
                    }
                }
            }
        }
        .alert(getLocalizedAlertTitle(), isPresented: $showingRestartAlert) {
            Button(getLocalizedCancelButton(), role: .cancel) { }
            Button(getLocalizedRestartButton()) {
                // 这里可以添加重启应用的逻辑
                print("🔄 重启应用以应用新语言设置")
            }
        } message: {
            Text(getLocalizedAlertMessage())
        }
        .onAppear {
            print("🧭 LanguageSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
            localizationManager.currentLanguage = selectedLanguage
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(localizationManager.localizedString(key: "multi_language"))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 本地化文本函数
    private func getLocalizedFooterText() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "更改语言后需要重启应用才能生效"
        case "zh-Hant": return "更改語言後需要重啟應用才能生效"
        case "en": return "App restart required for language changes to take effect"
        case "ja": return "言語変更を有効にするにはアプリの再起動が必要です"
        case "ko": return "언어 변경 사항을 적용하려면 앱을 다시 시작해야 합니다"
        default: return "更改语言后需要重启应用才能生效"
        }
    }

    private func getLocalizedAlertTitle() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "语言已更改"
        case "zh-Hant": return "語言已更改"
        case "en": return "Language Changed"
        case "ja": return "言語が変更されました"
        case "ko": return "언어가 변경되었습니다"
        default: return "语言已更改"
        }
    }

    private func getLocalizedAlertMessage() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "需要重启应用才能应用新的语言设置"
        case "zh-Hant": return "需要重啟應用才能應用新的語言設置"
        case "en": return "App restart required to apply new language settings"
        case "ja": return "新しい言語設定を適用するにはアプリの再起動が必要です"
        case "ko": return "새 언어 설정을 적용하려면 앱을 다시 시작해야 합니다"
        default: return "需要重启应用才能应用新的语言设置"
        }
    }

    private func getLocalizedCancelButton() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "稍后重启"
        case "zh-Hant": return "稍後重啟"
        case "en": return "Restart Later"
        case "ja": return "後で再起動"
        case "ko": return "나중에 다시 시작"
        default: return "稍后重启"
        }
    }

    private func getLocalizedRestartButton() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "立即重启"
        case "zh-Hant": return "立即重啟"
        case "en": return "Restart Now"
        case "ja": return "今すぐ再起動"
        case "ko": return "지금 다시 시작"
        default: return "立即重启"
        }
    }
}

// MARK: - 语言选项枚举
enum LanguageOption: String, CaseIterable {
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    var title: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁体中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var nativeTitle: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .zhHans: return "🇨🇳"
        case .zhHant: return "🇹🇼"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        }
    }
}

// MARK: - 预览
#Preview("消息") {
    MessagesView()
}

#Preview("会员中心") {
    MembershipView()
}

#Preview("设置") {
    SettingsView()
}
