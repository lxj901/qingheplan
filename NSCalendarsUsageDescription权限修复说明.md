# NSCalendarsUsageDescription 权限修复说明

## 问题描述

在提交 App Store 审核时,收到 Apple 的拒绝邮件,错误代码为 **ITMS-90683**:

```
ITMS-90683: Missing Purpose String in Info.plist - Your app's code references one or more APIs that access sensitive user data, or the app has one or more entitlements that permit such access. The Info.plist file for "qinghe.app" bundle should contain a NSCalendarsUsageDescription key with a user-facing purpose string explaining clearly and completely why your app needs the data.
```

### 错误原因

应用中使用的第三方 SDK(如广告 SDK GDTMobSDK)可能会引用访问日历的 API,即使应用本身不直接使用这些 API,也需要在 Info.plist 中提供相应的权限说明。

## 解决方案

### 修改的文件

- **文件路径**: `qinghe/ /qinghe/qinghe/Info.plist`

### 添加的权限说明

在 Info.plist 中添加了 `NSCalendarsUsageDescription` 键及其说明:

```xml
<key>NSCalendarsUsageDescription</key>
<string>我们需要访问您的日历以便为您提供更好的服务体验。</string>
```

### 修改后的完整 Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
	</array>
	<key>NSUserTrackingUsageDescription</key>
	<string>我们需要获取您的广告标识符(IDFA)以便为您提供个性化广告和优化广告效果。您可以随时在系统设置中更改此权限。</string>
	<key>NSCalendarsUsageDescription</key>
	<string>我们需要访问您的日历以便为您提供更好的服务体验。</string>
	<key>SKAdNetworkItems</key>
	<array>
		<dict>
			<key>SKAdNetworkIdentifier</key>
			<string>f7s53z58qe.skadnetwork</string>
		</dict>
	</array>
</dict>
</plist>
```

## 验证结果

使用 Xcode 16 编译器进行了完整的 Release 配置编译:

```bash
xcodebuild -project qinghe.xcodeproj -scheme qinghe -configuration Release clean build
```

**编译结果**: ✅ **BUILD SUCCEEDED**

- 没有编译错误
- 只有一些代码警告(不影响提交)

## 下一步操作

1. **重新打包应用**
   - 在 Xcode 中选择 Product > Archive
   - 创建新的归档版本

2. **上传到 App Store Connect**
   - 使用 Xcode Organizer 上传新的二进制文件
   - 或使用 Application Loader/Transporter 上传

3. **重新提交审核**
   - 在 App Store Connect 中选择新上传的构建版本
   - 重新提交应用审核

## 相关信息

- **应用名称**: 青禾计划
- **应用 ID**: 6749306149
- **版本**: 1.0
- **Build**: 8
- **修复日期**: 2025-10-17

## 参考文档

Apple 官方文档: [Requesting Access to Protected Resources](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/requesting_access_to_protected_resources)

## 注意事项

1. 如果将来添加其他第三方 SDK,可能需要添加更多的权限说明
2. 常见的权限说明键包括:
   - `NSCalendarsUsageDescription` - 日历访问
   - `NSCameraUsageDescription` - 相机访问
   - `NSPhotoLibraryUsageDescription` - 相册访问
   - `NSLocationWhenInUseUsageDescription` - 位置访问
   - `NSMicrophoneUsageDescription` - 麦克风访问
   - `NSContactsUsageDescription` - 通讯录访问
   - 等等

3. 权限说明文字应该清晰、完整地解释为什么需要该权限,以便用户理解

