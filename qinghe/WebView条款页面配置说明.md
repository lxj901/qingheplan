# WebView 条款页面配置说明

## 概述
所有条款和协议页面已配置为使用 WebKit WebView 加载在线内容，替代之前的静态文本展示。

## 已配置的页面

### 1. 隐私政策 (PrivacyPolicyView)
- **文件位置**: `qinghe/qinghe/FinalSettingsPages.swift` (第 923-934 行)
- **URL**: https://www.yingwudaojiafuwuduan.cn/privacy.html
- **标题**: "隐私政策"
- **使用位置**:
  - 登录页面 (`LoginView.swift`)
  - 会员中心 (`MembershipCenterView.swift`)
  - 设置页面

### 2. 使用条款 (TermsOfUseView)
- **文件位置**: `qinghe/qinghe/FinalSettingsPages.swift` (第 1087-1098 行)
- **URL**: https://www.yingwudaojiafuwuduan.cn/terms.html
- **标题**: "使用条款"
- **使用位置**:
  - 会员中心 (`MembershipCenterView.swift`)
  - 设置页面
- **注意**: 已删除旧的静态文本版本 `TermsOfUseView.swift`

### 3. 用户协议 (UserAgreementView)
- **文件位置**: `qinghe/qinghe/FinalSettingsPages.swift` (第 199-210 行)
- **URL**: https://www.yingwudaojiafuwuduan.cn/user-agreement.html
- **标题**: "用户协议"
- **使用位置**:
  - 登录页面 (`LoginView.swift`)
  - 设置页面

### 4. 会员服务协议 (MembershipServiceAgreementView)
- **文件位置**: `qinghe/qinghe/FinalSettingsPages.swift` (第 213-224 行)
- **URL**: https://www.yingwudaojiafuwuduan.cn/membership.html
- **标题**: "会员服务协议"
- **使用位置**:
  - 会员中心 (`MembershipCenterView.swift`)

## WebViewContainer 组件

### 文件位置
`qinghe/qinghe/WebViewContainer.swift`

### 功能特性
1. **加载指示器**: 显示加载进度和"加载中..."提示
2. **错误处理**: 
   - 显示友好的错误提示
   - 提供"重新加载"按钮
   - 区分网络错误和加载失败
3. **自定义导航栏**: 
   - 返回按钮（支持 NavigationPath 和 dismiss）
   - 居中显示标题
4. **WebKit 配置**:
   - 支持内联媒体播放
   - 自动调整内容边距
   - 完整的导航代理支持

### 使用示例
```swift
WebViewContainer(
    navigationPath: $navigationPath,
    title: "隐私政策",
    url: URL(string: "https://www.yingwudaojiafuwuduan.cn/privacy.html")!
)
```

## 调用方式

### 在 LoginView 中
```swift
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
```

### 在 MembershipCenterView 中
```swift
// 会员服务协议
.sheet(isPresented: $showMembershipAgreement) {
    NavigationStack(path: $membershipAgreementNavPath) {
        MembershipServiceAgreementView(navigationPath: $membershipAgreementNavPath)
            .navigationBarHidden(true)
    }
}

// 隐私政策
.sheet(isPresented: $showPrivacyPolicy) {
    NavigationStack(path: $privacyPolicyNavPath) {
        PrivacyPolicyView(navigationPath: $privacyPolicyNavPath)
            .navigationBarHidden(true)
    }
}

// 使用条款
.sheet(isPresented: $showTermsOfUse) {
    NavigationStack(path: $termsOfUseNavPath) {
        TermsOfUseView(navigationPath: $termsOfUseNavPath)
            .navigationBarHidden(true)
    }
}
```

## 网络要求

### Info.plist 配置
确保 `Info.plist` 中已配置 App Transport Security (ATS)：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>yingwudaojiafuwuduan.cn</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## 测试清单

- [ ] 登录页面 - 点击"用户协议"能正确加载网页
- [ ] 登录页面 - 点击"隐私政策"能正确加载网页
- [ ] 会员中心 - 点击"会员服务协议"能正确加载网页
- [ ] 会员中心 - 点击"隐私政策"能正确加载网页
- [ ] 会员中心 - 点击"使用条款"能正确加载网页
- [ ] WebView 加载失败时显示错误提示
- [ ] 点击"重新加载"按钮能重新加载页面
- [ ] 返回按钮能正确关闭页面
- [ ] 网页内容能正常滚动和交互

## 日志输出
WebView 加载时会输出以下日志：
```
🌐 WebViewContainer onAppear - title: 隐私政策, url: https://www.yingwudaojiafuwuduan.cn/privacy.html
```

## 注意事项

1. **URL 必须有效**: 确保所有 URL 都能正常访问
2. **网络权限**: 首次使用时可能需要用户授权网络访问
3. **HTTPS**: 建议所有条款页面使用 HTTPS 协议
4. **移动端适配**: 确保网页内容在移动端显示良好
5. **加载性能**: 网页加载速度取决于网络状况和服务器响应

## 维护建议

1. **定期检查**: 定期检查所有 URL 是否可访问
2. **内容更新**: 网页内容更新后无需重新发布 App
3. **版本控制**: 在网页中标注"最后更新时间"
4. **备用方案**: 考虑在网络不可用时提供离线版本或缓存

## 相关文件

- `qinghe/qinghe/WebViewContainer.swift` - WebView 容器组件
- `qinghe/qinghe/FinalSettingsPages.swift` - 所有条款页面定义
- `qinghe/qinghe/LoginView.swift` - 登录页面（使用用户协议和隐私政策）
- `qinghe/qinghe/MembershipCenterView.swift` - 会员中心（使用所有条款）

## 更新历史

- **2025-10-17**: 删除旧的静态文本版本 `TermsOfUseView.swift`，统一使用 WebView
- **2025-10-17**: 配置所有条款页面使用 WebView 加载在线内容
- **2025-10-17**: 创建 `WebViewContainer` 通用组件

