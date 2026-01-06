import { http } from "@/utils/request.js";

// 获取流量日志
export const getTrafficLog = () => {
    return http({
        url: "/api/v1/user/stat/getTrafficLog",
        method: "get",
    });
};
