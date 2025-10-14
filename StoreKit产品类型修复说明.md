# StoreKit 产品类型修复说明

## 问题描述

在测试内购功能时，发现 StoreKit 返回 0 个产品，导致无法购买会员。

### 日志显示
```
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthlyv4 -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly.autov5 -> planCode: monthly
  - com.qinghe.qinghe.membership.monthly.autov6 -> planCode: quarterly
  - com.qinghe.qinghe.membership.monthly.autov7 -> planCode: yearly
🔍 从 StoreKit 请求 4 个产品
✅ StoreKit 返回 0 个产品 ❌
```

## 根本原因

**前端 StoreKit 配置的产品类型与后端返回的产品类型不匹配**

### 后端返回的产品类型
```json
{
  "com.qinghe.qinghe.membership.monthlyv4": "auto_renewable_subscription",
  "com.qinghe.qinghe.membership.monthly.autov5": "non_renewing_subscription",
  "com.qinghe.qinghe.membership.monthly.autov6": "non_renewing_subscription",
  "com.qinghe.qinghe.membership.monthly.autov7": "non_renewing_subscription"
}
```

### 修复前的 StoreKit 配置
所有 4 个产品都配置为 `AutoRenewableSubscription`（自动续费订阅）

## 解决方案

### 1. 修正 Scheme 配置路径
**文件**: `qinghe.xcodeproj/xcshareddata/xcschemes/qinghe.xcscheme`

**修改前**:
```xml
<StoreKitConfigurationFileReference
   identifier = "../../../qinghe/Configuration.storekit">
</StoreKitConfigurationFileReference>
```

**修改后**:
```xml
<StoreKitConfigurationFileReference
   identifier = "qinghe/Configuration.storekit">
</StoreKitConfigurationFileReference>
```

### 2. 调整产品类型配置
**文件**: `qinghe/Configuration.storekit`

将后三个产品从 `subscriptions` 数组移到 `nonRenewingSubscriptions` 数组：

#### 自动续费订阅 (subscriptions)
- ✅ `com.qinghe.qinghe.membership.monthlyv4` - 连续包月会员
  - 类型: `AutoRenewableSubscription`
  - 价格: ¥29.9/月
  - 自动续费

#### 非续费订阅 (nonRenewingSubscriptions)
- ✅ `com.qinghe.qinghe.membership.monthly.autov5` - 月度会员
  - 类型: `NonRenewingSubscription`
  - 价格: ¥39.9
  - 不自动续费

- ✅ `com.qinghe.qinghe.membership.monthly.autov6` - 季度会员
  - 类型: `NonRenewingSubscription`
  - 价格: ¥69.9
  - 不自动续费

- ✅ `com.qinghe.qinghe.membership.monthly.autov7` - 年度会员
  - 类型: `NonRenewingSubscription`
  - 价格: ¥169
  - 不自动续费

## 修改的文件

1. ✅ `qinghe.xcodeproj/xcshareddata/xcschemes/qinghe.xcscheme`
   - 修正 StoreKit 配置文件路径

2. ✅ `qinghe/Configuration.storekit`
   - 将 3 个产品从自动续费改为非续费订阅
   - 保持 1 个产品为自动续费订阅

## 验证步骤

### 1. 验证 JSON 格式
```bash
python3 -m json.tool qinghe/Configuration.storekit > /dev/null && echo "✅ JSON 格式正确"
```

### 2. 清理并编译
```bash
cd "qinghe/ /qinghe"
xcodebuild clean -project qinghe.xcodeproj -scheme qinghe
xcodebuild build -project qinghe.xcodeproj -scheme qinghe -sdk iphonesimulator
```

### 3. 运行测试
1. 在 Xcode 中打开项目
2. 选择 iPhone 16 模拟器
3. 运行应用 (Cmd + R)
4. 进入会员中心
5. 查看控制台日志

**期望结果**:
```
✅ 后端返回 4 个产品
✅ StoreKit 返回 4 个产品
  - com.qinghe.qinghe.membership.monthlyv4: 连续包月会员 - ¥29.90
  - com.qinghe.qinghe.membership.monthly.autov5: 月度会员 - ¥39.90
  - com.qinghe.qinghe.membership.monthly.autov6: 季度会员 - ¥69.90
  - com.qinghe.qinghe.membership.monthly.autov7: 年度会员 - ¥169.00
```

## 编译结果

✅ **BUILD SUCCEEDED**

## 注意事项

### 产品类型说明

#### 自动续费订阅 (Auto-Renewable Subscription)
- 用户购买后会自动续费
- 适合连续包月/包年服务
- 需要在 App Store Connect 中配置订阅组
- 用户可以在设置中管理订阅

#### 非续费订阅 (Non-Renewing Subscription)
- 用户购买后不会自动续费
- 到期后需要手动重新购买
- 适合固定期限的会员服务
- 应用需要自己管理订阅状态

### App Store Connect 配置

在真机测试或上架前，需要在 App Store Connect 中创建对应的产品：

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择应用 → 功能 → App 内购买项目
3. 创建 4 个产品，产品 ID 必须与配置文件一致
4. 设置产品类型、价格、描述等信息
5. 提交审核

### 测试环境

- ✅ **模拟器**: 使用 StoreKit 配置文件测试（无需真实支付）
- ✅ **真机沙盒**: 使用沙盒测试账号测试（无需真实支付）
- ⚠️ **真机生产**: 需要在 App Store Connect 中配置产品

## 下一步

1. ✅ 在模拟器上测试内购流程
2. ⏳ 在真机上使用沙盒账号测试
3. ⏳ 在 App Store Connect 中创建产品
4. ⏳ 提交审核

## 相关文档

- [Apple StoreKit 文档](https://developer.apple.com/documentation/storekit)
- [App 内购买项目配置指南](https://developer.apple.com/app-store/in-app-purchase/)
- [StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
