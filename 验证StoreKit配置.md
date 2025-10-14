# StoreKit 配置验证指南

## 当前状态

✅ **后端产品ID已修正**
```
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthly.auto -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly -> planCode: monthly
  - com.qinghe.qinghe.membership.quarterly -> planCode: quarterly
  - com.qinghe.qinghe.membership.yearly -> planCode: yearly
```

❌ **StoreKit 仍返回 0 个产品**
```
✅ StoreKit 返回 0 个产品  ❌
```

---

## 问题分析

### 你当前在真机上运行 📱

从日志可以看出：
```
📍 收到位置更新: 39.85996599, 116.17649847
```

**重要**：StoreKit 配置文件（`.storekit`）**只在模拟器上有效**！

在真机上，StoreKit 会尝试连接真实的 App Store，需要：
1. 在 App Store Connect 中创建对应的产品
2. 产品状态必须是 "准备提交" 或 "可供销售"
3. 或者使用沙盒测试账号

---

## 解决方案

### 方案 A：在模拟器上测试（推荐用于快速验证）✅

1. **在 Xcode 中选择模拟器**
   - 点击顶部工具栏的设备选择器
   - 选择任意 iPhone 模拟器（如 iPhone 16）

2. **运行应用**
   - 按 `Cmd + R` 运行
   - 进入会员中心

3. **查看日志**
   - 应该看到：`✅ StoreKit 返回 4 个产品`

4. **测试购买**
   - 点击任意套餐
   - 会弹出测试购买对话框
   - 点击"订阅"即可完成测试（不会真实扣费）

---

### 方案 B：在真机上测试（需要配置 App Store Connect）📱

#### 步骤 1：在 App Store Connect 中创建产品

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)

2. 选择你的应用（Bundle ID: `com.qinghe.qinghe`）

3. 进入 **功能** → **App 内购买项目**

4. 创建以下 4 个产品：

##### 产品 1: 连续包月会员 🔄
- **类型**: 自动续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.monthly.auto`
- **参考名称**: 连续包月会员
- **订阅群组**: 创建新群组 "会员订阅"
- **订阅时长**: 1个月
- **价格**: ¥29.9
- **本地化信息**（中文-简体）:
  - 显示名称: 连续包月会员
  - 描述: 自动续费，畅享所有健康管理功能

##### 产品 2: 月度会员 📅
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.monthly`
- **参考名称**: 月度会员
- **价格**: ¥39.9
- **本地化信息**（中文-简体）:
  - 显示名称: 月度会员
  - 描述: 单次购买，畅享一个月所有功能

##### 产品 3: 季度会员 📆
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.quarterly`
- **参考名称**: 季度会员
- **价格**: ¥69.9
- **本地化信息**（中文-简体）:
  - 显示名称: 季度会员
  - 描述: 三个月畅享，更优惠更划算

##### 产品 4: 年度会员 📅
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.yearly`
- **参考名称**: 年度会员
- **价格**: ¥169
- **本地化信息**（中文-简体）:
  - 显示名称: 年度会员
  - 描述: 全年畅享，超值优惠，专属健康顾问服务

#### 步骤 2：等待同步

创建产品后，需要等待 **15分钟 - 2小时** 让 App Store Connect 同步。

#### 步骤 3：创建沙盒测试账号

1. 在 App Store Connect 中
2. 进入 **用户和访问** → **沙盒测试员**
3. 点击 **+** 创建新测试账号
4. 填写信息（使用虚拟邮箱，不要用真实 Apple ID）

#### 步骤 4：在真机上配置沙盒账号

1. 打开 iPhone **设置**
2. 滚动到 **App Store**
3. 点击 **沙盒账户**
4. 登录刚才创建的测试账号

**注意**：
- ⚠️ **不要**在 App Store 应用中登录测试账号
- ⚠️ 只在 **设置 → App Store → 沙盒账户** 中登录

#### 步骤 5：测试

1. 运行应用
2. 进入会员中心
3. 点击任意套餐购买
4. 会弹出购买对话框（使用沙盒环境，不会真实扣费）

---

## 快速验证步骤（推荐）

### 1. 先在模拟器上验证 ✅

```bash
# 在 Xcode 中
1. 选择模拟器（iPhone 16）
2. 按 Cmd + R 运行
3. 进入会员中心
4. 查看日志是否显示 "StoreKit 返回 4 个产品"
```

### 2. 如果模拟器测试成功，再配置真机

这样可以确保代码逻辑没问题，然后再处理 App Store Connect 的配置。

---

## 常见问题

### Q1: 模拟器上也返回 0 个产品？

**A:** 检查以下几点：
1. Xcode Scheme 中是否配置了 StoreKit Configuration
2. `Configuration.storekit` 文件是否存在
3. 重新编译并运行

### Q2: 真机上一直返回 0 个产品？

**A:** 可能原因：
1. App Store Connect 中还没创建产品
2. 产品状态不正确（必须是"准备提交"或"可供销售"）
3. Bundle ID 不匹配
4. 需要等待同步（最多 2 小时）
5. 协议未签署

### Q3: 如何检查 Bundle ID 是否正确？

**A:** 
```bash
# 在项目目录运行
grep -r "PRODUCT_BUNDLE_IDENTIFIER" qinghe.xcodeproj/project.pbxproj
```

应该显示：`PRODUCT_BUNDLE_IDENTIFIER = com.qinghe.qinghe;`

### Q4: 购买时提示 "无法连接到 App Store"？

**A:** 
- 模拟器：确保 StoreKit 配置文件已正确配置
- 真机：检查网络连接，确保沙盒账号已登录

---

## 验证清单

### 模拟器测试 ✅
- [ ] Xcode Scheme 中已配置 StoreKit Configuration
- [ ] `Configuration.storekit` 文件存在
- [ ] 选择了模拟器设备
- [ ] 运行应用，日志显示 "StoreKit 返回 4 个产品"
- [ ] 能弹出购买对话框

### 真机测试 📱
- [ ] App Store Connect 中已创建 4 个产品
- [ ] 产品状态正确
- [ ] 已创建沙盒测试账号
- [ ] 真机上已登录沙盒账号（设置 → App Store → 沙盒账户）
- [ ] 等待同步完成（15分钟 - 2小时）
- [ ] 运行应用，日志显示 "StoreKit 返回 4 个产品"

---

## 下一步

**立即执行**：
1. 在 Xcode 中选择模拟器
2. 运行应用
3. 查看日志输出
4. 将结果告诉我

如果模拟器测试成功，我会帮你配置真机测试。
