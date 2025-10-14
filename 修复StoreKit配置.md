# 修复 StoreKit 配置 - 模拟器返回 0 个产品

## 问题

即使在**模拟器**上运行，StoreKit 仍然返回 0 个产品。

## 原因

Xcode 可能没有正确加载 StoreKit 配置文件。

---

## 解决方案

### 方法 1：在 Xcode 中手动配置（推荐）✅

#### 步骤 1：打开 Scheme 编辑器

1. 在 Xcode 中，点击顶部工具栏的 **qinghe** scheme（设备选择器旁边）
2. 选择 **Edit Scheme...**
3. 或者使用快捷键：`Cmd + Shift + <`

#### 步骤 2：配置 StoreKit

1. 在左侧选择 **Run**
2. 点击右侧的 **Options** 标签
3. 找到 **StoreKit Configuration** 下拉菜单
4. 选择 **Configuration.storekit**

如果下拉菜单中没有看到 `Configuration.storekit`：
- 点击下拉菜单
- 选择 **Other...**
- 浏览到 `qinghe/Configuration.storekit` 文件
- 点击 **Choose**

#### 步骤 3：保存并重新编译

1. 点击 **Close** 关闭 Scheme 编辑器
2. 清理构建：`Cmd + Shift + K`
3. 重新编译：`Cmd + B`

#### 步骤 4：在模拟器上运行

1. 选择任意 iPhone 模拟器（如 iPhone 16）
2. 运行：`Cmd + R`
3. 进入会员中心
4. 查看日志

**预期结果**：
```
✅ StoreKit 返回 4 个产品
  - com.qinghe.qinghe.membership.monthly.auto: 连续包月会员 - ¥29.9
  - com.qinghe.qinghe.membership.monthly: 月度会员 - ¥39.9
  - com.qinghe.qinghe.membership.quarterly: 季度会员 - ¥69.9
  - com.qinghe.qinghe.membership.yearly: 年度会员 - ¥169
```

---

### 方法 2：重启 Xcode

有时 Xcode 需要重启才能识别新的配置文件。

1. 完全退出 Xcode（`Cmd + Q`）
2. 重新打开 Xcode
3. 打开项目
4. 按照方法 1 的步骤配置 StoreKit
5. 运行应用

---

### 方法 3：检查文件是否被包含在 Target 中

1. 在 Xcode 中，选择 `Configuration.storekit` 文件
2. 打开右侧的 **File Inspector**（`Cmd + Option + 1`）
3. 在 **Target Membership** 部分，确保 **qinghe** 被勾选

---

## 验证步骤

### 1. 检查 Scheme 配置

在终端运行：

```bash
cd "qinghe/ /qinghe"
grep -A 2 "StoreKitConfigurationFileReference" qinghe.xcodeproj/xcshareddata/xcschemes/qinghe.xcscheme
```

应该看到：
```xml
<StoreKitConfigurationFileReference
   identifier = "../qinghe/Configuration.storekit">
</StoreKitConfigurationFileReference>
```

### 2. 检查文件存在

```bash
ls -la qinghe/Configuration.storekit
```

应该看到文件存在。

### 3. 验证 JSON 格式

```bash
python3 -m json.tool qinghe/Configuration.storekit > /dev/null && echo "✅ JSON 格式正确"
```

---

## 常见问题

### Q1: 下拉菜单中没有 Configuration.storekit？

**A:** 
1. 确保文件在 `qinghe/Configuration.storekit` 路径
2. 在 Xcode 中，右键点击 `qinghe` 文件夹
3. 选择 **Add Files to "qinghe"...**
4. 选择 `Configuration.storekit`
5. 确保 **Copy items if needed** 未勾选
6. 点击 **Add**

### Q2: 模拟器上仍然返回 0 个产品？

**A:** 
1. 完全退出 Xcode
2. 删除 DerivedData：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/qinghe-*
   ```
3. 重新打开 Xcode
4. 清理构建：`Cmd + Shift + K`
5. 重新编译：`Cmd + B`
6. 运行应用

### Q3: 真机上返回 0 个产品？

**A:** 
这是正常的！真机需要：
1. 在 App Store Connect 中创建产品（你已经创建了）
2. 产品状态必须是 "准备提交" 或 "可供销售"
3. 等待同步（15分钟 - 2小时）
4. 使用沙盒测试账号

---

## 关于 App Store Connect 中的产品

我看到你已经在 App Store Connect 中创建了 4 个产品：

✅ **季度会员**: `com.qinghe.qinghe.membership.quarterly`
✅ **年度会员**: `com.qinghe.qinghe.membership.yearly`
✅ **月度会员**: `com.qinghe.qinghe.membership.monthly`
✅ **连续包月会员**: `com.qinghe.qinghe.membership.monthly.auto`

这些产品ID是**正确的**！

### 下一步（真机测试）

1. **检查产品状态**
   - 确保所有产品状态都是 "准备提交" 或 "可供销售"
   - 如果是 "元数据缺失"，需要补充信息

2. **等待同步**
   - 新创建的产品需要 15分钟 - 2小时 同步到 App Store

3. **创建沙盒测试账号**
   - App Store Connect → 用户和访问 → 沙盒测试员
   - 创建测试账号

4. **在真机上登录沙盒账号**
   - 设置 → App Store → 沙盒账户
   - 登录测试账号

5. **测试**
   - 运行应用
   - 进入会员中心
   - 查看日志

---

## 立即执行

**现在就做**：

1. 打开 Xcode
2. 按 `Cmd + Shift + <` 打开 Scheme 编辑器
3. Run → Options → StoreKit Configuration → 选择 Configuration.storekit
4. 关闭编辑器
5. 选择模拟器（iPhone 16）
6. 按 `Cmd + R` 运行
7. 查看日志

如果还是返回 0 个产品，请：
1. 截图 Scheme 编辑器的 Options 标签
2. 发送给我
3. 我会帮你进一步诊断
