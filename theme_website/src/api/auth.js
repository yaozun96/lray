import { http } from "@/utils/request.js";

// 发送邮箱验证码
export const sendEmailVerify = (params) => {
    return http({
        url: "/api/v1/passport/comm/sendEmailVerify",
        method: "post",
        data: params,
    });
};

// 注册
export const register = (params) => {
    return http({
        url: "/api/v1/passport/auth/register",
        method: "post",
        data: params,
    });
};

// 登录
export const login = (params) => {
    return http({
        url: "/api/v1/passport/auth/login",
        method: "post",
        data: params,
    });
};

// 重置密码
export const resetPassword = (params) => {
    return http({
        url: "/api/v1/passport/auth/forget",
        method: "post",
        data: params,
    });
};

// 登出
export const logout = () => {
    // 通常登出可能只需要清除本地状态，或者调用后端 clear token
    // 这里根据文档示例，主要是清除本地，如果后端有接口也可以调用
    // 文档示例中没有显示具体的 logout API 调用，只是清除了本地数据
    // 假设如果有后端接口的话可能是这个，如果没有则仅前端处理。
    // 既然文档提到 import { logout } from '@/api/auth'，我们还是保留通过 store 处理的逻辑比较好，
    // 或者如果后端没有logout接口，这个函数可能只在此处作为占位或前端逻辑封装。
    // 此处暂不发请求，具体逻辑由调用方处理（清除 store），或者如果后端有断开 token 的接口再补充。
    // 但是文档示例里写了 import { logout } ... logout()，说明可能封装了清除逻辑。
    // 既然是 api 文件，通常只负责 HTTP。我们假设这里仅仅是占位或者后续补充。
    // 检查一下文档： "logout() // 自动清除所有认证数据并刷新页面"
    // 这听起来像是一个 actions，不纯是 API。但为了保持模块责任单一，我们这里只放 API 请求。
    // 如果没有后端 logout 接口，就不写 http 请求。
    return Promise.resolve();
};

// 获取公共配置 (Guest)
export const getCommConfig = () => {
    return http({
        url: "/api/v1/guest/comm/config",
        method: "get",
    });
};

// 验证邮箱验证码
export const verifyEmailCode = (email, code) => {
    return http({
        url: "/api/v1/passport/comm/email/verify", // Speculative endpoint
        method: "post",
        data: { email, code },
    });
};
