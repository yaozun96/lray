import {http} from "@/utils/request.js";
import hr from "markdown-it/lib/rules_block/hr.mjs";

export const PlanList=()=>{
    return http({
        url:"api/v1/user/plan/fetch"
    })
}

export const Order=()=>{
    return http({
        url:'api/v1/user/order/fetch'
    })
}

export const Plan_item=(id)=>{
    return http({
        url:"api/v1/user/plan/fetch?id="+id
    })
}

export const Plan_Coupon=(data)=>{
    return http({
        url:"api/v1/user/coupon/check",
        method:"post",
        data
    })
}

export const Plan_Save=(data)=>{
    return http({
        url:"api/v1/user/order/save",
        method:"post",
        data
    })
}

export const Plan_Detail=(id)=>{
    return http({
        url:"api/v1/user/order/detail?trade_no="+id
    })
}

// 支付
export const Plan_CheckOut=(data)=>{
    return http({
        url:"api/v1/user/order/checkout",
        method:"post",
        data
    })
}

export const Plan_Way=()=>{
    return http({
        url:"api/v1/user/order/getPaymentMethod"
    })
}

export const Plan_Cancel=(data)=>{
    return http({
        url:"api/v1/user/order/cancel",
        method:"post",
        data
    })
}