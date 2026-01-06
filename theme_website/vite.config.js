// https://vitejs.dev/config/
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import Components from "unplugin-vue-components/dist/vite.js";
import { AntDesignVueResolver } from "unplugin-vue-components/dist/resolvers.js";
import * as path from "path";
import { terser } from "rollup-plugin-terser"; // 引入 terser 插件

export default ({ command, mode }) => {
    console.log('command ===>', command);
    console.log('mode ===>', mode);

    const isProduction = command === 'build';

    return defineConfig({
        base: './',
        plugins: [
            vue(),
            Components({
                resolvers: [
                    AntDesignVueResolver({
                        importStyle: false, // 使用 css in js
                    }),
                ],
            }),
            terser({
                mangle: {
                    toplevel: true, // 混淆顶层作用域中的变量名
                },
                compress: {
                    drop_console: true, // 删除 console 语句
                    drop_debugger: true, // 删除 debugger 语句
                    dead_code: true, // 移除无效代码
                    passes: 3, // 压缩优化的次数
                },
                format: {
                    comments: false, // 删除所有注释
                }
            })
        ],
        resolve: {
            alias: {
                '@': path.resolve(__dirname, './src')
            },
        },
        server: {
            host: "0.0.0.0",
            port: "5173"
        },
        build: {
            outDir: 'dist',
            sourcemap: false, // 构建后不生成 source map 文件
            cssCodeSplit: true, // 保持 CSS 文件独立分离
            minify: 'terser', // 使用 terser 进行最小化
            rollupOptions: {
                output: {
                    manualChunks: () => 'everything.js', // 将所有 JavaScript 合并到一个文件
                    entryFileNames: 'assets/[name].js', // JS 文件的命名格式
                    assetFileNames: 'assets/[name].[ext]' // CSS 文件的命名格式
                }
            }
        },
        esbuild: {
            drop: ['console', 'debugger'], // 构建时移除 console 和 debugger 语句
        }
    });
}
