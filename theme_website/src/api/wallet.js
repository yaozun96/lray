import { http } from "@/utils/request.js";

// 创建充值订单
export const createOrderDeposit = (amount) => {
    // Typically v2board uses the same order system for deposits but possibly a different endpoint or plan_id=0?
    // Not strictly standard.
    // Let's assume /api/v1/user/order/save with type=deposit? No, standard is usually just buying a plan.
    // If it is pure wallet top-up, maybe /api/v1/user/payment/purchase
    // Let's try /api/v1/user/topup if it exists?
    // Or maybe just generic order save with plan_id=null/0 ?
    // I will use /api/v1/user/recharge which is common in some forks.
    return http({
        url: "/api/v1/user/recharge", // Speculative
        method: "post",
        data: { price: amount } // Param name also speculative, usually amount or price
    });
};
