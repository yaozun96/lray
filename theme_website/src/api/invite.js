import { http } from "@/utils/request.js";

// 获取邀请数据
export const getInviteData = () => {
    return http({
        url: "/api/v1/user/invite/fetch",
        method: "get",
    });
};

// 生成邀请码
export const generateInviteCode = () => {
    return http({
        url: "/api/v1/user/invite/save",
        method: "get", // v2board usually uses GET for generating/refreshing code or POST? Standard seems to be GET /save or POST /save.
        // If it's generating a *new* code, likely /save. Let's assume GET as per some implementations or POST.
        // Documentation example: generateInviteCode() -> no args.
        // Assuming /api/v1/user/invite/save which is often used to refresh.
    });
};

// 佣金转账（划转至余额）
export const transferCommission = (params) => {
    return http({
        url: "/api/v1/user/transfer",
        method: "post",
        data: params,
    });
};

// 获取邀请详情 (commission logs)
export const fetchInviteDetails = () => {
    return http({
        url: "/api/v1/user/invite/details",
        method: "get",
    });
};
