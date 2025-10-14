# StoreKit 配置路径修复说明

## 🔧 问题诊断

### 症状
```
📦 开始加载产品列表...
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthlyv4 -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly.autov5 -> planCode: monthly
  - com.qinghe.qinghe.membership.monthly.autov6 -> planCode: quarterly
  - com.qinghe.qinghe.membership.monthly.autov7 -> planCode: yearly
🔍 从 StoreKit 请求 4 个产品: [...]
✅ StoreKit 返回 0 个产品  ❌
```

### 根本原因
Xcode Scheme 文件中的 StoreKit 配置文件路径不正确。

**错误的路径**: `../../qinghe/Configuration.storekit`
**正确的路径**: `../../../qinghe/Configuration.storekit`

---

## ✅ 已修复的内容

### 1. 修复了 Scheme 配置文件路径

修改了以下两个文件:

#### 文件 1: 共享 Scheme
**路径**: `qinghe/ /qinghe/qinghe.xcodeproj/xcshareddata/xcschemes/qinghe.xcscheme`

```xml
<StoreKitConfigurationFileReference
   identifier = "../../../qinghe/Configuration.storekit">
</StoreKitConfigurationFileReference>
```

#### 文件 2: 用户 Scheme
**路径**: `qinghe/ /qinghe/qinghe.xcodeproj/xcuserdata/lixujie.xcuserdatad/xcschemes/Copy of qinghe.xcscheme`

```xml
<StoreKitConfigurationFileReference
   identifier = "../../../qinghe/Configuration.storekit">
</StoreKitConfigurationFileReference>
```

### 2. 验证编译成功 ✅

使用 Xcode 16 编译器编译项目成功，没有报错:
```
** BUILD SUCCEEDED **
```

---

## 🧪 测试步骤

### 步骤 1: 清理并重新编译

1. 在 Xcode 中打开项目
2. 选择菜单: **Product > Clean Build Folder** (⇧⌘K)
3. 等待清理完成
4. 选择菜单: **Product > Build** (⌘B)
5. 确认编译成功

### 步骤 2: 重启 Xcode (重要!)

1. 完全退出 Xcode
2. 重新打开 Xcode
3. 打开项目

### 步骤 3: 验证 StoreKit 配置

1. 在 Xcode 中，选择菜单: **Product > Scheme > Edit Scheme...**
2. 选择左侧的 **Run**
3. 选择 **Options** 标签
4. 在 **StoreKit Configuration** 下拉菜单中，确认选择了 **Configuration.storekit**
5. 点击 **Close**

### 步骤 4: 运行应用并测试

1. 选择模拟器: **iPhone 16 (iOS 18.5)** 或更高版本
2. 运行应用 (⌘R)
3. 导航到会员中心页面
4. 查看控制台日志

### 预期结果 ✅

```
📦 开始加载产品列表...
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthlyv4 -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly.autov5 -> planCode: monthly
  - com.qinghe.qinghe.membership.monthly.autov6 -> planCode: quarterly
  - com.qinghe.qinghe.membership.monthly.autov7 -> planCode: yearly
🔍 从 StoreKit 请求 4 个产品: [...]
✅ StoreKit 返回 4 个产品  ← 关键！必须是 4！
  - com.qinghe.qinghe.membership.monthlyv4: 连续包月会员 - ¥29.9
  - com.qinghe.qinghe.membership.monthly.autov5: 月度会员 - ¥39.9
  - com.qinghe.qinghe.membership.monthly.autov6: 季度会员 - ¥69.9
  - com.qinghe.qinghe.membership.monthly.autov7: 年度会员 - ¥169
```

### 步骤 5: 测试购买流程

1. 点击任意套餐（如"连续包月会员"）
2. 应该弹出 StoreKit 测试购买对话框
3. 点击"订阅"
4. 在测试环境中，购买应该立即成功
5. 查看控制台日志，确认购买成功

---

## 📋 StoreKit 配置文件内容

配置文件位置: `qinghe/ /qinghe/qinghe/Configuration.storekit`

包含 4 个自动续期订阅产品:

| 产品ID | 名称 | 价格 | 周期 |
|--------|------|------|------|
| `com.qinghe.qinghe.membership.monthlyv4` | 连续包月会员 | ¥29.9 | 1个月 |
| `com.qinghe.qinghe.membership.monthly.autov5` | 月度会员 | ¥39.9 | 1个月 |
| `com.qinghe.qinghe.membership.monthly.autov6` | 季度会员 | ¥69.9 | 3个月 |
| `com.qinghe.qinghe.membership.monthly.autov7` | 年度会员 | ¥169 | 1年 |

---

## 🔍 故障排除

### 如果 StoreKit 仍然返回 0 个产品

#### 方法 1: 重置模拟器
```bash
# 列出所有模拟器
xcrun simctl list devices

# 重置特定模拟器 (替换 DEVICE_ID)
xcrun simctl erase DEVICE_ID

# 或者重置所有模拟器
xcrun simctl erase all
```

#### 方法 2: 删除 DerivedData
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

然后重新编译项目。

#### 方法 3: 检查 Scheme 配置

1. 在 Xcode 中，选择菜单: **Product > Scheme > Edit Scheme...**
2. 选择左侧的 **Run**
3. 选择 **Options** 标签
4. 确认 **StoreKit Configuration** 设置为 **Configuration.storekit**
5. 如果没有看到这个选项，尝试:
   - 点击下拉菜单
   - 选择 **Configuration.storekit**
   - 点击 **Close**
   - 重新运行应用

#### 方法 4: 手动重新选择 StoreKit 配置

1. 在 Xcode 中，选择菜单: **Product > Scheme > Edit Scheme...**
2. 选择左侧的 **Run**
3. 选择 **Options** 标签
4. 在 **StoreKit Configuration** 下拉菜单中:
   - 先选择 **None**
   - 点击 **Close**
   - 重新打开 Scheme 编辑器
   - 选择 **Configuration.storekit**
   - 点击 **Close**
5. 重新运行应用

---

## 📝 技术细节

### 路径解析说明

**Scheme 文件位置**:
```
qinghe/ /qinghe/qinghe.xcodeproj/xcshareddata/xcschemes/qinghe.xcscheme
```

**StoreKit 配置文件位置**:
```
qinghe/ /qinghe/qinghe/Configuration.storekit
```

**相对路径计算**:
```
从: qinghe/ /qinghe/qinghe.xcodeproj/xcshareddata/xcschemes/
到: qinghe/ /qinghe/qinghe/

步骤:
1. ../ → qinghe/ /qinghe/qinghe.xcodeproj/xcshareddata/
2. ../ → qinghe/ /qinghe/qinghe.xcodeproj/
3. ../ → qinghe/ /qinghe/
4. qinghe/ → qinghe/ /qinghe/qinghe/

完整路径: ../../../qinghe/Configuration.storekit
```

---

## ✅ 总结

1. ✅ 修复了 Scheme 配置文件中的 StoreKit 路径
2. ✅ 使用 Xcode 16 编译器编译成功
3. ✅ StoreKit 配置文件包含所有 4 个产品
4. ✅ 产品ID与后端返回的ID完全匹配

现在应该可以在模拟器中正常加载和测试内购产品了！

---

## 📞 下一步

如果测试成功，请告诉我结果。如果仍有问题，请提供:
1. 完整的控制台日志
2. StoreKit 返回的产品数量
3. 任何错误信息
