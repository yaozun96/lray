// noinspection t

import { ref } from 'vue'
import { defineStore } from 'pinia'

import { getUserConfig } from "@/api/User.js";
import { getSubscribe, getNotices, getKnowledge } from "@/api/dashboard.js";
import { getUserInfo } from "@/api/User.js";
import { fetchOrderList } from "@/api/orderlist.js";
import { fetchPlans } from "@/api/shop.js";

export const useUserStore = defineStore('User', () => {
    // airBuddy 依赖信息
    const AirBuddyCopyRight = ref(false)
    AirBuddyCopyRight.value = import.meta.env.MODE === 'airbus'

    // 兑换码弹窗开关
    const ExchangeModal = ref(false)

    // 个人信息
    const Info = ref()
    const Set_Info = () => {
        return new Promise((resolve, reject) => {
            if (Info.value !== undefined) return resolve()
            getUserInfo().then(res => {
                Info.value = res.data
                return resolve()
            }).catch(() => { return reject() })
        })
    }

    // 公告
    const Notice = ref()
    const Set_Notice = () => {
        return new Promise((resolve, reject) => {
            if (Notice.value !== undefined) return resolve()
            getNotices().then(res => {
                Notice.value = res // 保存完整的响应对象 { data: [...] }
                return resolve()
            }).catch(() => { return reject() })
        })
    }

    const Config = ref()
    const Set_Config = () => {
        return new Promise((resolve, reject) => {
            if (Config.value !== undefined) return resolve()
            getUserConfig().then(res => {
                Config.value = res.data;
                return resolve()
            }).catch(() => { return reject() })
        })
    }

    const Subscribe = ref()
    const Set_Subscribe = () => {
        return new Promise((resolve, reject) => {
            if (Subscribe.value !== undefined) return resolve()
            getSubscribe().then(res => {
                Subscribe.value = res.data;
                return resolve()
            }).catch(() => { return reject() })
        })
    }

    function Init() {
        return Promise.all([Set_Info(), Set_Config(), Set_Notice(), Set_Subscribe()])
    }

    const Knowledge = ref()
    const Set_Knowledge = () => {
        return new Promise((y, n) => {
            if (Knowledge.value !== undefined) y()
            getKnowledge().then(res => {
                Knowledge.value = res.data
                y()
            }).catch(() => { n() })
        })
    }

    const PlanList = ref()
    const Set_PlanList = () => {
        return new Promise((resolve, reject) => {
            if (PlanList.value !== undefined) resolve()
            fetchPlans().then(res => {
                PlanList.value = res.data
                resolve()
            }).catch(() => reject())
        })
    }

    const Order = ref()
    const Set_Order = (forceRefresh = false) => {
        return new Promise((resolve, reject) => {
            if (Order.value && !forceRefresh) return resolve()
            fetchOrderList().then(res => {
                Order.value = res.data
                resolve()
            }).catch(() => reject())
        })
    }

    return {
        AirBuddyCopyRight,
        ExchangeModal,
        Init,
        Info,
        Notice,
        Config,
        Subscribe,
        Knowledge, Set_Knowledge,
        PlanList, Set_PlanList,
        Order, Set_Order
    }
})
