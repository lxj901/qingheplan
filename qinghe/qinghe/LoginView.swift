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

// MARK: - Login View

struct LoginView: View {
    // 颜色
    private let neonGreen = Color(hex: "B4F65C")
    private let softPurple = Color(hex: "E0C3FC")
    private let primaryButtonBackground = Color(red: 0.2, green: 0.2, blue: 0.2) // 深灰色，接近设计稿

    // 登录方式
    enum LoginType {
        case sms
        case password
    }

    @State private var loginType: LoginType = .sms

    // 表单状态
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isAgreed: Bool = false

    // 倒计时状态
    @State private var countdown: Int = 0
    @State private var isCountingDown: Bool = false
    @State private var timer: Timer? = nil
    @State private var lastSendTime: Date?

    // 动画状态
    @State private var animateBlob1: Bool = false
    @State private var animateBlob2: Bool = false
    @State private var showContent: Bool = false

    // 业务状态
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var showUserAgreement = false
    @State private var showPrivacyPolicy = false
    @State private var agreementNavPath = NavigationPath()
    @State private var privacyNavPath = NavigationPath()

    // 认证服务
    private let authService = AuthService.shared
    private let sendCooldownInterval: TimeInterval = 60 // 60秒冷却时间

    // 计算属性
    private var isValidPhone: Bool {
        phone.count == 11 && phone.hasPrefix("1")
    }

    private var canLogin: Bool {
        guard isValidPhone && !isLoading else { return false }

        switch loginType {
        case .password:
            return !password.isEmpty && password.count >= 6
        case .sms:
            return code.count == 6
        }
    }

    private var canSendCode: Bool {
        guard isValidPhone && !isCountingDown else { return false }

        if let lastTime = lastSendTime {
            let timeSinceLastSend = Date().timeIntervalSince(lastTime)
            return timeSinceLastSend >= sendCooldownInterval
        }
        return true
    }

    var body: some View {
        ZStack {
            // 背景渐变（更贴近设计稿，而非两团光斑）
            LinearGradient(
                gradient: Gradient(colors: [
                    neonGreen.opacity(0.95),
                    neonGreen.opacity(0.7),
                    Color.white,
                    softPurple.opacity(0.25)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题
                VStack(spacing: 12) {
                    Text("欢迎回来。")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.black)
                        .tracking(-1.5)

                    Capsule()
                        .fill(neonGreen)
                        .frame(width: 50, height: 6)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -20)

                // 登录方式切换
                HStack(spacing: 30) {
                    LoginTabButton(
                        title: "验证码登录",
                        isSelected: loginType == .sms,
                        color: neonGreen
                    ) {
                        withAnimation {
                            loginType = .sms
                            // 切回短信模式时清空密码
                            password = ""
                        }
                    }

                    LoginTabButton(
                        title: "密码登录",
                        isSelected: loginType == .password,
                        color: neonGreen
                    ) {
                        withAnimation {
                            loginType = .password
                            // 切到密码模式时清空验证码
                            code = ""
                        }
                    }
                }
                .padding(.bottom, 30)
                .opacity(showContent ? 1 : 0)

                // 表单区域
                VStack(spacing: 24) {
                    if loginType == .sms {
                        // 手机号输入
                        InputContainer(icon: "iphone") {
                            TextField("请输入手机号", text: $phone)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .onChange(of: phone) { newValue in
                                    if newValue.count > 11 {
                                        phone = String(newValue.prefix(11))
                                    }
                                }
                        }

                        // 验证码输入
                        InputContainer(icon: "lock") {
                            HStack {
                                TextField("验证码", text: $code)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .onChange(of: code) { newValue in
                                        if newValue.count > 6 {
                                            code = String(newValue.prefix(6))
                                        }
                                    }

                                Button(action: sendVerificationCode) {
                                    Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(canSendCode ? .black : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    countdown > 0
                                                    ? Color.gray.opacity(0.1)
                                                    : (canSendCode ? neonGreen : Color.gray.opacity(0.2))
                                                )
                                        )
                                }
                                .disabled(!canSendCode)
                            }
                        }
                    } else {
                        // 账号 / 手机号
                        InputContainer(icon: "person") {
                            TextField("账号 / 手机号", text: $phone)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }

                        // 密码输入
                        VStack(alignment: .trailing, spacing: 8) {
                            InputContainer(icon: "lock") {
                                HStack {
                                    if isPasswordVisible {
                                        TextField("请输入密码", text: $password)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                    } else {
                                        SecureField("请输入密码", text: $password)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                    }

                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Button("忘记密码?") {
                                // TODO: 接入找回密码流程
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        }
                    }

                    // 登录按钮
                    Button(action: performLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("立即登录")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(canLogin && !isLoading ? .white : Color.gray.opacity(0.6))
                            }

                            Spacer()

                            Circle()
                                .fill(neonGreen)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                )
                        }
                        .padding(.leading, 32)
                        .padding(.trailing, 8)
                        .frame(height: 64)
                        .background(primaryButtonBackground)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
                    }
                    .padding(.top, 10)
                    .disabled(!canLogin || isLoading)
                    .opacity(!canLogin || isLoading ? 0.6 : 1.0)

                    // 协议勾选
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: { isAgreed.toggle() }) {
                            Circle()
                                .strokeBorder(
                                    isAgreed ? Color.black : Color.gray.opacity(0.5),
                                    lineWidth: 1.5
                                )
                                .background(isAgreed ? Circle().fill(Color.black) : nil)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(neonGreen)
                                        .opacity(isAgreed ? 1 : 0)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text("我已阅读并同意 ")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))

                                Button(action: { showUserAgreement = true }) {
                                    Text("用户协议")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .underline(true, color: neonGreen)
                                }

                                Text(" 与 ")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))

                                Button(action: { showPrivacyPolicy = true }) {
                                    Text("隐私政策")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .underline(true, color: neonGreen)
                                }

                                Text("，未注册的手机号将自动创建账号。")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 30)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // 第三方登录
                VStack(spacing: 24) {
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)

                        Text("OR LOGIN WITH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 8)

                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }

                    HStack(spacing: 20) {
                        // 一键登录（当前复用苹果登录能力）
                        Button(action: { triggerAppleSignIn() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 18))
                                Text("一键登录")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .frame(height: 56)
                            .background(neonGreen)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(neonGreen, lineWidth: 1)
                            )
                        }

                        // Apple 登录
                        Button(action: { triggerAppleSignIn() }) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // 用户协议
        .sheet(isPresented: $showUserAgreement) {
            NavigationStack(path: $agreementNavPath) {
                UserAgreementView(navigationPath: $agreementNavPath)
                    .navigationBarHidden(true)
            }
        }
        // 隐私政策
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack(path: $privacyNavPath) {
                PrivacyPolicyView(navigationPath: $privacyNavPath)
                    .navigationBarHidden(true)
            }
        }
        .onAppear {
            animateBlob1 = true
            animateBlob2 = true
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .preferredColorScheme(.light)
    }

    // MARK: - 发送验证码

    private func sendVerificationCode() {
        guard isValidPhone else {
            showAlert(message: "请输入正确的手机号")
            return
        }

        // 冷却检查
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
        lastSendTime = now

        authService.sendVerificationCode(phone: phone) { [self] success, message in
            DispatchQueue.main.async {
                isLoading = false

                if success {
                    // 开始倒计时
                    isCountingDown = true
                    countdown = 60

                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
                        countdown -= 1
                        if countdown <= 0 {
                            t.invalidate()
                            isCountingDown = false
                            countdown = 0
                        }
                    }

                    showAlert(message: "验证码已发送")
                } else {
                    // 发送失败，允许立即重试
                    lastSendTime = nil
                    showAlert(message: message)
                }
            }
        }
    }

    // MARK: - 登录逻辑

    private func performLogin() {
        guard canLogin else { return }

        isLoading = true

        switch loginType {
        case .password:
            authService.loginWithPassword(phone: phone, password: password) { [self] success, message, userData in
                DispatchQueue.main.async {
                    isLoading = false

                    if success {
                        print("✅ 密码登录成功: \(message)")
                        if let userData = userData {
                            print("用户数据: \(userData)")
                        }
                        // AuthManager 会更新 isAuthenticated，界面自动跳转
                    } else {
                        showAlert(message: message)
                    }
                }
            }
        case .sms:
            authService.login(phone: phone, code: code) { [self] success, message, userData in
                DispatchQueue.main.async {
                    isLoading = false

                    if success {
                        print("✅ 验证码登录成功: \(message)")
                        if let userData = userData {
                            print("用户数据: \(userData)")
                        }
                        // AuthManager 会更新 isAuthenticated，界面自动跳转
                    } else {
                        showAlert(message: message)
                    }
                }
            }
        }
    }

    // MARK: - Apple 登录

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
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showAlert(message: "苹果登录失败：授权信息无效")
                return
            }

            print("🍎 苹果登录授权成功")
            print("Apple ID: \(appleIDCredential.user)")
            print("Email: \(appleIDCredential.email ?? "N/A")")
            print("Full Name: \(appleIDCredential.fullName?.description ?? "N/A")")

            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                showAlert(message: "苹果登录失败：无法获取身份令牌")
                return
            }

            var authorizationCode: String?
            if let authorizationCodeData = appleIDCredential.authorizationCode {
                authorizationCode = String(data: authorizationCodeData, encoding: .utf8)
            }

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
                    userInfo?["name"] = nameInfo
                }
                if let email = appleIDCredential.email {
                    userInfo?["email"] = email
                }
            }

            isLoading = true

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
                        // AuthManager 会更新 isAuthenticated，界面自动跳转
                    } else {
                        showAlert(message: "苹果登录失败: \(message)")
                    }
                }
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" && nsError.code == 1001 {
                // 用户取消登录
                print("ℹ️ 用户取消了苹果登录")
                return
            }

            print("❌ 苹果登录授权失败: \(error.localizedDescription)")
            showAlert(message: "苹果登录失败，请稍后重试")
        }
    }

    // MARK: - Alert

    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - 组件：输入框容器 (Glass Style)

struct InputContainer<Content: View>: View {
    let icon: String
    let content: Content

    init(icon: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                )

            content
        }
        .padding(6)
        .background(Color.white.opacity(0.9))
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

// MARK: - 组件：Tab 切换按钮

struct LoginTabButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .black : Color.gray.opacity(0.6))

                Capsule()
                    .fill(isSelected ? color : Color.clear)
                    .frame(width: 20, height: 4)
            }
        }
    }
}

// MARK: - 预览

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
