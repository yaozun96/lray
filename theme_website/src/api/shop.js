import { http } from "@/utils/request.js";

// 获取套餐列表
export const fetchPlans = () => {
    return http({
        url: "/api/v1/user/plan/fetch",
        method: "get",
    });
};

// 验证优惠券
export const verifyCoupon = (code, plan_id) => {
    return http({
        url: "/api/v1/user/coupon/check",
        method: "post",
        data: { code, plan_id },
    });
};

// 创建订单
export const submitOrder = (params) => {
    return http({
        url: "/api/v1/user/order/save",
        method: "post",
        data: params,
    });
};

// 获取支付方式
export const getPaymentMethods = () => {
    return http({
        url: "/api/v1/user/order/getPaymentMethod",
        method: "get",
    });
};

// 结算订单
export const checkoutOrder = (trade_no, method_id) => {
    return http({
        url: `/api/v1/user/order/checkout`,
        method: "post",
        data: { trade_no, method: method_id },
    });
};

// 检查订单状态
export const checkOrderStatus = (trade_no) => {
    return http({
        url: `/api/v1/user/order/detail`,
        method: "get",
        params: { trade_no },
    });
};
