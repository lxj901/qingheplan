import SwiftUI

/// 编辑用户资料视图 - 快手风格设计
struct EditProfileView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()

    // 编辑状态
    @State private var nickname: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var hometown: String = ""
    @State private var school: String = ""
    @State private var gender: String = ""
    @State private var birthday: String = ""
    @State private var avatar: String = ""
    @State private var ipLocation: String = ""
    @State private var showingImagePicker = false
    @State private var showingGenderPicker = false
    @State private var showingDatePicker = false
    @State private var showingLocationPicker = false
    @State private var showingHometownPicker = false
    @State private var selectedDate = Date()
    @State private var selectedYear = 2003
    @State private var selectedMonth = 11
    @State private var selectedDay = 30

    // 头像上传相关状态
    @State private var isUploadingAvatar = false
    @State private var uploadProgress: Double = 0.0

    // 性别选项
    private let genderOptions = ["男", "女", "保密"]

    var body: some View {
        ZStack {
            // 背景色
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 编辑表单
                editForm
            }
        }
        .navigationBarHidden(true)
        .asSubView()
        .onAppear {
            loadCurrentData()
        }
        .sheet(isPresented: $showingImagePicker) {
            AvatarPickerView(currentAvatarURL: avatar) { selectedImage in
                uploadAvatar(selectedImage)
            }
        }
        .sheet(isPresented: $showingGenderPicker) {
            genderPickerSheet
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showingLocationPicker) {
            AddressPickerView(title: "选择所在地") { selectedAddress in
                location = selectedAddress
            }
        }
        .sheet(isPresented: $showingHometownPicker) {
            AddressPickerView(title: "选择家乡") { selectedAddress in
                hometown = selectedAddress
            }
        }
        .overlay(
            // 成功消息Toast
            Group {
                if let successMessage = viewModel.successMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(successMessage)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // 3秒后自动隐藏
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                viewModel.successMessage = nil
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.successMessage)
        )
        .overlay(
            // 错误消息Toast
            Group {
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // 5秒后自动隐藏
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                viewModel.errorMessage = nil
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        )
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("返回")
                        .font(.system(size: 16))
                }
                .foregroundColor(.primary)
            }

            Spacer()

            // 标题
            Text("设置资料")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // 保存按钮
            Button("保存") {
                Task {
                    await saveProfile()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            .disabled(viewModel.isSaving)
            .opacity(viewModel.isSaving ? 0.6 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 编辑表单
    private var editForm: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头像和资料完成度区域
                headerSection

                // 基本信息区域
                basicInfoSection

                // 个人信息区域
                personalInfoSection

                // 其他信息区域
                otherInfoSection

                Spacer(minLength: 50)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - 头像区域
    private var headerSection: some View {
        VStack(spacing: 20) {
            // 头像区域
            VStack(spacing: 12) {
                // 头像
                Button(action: {
                    if !isUploadingAvatar {
                        showingImagePicker = true
                    }
                }) {
                    ZStack {
                        NetworkAwareAsyncImage(url: URL(string: avatar.isEmpty ? userProfile.avatar ?? "" : avatar)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 35))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .opacity(isUploadingAvatar ? 0.6 : 1.0)

                        // 上传进度指示器
                        if isUploadingAvatar {
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    VStack(spacing: 4) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)

                                        Text("上传中")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                )
                        } else {
                            // 相机图标
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 24, height: 24)

                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                    .offset(x: -5, y: -5)
                                }
                            }
                            .frame(width: 80, height: 80)
                        }
                    }
                }
                .disabled(isUploadingAvatar)

                // 更换按钮
                Button(isUploadingAvatar ? "上传中..." : "更换") {
                    if !isUploadingAvatar {
                        showingImagePicker = true
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isUploadingAvatar ? .orange : ModernDesignSystem.Colors.primaryGreen)
                .disabled(isUploadingAvatar)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - 基本信息区域
    private var basicInfoSection: some View {
        VStack(spacing: 0) {
            // 昵称
            ProfileEditRow(
                title: "昵称",
                value: nickname,
                placeholder: nickname.isEmpty ? "请设置您的昵称" : nickname,
                showArrow: false
            ) { newValue in
                nickname = newValue
            }

            // 自律ID（原快手号）
            ProfileEditRow(
                title: "自律ID",
                value: userProfile.displayUsername,
                placeholder: "",
                isReadOnly: true,
                showArrow: false
            ) { _ in }

            // 个人介绍
            ProfileEditRow(
                title: "个人介绍",
                value: bio,
                placeholder: bio.isEmpty ? "请介绍一下自己吧" : bio,
                showArrow: false
            ) { newValue in
                bio = newValue
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - 个人信息区域
    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            // 性别
            ProfileEditRow(
                title: "性别",
                value: getGenderDisplayText(),
                placeholder: "",
                isReadOnly: true,
                showArrow: true
            ) { _ in
                showingGenderPicker = true
            }

            // 生日星座
            ProfileEditRow(
                title: "生日星座",
                value: getBirthdayConstellationDisplayText(),
                placeholder: "",
                isReadOnly: true,
                showArrow: true
            ) { _ in
                showingDatePicker = true
            }

            // 所在地
            ProfileEditRow(
                title: "所在地",
                value: location,
                placeholder: location.isEmpty ? "请选择您的所在地" : location,
                isReadOnly: true,
                showArrow: true
            ) { _ in
                showingLocationPicker = true
            }

            // 家乡
            ProfileEditRow(
                title: "家乡",
                value: hometown,
                placeholder: hometown.isEmpty ? "请选择您的家乡" : hometown,
                isReadOnly: true,
                showArrow: true
            ) { _ in
                showingHometownPicker = true
            }

            // 学校
            ProfileEditRow(
                title: "学校",
                value: school,
                placeholder: school.isEmpty ? "选择学校，让校友找到你" : school,
                showArrow: true
            ) { newValue in
                school = newValue
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 其他信息区域
    private var otherInfoSection: some View {
        VStack(spacing: 0) {
            // IP归属地
            ProfileEditRow(
                title: "IP归属地",
                value: getIPLocationDisplayText(),
                placeholder: "",
                isReadOnly: true,
                showArrow: false,
                isLast: true
            ) { _ in }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 私有方法

    /// 加载当前数据
    private func loadCurrentData() {
        nickname = userProfile.nickname
        bio = userProfile.bio ?? ""
        location = userProfile.location ?? ""
        avatar = userProfile.avatar ?? ""
        gender = userProfile.gender ?? ""
        birthday = userProfile.birthday ?? ""
        hometown = userProfile.hometown ?? ""
        school = userProfile.school ?? ""
        ipLocation = userProfile.ipLocation ?? ""
    }

    /// 获取性别显示文本
    private func getGenderDisplayText() -> String {
        if gender.isEmpty {
            return "请选择性别"
        }

        // 将API返回的英文性别转换为中文显示
        switch gender.lowercased() {
        case "male":
            return "男"
        case "female":
            return "女"
        case "private":
            return "保密"
        default:
            return gender.isEmpty ? "请选择性别" : gender
        }
    }

    /// 获取生日星座显示文本
    private func getBirthdayConstellationDisplayText() -> String {
        if birthday.isEmpty {
            return "请选择生日"
        }

        // 根据生日计算星座
        let constellation = calculateConstellation(from: birthday)
        return "\(birthday) · \(constellation)"
    }

    /// 获取IP归属地显示文本
    private func getIPLocationDisplayText() -> String {
        if ipLocation.isEmpty {
            return "系统自动获取"
        }
        return ipLocation
    }

    /// 检查性别是否被选中
    private func isGenderSelected(_ option: String) -> Bool {
        switch option {
        case "男":
            return gender.lowercased() == "male"
        case "女":
            return gender.lowercased() == "female"
        case "保密":
            return gender.lowercased() == "private"
        default:
            return gender == option
        }
    }

    /// 获取选中月份的天数
    private func daysInSelectedMonth() -> Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        guard let date = calendar.date(from: dateComponents) else { return 31 }
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 31
    }

    /// 调整日期以适应月份变化
    private func adjustDayForMonth() {
        let maxDays = daysInSelectedMonth()
        if selectedDay > maxDays {
            selectedDay = maxDays
        }
    }

    /// 根据生日计算星座
    private func calculateConstellation(from birthday: String) -> String {
        let components = birthday.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return "未知"
        }

        switch (month, day) {
        case (1, 20...31), (2, 1...18):
            return "水瓶座"
        case (2, 19...29), (3, 1...20):
            return "双鱼座"
        case (3, 21...31), (4, 1...19):
            return "白羊座"
        case (4, 20...30), (5, 1...20):
            return "金牛座"
        case (5, 21...31), (6, 1...21):
            return "双子座"
        case (6, 22...30), (7, 1...22):
            return "巨蟹座"
        case (7, 23...31), (8, 1...22):
            return "狮子座"
        case (8, 23...31), (9, 1...22):
            return "处女座"
        case (9, 23...30), (10, 1...23):
            return "天秤座"
        case (10, 24...31), (11, 1...22):
            return "天蝎座"
        case (11, 23...30), (12, 1...21):
            return "射手座"
        case (12, 22...31), (1, 1...19):
            return "摩羯座"
        default:
            return "未知"
        }
    }

    /// 上传头像
    private func uploadAvatar(_ image: UIImage) {
        Task {
            await MainActor.run {
                isUploadingAvatar = true
                uploadProgress = 0.0
            }

            do {
                print("📸 开始上传头像，图片尺寸: \(image.size)")

                // 调用头像上传服务
                let uploadResponse = try await AvatarUploadService.shared.uploadAvatar(image)

                await MainActor.run {
                    // 上传成功，立即更新本地头像URL
                    avatar = uploadResponse.data.url
                    isUploadingAvatar = false
                    print("✅ 头像上传成功: \(uploadResponse.data.url)")
                }

                // 头像上传成功后，需要手动更新用户资料中的头像字段
                await updateUserProfileAvatar(uploadResponse.data.url)

                await MainActor.run {
                    // 显示成功提示
                    viewModel.successMessage = "头像更新成功！"
                }

            } catch {
                await MainActor.run {
                    isUploadingAvatar = false
                    let errorMessage = AvatarUploadService.getUserFriendlyError(error)
                    viewModel.errorMessage = errorMessage
                    print("❌ 头像上传失败: \(error)")
                }
            }
        }
    }

    /// 更新用户资料中的头像
    private func updateUserProfileAvatar(_ avatarUrl: String) async {
        do {
            // 更新本地头像URL
            await MainActor.run {
                avatar = avatarUrl
            }

            // 调用现有的保存资料方法，这会更新所有字段包括新的头像
            await saveProfile()

            print("✅ 用户资料头像更新成功")
        } catch {
            print("❌ 更新用户资料头像时发生错误: \(error)")
        }
    }

    /// 刷新用户资料
    private func refreshUserProfile() async {
        guard let currentUserId = AuthManager.shared.getCurrentUserId() else {
            print("⚠️ 无法获取当前用户ID，跳过刷新")
            return
        }

        do {
            let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUserId)
            await MainActor.run {
                // 更新本地用户资料数据
                if let userData = response.data, let newAvatar = userData.avatar {
                    avatar = newAvatar
                }
                print("🔄 用户资料已刷新")
            }
        } catch {
            print("⚠️ 刷新用户资料失败: \(error)")
            // 刷新失败不影响头像上传的成功状态
        }
    }
    
    /// 保存资料
    private func saveProfile() async {
        // 验证输入
        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.errorMessage = "昵称不能为空"
            return
        }
        
        guard nickname.count >= 2 && nickname.count <= 50 else {
            viewModel.errorMessage = "昵称长度应在2-50个字符之间"
            return
        }
        
        guard bio.count <= 500 else {
            viewModel.errorMessage = "个人简介不能超过500个字符"
            return
        }
        
        guard location.count <= 100 else {
            viewModel.errorMessage = "所在地区不能超过100个字符"
            return
        }
        
        // 调用保存方法
        let success = await viewModel.updateProfile(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
            avatar: avatar.isEmpty ? nil : avatar,
            backgroundImage: nil,
            gender: gender.isEmpty ? nil : gender,
            birthday: birthday.isEmpty ? nil : birthday,
            hometown: hometown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : hometown.trimmingCharacters(in: .whitespacesAndNewlines),
            school: school.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : school.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        if success {
            // 更新传入的用户资料
            userProfile = UserProfile(
                id: userProfile.id,
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                avatar: avatar.isEmpty ? userProfile.avatar : avatar,
                backgroundImage: userProfile.backgroundImage,
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                gender: gender.isEmpty ? userProfile.gender : gender,
                birthday: birthday.isEmpty ? userProfile.birthday : birthday,
                constellation: userProfile.constellation,
                hometown: hometown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? userProfile.hometown : hometown.trimmingCharacters(in: .whitespacesAndNewlines),
                school: school.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? userProfile.school : school.trimmingCharacters(in: .whitespacesAndNewlines),
                ipLocation: userProfile.ipLocation,
                qingheId: userProfile.qingheId,
                level: userProfile.level,
                isVerified: userProfile.isVerified,
                followersCount: userProfile.followersCount,
                followingCount: userProfile.followingCount,
                postsCount: userProfile.postsCount,
                createdAt: userProfile.createdAt,
                lastActiveAt: userProfile.lastActiveAt,
                isFollowing: userProfile.isFollowing,
                isFollowedBy: userProfile.isFollowedBy,
                isBlocked: userProfile.isBlocked,
                isMe: userProfile.isMe
            )
            
            dismiss()
        }
    }

    // MARK: - 性别选择器
    private var genderPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                ForEach(genderOptions, id: \.self) { option in
                    Button(action: {
                        // 将中文性别转换为API需要的英文值
                        let apiGender: String
                        switch option {
                        case "男":
                            apiGender = "male"
                        case "女":
                            apiGender = "female"
                        case "保密":
                            apiGender = "private"
                        default:
                            apiGender = option
                        }
                        gender = apiGender
                        showingGenderPicker = false
                    }) {
                        HStack {
                            Text(option)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            // 检查当前选中状态
                            if isGenderSelected(option) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if option != genderOptions.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }

                Spacer()
            }
            .navigationTitle("选择性别")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("取消") {
                    showingGenderPicker = false
                }
            )
        }
        .presentationDetents([.medium])
    }

    // MARK: - 日期选择器
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 自定义年月日选择器
                HStack(spacing: 0) {
                    // 年份选择器
                    Picker("年", selection: $selectedYear) {
                        ForEach(1950...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)

                    // 月份选择器
                    Picker("月", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedMonth) { _, _ in
                        // 月份改变时，调整日期范围
                        adjustDayForMonth()
                    }
                    .onChange(of: selectedYear) { _, _ in
                        // 年份改变时，调整日期范围（考虑闰年）
                        adjustDayForMonth()
                    }

                    // 日期选择器
                    Picker("日", selection: $selectedDay) {
                        ForEach(1...daysInSelectedMonth(), id: \.self) { day in
                            Text("\(day)日").tag(day)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("选择生日")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    showingDatePicker = false
                },
                trailing: Button("确定") {
                    birthday = String(format: "%04d-%02d-%02d", selectedYear, selectedMonth, selectedDay)
                    showingDatePicker = false
                }
            )
        }
        .presentationDetents([.height(350)])
        .onAppear {
            // 如果已有生日数据，设置为选中的年月日
            if !birthday.isEmpty {
                let components = birthday.split(separator: "-")
                if components.count == 3 {
                    selectedYear = Int(components[0]) ?? 2003
                    selectedMonth = Int(components[1]) ?? 11
                    selectedDay = Int(components[2]) ?? 30
                } else {
                    // 默认值
                    selectedYear = 2003
                    selectedMonth = 11
                    selectedDay = 30
                }
            }
        }
    }
}

// MARK: - 资料编辑行组件
struct ProfileEditRow: View {
    let title: String
    let value: String
    let placeholder: String
    var isReadOnly: Bool = false
    var showArrow: Bool = false
    var isLast: Bool = false
    let onValueChange: (String) -> Void

    @State private var editingValue: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 标题
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .leading)

                // 内容区域
                if isReadOnly {
                    // 只读模式
                    HStack {
                        Text(getDisplayText())
                            .font(.system(size: 16))
                            .foregroundColor(getTextColor())
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if showArrow {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // 可编辑模式
                    TextField(placeholder, text: $editingValue)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onAppear {
                            editingValue = value
                        }
                        .onChange(of: editingValue) { _, newValue in
                            onValueChange(newValue)
                        }

                    if showArrow {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .onTapGesture {
                if isReadOnly {
                    onValueChange("")
                }
            }

            // 分割线
            if !isLast {
                Divider()
                    .padding(.leading, 108) // 标题宽度 + 间距
            }
        }
    }

    // MARK: - 辅助方法

    /// 获取显示文本
    private func getDisplayText() -> String {
        if value.isEmpty {
            return placeholder
        }
        return value
    }

    /// 获取文本颜色
    private func getTextColor() -> Color {
        if value.isEmpty {
            return .secondary
        }
        return .primary
    }
}

// MARK: - 编辑资料视图模型
@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let communityService = CommunityAPIService.shared
    
    /// 更新用户资料
    func updateProfile(nickname: String, bio: String?, location: String?, avatar: String?, backgroundImage: String?, gender: String?, birthday: String?, hometown: String?, school: String?) async -> Bool {
        print("🔄 开始更新用户资料")

        isSaving = true
        errorMessage = nil

        do {
            let response = try await communityService.updateUserProfile(
                nickname: nickname,
                bio: bio,
                location: location,
                avatar: avatar,
                backgroundImage: backgroundImage,
                gender: gender,
                birthday: birthday,
                hometown: hometown,
                school: school
            )
            
            if response.success {
                print("✅ 用户资料更新成功")
                return true
            } else {
                errorMessage = response.message ?? "更新失败"
                print("❌ 用户资料更新失败: \(errorMessage ?? "未知错误")")
                return false
            }
        } catch {
            errorMessage = "网络请求失败: \(error.localizedDescription)"
            print("❌ 网络请求失败: \(error)")
            return false
        }
    }
}

// MARK: - 预览
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(userProfile: .constant(UserProfile(
            id: 1,
            nickname: "李守一",
            avatar: nil,
            backgroundImage: nil,
            bio: "药不能医者，唯自救。",
            location: "河北 张家口市",
            gender: "男",
            birthday: "2003-11-30",
            constellation: "射手座",
            hometown: "河北 张家口市",
            school: "某某大学",
            ipLocation: "河北省张家口市",
            qingheId: "qinghe123456",
            level: 1,
            isVerified: false,
            followersCount: 100,
            followingCount: 50,
            postsCount: 20,
            createdAt: "2024-01-01T00:00:00.000Z",
            lastActiveAt: "2024-08-17T10:30:00.000Z",
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false,
            isMe: true
        )))
    }
}
