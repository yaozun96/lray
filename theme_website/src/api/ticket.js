import { http } from "@/utils/request.js";

// 创建工单
export const createTicket = (params) => {
    return http({
        url: "/api/v1/user/ticket/save",
        method: "post",
        data: params,
    });
};

// 获取工单列表
export const fetchTicketList = () => {
    return http({
        url: "/api/v1/user/ticket/fetch",
        method: "get",
    });
};

// 获取工单详情
export const fetchTicketDetail = (id) => {
    return http({
        url: "/api/v1/user/ticket/fetch",
        method: "get",
        params: { id }
    });
};

// 关闭工单
export const closeTicket = (id) => {
    return http({
        url: "/api/v1/user/ticket/close",
        method: "post",
        data: { id }
    });
};

// 回复工单
export const replyTicket = (id, message) => {
    return http({
        url: "/api/v1/user/ticket/reply",
        method: "post",
        data: { id, message },
    });
};
