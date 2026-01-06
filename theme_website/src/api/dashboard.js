import { http } from "@/utils/request.js";

// 获取用户统计
export const getUserStats = () => {
    return http({
        url: "/api/v1/user/getStat",
        method: "get",
    });
};

// 获取订阅信息
export const getSubscribe = () => {
    return http({
        url: "/api/v1/user/getSubscribe",
        method: "get",
    });
};

// 获取公告列表
export const getNotices = () => {
    return http({
        url: "/api/v1/user/notice/fetch",
        method: "get",
    });
};

// 获取知识库
export const getKnowledge = (id) => {
    return http({
        url: "/api/v1/user/knowledge/fetch",
        method: "get",
        params: { id }
    });
};
