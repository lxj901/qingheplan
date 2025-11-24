import SwiftUI
import PhotosUI

// MARK: - 步骤1: 基本信息
struct BasicInfoStepView: View {
    @ObservedObject var viewModel: CreateCircleViewModel
    @State private var showingAvatarPicker = false
    @State private var showingCoverPicker = false
    @State private var showingCityPicker = false
    @State private var newTag = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 组织类型选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("组织类型")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        TypeButton(
                            title: "个人组织",
                            isSelected: viewModel.organizationType == "personal",
                            action: { viewModel.organizationType = "personal" }
                        )
                        
                        TypeButton(
                            title: "企业组织",
                            isSelected: viewModel.organizationType == "enterprise",
                            action: { viewModel.organizationType = "enterprise" }
                        )
                    }
                }
                
                // 圈子名称
                FormTextField(
                    title: "圈子名称",
                    placeholder: "请输入圈子名称",
                    text: $viewModel.circleName,
                    required: true
                )
                
                // 圈子描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("圈子描述")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .foregroundColor(.red)
                    }
                    
                    TextEditor(text: $viewModel.description)
                        .font(.system(size: 15))
                        .frame(height: 100)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // 分类选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("圈子分类")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(viewModel.categoryOptions, id: \.self) { category in
                            Button(category) {
                                viewModel.category = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.category)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // 所在城市
                FormTextField(
                    title: "所在城市",
                    placeholder: "请选择城市",
                    text: $viewModel.city,
                    required: true,
                    isButton: true,
                    action: { showingCityPicker = true }
                )
                
                // 详细地址
                FormTextField(
                    title: "详细地址",
                    placeholder: "请输入详细地址(可选)",
                    text: $viewModel.address
                )
                
                // 联系电话
                FormTextField(
                    title: "联系电话",
                    placeholder: "请输入联系电话",
                    text: $viewModel.contactPhone,
                    required: true,
                    keyboardType: .phonePad
                )
                
                // 联系邮箱
                FormTextField(
                    title: "联系邮箱",
                    placeholder: "请输入联系邮箱(可选)",
                    text: $viewModel.contactEmail,
                    keyboardType: .emailAddress
                )
                
                // 标签
                VStack(alignment: .leading, spacing: 8) {
                    Text("圈子标签")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // 已添加的标签
                    if !viewModel.tags.isEmpty {
                        CircleTagFlowLayout(spacing: 8) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                CircleTagChip(text: tag, onDelete: {
                                    viewModel.tags.removeAll { $0 == tag }
                                })
                            }
                        }
                    }
                    
                    // 添加标签
                    HStack {
                        TextField("添加标签", text: $newTag)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        Button(action: {
                            if !newTag.isEmpty && viewModel.tags.count < 10 {
                                viewModel.tags.append(newTag)
                                newTag = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingCityPicker) {
            AddressPickerView(title: "选择城市") { selectedCity in
                viewModel.city = selectedCity
            }
        }
    }
}

// MARK: - 步骤2: 实名认证
struct RealNameVerificationStepView: View {
    @ObservedObject var viewModel: CreateCircleViewModel
    @State private var showingIDCardFrontPicker = false
    @State private var showingIDCardBackPicker = false
    @State private var showingFacePicker = false
    @State private var showingBusinessLicensePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 提示信息
                InfoBanner(
                    icon: "info.circle.fill",
                    text: "根据相关法规,创建组织需要进行实名认证",
                    color: .blue
                )

                // 身份证正面
                ImageUploadCard(
                    title: "身份证正面",
                    image: viewModel.idCardFrontImage,
                    placeholder: "点击上传身份证正面照片",
                    onTap: { showingIDCardFrontPicker = true }
                )

                // 身份证反面
                ImageUploadCard(
                    title: "身份证反面",
                    image: viewModel.idCardBackImage,
                    placeholder: "点击上传身份证反面照片",
                    onTap: { showingIDCardBackPicker = true }
                )

                // 真实姓名(OCR自动识别)
                FormTextField(
                    title: "真实姓名",
                    placeholder: "上传身份证后自动识别",
                    text: $viewModel.realName,
                    required: true,
                    disabled: true
                )

                // 身份证号码(OCR自动识别)
                FormTextField(
                    title: "身份证号码",
                    placeholder: "上传身份证后自动识别",
                    text: $viewModel.idCardNumber,
                    required: true,
                    disabled: true
                )

                // 人脸核身验证（金融级）
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("人脸核身验证")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .foregroundColor(.red)

                        Spacer()

                        // 金融级标识
                        HStack(spacing: 4) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 12))
                            Text("金融级")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    // 提示信息
                    InfoBanner(
                        icon: "info.circle.fill",
                        text: "采用阿里云金融级人脸核身技术，安全可靠",
                        color: .blue
                    )

                    if viewModel.faceVerifyPassed {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("人脸核身验证通过 ✓")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    } else if !viewModel.realName.isEmpty && !viewModel.idCardNumber.isEmpty {
                        Button(action: {
                            // 获取当前 UIViewController
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                viewModel.startFaceVerification(from: rootViewController) { _ in }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 16))
                                    Text("下一步：人脸核身")
                                        .font(.system(size: 15, weight: .medium))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppConstants.Colors.primaryGreen)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("请先完成身份证识别")
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                // 企业组织需要上传营业执照
                if viewModel.organizationType == "enterprise" {
                    Divider()
                        .padding(.vertical, 8)

                    Text("企业信息")
                        .font(.system(size: 16, weight: .semibold))

                    ImageUploadCard(
                        title: "营业执照",
                        image: viewModel.businessLicenseImage,
                        placeholder: "点击上传营业执照照片",
                        onTap: { showingBusinessLicensePicker = true }
                    )

                    FormTextField(
                        title: "营业执照号码",
                        placeholder: "请输入营业执照号码",
                        text: $viewModel.businessLicenseNumber,
                        required: true
                    )

                    FormTextField(
                        title: "企业名称",
                        placeholder: "请输入企业名称",
                        text: $viewModel.companyName,
                        required: true
                    )
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingIDCardFrontPicker) {
            CircleImagePicker(image: $viewModel.idCardFrontImage) { image in
                viewModel.recognizeIDCard(image: image, side: "front") { _ in }
            }
        }
        .sheet(isPresented: $showingIDCardBackPicker) {
            CircleImagePicker(image: $viewModel.idCardBackImage) { _ in }
        }
        .sheet(isPresented: $showingFacePicker) {
            CircleImagePicker(image: $viewModel.faceImage, sourceType: .camera) { _ in }
        }
        .sheet(isPresented: $showingBusinessLicensePicker) {
            CircleImagePicker(image: $viewModel.businessLicenseImage) { _ in }
        }
    }
}

// MARK: - 步骤3: 绑定支付宝
struct AlipayBindingStepView: View {
    @ObservedObject var viewModel: CreateCircleViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 提示信息
                InfoBanner(
                    icon: "info.circle.fill",
                    text: "绑定支付宝账号用于活动收入提现和服务费退款",
                    color: .orange
                )

                // 支付宝账号
                FormTextField(
                    title: "支付宝账号",
                    placeholder: "请输入支付宝账号(手机号或邮箱)",
                    text: $viewModel.alipayAccount,
                    required: true
                )

                // 支付宝实名姓名
                FormTextField(
                    title: "支付宝实名姓名",
                    placeholder: "请输入支付宝实名姓名",
                    text: $viewModel.alipayRealName,
                    required: true
                )

                if !viewModel.alipayRealName.isEmpty && viewModel.alipayRealName != viewModel.realName {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("支付宝实名姓名需与身份证姓名一致")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }

                // 说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("温馨提示")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint(text: "支付宝账号用于接收活动收入和服务费退款")
                        BulletPoint(text: "支付宝实名姓名必须与身份证姓名一致")
                        BulletPoint(text: "请确保支付宝账号可正常使用")
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(20)
        }
    }
}

// MARK: - 步骤4: 确认提交
struct ReviewStepView: View {
    @ObservedObject var viewModel: CreateCircleViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 提示信息
                InfoBanner(
                    icon: "checkmark.circle.fill",
                    text: "请仔细核对以下信息,确认无误后提交申请",
                    color: .green
                )

                // 基本信息
                SectionCard(title: "基本信息") {
                    CircleReviewItem(label: "组织类型", value: viewModel.organizationType == "personal" ? "个人组织" : "企业组织")
                    CircleReviewItem(label: "圈子名称", value: viewModel.circleName)
                    CircleReviewItem(label: "圈子分类", value: viewModel.category)
                    CircleReviewItem(label: "所在城市", value: viewModel.city)
                    CircleReviewItem(label: "联系电话", value: viewModel.contactPhone)
                    if !viewModel.contactEmail.isEmpty {
                        CircleReviewItem(label: "联系邮箱", value: viewModel.contactEmail)
                    }
                }

                // 实名认证信息
                SectionCard(title: "实名认证") {
                    CircleReviewItem(label: "真实姓名", value: viewModel.realName)
                    CircleReviewItem(label: "身份证号", value: maskIDCard(viewModel.idCardNumber))
                    CircleReviewItem(label: "人脸验证", value: "已通过 (\(String(format: "%.1f", viewModel.faceVerifySimilarity))%)")

                    if viewModel.organizationType == "enterprise" {
                        CircleReviewItem(label: "企业名称", value: viewModel.companyName)
                        CircleReviewItem(label: "营业执照号", value: viewModel.businessLicenseNumber)
                    }
                }

                // 支付宝信息
                SectionCard(title: "支付宝账号") {
                    CircleReviewItem(label: "支付宝账号", value: maskAlipayAccount(viewModel.alipayAccount))
                    CircleReviewItem(label: "实名姓名", value: viewModel.alipayRealName)
                }

                // 费用说明
                VStack(alignment: .leading, spacing: 12) {
                    Text("费用说明")
                        .font(.system(size: 16, weight: .semibold))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("组织服务费")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("有效期: 1年")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("¥1,000")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint(text: "提交申请后需支付1000元服务费")
                        BulletPoint(text: "服务费有效期为1年,到期后需续费")
                        BulletPoint(text: "支付成功后将进入审核流程")
                        BulletPoint(text: "审核通过后即可正式运营")
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                }
            }
            .padding(20)
        }
    }

    private func maskIDCard(_ idCard: String) -> String {
        guard idCard.count >= 14 else { return idCard }
        let start = idCard.prefix(6)
        let end = idCard.suffix(4)
        return "\(start)********\(end)"
    }

    private func maskAlipayAccount(_ account: String) -> String {
        if account.contains("@") {
            // 邮箱
            let parts = account.split(separator: "@")
            guard let name = parts.first, let domain = parts.last else { return account }
            let maskedName = name.prefix(3) + "***"
            return "\(maskedName)@\(domain)"
        } else {
            // 手机号
            guard account.count == 11 else { return account }
            return "\(account.prefix(3))****\(account.suffix(4))"
        }
    }
}

// MARK: - 辅助组件

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var required: Bool = false
    var disabled: Bool = false
    var isButton: Bool = false
    var keyboardType: UIKeyboardType = .default
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            if isButton {
                Button(action: { action?() }) {
                    HStack {
                        Text(text.isEmpty ? placeholder : text)
                            .foregroundColor(text.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .disabled(disabled)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .opacity(disabled ? 0.6 : 1.0)
            }
        }
    }
}

struct TypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? AppConstants.Colors.primaryGreen : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct InfoBanner: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ImageUploadCard: View {
    let title: String
    let image: UIImage?
    let placeholder: String
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Button(action: onTap) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(placeholder)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct CircleTagChip: View {
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 13))
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppConstants.Colors.primaryGreen.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct CircleReviewItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 图片选择器
struct CircleImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onImagePicked: ((UIImage) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CircleImagePicker

        init(_ parent: CircleImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked?(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - CircleTagFlowLayout (标签流式布局)
struct CircleTagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

