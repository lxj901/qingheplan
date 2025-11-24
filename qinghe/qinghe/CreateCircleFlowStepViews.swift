import SwiftUI
import PhotosUI

// MARK: - Step 1: 基本信息
struct Step1BasicInfoView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("起个响亮的名字")
                    .font(.system(size: 24, weight: .bold))
                Text("好名字能让更多人发现你的圈子")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("圈子名称")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 4)
                    
                    TextField("例如：周末徒步小分队", text: $viewModel.circleName)
                        .font(.system(size: 18, weight: .medium))
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .onChange(of: viewModel.circleName) { newValue in
                            if newValue.count > 15 {
                                viewModel.circleName = String(newValue.prefix(15))
                            }
                        }
                    
                    HStack {
                        Spacer()
                        Text("\(viewModel.circleName.count)/15")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("圈子简介")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 4)
                    
                    TextEditor(text: $viewModel.circleBio)
                        .font(.system(size: 16))
                        .frame(height: 120)
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .onChange(of: viewModel.circleBio) { newValue in
                            if newValue.count > 200 {
                                viewModel.circleBio = String(newValue.prefix(200))
                            }
                        }
                    
                    HStack {
                        Spacer()
                        Text("\(viewModel.circleBio.count)/200")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Step 2: 图片上传
struct Step2ImagesView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("打造视觉门面")
                    .font(.system(size: 24, weight: .bold))
                Text("上传有辨识度的头像和氛围感背景图")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 32) {
                // 头像上传
                VStack(spacing: 12) {
                    PhotosPicker(selection: $viewModel.selectedAvatarItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let image = viewModel.avatarImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 112, height: 112)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 112, height: 112)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.9))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        }
                    }
                    .onChange(of: viewModel.selectedAvatarItem) { _ in
                        viewModel.loadAvatarImage()
                    }
                    
                    Text("点击上传头像")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // 背景图上传
                VStack(alignment: .leading, spacing: 8) {
                    Text("背景封面")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 4)

                    PhotosPicker(selection: $viewModel.selectedBgItem, matching: .images) {
                        ZStack {
                            if let image = viewModel.bgImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 192)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        ZStack {
                                            LinearGradient(
                                                colors: [Color.black.opacity(0.3), Color.clear],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )

                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 20))
                                                    Text("已上传")
                                                        .font(.system(size: 16, weight: .bold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.bottom, 16)
                                            }
                                        }
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.05))
                                    .frame(height: 192)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray.opacity(0.3))
                                            Text("点击上传背景图 (16:9)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray.opacity(0.4))
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedBgItem) { _ in
                        viewModel.loadBgImage()
                    }
                }
            }
        }
    }
}

// MARK: - Step 3: 分类选择
struct Step3CategoryView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    let categories = [
        CircleCategory(id: 1, name: "运动健身", icon: "🏃"),
        CircleCategory(id: 2, name: "户外探险", icon: "⛺️"),
        CircleCategory(id: 3, name: "读书会", icon: "📚"),
        CircleCategory(id: 4, name: "职场交流", icon: "💼"),
        CircleCategory(id: 5, name: "桌游电竞", icon: "🎮"),
        CircleCategory(id: 6, name: "萌宠聚会", icon: "🐱"),
        CircleCategory(id: 7, name: "艺术展览", icon: "🎨"),
        CircleCategory(id: 8, name: "美食探店", icon: "🥘")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("选择圈子赛道")
                    .font(.system(size: 24, weight: .bold))
                Text("精准的分类有助于获得推荐流量")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(categories) { category in
                    Button(action: {
                        viewModel.selectedCategory = category
                    }) {
                        HStack(spacing: 12) {
                            Text(category.icon)
                                .font(.system(size: 24))

                            Text(category.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(viewModel.selectedCategory?.id == category.id ? Color(red: 0.4, green: 0.8, blue: 0.6) : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.selectedCategory?.id == category.id
                                ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1)
                                : Color.white
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.selectedCategory?.id == category.id
                                        ? Color(red: 0.4, green: 0.8, blue: 0.6)
                                        : Color.gray.opacity(0.1),
                                    lineWidth: viewModel.selectedCategory?.id == category.id ? 2 : 1
                                )
                        )
                        .shadow(
                            color: viewModel.selectedCategory?.id == category.id
                                ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2)
                                : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: 地址
struct Step4AddressView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("填写据点地址")
                    .font(.system(size: 24, weight: .bold))
                Text("圈子的线下活动主要聚集地")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                // 地图预览
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .frame(height: 160)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        .offset(y: -10)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

                // 地址输入
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.4))

                    TextField("搜索或输入详细地址", text: $viewModel.address)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                // 使用当前定位
                Button(action: {
                    viewModel.address = "上海市黄浦区南京东路888号"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text("使用当前定位")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
        }
    }
}

// MARK: - Step 5: 电话
struct Step5PhoneView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("预留联系方式")
                    .font(.system(size: 24, weight: .bold))
                Text("方便官方或成员紧急联系管理员")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text("+86")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.trailing, 8)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1)
                                .padding(.leading, 8),
                            alignment: .trailing
                        )

                    TextField("请输入11位手机号", text: $viewModel.phone)
                        .font(.system(size: 20, weight: .bold))
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.phone) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count > 11 {
                                viewModel.phone = String(filtered.prefix(11))
                            } else {
                                viewModel.phone = filtered
                            }
                        }

                    Image(systemName: "phone.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.4))
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)

                // 隐私提示
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)

                    Text("隐私保护：您的手机号仅用于后台审核及紧急联系，不会对普通成员公开。")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Step 6: 身份证识别
struct Step6IDCardView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("实名身份认证")
                    .font(.system(size: 24, weight: .bold))
                Text("根据法规要求，圈主需完成实名认证")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                // 身份证正面
                Button(action: {
                    if !viewModel.isRealNameVerified {
                        viewModel.simulateOCR()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.idCardFrontImage != nil ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1) : Color.gray.opacity(0.05))
                            .frame(height: 176)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        viewModel.idCardFrontImage != nil ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.gray.opacity(0.2),
                                        style: StrokeStyle(lineWidth: 2, dash: [8])
                                    )
                            )

                        if viewModel.isLoading && !viewModel.isRealNameVerified {
                            ZStack {
                                Color.black.opacity(0.5)
                                    .cornerRadius(16)

                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.viewfinder")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)

                                    Text("智能识别中...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        } else if viewModel.isRealNameVerified {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                                Text("身份信息已识别")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                                Text("\(viewModel.realName) \(viewModel.idCardNumber)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.7))
                            }
                        } else {
                            VStack(spacing: 12) {
                                // 身份证示意图
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 128, height: 80)
                                    .overlay(
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 32, height: 32)

                                            VStack(alignment: .leading, spacing: 4) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 64, height: 8)
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 40, height: 8)
                                            }
                                        }
                                        .padding(12)
                                    )
                                    .opacity(0.6)

                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                    Text("上传身份证人像面")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                }
                .disabled(viewModel.isRealNameVerified)

                // 身份证国徽面
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                        .frame(height: 176)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )

                    if viewModel.isRealNameVerified {
                        Text("已自动关联国徽面")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 128, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                        .frame(width: 48, height: 48)
                                )
                                .opacity(0.6)

                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("上传身份证国徽面")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
                .opacity(viewModel.isRealNameVerified ? 0.5 : 1)
            }
        }
    }
}

// MARK: - Step 7: 活体检测
struct Step7FaceVerifyView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(spacing: 8) {
                Text("活体人脸识别")
                    .font(.system(size: 24, weight: .bold))
                Text("请正对屏幕，确保光线充足")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // 扫描框
            ZStack {
                Circle()
                    .stroke(
                        viewModel.isLivenessPassed ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color(red: 0.3, green: 0.7, blue: 0.7),
                        lineWidth: 4
                    )
                    .frame(width: 256, height: 256)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                if viewModel.isLivenessPassed {
                    VStack(spacing: 16) {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                        Text("识别通过")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                    .background(
                        Circle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.05))
                            .frame(width: 256, height: 256)
                    )
                } else if viewModel.isLoading {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.9))
                            .frame(width: 256, height: 256)

                        Image(systemName: "person.fill")
                            .font(.system(size: 128))
                            .foregroundColor(.gray.opacity(0.7))

                        // 扫描线动画
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                            .frame(width: 256, height: 4)
                            .shadow(color: Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.8), radius: 8, x: 0, y: 0)
                            .offset(y: -60)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 256, height: 256)

                        Image(systemName: "person.fill")
                            .font(.system(size: 128))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
            }

            if !viewModel.isLivenessPassed && !viewModel.isLoading {
                Text("请摘下眼镜和口罩")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Spacer()

            if !viewModel.isLivenessPassed {
                Button(action: {
                    viewModel.simulateLiveness()
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 20))
                        }

                        Text(viewModel.isLoading ? "正在检测..." : "开始检测")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(28)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Step 8: 营业执照
struct Step8BusinessLicenseView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("提交营业执照")
                    .font(.system(size: 24, weight: .bold))
                Text("企业/组织创建需验证资质，保障圈子权益")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            PhotosPicker(selection: $viewModel.selectedLicenseItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.businessLicenseImage != nil ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1) : Color.gray.opacity(0.05))
                        .frame(height: 256)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.businessLicenseImage != nil ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.gray.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [8])
                                )
                        )

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else if let image = viewModel.businessLicenseImage {
                        VStack(spacing: 12) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 64, height: 80)
                                    .overlay(
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Circle()
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 8, y: -8)
                            }

                            Text("已上传营业执照")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                            Text("点击可重新上传")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.7))
                        }
                    } else {
                        VStack(spacing: 16) {
                            // 营业执照示意图
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 80, height: 96)
                                .overlay(
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 8)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 8)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 60, height: 8)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 60, height: 8)

                                        Spacer()

                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                            .frame(width: 32, height: 32)
                                    }
                                    .padding(8)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 20))
                                    Text("点击上传营业执照/组织机构代码证")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.gray.opacity(0.6))

                                Text("支持 JPG/PNG/PDF 格式")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedLicenseItem) { _ in
                viewModel.loadLicenseImage()
            }

            // 认证说明
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("认证说明")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange.opacity(0.7))

                    Text("仅用于平台审核企业资质，信息严格保密。若主体为个人，请先咨询客服获取豁免通道。")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.orange.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 9: 支付方式
struct Step9PaymentView: View {
    @ObservedObject var viewModel: CreateCircleFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("绑定账户并支付")
                    .font(.system(size: 24, weight: .bold))
                Text("支付定金以锁定圈子名额，审核不通过原路退回")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // 订单卡片
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.5, blue: 0.4), Color(red: 0.3, green: 0.7, blue: 0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(16)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 96, height: 96)
                    .blur(radius: 20)
                    .offset(x: 80, y: -40)

                VStack(spacing: 32) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("创建项目")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.8))

                            Text(viewModel.circleName.isEmpty ? "未命名圈子" : viewModel.circleName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("需支付定金")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.8))

                            Text("¥ 199.00")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                        Text("资金安全担保 · 随时可退")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .overlay(
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3))
                            .frame(height: 1),
                        alignment: .top
                    )
                }
                .padding(24)
            }
            .frame(height: 180)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            // 支付方式选择
            VStack(alignment: .leading, spacing: 12) {
                Text("选择支付方式")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)

                // 支付宝
                Button(action: {
                    viewModel.paymentMethod = .alipay
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)

                            Text("支")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("支付宝")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("推荐使用，极速到账")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(viewModel.paymentMethod == .alipay ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 20, height: 20)

                            if viewModel.paymentMethod == .alipay {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    .padding(16)
                    .background(viewModel.paymentMethod == .alipay ? Color.blue.opacity(0.05) : Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.paymentMethod == .alipay ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }

                // 微信支付
                Button(action: {
                    viewModel.paymentMethod = .wechat
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                .frame(width: 40, height: 40)

                            Text("微")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("微信支付")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("亿万用户的选择")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(viewModel.paymentMethod == .wechat ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 20, height: 20)

                            if viewModel.paymentMethod == .wechat {
                                Circle()
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    .padding(16)
                    .background(viewModel.paymentMethod == .wechat ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.05) : Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.paymentMethod == .wechat ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }
}

