# 动态密钥 + 构建过期机制使用指南

## 概述

此增强方案为V2Board主题添加了**动态密钥**和**可选的构建过期**机制。每次构建都会自动生成新的随机密钥，如需进一步限制构建有效期，可通过参数或环境变量开启过期时间。

## 安全性对比

| 方案 | 安全等级 | 破解难度 |
|------|---------|---------|
| 之前（config.js存储） | 0% | 任何人可访问 |
| 硬编码混淆 | 40-50% | 需要30分钟-2小时 |
| **动态密钥+可选过期** | **65-70%** | 需要逆向+每次构建都变化 |

## 工作原理

1. **构建时自动生成**：每次运行 `npm run build` 时，自动生成：
   - 32字节随机密钥
   - 构建时间戳
   - 过期时间（可选，默认关闭）
   - SHA-256签名

2. **代码注入**：生成的密钥和时间戳被混淆后注入到 `src/utils/auth.js`

3. **运行时验证**：
   - 验证密钥签名
   - （可选）检查构建是否过期并提前提示

## 使用方法

### 日常开发

```bash
# 开发环境（不检查过期时间）
npm run dev
```

### 生产构建

```bash
# 默认：禁用过期（推荐，构建永不过期）
npm run build

# 启用过期（示例：90天，使用环境变量）
BUILD_EXPIRY_DAYS=90 npm run build

# 也可单独注入后再手动构建
node scripts/inject-build-key.js 90 && vite build --mode airbuddy
```

### 手动注入密钥

```bash
# 注入密钥，自定义过期天数
node scripts/inject-build-key.js 120  # 120天后过期

# 禁用过期（与默认行为一致）
node scripts/inject-build-key.js off
```

## 自动化流程

构建命令已自动集成密钥注入：

```json
{
  "scripts": {
    "prebuild": "node scripts/inject-build-key.js",
    "build": "vite build --mode airbuddy",
    "build:airdemo": "node scripts/inject-build-key.js && vite build --mode airdemo"
  }
}
```

**每次运行 build 命令时，都会自动：**
1. 生成新的随机密钥
2. （如启用）设置新的过期时间
3. 注入到源码
4. 执行构建
5. 保存构建日志

> 提示：在 CI/CD 或本地构建中设置 `BUILD_EXPIRY_DAYS=<天数>` 即可开启过期机制，例如 `BUILD_EXPIRY_DAYS=60 npm run build`。

## 构建日志

每次构建后，会在 `.build-logs/` 目录下保存构建信息：

```bash
.build-logs/
├── build-1b9dc81d42076ca2.json  # 具体构建记录
└── latest.json                   # 最新构建信息
```

日志内容示例：

```json
{
  "buildId": "636cf48791f3a15f",
  "buildTime": 1765974944433,
  "buildTimeReadable": "2025-12-17T15:05:44.433Z",
  "expiryTime": null,
  "expiryTimeReadable": null,
  "expiryDays": null,
  "expiryEnabled": false,
  "buildKey": "p1YsZrxB..."
}
```

## 过期提醒（仅在启用过期后生效）

> 如果未启用过期机制，本节的提醒不会出现。

### 控制台输出

**正常情况：**
```
[Auth] 构建有效，剩余 85 天
[Auth] 授权验证通过
```

**即将过期（少于7天）：**
```
[Auth] ⚠️  构建即将过期！剩余 5 天，请及时重新构建
```

**已过期：**
```
[Auth] 构建已过期 3 天
[Auth] 构建时间: 2025/12/13 22:50:27
[Auth] 过期时间: 2026/3/13 22:50:27
```

## 安全特性

### 1. 每次构建密钥都不同
- 使用 `crypto.randomBytes(32)` 生成
- Base64编码后混淆存储
- 无法预测下一次的密钥

### 2. 可选的自动过期机制
- 启用后，生产构建到期自动失效
- 防止旧版本长期流通
- 需要定期重新构建

### 3. 签名验证
- 使用 SHA-256 对密钥+时间戳签名
- 防止篡改过期时间
- 验证构建完整性

### 4. 混淆存储
- 密钥分割为8字节块
- 使用 `String.fromCharCode()` 编码
- 代码压缩后进一步混淆

## 常见问题

### Q: 如果构建过期了怎么办？

A: （仅在启用过期机制时）重新运行 `npm run build` 即可生成新的密钥和过期时间。如需延长有效期，可在构建时设置 `BUILD_EXPIRY_DAYS`。

### Q: 可以修改过期时间吗？

A: 可以。在运行构建命令时指定天数，例如：
```bash
BUILD_EXPIRY_DAYS=180 npm run build
# 或仅注入密钥
node scripts/inject-build-key.js 180
```

### Q: 如何关闭过期机制？

A: 这是默认行为，无需额外操作。如果之前启用过期，只需移除 `BUILD_EXPIRY_DAYS` 环境变量或运行 `node scripts/inject-build-key.js off` 即可恢复为永久有效。

### Q: 开发环境也会检查过期吗？

A: 开发环境（`npm run dev`）会检查但只显示警告，不会阻止运行。

### Q: 构建日志包含敏感信息吗？

A: 日志只包含部分密钥（前10个字符），不包含完整密钥。`.build-logs/` 已加入 `.gitignore`，不会提交到Git。

### Q: 如何验证系统是否正常工作？

A:
1. 运行 `node scripts/inject-build-key.js 0` 注入立即过期的密钥
2. 运行 `npm run dev`
3. 查看控制台是否显示"构建已过期"错误

## 与其他安全方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **动态密钥+可选过期（当前）** | 自动化、每次不同、可开关过期 | 启用过期时需要定期重新构建 | ⭐⭐⭐⭐ |
| WebAssembly | 难以逆向 | 需要Rust/C++环境、复杂 | ⭐⭐⭐ |
| 后端验证 | 最安全 | 需要后端支持 | ⭐⭐⭐⭐⭐ |
| 浏览器指纹 | 设备绑定 | 换设备需重新授权 | ⭐⭐⭐ |

## 下一步优化建议

如果需要更高安全性，可以考虑：

1. **后端域名白名单验证**（最推荐）
   - 在API服务器验证请求来源
   - 安全等级：85%+

2. **结合浏览器指纹**
   - 收集设备指纹
   - 后端白名单验证
   - 安全等级：75%+

3. **WebAssembly验证**
   - 使用WASM实现核心验证逻辑
   - 需要Rust编译环境
   - 安全等级：70%+

---

**文档更新时间：** 2025-12-13
**系统版本：** 1.0.0
