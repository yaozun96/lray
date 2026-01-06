import './styles/main.css'
import { createApp } from 'vue'
import pinia from "@/stores/init.js";
import App from './App.vue'
import router from './router'
import { initAuth } from './utils/auth.js'
import { notifyApiError } from "./utils/error.js";
import Antd, { message, notification } from 'ant-design-vue';
import 'ant-design-vue/dist/reset.css';
import { setupDisableDevtool } from './plugins/disableDevtool.js';

message.config({
    top: '100px',
    duration: 3,
    maxCount: 3,
});

notification.config({
    top: '100px',
    duration: 3,
});

// 授权验证：应用启动前必须通过验证
if (!initAuth(window.config)) {
    throw new Error('Authorization verification failed');
}

if (import.meta.env.PROD) {
    setupDisableDevtool();
}

const app = createApp(App)

app.use(pinia)
app.use(router)
app.use(Antd)

app.mount('#app')



document.title = window.config.title

// 全局 Promise 错误兜底：确保所有 API 返回信息只需一次点击即可提示
window.addEventListener('unhandledrejection', (event) => {
    if (event.reason?.response?.status === 401) {
        return;
    }
    notifyApiError(event.reason);
});
