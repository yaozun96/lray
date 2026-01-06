import { http } from "@/utils/request.js";

// 获取订单列表
export const fetchOrderList = () => {
    return http({
        url: "/api/v1/user/order/fetch",
        method: "get",
    });
};

// 取消订单
export const cancelOrder = (trade_no) => {
    return http({
        url: "/api/v1/user/order/cancel",
        method: "post",
        data: { trade_no },
    });
};
