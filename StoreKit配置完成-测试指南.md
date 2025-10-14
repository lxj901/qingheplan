# StoreKit 配置完成 - 测试指南

## ✅ 已完成的工作

### 1. 后端产品ID修正 ✅
后端已返回正确的产品ID：
- `com.qinghe.qinghe.membership.monthly.auto` (连续包月会员)
- `com.qinghe.qinghe.membership.monthly` (月度会员)
- `com.qinghe.qinghe.membership.quarterly` (季度会员)
- `com.qinghe.qinghe.membership.yearly` (年度会员)

### 2. StoreKit 配置文件创建 ✅
- 创建了 `qinghe/Configuration.storekit` 文件
- 包含 4 个产品配置
- 产品ID与后端一致

### 3. Xcode 项目配置 ✅
- 将 `Configuration.storekit` 添加到项目文件引用
- 配置了 Xcode Scheme 使用 StoreKit 配置
- 清理并重新编译项目成功

### 4. App Store Connect 产品创建 ✅
你已经在 App Store Connect 中创建了 4 个产品：
- ✅ 季度会员: `com.qinghe.qinghe.membership.quarterly`
- ✅ 年度会员: `com.qinghe.qinghe.membership.yearly`
- ✅ 月度会员: `com.qinghe.qinghe.membership.monthly`
- ✅ 连续包月会员: `com.qinghe.qinghe.membership.monthly.auto`

---

## 🧪 现在开始测试

### 测试 1：模拟器测试（立即可用）✅

#### 步骤：

1. **打开 Xcode**
   ```bash
   open "qinghe/ /qinghe/qinghe.xcodeproj"
   ```

2. **选择模拟器**
   - 点击顶部工具栏的设备选择器
   - 选择 **iPhone 16 (18.5)** 或任意其他 iPhone 模拟器

3. **运行应用**
   - 按 `Cmd + R` 或点击运行按钮
   - 等待应用启动

4. **进入会员中心**
   - 在应用中导航到会员中心页面

5. **查看日志**
   - 在 Xcode 底部的控制台中查看日志输出

#### 预期结果：

```
📦 开始加载产品列表...
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthly.auto -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly -> planCode: monthly
  - com.qinghe.qinghe.membership.quarterly -> planCode: quarterly
  - com.qinghe.qinghe.membership.yearly -> planCode: yearly
🔍 从 StoreKit 请求 4 个产品: [...]
✅ StoreKit 返回 4 个产品  ← 关键！必须是 4！
  - com.qinghe.qinghe.membership.monthly.auto: 连续包月会员 - ¥29.9
  - com.qinghe.qinghe.membership.monthly: 月度会员 - ¥39.9
  - com.qinghe.qinghe.membership.quarterly: 季度会员 - ¥69.9
  - com.qinghe.qinghe.membership.yearly: 年度会员 - ¥169
```

#### 测试购买流程：

1. 点击任意套餐（如"连续包月会员"）
2. 应该弹出 StoreKit 测试购买对话框
3. 点击"订阅"或"购买"
4. 购买应该成功完成（不会真实扣费）

---

### 测试 2：真机测试（需要等待同步）📱

#### 前提条件：

1. ✅ App Store Connect 中已创建产品（已完成）
2. ⏳ 等待产品同步（15分钟 - 2小时）
3. ⏳ 创建沙盒测试账号
4. ⏳ 在真机上登录沙盒账号

#### 步骤 1：检查产品状态

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)
2. 进入你的应用 → 功能 → App 内购买项目
3. 确保所有 4 个产品的状态都是：
   - ✅ "准备提交" 或
   - ✅ "可供销售"
   
如果状态是 "元数据缺失"，需要补充信息。

#### 步骤 2：创建沙盒测试账号

1. App Store Connect → **用户和访问** → **沙盒测试员**
2. 点击 **+** 创建新测试账号
3. 填写信息：
   - 名字：测试
   - 姓氏：用户
   - 电子邮件：使用虚拟邮箱（如 test123@example.com）
   - 密码：设置一个密码
   - 国家或地区：中国
4. 点击 **创建**

#### 步骤 3：在真机上登录沙盒账号

1. 打开 iPhone **设置**
2. 滚动到 **App Store**
3. 点击 **沙盒账户**
4. 登录刚才创建的测试账号

⚠️ **重要**：
- **不要**在 App Store 应用中登录测试账号
- 只在 **设置 → App Store → 沙盒账户** 中登录

#### 步骤 4：在真机上运行应用

1. 在 Xcode 中，选择 **李旭杰的iPhone**
2. 按 `Cmd + R` 运行
3. 进入会员中心
4. 查看日志

#### 预期结果：

如果同步完成，应该看到：
```
✅ StoreKit 返回 4 个产品
```

如果还是返回 0 个产品：
- 可能需要等待更长时间（最多 2 小时）
- 检查产品状态是否正确
- 确保沙盒账号已登录

---

## 🔍 故障排除

### 问题 1：模拟器上返回 0 个产品

**解决方案**：

1. **重启 Xcode**
   ```bash
   # 完全退出 Xcode
   killall Xcode
   # 重新打开
   open "qinghe/ /qinghe/qinghe.xcodeproj"
   ```

2. **删除 DerivedData**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/qinghe-*
   ```

3. **重新编译**
   - 在 Xcode 中按 `Cmd + Shift + K` 清理
   - 按 `Cmd + B` 重新编译

4. **检查 Scheme 配置**
   - 按 `Cmd + Shift + <` 打开 Scheme 编辑器
   - Run → Options → StoreKit Configuration
   - 确保选择了 `Configuration.storekit`

### 问题 2：真机上返回 0 个产品

**可能原因**：

1. **产品还在同步中**
   - 等待 15分钟 - 2小时

2. **产品状态不正确**
   - 检查 App Store Connect 中的产品状态
   - 必须是 "准备提交" 或 "可供销售"

3. **沙盒账号未登录**
   - 设置 → App Store → 沙盒账户
   - 确保已登录测试账号

4. **协议未签署**
   - App Store Connect → 协议、税务和银行业务
   - 确保所有协议都已签署

### 问题 3：购买时提示错误

**解决方案**：

- **模拟器**：确保 StoreKit 配置文件已正确配置
- **真机**：确保沙盒账号已登录，产品状态正确

---

## 📊 验证清单

### 模拟器测试 ✅
- [ ] 在 Xcode 中选择模拟器
- [ ] 运行应用
- [ ] 日志显示 "StoreKit 返回 4 个产品"
- [ ] 能看到 4 个套餐及价格
- [ ] 点击套餐能弹出购买对话框
- [ ] 购买流程能正常完成

### 真机测试 📱
- [ ] App Store Connect 中产品状态正确
- [ ] 已创建沙盒测试账号
- [ ] 真机上已登录沙盒账号
- [ ] 等待同步完成（15分钟 - 2小时）
- [ ] 运行应用，日志显示 "StoreKit 返回 4 个产品"
- [ ] 能看到 4 个套餐及价格
- [ ] 点击套餐能弹出购买对话框
- [ ] 购买流程能正常完成

---

## 🎯 下一步

1. **立即执行**：在模拟器上测试
   ```bash
   # 打开 Xcode
   open "qinghe/ /qinghe/qinghe.xcodeproj"
   # 选择模拟器，按 Cmd + R 运行
   ```

2. **查看日志**：确认 StoreKit 返回 4 个产品

3. **测试购买**：点击套餐，测试购买流程

4. **如果模拟器测试成功**：
   - 等待 App Store Connect 产品同步
   - 创建沙盒测试账号
   - 在真机上测试

---

## 📞 需要帮助？

如果遇到问题：

1. 截图日志输出
2. 截图 Xcode Scheme 配置（Run → Options）
3. 告诉我具体的错误信息

我会帮你进一步诊断！
