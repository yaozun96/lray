# 后端 API 域名防破解机制说明

> 适用于 `src/utils/auth.js` 中的授权校验逻辑。

## 1. 机制概览

1. **域名隐藏**  
   - 真正的 API 域名会先执行双重 Base64，再拆成字符编码表（`_0xDomainSeeds`）。运行时根据固定序列 `_0xDomainPattern` 还原，再次解码得到授权域名。  
   - 外部看不到明文字符串，逆向成本高。

2. **指纹验证**  
   - 获得域名后，会用 `域名 + 隐藏密钥 + 长度信息` 计算自定义 hash，结果拆成 `_0xFingerprintSegments`。  
   - 每次请求前会把当前 `baseURL` 归一化后重新算指纹，只有和保存的片段完全一致才算合法。

3. **HTTP 客户端锁定**  
   - `guardHttpClient()` 会给 axios 的 `defaults.baseURL` 套 `Object.defineProperty`，禁止运行时被改写。  
   - 拦截器里也会强制把 `config.baseURL` 写成锁定值，再跑一遍 `verifyApiDomain()`，双重保险。

所以：即使有人拿到主题，修改 `baseURL` 或配置文件都无法让前端接入别的后端，一旦不匹配就触发 `_onAuthFailed`，直接渲染“未授权”页面。

## 2. 更换后端域名

合法需要切换到新的 V2Board 实例时，请使用内置脚本 `scripts/update-api-domain.js`，它会自动：

1. 检查输入 URL（必须包含 `http/https` 协议）。
2. 规范化并补全末尾 `/`。
3. 重新生成 `_0xDomainSeeds`（双重 Base64 + 编码种子）。
4. 基于同一算法重新计算指纹，切片并写入 `_0xFingerprintSegments`。
5. 将变更直接写回 `src/utils/auth.js`。

命令示例：

```bash
npm run update:api -- https://api.example.com
```

执行完成后会打印：

- 授权域名（带 `/`）
- 新指纹值
- 被更新的文件路径

随后重新构建部署即可（`npm run build` 或对应模式）。所有包都会携带新的域名与指纹。

## 3. 常见问题

| 问题 | 处理方式 |
| --- | --- |
| 脚本报“无法解析域名” | 确认命令里包含协议，如 `https://`。 |
| 想验证脚本产出的域名 | 运行 `npm run update:api -- 当前域名`，输出应与已有指纹一致，不会修改内容。 |
| 运行时仍提示未授权 | 确认部署的是新构建产物；若 CDN 有缓存需全部刷新。 |
| 需要彻底移除防护 | 不建议，主题将失去防盗版能力。若确有需求请修改 `auth.js` 并承担风险。 |

## 4. 相关文件

- `src/utils/auth.js`：核心逻辑（域名还原、指纹验证、HTTP 锁定）。
- `scripts/update-api-domain.js`：自动化更新工具。
- `README.md`：「便捷更换后端 API 域名」小节，快速入门。
