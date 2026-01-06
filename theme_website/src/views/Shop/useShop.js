import { createSharedComposable } from "@vueuse/core";
import { computed, ref, watch } from "vue";
import { http } from "@/utils/request.js";
import { message } from "ant-design-vue";
import { login } from "@/api/auth.js";  // 引入登录接口
import { useInfoStore } from "@/stores/counter.js";
import { nextTick } from 'vue';
import { useRoute } from 'vue-router';

export const useShop = createSharedComposable(() => {
  const route = useRoute();
  const subscribes = ref([]);
  const selectedPlanType = ref('onetime');

  // 获取套餐的所有标签
  const getPlanTags = (plan) => {
    if (!plan.tags) return [];
    if (Array.isArray(plan.tags)) {
      return plan.tags.map(tag => {
        if (typeof tag === 'string') return tag;
        if (typeof tag === 'object' && tag.name) return tag.name;
        return '';
      }).filter(Boolean);
    }
    return [];
  };

  const planTypeOptions = computed(() => {
    const plans = subscribes.value || [];
    const options = [];
    const dynamicTags = new Map(); // { tag: { hasOnetime, hasCycle } }
    let hasOnetime = false;
    let hasCycle = false;

    plans.forEach(p => {
      const tags = getPlanTags(p);
      const isOnetime = p.onetime_price !== null;
      const isCycle = p.month_price !== null || p.quarter_price !== null ||
        p.half_year_price !== null || p.year_price !== null ||
        p.two_year_price !== null || p.three_year_price !== null;

      if (tags.length > 0) {
        tags.forEach(tag => {
          if (!dynamicTags.has(tag)) {
            dynamicTags.set(tag, { hasOnetime: false, hasCycle: false });
          }
          const tagInfo = dynamicTags.get(tag);
          if (isOnetime) tagInfo.hasOnetime = true;
          if (isCycle) tagInfo.hasCycle = true;
        });
      } else {
        // Only classify as Onetime/Cycle if NO tags are present
        if (isOnetime && !isCycle) hasOnetime = true;
        if (isCycle) hasCycle = true;
      }
    });

    // 1. Add standard types based on config order
    const planTypeOrder = window.config?.Buy?.plan_type_order || ['cycle', 'onetime'];
    const standardTypes = {
      cycle: { label: '周期套餐', value: 'cycle', tip: '流量每月账单日重置', exists: hasCycle },
      onetime: { label: '永久套餐', value: 'onetime', tip: '一次付费，永久使用', exists: hasOnetime }
    };

    planTypeOrder.forEach(type => {
      if (standardTypes[type] && standardTypes[type].exists) {
        options.push({ label: standardTypes[type].label, value: standardTypes[type].value, tip: standardTypes[type].tip });
      }
    });

    // 2. Add dynamic tags last with appropriate tips
    dynamicTags.forEach((info, tag) => {
      let tip = '';
      if (info.hasOnetime && !info.hasCycle) {
        tip = '一次付费，永久使用';
      } else if (info.hasCycle && !info.hasOnetime) {
        tip = '流量每月账单日重置';
      } else if (info.hasOnetime && info.hasCycle) {
        tip = '包含周期和永久套餐';
      }
      options.push({ label: tag, value: tag, isDynamic: true, tip });
    });

    return options;
  });
  const payMethods = ref([]);
  const selectedPayMethod = ref(null);
  const subscribeForm = ref({
    plan_id: null,
    period: null,
  });
  const accountForm = ref({
    email: '',
    password: '',
  });

  // 优惠码相关状态
  const couponCode = ref(null);
  const couponData = ref({
    status: false,
    type: 0,
    value: 0,
    plan_ids: null,
    period: null,
  });
  const lastAutoCoupon = ref(null);

  // 初始化数据
  const fetchInit = async () => {
    console.group('fetchInit');
    const extractRouteCoupon = () => {
      const coupon = route.query?.coupon;
      return typeof coupon === 'string' && coupon.trim() ? coupon.trim() : null;
    };

    const [resSubscribes, resPayMethods] = await Promise.all([
      http('api/v1/air/shop/fetch'),
      http('api/v1/air/getPaymentMethod'),
    ]);

    subscribes.value = resSubscribes.data;
    payMethods.value = resPayMethods.data;
    selectedPayMethod.value = payMethods.value[0].id;

    // 自动选择第一个标签分组
    const options = planTypeOptions.value;
    if (options.length > 0) {
      selectedPlanType.value = options[0].value;
    }

    // 确保数据存在，设置默认选项
    if (subscribeFilterPlans.value.length > 0) {
      // 优先选择有 _hidden 标签的套餐
      const planWithBadge = subscribeFilterPlans.value.find(plan => {
        // 检查 plan._hidden
        if (plan._hidden) return true;

        // 检查 content 中的 _hidden
        try {
          const content = JSON.parse(plan.content);
          if (content && typeof content === 'object' && !Array.isArray(content)) {
            if (content._hidden) return true;
          } else if (Array.isArray(content)) {
            return content.some(item => item && typeof item === 'object' && item._hidden);
          }
        } catch (e) {
          // JSON 解析失败，跳过
        }
        return false;
      });

      // 如果找到有 badge 的套餐，选择它；否则选择第一个
      const selectedPlan = planWithBadge || subscribeFilterPlans.value[0];
      subscribeForm.value.plan_id = selectedPlan.id;
      selectDefaultPeriod(selectedPlan.id);
    }

    console.groupEnd();

    // 在 Hash 模式下解析 URL 参数
    let couponParam = extractRouteCoupon();
    if (!couponParam) {
      couponParam = sessionStorage.getItem('appliedCoupon');
    }

    if (couponParam) {
      console.log('Applying coupon:', couponParam);  // 打印优惠码
      await autoApplyCoupon(couponParam);  // 自动应用优惠码
    } else {
      console.log('No coupon found in URL or localStorage');
    }
  };

  watch(
    () => route.query?.coupon,
    async (newCoupon, oldCoupon) => {
      if (newCoupon === oldCoupon) return;
      const couponParam = typeof newCoupon === 'string' && newCoupon.trim() ? newCoupon.trim() : null;
      if (!couponParam) return;
      if (couponParam === lastAutoCoupon.value) return;
      await autoApplyCoupon(couponParam);
    }
  );

  // 自动应用优惠码
  const autoApplyCoupon = async (coupon) => {
    // 设置优惠码
    couponCode.value = coupon;

    // 调用后端 API 验证优惠码是否有效
    const isValid = await validateCoupon(coupon);  // 验证优惠码是否有效

    if (isValid) {
      // 如果优惠码有效，存储到 sessionStorage 并自动应用
      sessionStorage.setItem('appliedCoupon', coupon);
      lastAutoCoupon.value = coupon;
      await couponValidate(); // 执行优惠码的应用逻辑
    } else {
      // 如果无效，不自动应用，也不显示错误提示
      console.log('Invalid coupon, not applying:', coupon);
      couponCode.value = '';  // 清空优惠码输入框
      sessionStorage.removeItem('appliedCoupon');  // 移除会话存储中的优惠码
    }
  };

  // 验证优惠码是否有效（通过 API）
  const validateCoupon = async (coupon) => {
    try {
      const response = await http('api/v1/air/coupon/check', {
        method: 'POST',
        data: {
          code: coupon,
          plan_id: subscribeForm.value.plan_id,  // 确保优惠码是针对当前计划的
        }
      });

      console.log('Coupon validation response:', response);

      // 根据后端 API 的返回数据来判断优惠码是否有效
      return response && response.data && response.data.value > 0;

    } catch (error) {
      // 捕获错误但不向用户显示，只在控制台记录
      console.error('Error validating coupon:', error);
      return false;  // 如果 API 请求失败，认为优惠码无效
    }
  };

  // 判断是否有两种类型的套餐
  const hasBothPlanTypes = computed(() => planTypeOptions.value.length > 1);

  // 过滤符合当前套餐类型的套餐列表
  const subscribeFilterPlans = computed(() => {
    return subscribes.value.filter((plan) => {
      const tags = getPlanTags(plan);
      const isTagged = tags.length > 0;

      const hasCycle = plan.month_price !== null || plan.quarter_price !== null || plan.half_year_price !== null ||
        plan.year_price !== null || plan.two_year_price !== null || plan.three_year_price !== null;

      if (selectedPlanType.value === 'onetime') {
        const hasOnetime = plan.onetime_price !== null;
        return hasOnetime && !hasCycle && !isTagged;
      } else if (selectedPlanType.value === 'cycle') {
        return hasCycle && !isTagged;
      } else {
        // Dynamic tag group
        return tags.includes(selectedPlanType.value);
      }
    });
  });

  // 过滤符合当前套餐类型的周期选项
  const subscribeFilterPlanTimes = computed(() => {
    const plan = subscribes.value.find(plan => plan.id === subscribeForm.value.plan_id);

    if (!plan) return null;

    let filterTimes = [];

    if (selectedPlanType.value === 'onetime') {
      // 永久套餐只显示永久选项
      filterTimes.push({ id: 'onetime_price', display: '永久' });
    } else {
      // 周期性套餐显示各周期选项
      if (plan.month_price) filterTimes.push({ id: 'month_price', display: '月付' });
      if (plan.quarter_price) filterTimes.push({ id: 'quarter_price', display: '季付' });
      if (plan.half_year_price) filterTimes.push({ id: 'half_year_price', display: '半年付' });
      if (plan.year_price) filterTimes.push({ id: 'year_price', display: '年付' });
      if (plan.two_year_price) filterTimes.push({ id: 'two_year_price', display: '两年' });
      if (plan.three_year_price) filterTimes.push({ id: 'three_year_price', display: '三年' });
    }

    return filterTimes;
  });

  // 计算可供显示的套餐列表
  const subscribeCpData = computed(() => {
    const list = [];
    subscribes.value.forEach(subscribe => {
      const priceTypes = [
        { type: 'month_price', period_pay: '月付', period_num: '30天' },
        { type: 'quarter_price', period_pay: '季付', period_num: '90天' },
        { type: 'half_year_price', period_pay: '半年付', period_num: '180天' },
        { type: 'year_price', period_pay: '年付', period_num: '365天' },
        { type: 'two_year_price', period_pay: '两年', period_num: '两年' },
        { type: 'three_year_price', period_pay: '三年', period_num: '三年' },
        { type: 'onetime_price', period_pay: '一次性', period_num: '永久' },
      ];
      priceTypes.forEach(priceType => {
        if (subscribe[priceType.type]) {
          list.push({
            id: subscribe.id,
            name: subscribe.name,
            period: priceType.type,
            period_pay: priceType.period_pay,
            period_num: priceType.period_num,
            price: subscribe[priceType.type],
            content: subscribe.content,
          });
        }
      });
    });
    return list;
  });

  const selectSubscribe = (subscribe) => {
    console.log('selectSubscribe ===> ', subscribe);
    subscribeForm.value.plan_id = subscribe.id;
    subscribeForm.value.period = subscribe.period;
    console.log('subscribeForm ===> ', subscribeForm.value);
  };

  // 验证优惠码
  const couponValidate = async () => {
    console.log('优惠码验证 ===> ', couponCode.value);
    if (!couponCode.value) {
      message.error('请输入优惠码');
      return;
    }
    const response = await http('api/v1/air/coupon/check', {
      method: 'POST',
      data: {
        code: couponCode.value,
        plan_id: subscribeForm.value.plan_id,
      }
    });
    console.log('优惠码验证响应 ===> ', response);
    console.log('subscribeForm ===> ', subscribeForm.value);

    if (response.data.limit_plan_ids && !response.data.limit_plan_ids.includes(subscribeForm.value.plan_id.toString())) {
      console.error('此优惠码不适用于当前套餐');
      message.error('此优惠码不适用于当前套餐');
      return;
    }
    if (response.data.limit_period && !response.data.limit_period.includes(subscribeForm.value.period)) {
      console.error('此优惠码不适用于当前套餐周期');
      message.error('此优惠码不适用于当前套餐周期');
      return;
    }
    // 在这里将返回的 name 赋值给 couponName
    couponData.value.name = response.data.name;  // 使用 name 作为优惠码的名称

    message.success('优惠码验证成功');
    couponData.value.status = true;
    couponData.value.type = response.data.type;
    couponData.value.value = response.data.value / 100;
    couponData.value.plan_ids = response.data.plan_ids;
    couponData.value.period = response.data.period;
    console.log('couponData ===> ', couponData.value);
  };

  // 支付页面计算支付价格
  const payCpData = computed(() => {
    const planId = subscribeForm.value.plan_id;
    const plan_period = subscribeForm.value.period;
    const plan = subscribeCpData.value.find(subscribe => subscribe.id === planId && subscribe.period === plan_period);
    if (!plan) return null;

    // 获取完整的套餐信息（包含所有价格）
    const fullPlan = subscribes.value.find(p => p.id === planId);

    const name = plan.name;
    const price = (plan.price * 0.01).toFixed(2) + ' ￥';
    const period = plan.period_num;

    // 计算月付原价 × 周期月数
    let originalPrice = null;
    if (fullPlan && fullPlan.month_price && plan_period !== 'month_price' && plan_period !== 'onetime_price') {
      const monthPrice = fullPlan.month_price / 100;
      let months = 1;
      if (plan_period === 'quarter_price') months = 3;
      else if (plan_period === 'half_year_price') months = 6;
      else if (plan_period === 'year_price') months = 12;
      else if (plan_period === 'two_year_price') months = 24;
      else if (plan_period === 'three_year_price') months = 36;

      originalPrice = (monthPrice * months).toFixed(2) + ' ￥';
    }

    // 计算优惠码抵扣金额和折扣百分比
    let couponNum = 0;
    let couponValue = 0;
    let couponName = '';  // 添加优惠码名称
    if (couponData.value.status) {
      if (couponData.value.type === 1) { // 固定金额折扣
        couponNum = couponData.value.value;
      } else if (couponData.value.type === 2) { // 按百分比折扣
        couponNum = plan.price * 0.01 * couponData.value.value;
      }
      couponName = couponData.value.name;  // 使用返回的 name 作为优惠码名称
    }

    const couponPrice = couponNum.toFixed(2) + '￥';
    const payPrice = (plan.price * 0.01 - couponNum).toFixed(2) + ' ￥';

    // 计算实付每月价格和节省百分比
    let payMonthlyPrice = null;
    let savingsPercent = null;
    if (plan_period !== 'onetime_price') {
      let months = 1;
      if (plan_period === 'month_price') months = 1;
      else if (plan_period === 'quarter_price') months = 3;
      else if (plan_period === 'half_year_price') months = 6;
      else if (plan_period === 'year_price') months = 12;
      else if (plan_period === 'two_year_price') months = 24;
      else if (plan_period === 'three_year_price') months = 36;

      const finalPrice = plan.price * 0.01 - couponNum;
      payMonthlyPrice = (finalPrice / months).toFixed(1);

      // 计算节省百分比（相比月付原价 × 月数）
      if (fullPlan && fullPlan.month_price && plan_period !== 'month_price') {
        const monthPrice = fullPlan.month_price / 100;
        const originalTotal = monthPrice * months;
        savingsPercent = Math.round((1 - finalPrice / originalTotal) * 100);
      }
    }

    return {
      name,
      price,
      originalPrice,
      period,
      couponPrice,
      couponName,  // 将优惠码名称传递
      payPrice,
      payMonthlyPrice,
      savingsPercent,
    };
  });




  const submitPay = async () => {
    // 校验邮箱和密码
    if (!accountForm.value.email) {
      message.error('请输入邮箱');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(accountForm.value.email)) {
      message.error('邮箱格式不正确');
      return;
    }
    if (!accountForm.value.password) {
      message.error('请输入密码');
      return;
    }
    if (accountForm.value.password.length < 8) {
      message.error('密码长度不少于8位');
      return;
    }

    console.group('submitPay');
    console.log('subscribeForm ===> ', subscribeForm.value);

    const data = {
      plan_id: subscribeForm.value.plan_id,
      period: subscribeForm.value.period,
      email: accountForm.value.email,
      password: accountForm.value.password,
      method: selectedPayMethod.value,
    };

    if (couponData.value.status) {
      data.coupon_code = couponCode.value;
    }

    // 执行支付请求并注册
    const response = await http('api/v1/air/order/pay', {
      method: 'POST',
      data: data,
    });
    console.log('支付响应 ===> ', response);

    // 从支付响应中获取 trade_no
    const trade_no = response.trade_no;

    // 如果支付请求返回成功，直接使用输入的邮箱和密码进行登录
    try {
      const loginResponse = await login({
        email: accountForm.value.email,
        password: accountForm.value.password
      });
      console.log('登录响应:', loginResponse);

      if (loginResponse && loginResponse.data && loginResponse.data.auth_data) {
        // 登录成功后，存储 token
        const Token = useInfoStore();  // 使用 useInfoStore
        Token.Set_Token(loginResponse.data.auth_data);  // 存储 token
        console.log('登录成功，存储的 Token:', loginResponse.data.auth_data);

        message.success('登录成功');

        // 确保 DOM 更新后再进行页面跳转
        nextTick(() => {
          // 跳转到订单详情页面，使用支付响应的 trade_no
          window.location.href = `/#/order/${trade_no}`;
        });
      } else {
        console.error('登录失败，未返回 auth_data', loginResponse);
        message.error('登录失败');
      }
    } catch (error) {
      console.error('登录请求失败:', error);
      message.error('登录请求失败');
    }

    console.groupEnd();
  };




  const selectDefaultPeriod = (planId) => {
    const plan = subscribes.value.find(p => p.id === planId);
    if (!plan) return;

    // 先检查当前选择的周期是否依然有效，如果有效则不变更
    if (subscribeForm.value.period && plan[subscribeForm.value.period]) {
      return;
    }

    if (selectedPlanType.value === 'onetime') {
      subscribeForm.value.period = 'onetime_price';
    } else {
      // 按周期从长到短排序，默认选择最长周期
      const periods = ['three_year_price', 'two_year_price', 'year_price', 'half_year_price', 'quarter_price', 'month_price'];
      for (const p of periods) {
        if (plan[p] !== null) {
          subscribeForm.value.period = p;
          break;
        }
      }
    }
  };

  // 监听套餐ID变化，自动选择第一个可用周期
  watch(() => subscribeForm.value.plan_id, (newId) => {
    if (newId) {
      selectDefaultPeriod(newId);
    }
  });

  // 监听套餐类型变化，自动选择该类型下的第一个套餐
  watch(selectedPlanType, () => {
    if (subscribeFilterPlans.value.length > 0) {
      // 优先选择有 _hidden 标签的套餐
      const planWithBadge = subscribeFilterPlans.value.find(plan => {
        if (plan._hidden) return true;
        try {
          const content = JSON.parse(plan.content);
          if (content && typeof content === 'object' && !Array.isArray(content)) {
            if (content._hidden) return true;
          } else if (Array.isArray(content)) {
            return content.some(item => item && typeof item === 'object' && item._hidden);
          }
        } catch (e) { }
        return false;
      });

      const selectedPlan = planWithBadge || subscribeFilterPlans.value[0];
      subscribeForm.value.plan_id = selectedPlan.id;
      subscribeForm.value.period = null; // 重置周期，让 selectDefaultPeriod 重新选择
      selectDefaultPeriod(selectedPlan.id);
    }
  });

  return {
    selectedPlanType,
    planTypeOptions,
    hasBothPlanTypes,
    subscribes,
    subscribeForm,
    payMethods,
    selectedPayMethod,
    accountForm,
    subscribeFilterPlans,
    subscribeFilterPlanTimes,
    subscribeCpData,
    couponCode,
    couponData,
    payCpData,
    fetchInit,
    selectSubscribe,
    couponValidate,
    submitPay,
  };
});
