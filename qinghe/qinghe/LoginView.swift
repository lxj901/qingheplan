import SwiftUI
import AuthenticationServices

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

struct LoginView: View {
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var password = ""
    @State private var isCodeSent = false
    @State private var countdown = 60
    @State private var isCountingDown = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var lastSendTime: Date?
    @State private var timer: Timer?
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var isPasswordMode = false // 控制登录方式：false=验证码登录，true=密码登录
    @State private var showUserAgreement = false
    @State private var showPrivacyPolicy = false
    @State private var agreementNavPath = NavigationPath()
    @State private var privacyNavPath = NavigationPath()

    // 认证服务
    private let authService = AuthService.shared

    // 防抖配置
    private let sendCooldownInterval: TimeInterval = 60 // 60秒冷却时间

    let onLoginSuccess: () -> Void

    // 现代化配色方案 - 使用系统动态颜色
    let primaryGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    let secondaryGreen = Color(red: 48/255, green: 176/255, blue: 199/255)
    let backgroundColor = Color(.secondarySystemBackground)
    let cardBackground = Color(.systemBackground)
    let textPrimary = Color(.label)
    let textSecondary = Color(.secondaryLabel)
    let inputBackground = Color(.tertiarySystemBackground)
    let borderColor = Color(.separator)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor,
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 装饰性元素
                decorativeElements
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部间距 - 减少间距让内容上移
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 20)

                        // 主要内容卡片
                        mainContentCard

                        // 底部间距
                        Spacer()
                            .frame(height: 20)
                    }
                }




            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // 弹出：用户协议
        .sheet(isPresented: $showUserAgreement) {
            NavigationStack(path: $agreementNavPath) {
                UserAgreementView(navigationPath: $agreementNavPath)
                    .navigationBarHidden(true)
            }
        }
        // 弹出：隐私政策
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack(path: $privacyNavPath) {
                PrivacyPolicyView(navigationPath: $privacyNavPath)
                    .navigationBarHidden(true)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .preferredColorScheme(.light) // 登录页面不适配深色模式
    }

    // MARK: - 装饰性元素
    var decorativeElements: some View {
        ZStack {
            // 顶部装饰圆圈
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryGreen.opacity(0.1), secondaryGreen.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -150)
                .blur(radius: 1)

            Circle()
                .fill(primaryGreen.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: -100)
                .blur(radius: 0.5)

            // 底部装饰
            Circle()
                .fill(secondaryGreen.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 80, y: 200)
                .blur(radius: 1)
        }
    }

    // MARK: - 主要内容卡片
    var mainContentCard: some View {
        VStack(spacing: 24) {
            // 应用图标和标题
            headerSection

            // 登录表单
            loginFormCard

            // 底部协议文字
            agreementSection
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 头部区域
    var headerSection: some View {
        VStack(spacing: 20) {
            // 应用图标
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [primaryGreen, secondaryGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: primaryGreen.opacity(0.3), radius: 12, x: 0, y: 6)

                // 图标
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }

            // 标题文字
            VStack(spacing: 8) {
                Text("欢迎使用青禾")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("请输入手机号码获取验证码进行登录")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - 登录表单卡片
    var loginFormCard: some View {
        VStack(spacing: 24) {
            // 手机号输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("手机号")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textPrimary)

                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                        .frame(width: 20)

                    TextField("请输入11位手机号", text: $phoneNumber)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textPrimary)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: phoneNumber) { _, newValue in
                            if newValue.count > 11 {
                                phoneNumber = String(newValue.prefix(11))
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(phoneNumber.isEmpty ? borderColor : primaryGreen.opacity(0.5), lineWidth: 1.5)
                )
                .cornerRadius(12)
            }

            // 验证码/密码输入框
            VStack(alignment: .leading, spacing: 8) {
                Text(isPasswordMode ? "密码" : "验证码")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textPrimary)

                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: isPasswordMode ? "key.fill" : "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(textSecondary)
                            .frame(width: 20)

                        if isPasswordMode {
                            SecureField("请输入密码", text: $password)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textPrimary)
                                .textFieldStyle(PlainTextFieldStyle())
                        } else {
                            TextField("请输入6位验证码", text: $verificationCode)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textPrimary)
                                .keyboardType(.numberPad)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onChange(of: verificationCode) { _, newValue in
                                    if newValue.count > 6 {
                                        verificationCode = String(newValue.prefix(6))
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke((isPasswordMode ? password.isEmpty : verificationCode.isEmpty) ? borderColor : primaryGreen.opacity(0.5), lineWidth: 1.5)
                    )
                    .cornerRadius(12)

                    // 获取验证码按钮（仅在验证码模式显示）
                    if !isPasswordMode {
                        Button(action: sendVerificationCode) {
                            Text(isCountingDown ? "\(countdown)s" : "获取验证码")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isCountingDown ? textSecondary : primaryGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isCountingDown ? borderColor : primaryGreen.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isCountingDown ? borderColor : primaryGreen, lineWidth: 1.5)
                                        )
                                )
                        }
                        .disabled(!canSendCode)
                    }
                }
            }

            // 登录按钮
            loginButton

            // 苹果登录分割线和按钮
            appleSignInSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 20, x: 0, y: 8)
        )
    }

    // MARK: - 计算属性
    private var isValidPhoneNumber: Bool {
        phoneNumber.count == 11 && phoneNumber.hasPrefix("1")
    }
    
    private var canLogin: Bool {
        guard isValidPhoneNumber && !isLoading else { return false }

        if isPasswordMode {
            // 密码登录模式
            return !password.isEmpty && password.count >= 6
        } else {
            // 验证码登录模式
            return verificationCode.count == 6
        }
    }

    private var canSendCode: Bool {
        guard isValidPhoneNumber && !isCountingDown else { return false }

        // 检查是否在冷却时间内
        if let lastTime = lastSendTime {
            let timeSinceLastSend = Date().timeIntervalSince(lastTime)
            return timeSinceLastSend >= sendCooldownInterval
        }

        return true
    }

    // MARK: - 登录按钮
    var loginButton: some View {
        Button(action: performLogin) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(isLoading ? "登录中..." : (isPasswordMode ? "密码登录" : "验证码登录"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [primaryGreen, secondaryGreen]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: primaryGreen.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(canLogin ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: canLogin)
        }
        .disabled(isLoading || !canLogin)
        .opacity(canLogin ? 1.0 : 0.6)
    }

    // MARK: - 其他登录方式区域
    var appleSignInSection: some View {
        VStack(spacing: 16) {
            // 分割线
            HStack {
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)

                Text("其他登录方式")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)
                    .padding(.horizontal, 12)
                    .fixedSize()

                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)
            }

            // 登录方式图标
            HStack(spacing: 24) {
                // 苹果登录圆形图标
                Button(action: {
                    // 触发苹果登录
                    triggerAppleSignIn()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(.label))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "apple.logo")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }

                // 账号密码登录圆形图标
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPasswordMode = true
                        // 清空验证码相关状态
                        verificationCode = ""
                        isCodeSent = false
                        isCountingDown = false
                        timer?.invalidate()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: isPasswordMode ? [primaryGreen, secondaryGreen] : [Color(.systemGray4), Color(.systemGray5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: isPasswordMode ? primaryGreen.opacity(0.3) : Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }

                // 验证码登录圆形图标
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPasswordMode = false
                        // 清空密码
                        password = ""
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: !isPasswordMode ? [secondaryGreen, primaryGreen] : [Color(.systemGray4), Color(.systemGray5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: !isPasswordMode ? secondaryGreen.opacity(0.3) : Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "message.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - 底部协议区域
    var agreementSection: some View {
        VStack(spacing: 12) {
            // 协议文字
            VStack(spacing: 6) {
                // 第一行：登录即表示同意青禾的《用户协议》和《隐私政策》
                HStack(spacing: 0) {
                    Text("登录即表示同意青禾的")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textSecondary)

                    Button("《用户协议》") { showUserAgreement = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryGreen)

                    Text("和")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textSecondary)

                    Button("《隐私政策》") { showPrivacyPolicy = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryGreen)
                }
                .fixedSize(horizontal: false, vertical: true)

                // 第二行：未注册的手机号将自动创建青禾账号
                Text("未注册的手机号将自动创建青禾账号")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            // 装饰性分割线
            HStack {
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(primaryGreen.opacity(0.6))
                    .padding(.horizontal, 12)

                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - 方法
    private func sendVerificationCode() {
        guard isValidPhoneNumber else {
            showAlert(message: "请输入正确的手机号")
            return
        }

        // 防抖检查：如果距离上次发送时间不足冷却时间，则不允许发送
        let now = Date()
        if let lastTime = lastSendTime {
            let timeSinceLastSend = now.timeIntervalSince(lastTime)
            if timeSinceLastSend < sendCooldownInterval {
                let remainingTime = Int(sendCooldownInterval - timeSinceLastSend)
                showAlert(message: "请等待 \(remainingTime) 秒后再试")
                return
            }
        }

        isLoading = true
        lastSendTime = now // 记录发送时间

        // 调用认证服务发送验证码
        authService.sendVerificationCode(phone: phoneNumber) { [self] success, message in
            DispatchQueue.main.async {
                isLoading = false

                if success {
                    // 发送成功，开始倒计时
                    isCodeSent = true
                    isCountingDown = true
                    countdown = 60

                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        countdown -= 1
                        if countdown <= 0 {
                            timer?.invalidate()
                            isCountingDown = false
                            countdown = 60
                        }
                    }

                    showAlert(message: "验证码已发送")
                } else {
                    // 发送失败时，清除记录的发送时间，允许立即重试
                    lastSendTime = nil
                    showAlert(message: message)
                }
            }
        }
    }
    
    private func performLogin() {
        guard canLogin else { return }

        isLoading = true

        if isPasswordMode {
            // 密码登录
            authService.loginWithPassword(phone: phoneNumber, password: password) { [self] success, message, userData in
                DispatchQueue.main.async {
                    isLoading = false

                    if success {
                        print("✅ 密码登录成功: \(message)")
                        if let userData = userData {
                            print("用户数据: \(userData)")
                        }
                        onLoginSuccess()
                    } else {
                        showAlert(message: message)
                    }
                }
            }
        } else {
            // 验证码登录
            authService.login(phone: phoneNumber, code: verificationCode) { [self] success, message, userData in
                DispatchQueue.main.async {
                    isLoading = false

                    if success {
                        print("✅ 验证码登录成功: \(message)")
                        if let userData = userData {
                            print("用户数据: \(userData)")
                        }
                        onLoginSuccess()
                    } else {
                        showAlert(message: message)
                    }
                }
            }
        }
    }
    
    private func triggerAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        appleSignInDelegate = AppleSignInDelegate { result in
            DispatchQueue.main.async {
                self.handleAppleSignIn(result: result)
            }
        }

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = appleSignInDelegate
        authorizationController.performRequests()
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // 处理苹果登录成功
                print("🍎 苹果登录授权成功")
                print("Apple ID: \(appleIDCredential.user)")
                print("Email: \(appleIDCredential.email ?? "N/A")")
                print("Full Name: \(appleIDCredential.fullName?.description ?? "N/A")")

                // 获取必需的 identityToken
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    showAlert(message: "苹果登录失败：无法获取身份令牌")
                    return
                }

                // 获取可选的 authorizationCode
                var authorizationCode: String?
                if let authorizationCodeData = appleIDCredential.authorizationCode {
                    authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
                }

                // 构建用户信息（首次登录时提供）
                var userInfo: [String: Any]?
                if let fullName = appleIDCredential.fullName {
                    var nameInfo: [String: Any] = [:]
                    if let firstName = fullName.givenName {
                        nameInfo["firstName"] = firstName
                    }
                    if let lastName = fullName.familyName {
                        nameInfo["lastName"] = lastName
                    }

                    userInfo = [:]
                    if !nameInfo.isEmpty {
                        userInfo!["name"] = nameInfo
                    }
                    if let email = appleIDCredential.email {
                        userInfo!["email"] = email
                    }
                }

                // 开始加载状态
                isLoading = true

                // 调用苹果登录 API
                authService.loginWithApple(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    userInfo: userInfo
                ) { [self] success, message, userData in
                    DispatchQueue.main.async {
                        isLoading = false

                        if success {
                            print("✅ 苹果登录成功: \(message)")
                            if let userData = userData {
                                print("用户数据: \(userData)")
                            }
                            onLoginSuccess()
                        } else {
                            showAlert(message: "苹果登录失败: \(message)")
                        }
                    }
                }
            }
        case .failure(let error):
            print("❌ 苹果登录授权失败: \(error.localizedDescription)")
            showAlert(message: "苹果登录失败: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView {
            print("登录成功")
        }
    }
}
