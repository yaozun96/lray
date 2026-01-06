# Muse_重构

This template should help get you started developing with Vue 3 in Vite.

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Customize configuration

See [Vite Configuration Reference](https://vitejs.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

### 便捷更换后端 API 域名

防盗版机制会把授权域名和指纹写进 `src/utils/auth.js`。需要合法更换域名时，使用项目内置工具即可自动完成所有混淆与指纹更新：

```sh
# 传入新的后端域名（必须包含协议，工具会自动补全末尾 / ）
npm run update:api -- https://api.example.com
```

执行后会打印新指纹并替换 auth 模块中的 `_0xDomainSeeds`、`_0xFingerprintSegments`。记得重新构建/部署，所有前端包都会使用新域名。

详细原理与常见问题可查看 [`docs/api-domain-guard.md`](docs/api-domain-guard.md)。

### 打包后测试服务器

```sh
serve -s dist
```
```shst
# v2boards_theme_lray
