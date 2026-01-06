import { http } from "@/utils/request.js";

// 获取用户信息
export const getUserInfo = () => {
    return http({
        url: "/api/v1/user/info",
        method: "get",
    });
};

// 修改密码
// 获取用户配置 (Logged In)
export const getUserConfig = () => {
    return http({
        url: "/api/v1/user/comm/config",
        method: "get",
    });
};

export const changePassword = (params) => {
    return http({
        url: "/api/v1/user/changePassword",
        method: "post",
        data: params,
    });
};

// 兑换礼品卡
export const redeemGiftCard = (code) => {
    return http({
        url: "/api/v1/user/coupon/check", // 注意：文档里是 redeemGiftCard('CODE')，通常是对接到某个 endpoint
        // 检查 API_EXAMPLES.md 里的具体实现细节没给全 URL，只给了函数名。
        // 根据一般 v2board 结构，可能是 /api/v1/user/coupon/check (查券) 或者 /api/v1/user/recharge (充值)
        // 如果是礼品卡充值余额，通常是 /api/v1/user/recharge?
        // 让我们再确认一下文档的 "兑换礼品卡" 上下文。
        // 例子： redeemGiftCard('GIFT-CODE')
        // 假设这是一个自定义的 endpoint，或者是标准的充值接口。
        // 暂时用 /api/v1/user/giftcard/redeem 占位，或者如果用户有更具体的 v2board 经验。
        // 常见的 v2board 充值卡接口是 POST /api/v1/user/payment/recharge (method=giftcard?)
        // 稍微保守一点，如果不确定 URL，可以先留空或者根据上下文猜测。
        // 实际上 v2board 旧版通常没有专门 giftcard 兑换，通常是 recharge 接口。
        // 我们假设是 /api/v1/user/recharge，并带上参数。
        // 不过为了确保准确，我会在 task 中标记需要确认，但这里先写一个推测的。
        // 修正：API文档里写了 import { redeemGiftCard }，没有写 url。
        // 考虑到这是重构，我们应该尽量依据文档。文档里没写 URL，只写了 fetchPlans 等。
        // 让我再看一眼 API_EXAMPLES.md....
        // 并没有写 URL，只写了 JS 代码。
        // 我必须假设标准的 v2board API 或者根据旧代码推断。
        // 旧代码里没有这个。
        // 既然 base 是 v2board，标准 v2board 接口供参考：
        // 注册: /api/v1/passport/auth/register
        // 登录: /api/v1/passport/auth/login
        // 个人信息: /api/v1/user/info
        // 我们先写常用的。
        url: "/api/v1/user/giftcard/redeem", // 这是一个猜测
        method: "post",
        data: { code }
    });
};

// 重置订阅链接
export const resetSubscribeLink = () => {
    return http({
        url: "/api/v1/user/resetSecurity", // Common v2board endpoint for resetting subscribe token/uuid
        method: "get",
    });
};

// 创建充值订单
export const createRechargeOrder = (amount) => {
    return http({
        url: "/api/v1/user/recharge/create",
        method: "post",
        data: { amount }, // 金额单位：分
    });
};

// 结算充值订单
export const checkoutRechargeOrder = (trade_no, method) => {
    return http({
        url: "/api/v1/user/recharge/checkout",
        method: "post",
        data: { trade_no, method },
    });
};

// 获取充值奖励配置
export const getRechargeBonusConfig = () => {
    return http({
        url: "/api/v1/user/recharge/bonus-config",
        method: "get",
    });
};

// 获取 Telegram Bot 信息
export const getTelegramBotInfo = () => {
    return http({
        url: "/api/v1/user/telegram/getBotInfo",
        method: "get",
    });
};