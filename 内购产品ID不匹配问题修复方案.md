# 内购产品ID不匹配问题修复方案

## 问题诊断

### 核心问题
从日志分析发现：**StoreKit 返回 0 个产品** ❌

```
🔍 从 StoreKit 请求 4 个产品: ["com.qinghejihua.membership.standard.monthly", ...]
✅ StoreKit 返回 0 个产品  ❌ 这是问题根源！
```

### 原因分析

1. **Bundle ID 不匹配**
   - 项目 Bundle ID: `com.qinghe.qinghe`
   - 后端产品 ID: `com.qinghejihua.membership.*`
   
2. **Apple 规则**
   - 内购产品ID **必须**以应用的 Bundle ID 为前缀
   - 例如：Bundle ID 是 `com.qinghe.qinghe`，产品ID必须是 `com.qinghe.qinghe.*`

3. **当前状态**
   - 后端返回的产品ID与Bundle ID不匹配
   - StoreKit无法识别这些产品ID
   - 导致购买流程无法进行

---

## 解决方案

### 方案 A：修改后端产品ID（推荐）✅

**优点**：
- 不需要修改App Store Connect配置
- 不影响现有用户
- 修改范围小

**步骤**：

#### 1. 修改后端数据库

登录服务器并修改产品ID：

```bash
# 使用 setup-ssh-key.sh 登录服务器
./setup-ssh-key.sh

# 连接到阿里云数据库
mysql -h <阿里云数据库地址> -u <用户名> -p
```

执行SQL更新：

```sql
-- 查看当前产品
SELECT id, product_id, product_name FROM apple_iap_products;

-- 更新产品ID（将 qinghejihua 改为 qinghe.qinghe）
UPDATE apple_iap_products 
SET product_id = 'com.qinghe.qinghe.membership.monthly.auto'
WHERE product_id = 'com.qinghejihua.membership.standard.monthly';

UPDATE apple_iap_products 
SET product_id = 'com.qinghe.qinghe.membership.monthly'
WHERE product_id = 'com.qinghejihua.membership.premium.monthly';

UPDATE apple_iap_products 
SET product_id = 'com.qinghe.qinghe.membership.quarterly'
WHERE product_id = 'com.qinghejihua.membership.standard.yearly';

UPDATE apple_iap_products 
SET product_id = 'com.qinghe.qinghe.membership.yearly'
WHERE product_id = 'com.qinghejihua.membership.premium.yearly';

-- 验证修改
SELECT id, product_id, product_name FROM apple_iap_products;
```

#### 2. 在 App Store Connect 中创建产品

登录 [App Store Connect](https://appstoreconnect.apple.com/)：

1. 选择你的应用
2. 进入 **功能** → **App 内购买项目**
3. 点击 **+** 创建新产品

**创建以下产品**：

##### 产品 1: 连续包月会员
- **类型**: 自动续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.monthly.auto`
- **参考名称**: 连续包月会员
- **订阅群组**: 创建新群组 "会员订阅"
- **订阅时长**: 1个月
- **价格**: ¥29.9

##### 产品 2: 月度会员
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.monthly`
- **参考名称**: 月度会员
- **价格**: ¥39.9

##### 产品 3: 季度会员
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.quarterly`
- **参考名称**: 季度会员
- **价格**: ¥69.9

##### 产品 4: 年度会员
- **类型**: 非续期订阅
- **产品ID**: `com.qinghe.qinghe.membership.yearly`
- **参考名称**: 年度会员
- **价格**: ¥169

#### 3. 配置本地测试环境

我已经创建了 `Configuration.storekit` 文件，现在需要在Xcode中配置：

1. 打开 Xcode
2. 选择项目 → **qinghe** target
3. 点击顶部菜单 **Product** → **Scheme** → **Edit Scheme...**
4. 选择 **Run** → **Options**
5. 在 **StoreKit Configuration** 下拉菜单中选择 `Configuration.storekit`
6. 点击 **Close**

#### 4. 测试

重新编译并运行应用：

```bash
# 在 Xcode 中按 Cmd+R 运行
```

查看日志，应该看到：

```
📦 开始加载产品列表...
✅ 后端返回 4 个产品
  - com.qinghe.qinghe.membership.monthly.auto -> planCode: monthly_auto
  - com.qinghe.qinghe.membership.monthly -> planCode: monthly
  - com.qinghe.qinghe.membership.quarterly -> planCode: quarterly
  - com.qinghe.qinghe.membership.yearly -> planCode: yearly
🔍 从 StoreKit 请求 4 个产品: [...]
✅ StoreKit 返回 4 个产品  ✅ 成功！
  - com.qinghe.qinghe.membership.monthly.auto: 连续包月会员 - ¥29.9
  - ...
```

---

### 方案 B：修改 Bundle ID（不推荐）⚠️

**缺点**：
- 需要重新创建App Store Connect应用
- 会影响现有用户
- 修改范围大

如果必须使用此方案：

1. 修改 `project.pbxproj` 中的 `PRODUCT_BUNDLE_IDENTIFIER`
2. 在 App Store Connect 中创建新应用
3. 重新配置所有证书和配置文件

**不推荐此方案！**

---

## 本地测试步骤

### 1. 使用 StoreKit 配置文件测试（模拟器/真机）

1. 确保已在 Scheme 中配置 `Configuration.storekit`
2. 运行应用
3. 进入会员中心
4. 点击任意套餐购买
5. 会弹出测试购买对话框（不会真实扣费）

### 2. 沙盒测试（仅真机）

在真机上测试真实的Apple支付流程：

1. 在 App Store Connect 中创建沙盒测试账号
2. 在真机上：**设置** → **App Store** → **沙盒账户** → 登录测试账号
3. 运行应用并尝试购买
4. 会弹出真实的购买对话框（使用沙盒环境，不会真实扣费）

---

## 验证清单

完成修复后，验证以下内容：

- [ ] 后端产品ID已更新为 `com.qinghe.qinghe.*`
- [ ] App Store Connect 中已创建对应产品
- [ ] Xcode Scheme 中已配置 StoreKit 配置文件
- [ ] 运行应用，日志显示 "StoreKit 返回 4 个产品"
- [ ] 点击套餐能弹出购买对话框
- [ ] 购买流程能正常完成

---

## 常见问题

### Q1: 修改后端产品ID后，StoreKit 还是返回 0 个产品？

**A:** 可能原因：
1. App Store Connect 中还没创建对应产品
2. 产品状态不是 "准备提交" 或 "可供销售"
3. 需要等待 App Store Connect 同步（最多2小时）
4. Bundle ID 配置错误

### Q2: 本地测试时提示 "无法连接到 App Store"？

**A:** 
- 使用 StoreKit 配置文件测试，不需要连接真实 App Store
- 确保在 Scheme 中正确配置了 `Configuration.storekit`

### Q3: 真机测试时提示 "此 Apple ID 尚未在 iTunes Store 使用过"？

**A:**
- 使用沙盒测试账号，不要使用真实 Apple ID
- 在 **设置 → App Store → 沙盒账户** 中登录，不是在 App Store 应用中登录

---

## 下一步

1. **立即执行**：修改后端产品ID（方案A）
2. **配置 App Store Connect**：创建对应的内购产品
3. **本地测试**：使用 StoreKit 配置文件验证
4. **真机测试**：使用沙盒账号测试完整流程
5. **编译项目**：确保没有报错

需要我帮你执行哪一步？
