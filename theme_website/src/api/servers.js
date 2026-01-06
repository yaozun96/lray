import { http } from "@/utils/request.js";

// 获取节点列表
export const fetchServerNodes = () => {
    return http({
        url: "/api/v1/user/server/fetch",
        method: "get",
    });
};
