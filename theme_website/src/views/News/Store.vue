<script setup lang="ts">
import { computed, onBeforeMount, ref, onMounted, watch, nextTick, onActivated } from "vue";
import { useUserStore } from "@/stores/User.js";

import { cancelOrder } from "@/api/orderlist.js";
import { submitOrder as submitOrderApi, verifyCoupon, getPaymentMethods } from "@/api/shop.js";
import { message } from 'ant-design-vue';
import { useRouter, useRoute } from 'vue-router';
import { getAuthorizedApiOrigin } from '@/utils/auth.js';
import moment from 'moment';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

// Lucide Icons
import {
  Check,
  Tag,
  ShoppingCart,
  X,
  CreditCard,
  ChevronRight,
  Package,
  Star,
  Ticket,
  CheckCircle,
  Rocket,
  Infinity,
  CalendarClock,
  MessageSquareText,
  Radio,
} from 'lucide-vue-next';

// Banner 配置
const bannerConfig = computed(() => {
  const { title, description, features, background, elementImg } = window.config.Buy;
  return {
    title: title || '高可用的跨境网络互联服务',
    description: description || '',
    features: features || [],
    background,
    elementImg,
  };
});

interface IPayment {
  id: number;
  name: string;
  payment: string;
  icon?: any;
  handling_fee_fixed?: any;
  handling_fee_percent?: any;
}

interface IPlan {
  id: number;
  name: string;
  content: string;
  group_id: number;
  transfer_enable: number;
  device_limit: number | null;
  speed_limit?: any;
  show: number;
  sort?: any;
  renew: number;
  capacity_limit?: any;
  onetime_price: number | null;
  month_price: number | null;
  quarter_price: number | null;
  half_year_price: number | null;
  year_price: number | null;
  two_year_price: number | null;
  three_year_price: number | null;
  reset_price: number | null;
  reset_traffic_method?: any;
  created_at: number;
  updated_at: number;
  _hidden?: string;
}

const user = useUserStore();

const checkOrder = ref({
  open: false,
  trade_no: '',
  plan_name: '',
  is_recharge: false,
  created_at: 0,
});

const paymentOptions = ref<IPayment[]>([]);

const selectedPlanId = ref();
const selectedPlanTime = ref('year_price');
const selectedPaymentId = ref();

// 套餐类型选择
const selectedPlanType = ref('onetime');



// 获取套餐的所有标签
const getPlanTags = (plan: IPlan): string[] => {
  if (!plan.tags) return [];
  const tags: string[] = [];
  if (Array.isArray(plan.tags)) {
    plan.tags.forEach(tag => {
      if (typeof tag === 'string') tags.push(tag);
      else if (typeof tag === 'object' && tag.name) tags.push(tag.name);
    });
  }
  return tags;
};

// 动态计算可用套餐类型
const planTypeOptions = computed(() => {
  const plans = user.PlanList || [];
  const options = [];
  const dynamicTags = new Map<string, { hasOnetime: boolean, hasCycle: boolean }>();

  // 收集所有标签及其套餐类型
  plans.forEach(p => {
    const tags = getPlanTags(p);
    const hasOnetime = p.onetime_price !== null;
    const hasCycle = p.month_price !== null || p.quarter_price !== null ||
                     p.half_year_price !== null || p.year_price !== null ||
                     p.two_year_price !== null || p.three_year_price !== null;

    tags.forEach(t => {
      if (!dynamicTags.has(t)) {
        dynamicTags.set(t, { hasOnetime: false, hasCycle: false });
      }
      const tagInfo = dynamicTags.get(t)!;
      if (hasOnetime) tagInfo.hasOnetime = true;
      if (hasCycle) tagInfo.hasCycle = true;
    });
  });

  // 检查是否有未打标签的永久/周期套餐
  const hasOnetime = plans.some(p => {
    if (getPlanTags(p).length > 0) return false; // Exclude tagged plans
    const hasOnetime = p.onetime_price !== null;
    const hasCycle = p.month_price !== null || p.quarter_price !== null ||
                     p.half_year_price !== null || p.year_price !== null ||
                     p.two_year_price !== null || p.three_year_price !== null;
    return hasOnetime && !hasCycle;
  });

  const hasCycle = plans.some(p => {
    if (getPlanTags(p).length > 0) return false; // Exclude tagged plans
    return p.month_price !== null || p.quarter_price !== null || p.half_year_price !== null ||
           p.year_price !== null || p.two_year_price !== null || p.three_year_price !== null;
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

const hasBothPlanTypes = computed(() => planTypeOptions.value.length > 1);

const resolveIconUrl = (icon?: string | null): string => {
  if (!icon || typeof icon !== 'string') return '';
  if (/^(?:[a-z]+:)?\/\//i.test(icon) || icon.startsWith('data:')) return icon;
  const base = getAuthorizedApiOrigin();
  if (!base) return icon;
  const normalizedBase = base.replace(/\/+$/, '');
  const normalizedPath = icon.replace(/^\/+/, '');
  return `${normalizedBase}/${normalizedPath}`;
};

const discountElement = ref<HTMLElement | null>(null);
const displayCoupon = ref(false);
const couponCode = ref(null);
const couponData = ref({
  status: false,
  type: 0,
  value: 0,
  plan_ids: null,
  period: null,
});
const lastAutoCoupon = ref<string | null>(null);

// 静默验证优惠码
const validateCouponSilently = async (coupon: string) => {
  try {
    const response = await verifyCoupon(coupon, selectedPlanId.value);
    if (!response || !response.data) return false;
    if (response.data.limit_plan_ids && !response.data.limit_plan_ids.includes(selectedPlanId.value.toString())) return false;
    if (response.data.limit_period && !response.data.limit_period.includes(selectedPlanTime.value.toString())) return false;
    return response.data.value > 0;
  } catch (error) {
    return false;
  }
};

const couponValidate = async () => {
  if (!couponCode.value) {
    message.error('请输入优惠码');
    return;
  }

  const response = await verifyCoupon(couponCode.value, selectedPlanId.value);

  if (response.data.limit_plan_ids && !response.data.limit_plan_ids.includes(selectedPlanId.value.toString())) {
    message.error('此优惠码不适用于当前套餐');
    return;
  }
  if (response.data.limit_period && !response.data.limit_period.includes(selectedPlanTime.value.toString())) {
    message.error('此优惠码不适用于当前套餐周期');
    return;
  }

  sessionStorage.setItem('appliedCoupon', couponCode.value);
  message.success('优惠码验证成功');

  couponData.value.status = true;
  couponData.value.type = response.data.type;
  couponData.value.value = response.data.value / 100;
  couponData.value.plan_ids = response.data.plan_ids;
  couponData.value.period = response.data.period;
};

const tryAutoApplyCoupon = async (couponParam?: string | null) => {
  const couponValue = typeof couponParam === 'string' ? couponParam.trim() : '';
  if (!couponValue || !selectedPlanId.value) return;
  if (lastAutoCoupon.value === couponValue && couponData.value.status) return;

  const isValid = await validateCouponSilently(couponValue);
  if (isValid) {
    couponCode.value = couponValue;
    await nextTick();
    await couponValidate();
    sessionStorage.setItem('appliedCoupon', couponValue);
    lastAutoCoupon.value = couponValue;
  } else if (sessionStorage.getItem('appliedCoupon') === couponValue) {
    sessionStorage.removeItem('appliedCoupon');
  }
};

const router = useRouter();
const route = useRoute();

const submitOrder = async () => {
  if (!selectedPlanId.value) {
    message.error('请选择套餐');
    return;
  }
  if (!selectedPlanTime.value || cpData.value.planTime === '') {
    message.error('请选择周期');
    return;
  }

  try {
    const order = await submitOrderApi({
      plan_id: selectedPlanId.value,
      period: selectedPlanTime.value,
      coupon_code: couponData.value.status ? couponCode.value : null,
    });

    const orderId = order.data;
    if (!orderId) {
      message.error('订单创建失败');
      return;
    }

    router.push({ name: 'Order', params: { id: orderId } });
  } catch (error) {
    message.error('订单创建失败');
  }
};

const orderPay = (orderId: string) => {
  router.push({ name: 'Order', params: { id: orderId } });
};

const orderCancel = async (orderId: string) => {
  await cancelOrder(orderId);
  message.success('取消订单成功');
  location.reload();
};

const getPlanType = (plan: IPlan) => {
  const tags = getPlanTags(plan);
  if (tags.length > 0) return tags[0]; // Return first tag as type
  
  if (plan.onetime_price !== null &&
      plan.month_price === null &&
      plan.quarter_price === null &&
      plan.half_year_price === null &&
      plan.year_price === null &&
      plan.two_year_price === null &&
      plan.three_year_price === null) {
    return 'onetime';
  }
  return 'cycle';
};

// 获取套餐的徽章信息
const getPlanBadge = (plan: IPlan) => {
  if (plan._hidden) return plan._hidden;
  try {
    const json = JSON.parse(plan.content);
    if (json && typeof json === 'object' && !Array.isArray(json) && json._hidden) {
      return json._hidden;
    }
    if (Array.isArray(json)) {
      for (const item of json) {
        if (item && typeof item === 'object' && item._hidden) {
          return item._hidden;
        }
      }
    }
  } catch (e) {}
  return null;
};

// 格式化流量
const formatTraffic = (bytes: number) => {
  if (bytes >= 1024 * 1024 * 1024 * 1024) {
    return (bytes / (1024 * 1024 * 1024 * 1024)).toFixed(0) + ' TB';
  }
  if (bytes >= 1024 * 1024 * 1024) {
    return (bytes / (1024 * 1024 * 1024)).toFixed(0) + ' GB';
  }
  return (bytes / (1024 * 1024)).toFixed(0) + ' MB';
};

// 应用优惠码折扣的辅助函数
const applyCouponDiscount = (price: number) => {
  if (!couponData.value.status || !price) return price;
  if (couponData.value.type === 1) {
    return Math.max(0, price - couponData.value.value);
  } else {
    return price * (1 - couponData.value.value);
  }
};

// 获取套餐的月均价格（根据当前选择的周期计算，并应用优惠码）
const getPlanMonthlyPrice = (plan: IPlan) => {
  // 永久套餐显示一次性价格
  if (selectedPlanType.value === 'onetime') {
    const price = plan.onetime_price ? plan.onetime_price / 100 : 0;
    return applyCouponDiscount(price);
  }

  // 根据当前选择的周期计算月均价
  const period = selectedPlanTime.value;

  if (period === 'onetime_price' && plan.onetime_price) {
    return applyCouponDiscount(plan.onetime_price / 100);
  }
  if (period === 'month_price' && plan.month_price) {
    return applyCouponDiscount(plan.month_price / 100);
  }
  if (period === 'quarter_price' && plan.quarter_price) {
    return applyCouponDiscount(plan.quarter_price / 100) / 3;
  }
  if (period === 'half_year_price' && plan.half_year_price) {
    return applyCouponDiscount(plan.half_year_price / 100) / 6;
  }
  if (period === 'year_price' && plan.year_price) {
    return applyCouponDiscount(plan.year_price / 100) / 12;
  }
  if (period === 'two_year_price' && plan.two_year_price) {
    return applyCouponDiscount(plan.two_year_price / 100) / 24;
  }
  if (period === 'three_year_price' && plan.three_year_price) {
    return applyCouponDiscount(plan.three_year_price / 100) / 36;
  }

  // 如果当前套餐没有选中的周期价格，显示该套餐可用的最长周期月均价
  if (plan.three_year_price) return applyCouponDiscount(plan.three_year_price / 100) / 36;
  if (plan.two_year_price) return applyCouponDiscount(plan.two_year_price / 100) / 24;
  if (plan.year_price) return applyCouponDiscount(plan.year_price / 100) / 12;
  if (plan.half_year_price) return applyCouponDiscount(plan.half_year_price / 100) / 6;
  if (plan.quarter_price) return applyCouponDiscount(plan.quarter_price / 100) / 3;
  if (plan.month_price) return applyCouponDiscount(plan.month_price / 100);
  if (plan.onetime_price) return applyCouponDiscount(plan.onetime_price / 100);

  return 0;
};

// 获取套餐的第一个可用周期名称
const getPlanFirstPeriod = (plan: IPlan) => {
  // 根据当前选择的套餐类型显示对应周期
  if (selectedPlanType.value === 'onetime') {
    return '永久';
  } else if (selectedPlanType.value === 'cycle') {
    // 周期套餐统一显示"月"，因为价格已经是月均价
    return '月';
  } else {
     // 动态组：如果选了永久显示永久，否则显示月
     if (selectedPlanTime.value === 'onetime_price') return '永久';
     return '月';
  }
};

// 获取套餐的特性列表
const getPlanFeatures = (plan: IPlan) => {
  const { plan_feature_display } = window.config.Buy;
  if (!plan_feature_display) return [];

  try {
    const json = JSON.parse(plan.content);
    if (Array.isArray(json)) {
      return json.filter(item => item && typeof item === 'object' && item.feature);
    }
  } catch (e) {}
  return [];
};

const cpData = computed(() => {
  const { order_tips } = window.config.Buy;
  const orderTips = order_tips || '检查到你还有未支付的订单，点击下方的「支付订单」按钮完成支付，或者点击下方的取消按钮取消订单';
  const plans = user.PlanList as IPlan[] | undefined;

  let filterPlans: IPlan[] = [];
  let plan = null;
  let planName = '';
  let planTime = '';
  let planPrice = 0;

  let monthlyPriceForQuarter = null;
  let monthlyPriceForHalfYear = null;
  let monthlyPriceForYear = null;
  let monthlyPriceForTwoYears = null;
  let monthlyPriceForThreeYears = null;
  let originalMonthlyPrice = null;
  let savingsPercentQuarter = null;
  let savingsPercentHalfYear = null;
  let savingsPercentYear = null;
  let savingsPercentTwoYears = null;
  let savingsPercentThreeYears = null;
  let filterTimes: { id: string; display: string }[] = [];

  if (plans) {
    // 按类型过滤套餐
    filterPlans = plans.filter((p) => {
      const tags = getPlanTags(p);
      const isTagged = tags.length > 0;
      
      const hasOnetime = p.onetime_price !== null;
      const hasCycle = p.month_price !== null || p.quarter_price !== null ||
                       p.half_year_price !== null || p.year_price !== null ||
                       p.two_year_price !== null || p.three_year_price !== null;

      if (selectedPlanType.value === 'onetime') {
         return hasOnetime && !hasCycle && !isTagged;
      } else if (selectedPlanType.value === 'cycle') {
         return hasCycle && !isTagged;
      } else {
         // 动态标签组匹配
         return tags.includes(selectedPlanType.value);
      }
    });

    // 排序逻辑：价格从低到高
    filterPlans.sort((a, b) => {
      // Helper to get sort price
      const getPrice = (plan) => {
         if (selectedPlanType.value === 'onetime') return plan.onetime_price || 0;
         if (selectedPlanType.value === 'cycle') {
             const prices = [plan.month_price, plan.quarter_price, plan.half_year_price, plan.year_price, plan.two_year_price, plan.three_year_price].filter(p => p!==null);
             return prices.length ? Math.min(...prices) : 0;
         }
         // Dynamic: min of any valid price
         const allPrices = [plan.onetime_price, plan.month_price, plan.quarter_price, plan.half_year_price, plan.year_price, plan.two_year_price, plan.three_year_price].filter(p => p!==null);
         return allPrices.length ? Math.min(...allPrices) : 0;
      };
      
      return getPrice(a) - getPrice(b);
    });

    plan = filterPlans.find((item) => item.id === selectedPlanId.value);

    if (!plan && filterPlans.length > 0) {
      selectedPlanId.value = filterPlans[0].id;
      plan = filterPlans[0];
    }

    // 获取当前能够显示的周期列表
    if (plan) {
      // 根据套餐类型显示周期选项
      if (selectedPlanType.value === 'onetime') {
        filterTimes.push({ id: 'onetime_price', display: '永久' });
      } else if (selectedPlanType.value === 'cycle') {
        if (plan.month_price !== null) filterTimes.push({ id: 'month_price', display: '月付' });
        if (plan.quarter_price !== null) filterTimes.push({ id: 'quarter_price', display: '季付' });
        if (plan.half_year_price !== null) filterTimes.push({ id: 'half_year_price', display: '半年付' });
        if (plan.year_price !== null) filterTimes.push({ id: 'year_price', display: '年付' });
        if (plan.two_year_price !== null) filterTimes.push({ id: 'two_year_price', display: '两年付' });
        if (plan.three_year_price !== null) filterTimes.push({ id: 'three_year_price', display: '三年付' });
      } else {
         // 动态组：显示所有可用周期
        if (plan.onetime_price !== null) filterTimes.push({ id: 'onetime_price', display: '永久' });
        if (plan.month_price !== null) filterTimes.push({ id: 'month_price', display: '月付' });
        if (plan.quarter_price !== null) filterTimes.push({ id: 'quarter_price', display: '季付' });
        if (plan.half_year_price !== null) filterTimes.push({ id: 'half_year_price', display: '半年付' });
        if (plan.year_price !== null) filterTimes.push({ id: 'year_price', display: '年付' });
        if (plan.two_year_price !== null) filterTimes.push({ id: 'two_year_price', display: '两年付' });
        if (plan.three_year_price !== null) filterTimes.push({ id: 'three_year_price', display: '三年付' });
      }

      const monthPriceInYuan = plan.month_price ? plan.month_price / 100 : 0;
      const quarterPriceInYuan = plan.quarter_price ? plan.quarter_price / 100 : 0;
      const halfYearPriceInYuan = plan.half_year_price ? plan.half_year_price / 100 : 0;
      const yearPriceInYuan = plan.year_price ? plan.year_price / 100 : 0;
      const twoYearPriceInYuan = plan.two_year_price ? plan.two_year_price / 100 : 0;
      const threeYearPriceInYuan = plan.three_year_price ? plan.three_year_price / 100 : 0;

      // 月付原价
      if (monthPriceInYuan > 0) {
        originalMonthlyPrice = monthPriceInYuan;
      }

      // 应用优惠码折扣的辅助函数
      const applyCouponDiscount = (price: number) => {
        if (!couponData.value.status || !price) return price;
        // type 1: 固定金额折扣, type 2: 百分比折扣
        if (couponData.value.type === 1) {
          return Math.max(0, price - couponData.value.value);
        } else {
          return price * (1 - couponData.value.value);
        }
      };

      // 季付：总价 / 3个月
      if (quarterPriceInYuan > 0) {
        const discountedPrice = applyCouponDiscount(quarterPriceInYuan);
        monthlyPriceForQuarter = (discountedPrice / 3).toFixed(1);
        if (monthPriceInYuan > 0) {
          const originalTotal = monthPriceInYuan * 3;
          savingsPercentQuarter = Math.round((1 - discountedPrice / originalTotal) * 100);
        }
      }

      // 半年付：总价 / 6个月
      if (halfYearPriceInYuan > 0) {
        const discountedPrice = applyCouponDiscount(halfYearPriceInYuan);
        monthlyPriceForHalfYear = (discountedPrice / 6).toFixed(1);
        if (monthPriceInYuan > 0) {
          const originalTotal = monthPriceInYuan * 6;
          savingsPercentHalfYear = Math.round((1 - discountedPrice / originalTotal) * 100);
        }
      }

      // 年付：总价 / 12个月
      if (yearPriceInYuan > 0) {
        const discountedPrice = applyCouponDiscount(yearPriceInYuan);
        monthlyPriceForYear = (discountedPrice / 12).toFixed(1);
        if (monthPriceInYuan > 0) {
          const originalTotal = monthPriceInYuan * 12;
          savingsPercentYear = Math.round((1 - discountedPrice / originalTotal) * 100);
        }
      }

      // 两年付：总价 / 24个月
      if (twoYearPriceInYuan > 0) {
        const discountedPrice = applyCouponDiscount(twoYearPriceInYuan);
        monthlyPriceForTwoYears = (discountedPrice / 24).toFixed(1);
        if (monthPriceInYuan > 0) {
          const originalTotal = monthPriceInYuan * 24;
          savingsPercentTwoYears = Math.round((1 - discountedPrice / originalTotal) * 100);
        }
      }

      // 三年付：总价 / 36个月
      if (threeYearPriceInYuan > 0) {
        const discountedPrice = applyCouponDiscount(threeYearPriceInYuan);
        monthlyPriceForThreeYears = (discountedPrice / 36).toFixed(1);
        if (monthPriceInYuan > 0) {
          const originalTotal = monthPriceInYuan * 36;
          savingsPercentThreeYears = Math.round((1 - discountedPrice / originalTotal) * 100);
        }
      }
    }

    planName = plan ? plan.name : '';
    const time = filterTimes.find((item) => item.id === selectedPlanTime.value);
    if (time && plan) {
      planTime = time.display;
      planPrice = Math.ceil(plan[time.id]) / 100;
    }
  }

  // 计算月付原价 × 周期月数
  let calculatedOriginalPrice = null;
  if (plan && plan.month_price && selectedPlanTime.value !== 'month_price' && selectedPlanTime.value !== 'onetime_price') {
    const monthPrice = plan.month_price / 100;
    let months = 1;
    if (selectedPlanTime.value === 'quarter_price') months = 3;
    else if (selectedPlanTime.value === 'half_year_price') months = 6;
    else if (selectedPlanTime.value === 'year_price') months = 12;
    else if (selectedPlanTime.value === 'two_year_price') months = 24;
    else if (selectedPlanTime.value === 'three_year_price') months = 36;

    calculatedOriginalPrice = monthPrice * months;
  }

  let couponNum = 0;
  if (couponData.value.status) {
    couponNum = couponData.value.type === 1 ? couponData.value.value : parseFloat((planPrice * couponData.value.value).toFixed(2));
  }

  const payPrice = parseFloat((planPrice - couponNum).toFixed(2));

  // 计算实付每月价格和节省百分比
  let payMonthlyPrice = null;
  let savingsPercent = null;
  if (selectedPlanTime.value !== 'onetime_price') {
    let months = 1;
    if (selectedPlanTime.value === 'month_price') months = 1;
    else if (selectedPlanTime.value === 'quarter_price') months = 3;
    else if (selectedPlanTime.value === 'half_year_price') months = 6;
    else if (selectedPlanTime.value === 'year_price') months = 12;
    else if (selectedPlanTime.value === 'two_year_price') months = 24;
    else if (selectedPlanTime.value === 'three_year_price') months = 36;

    payMonthlyPrice = (payPrice / months).toFixed(1);

    // 计算节省百分比
    if (plan && plan.month_price && selectedPlanTime.value !== 'month_price') {
      const monthPrice = plan.month_price / 100;
      const originalTotal = monthPrice * months;
      savingsPercent = Math.round((1 - payPrice / originalTotal) * 100);
    }
  }

  return {
    orderTips,
    filterPlans,
    filterTimes,
    plan,
    planName,
    planTime,
    planPrice,
    calculatedOriginalPrice,
    couponNum,
    payPrice,
    payMonthlyPrice,
    savingsPercent,
    monthlyPriceForQuarter,
    monthlyPriceForHalfYear,
    monthlyPriceForYear,
    monthlyPriceForTwoYears,
    monthlyPriceForThreeYears,
    originalMonthlyPrice,
    savingsPercentQuarter,
    savingsPercentHalfYear,
    savingsPercentYear,
    savingsPercentTwoYears,
    savingsPercentThreeYears,
    hasBothPlanTypes: hasBothPlanTypes.value,
    getPlanType,
  };
});

watch(() => cpData.value.filterTimes, (times) => {
  if (times.length > 0) {
    const currentExists = times.find(t => t.id === selectedPlanTime.value);
    if (!currentExists) {
      selectedPlanTime.value = times[0].id;
    }
  }
}, { immediate: true });

// 监听套餐类型变化，自动选择该类型下的第一个套餐
watch(selectedPlanType, () => {
  if (cpData.value.filterPlans.length > 0) {
    // 优先选择有 _hidden 标签的套餐
    const planWithBadge = cpData.value.filterPlans.find(plan => {
      if (plan._hidden) return true;
      try {
        const content = JSON.parse(plan.content);
        if (content && typeof content === 'object' && !Array.isArray(content)) {
          if (content._hidden) return true;
        } else if (Array.isArray(content)) {
          return content.some(item => item && typeof item === 'object' && item._hidden);
        }
      } catch (e) {}
      return false;
    });

    const plan = planWithBadge || cpData.value.filterPlans[0];
    selectedPlanId.value = plan.id;
    // 重置周期选择（选择最长周期或永久）
    if (selectedPlanType.value === 'onetime') {
      selectedPlanTime.value = 'onetime_price';
    } else if (selectedPlanType.value === 'cycle') {
       // ... existing cycle logic ...
       const periods = ['three_year_price', 'two_year_price', 'year_price', 'half_year_price', 'quarter_price', 'month_price'];
       for (const p of periods) {
         if (plan[p] !== null) {
           selectedPlanTime.value = p;
           break;
         }
       }
    } else {
       // Dynamic: Prefer onetime if available, else max period
       if (plan.onetime_price !== null) selectedPlanTime.value = 'onetime_price';
       else {
         const periods = ['three_year_price', 'two_year_price', 'year_price', 'half_year_price', 'quarter_price', 'month_price'];
         for (const p of periods) {
            if (plan[p] !== null) {
              selectedPlanTime.value = p;
              break;
            }
         }
       }
    }
  }
});

// 获取套餐组图标
const getPlanIcon = (type: string) => {
  if (type === 'onetime') return Infinity;
  if (type === 'cycle') return CalendarClock;
  
  const lowerType = type.toLowerCase();
  if (lowerType.includes('tiktok') || lowerType.includes('直播') || lowerType.includes('live') || lowerType.includes('media')) {
    return Radio;
  }
  
  return Rocket;
};

// 检查未支付订单的函数
const checkUnpaidOrders = async () => {
  await user.Set_Order(true); // 强制刷新订单列表
  // 先重置弹窗状态
  checkOrder.value.open = false;
  checkOrder.value.trade_no = '';
  checkOrder.value.plan_name = '';

  // 检查是否有未支付订单
  if (user.Order && user.Order.length > 0) {
    const unpaidOrder = user.Order.find((order) => order.status === 0);
    if (unpaidOrder) {
      checkOrder.value.open = true;
      checkOrder.value.trade_no = unpaidOrder.trade_no;
      checkOrder.value.is_recharge = unpaidOrder.period === 'recharge';
      checkOrder.value.plan_name = checkOrder.value.is_recharge
        ? '余额充值'
        : (unpaidOrder.plan?.name || '未知套餐');
      checkOrder.value.created_at = unpaidOrder.created_at;
    }
  }
};

onBeforeMount(async () => {
  const extractCouponFromRoute = () => {
    const coupon = route.query?.coupon;
    return typeof coupon === 'string' && coupon.trim() ? coupon.trim() : null;
  };

  let couponParam = extractCouponFromRoute();
  if (!couponParam) {
    couponParam = sessionStorage.getItem('appliedCoupon');
  }

  await user.Set_PlanList();

  if (user.PlanList) {
    const options = planTypeOptions.value;
    if (options.length > 0) {
      selectedPlanType.value = options[0].value;
    }

    // 根据类型过滤套餐列表
    const filteredPlans = user.PlanList.filter(p => {
      const tags = getPlanTags(p);
      const isTagged = tags.length > 0;
      
      const hasCycle = p.month_price !== null || p.quarter_price !== null || p.half_year_price !== null ||
                       p.year_price !== null || p.two_year_price !== null || p.three_year_price !== null;
      
      if (selectedPlanType.value === 'onetime') return p.onetime_price !== null && !hasCycle && !isTagged;
      if (selectedPlanType.value === 'cycle') return hasCycle && !isTagged;
      return tags.includes(selectedPlanType.value);
    });

    // 优先选择有 _hidden 标签的套餐
    const planWithBadge = filteredPlans.find(plan => {
      if (plan._hidden) return true;
      try {
        const content = JSON.parse(plan.content);
        if (content && typeof content === 'object' && !Array.isArray(content)) {
          if (content._hidden) return true;
        } else if (Array.isArray(content)) {
          return content.some(item => item && typeof item === 'object' && item._hidden);
        }
      } catch (e) {}
      return false;
    });

    selectedPlanId.value = planWithBadge ? planWithBadge.id : (filteredPlans[0]?.id || user.PlanList[0].id);

    // 设置默认周期
    if (selectedPlanType.value === 'onetime') {
        selectedPlanTime.value = 'onetime_price';
    } else if (selectedPlanType.value === 'cycle') {
       // ... simplified
       const periods = ['three_year_price', 'two_year_price', 'year_price', 'half_year_price', 'quarter_price', 'month_price'];
       for (const p of periods) { if (planWithBadge[p]!==null) { selectedPlanTime.value = p; break; } }
    } else {
       if (planWithBadge.onetime_price !== null) selectedPlanTime.value = 'onetime_price';
       else {
         const periods = ['three_year_price', 'two_year_price', 'year_price', 'half_year_price', 'quarter_price', 'month_price'];
         for (const p of periods) { if (planWithBadge[p]!==null) { selectedPlanTime.value = p; break; } }
       }
    }
  }

  if (couponParam && selectedPlanId.value) {
    await nextTick();
    await new Promise(resolve => setTimeout(resolve, 100));
    await tryAutoApplyCoupon(couponParam);
  }

  getPaymentMethods().then((res) => {
    paymentOptions.value = (res.data || []).map((method: IPayment & { icon?: string | null }) => ({
      ...method,
      icon: resolveIconUrl(method.icon),
    }));
    if (paymentOptions.value.length > 0) {
      selectedPaymentId.value = paymentOptions.value[0].id;
    }
  });

  // 检查未支付订单
  checkUnpaidOrders();
});

watch(
  () => route.query?.coupon,
  async (newCoupon, oldCoupon) => {
    if (newCoupon === oldCoupon) return;
    const couponParam = typeof newCoupon === 'string' && newCoupon.trim() ? newCoupon.trim() : null;
    if (!couponParam) return;
    await tryAutoApplyCoupon(couponParam);
  }
);

// 组件激活时（从其他页面返回时）重新检查订单
onActivated(() => {
  checkUnpaidOrders();
});

// 每次组件挂载时检查未支付订单
onMounted(() => {
  checkUnpaidOrders();
});
</script>

<template>
  <div class="min-h-screen">

    <!-- 顶部 Banner - 星空背景 -->
    <div class="relative hidden sm:block overflow-hidden bg-gradient-to-b from-zinc-950 via-zinc-900 to-zinc-950">
      <!-- 星空动画 -->
      <div class="stars-container absolute inset-0">
        <div class="stars stars-small"></div>
        <div class="stars stars-medium"></div>
        <div class="stars stars-large"></div>
      </div>

      <!-- 流星 -->
      <div class="shooting-star shooting-star-1"></div>
      <div class="shooting-star shooting-star-2"></div>

      <div class="relative max-w-6xl mx-auto px-4 sm:px-6 py-6 lg:py-8 flex items-center justify-between z-10">
        <div class="max-w-xl lg:max-w-2xl">
          <!-- 标题 -->
          <h1 class="text-xl sm:text-2xl lg:text-3xl font-bold text-white mb-4">
            {{ bannerConfig.title }}
          </h1>

          <!-- 特性列表 -->
          <div v-if="bannerConfig.features && bannerConfig.features.length > 0" class="grid grid-cols-1 gap-3.5">
            <div
              v-for="(feature, index) in bannerConfig.features"
              :key="index"
              class="flex items-center gap-3"
            >
              <div class="w-5 h-5 rounded-full border-2 border-blue-400 flex items-center justify-center">
                <Check class="w-3 h-3 text-blue-400" stroke-width="3" />
              </div>
              <span class="text-base text-white font-medium">{{ feature }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧装饰图片 -->
      <div
        v-if="bannerConfig.elementImg"
        class="hidden lg:block absolute right-8 xl:right-16 bottom-1/2 translate-y-1/2 w-[320px] xl:w-[380px] z-10 pointer-events-none"
      >
        <div class="rocket-container">
          <img :src="bannerConfig.elementImg" alt="" class="w-full h-auto drop-shadow-2xl rocket-img" />
        </div>
      </div>
    </div>

    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12 lg:py-16 pb-32">

      <!-- 页面标题 -->
      <div class="mb-8 sm:mb-10">
        <h1 class="text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100">选择套餐</h1>
        <p class="text-sm sm:text-base text-zinc-500 mt-2">选择适合您的订阅计划</p>
      </div>

      <!-- 第一步：选择套餐 -->
      <div class="mb-8 sm:mb-10">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4 sm:mb-6">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">1</div>
            <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">选择订阅套餐</h2>
          </div>

          <!-- 套餐类型切换 Tab -->
          <div v-if="cpData.hasBothPlanTypes" class="flex flex-wrap gap-2">
            <button
              v-for="option in planTypeOptions"
              :key="option.value"
              @click="selectedPlanType = option.value"
              class="relative flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group"
              :class="selectedPlanType === option.value
                ? 'bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 shadow-lg'
                : 'bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700'"
            >
              <component :is="getPlanIcon(option.value)" class="w-4 h-4" />
              <span>{{ option.label }}</span>
              <!-- Tooltip -->
              <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 text-xs rounded-lg whitespace-nowrap opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 pointer-events-none z-10">
                {{ option.tip }}
                <div class="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-zinc-900 dark:border-t-zinc-100"></div>
              </div>
            </button>
          </div>
        </div>

        <div v-if="cpData.filterPlans.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <div
            v-for="item in cpData.filterPlans"
            :key="item.id"
            @click="selectedPlanId = item.id"
            class="relative bg-white dark:bg-zinc-900 rounded-2xl border-2 p-6 sm:p-7 cursor-pointer transition-all duration-300 overflow-hidden hover:-translate-y-1"
            :class="selectedPlanId === item.id
              ? 'border-blue-500 shadow-xl shadow-blue-500/15 -translate-y-1.5'
              : 'border-zinc-200 dark:border-zinc-800 hover:border-zinc-300 dark:hover:border-zinc-700 hover:shadow-lg'"
          >
            <!-- 徽章 - 斜角样式 -->
            <div
              v-if="getPlanBadge(item)"
              class="absolute top-5 -right-9 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-xs font-bold px-10 py-1.5 rotate-45 shadow-lg"
            >
              <Star class="w-3 h-3 inline mr-1" />
              {{ getPlanBadge(item) }}
            </div>

            <!-- 套餐名称 - 居中大标题 -->
            <h3 class="text-2xl sm:text-[28px] font-bold text-zinc-900 dark:text-zinc-100 text-center mb-2 tracking-tight">
              {{ item.name }}
            </h3>

            <!-- 价格 - 居中超大字体 -->
            <div class="flex items-end justify-center gap-1 my-5 sm:my-6">
              <span class="text-lg text-zinc-500 dark:text-zinc-400 pb-1">¥</span>
              <span class="text-5xl sm:text-[48px] font-extrabold text-blue-600 dark:text-blue-500 leading-none font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                {{ getPlanMonthlyPrice(item).toFixed(1) }}
              </span>
              <span class="text-lg text-zinc-500 dark:text-zinc-400 pb-1">/</span>
              <span class="text-lg text-zinc-500 dark:text-zinc-400 pb-1">{{ getPlanFirstPeriod(item) }}</span>
            </div>

            <!-- 特性列表 -->
            <div v-if="getPlanFeatures(item).length > 0" class="border-t border-zinc-200 dark:border-zinc-700 pt-5 mt-2 space-y-3">
              <div
                v-for="(feature, index) in getPlanFeatures(item)"
                :key="index"
                class="flex items-start gap-3"
                :class="feature.support !== false ? 'text-zinc-900 dark:text-zinc-100' : 'text-zinc-400 dark:text-zinc-500 opacity-60'"
              >
                <div
                  class="w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5"
                  :class="feature.support !== false ? 'bg-zinc-900 dark:bg-zinc-100' : 'bg-zinc-300 dark:bg-zinc-600'"
                >
                  <Check v-if="feature.support !== false" class="w-3.5 h-3.5 text-white dark:text-zinc-900" />
                  <X v-else class="w-3.5 h-3.5 text-white dark:text-zinc-900" />
                </div>
                <span class="text-[15px] leading-relaxed">{{ feature.feature || feature }}</span>
              </div>
            </div>

            <!-- 选中指示器 - 底部蓝色条 -->
            <div
              v-if="selectedPlanId === item.id"
              class="absolute bottom-0 left-0 right-0 h-1 bg-blue-500"
            ></div>
          </div>
        </div>


      </div>

      <!-- 第二步：选择周期 -->
      <div class="mb-8 sm:mb-10">
        <div class="flex items-center gap-3 mb-4 sm:mb-6">
          <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">2</div>
          <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">选择周期</h2>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
          <div
            v-for="item in cpData.filterTimes"
            :key="item.id"
            @click="selectedPlanTime = item.id"
            class="relative bg-white dark:bg-zinc-900 rounded-xl border-2 p-4 cursor-pointer transition-all duration-200"
            :class="selectedPlanTime === item.id
              ? 'border-blue-500'
              : 'border-zinc-200 dark:border-zinc-800 hover:border-zinc-300 dark:hover:border-zinc-700'"
          >
            <div class="flex items-center justify-between">
              <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ item.display }}</span>
              <div
                class="w-5 h-5 rounded-full border-2 flex items-center justify-center"
                :class="selectedPlanTime === item.id
                  ? 'border-blue-500 bg-blue-500'
                  : 'border-zinc-300 dark:border-zinc-600'"
              >
                <Check v-if="selectedPlanTime === item.id" class="w-3 h-3 text-white" />
              </div>
            </div>

            <!-- 节省百分比标签 -->
            <span
              v-if="item.id === 'quarter_price' && cpData.savingsPercentQuarter > 0"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-green-500 text-white text-xs font-bold rounded-full shadow-sm flex items-center gap-1"
            >
              <Tag class="w-3 h-3" />省{{ cpData.savingsPercentQuarter }}%
            </span>
            <span
              v-if="item.id === 'half_year_price' && cpData.savingsPercentHalfYear > 0"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-green-500 text-white text-xs font-bold rounded-full shadow-sm flex items-center gap-1"
            >
              <Tag class="w-3 h-3" />省{{ cpData.savingsPercentHalfYear }}%
            </span>
            <span
              v-if="item.id === 'year_price' && cpData.savingsPercentYear > 0"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-green-500 text-white text-xs font-bold rounded-full shadow-sm flex items-center gap-1"
            >
              <Tag class="w-3 h-3" />省{{ cpData.savingsPercentYear }}%
            </span>
            <span
              v-if="item.id === 'two_year_price' && cpData.savingsPercentTwoYears > 0"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-green-500 text-white text-xs font-bold rounded-full shadow-sm flex items-center gap-1"
            >
              <Tag class="w-3 h-3" />省{{ cpData.savingsPercentTwoYears }}%
            </span>
            <span
              v-if="item.id === 'three_year_price' && cpData.savingsPercentThreeYears > 0"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-green-500 text-white text-xs font-bold rounded-full shadow-sm flex items-center gap-1"
            >
              <Tag class="w-3 h-3" />省{{ cpData.savingsPercentThreeYears }}%
            </span>

            <!-- 月付：只显示原价 -->
            <div
              v-if="item.id === 'month_price' && cpData.originalMonthlyPrice"
              class="mt-3"
            >
              <span class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>

            <!-- 季付价格 -->
            <div
              v-if="item.id === 'quarter_price' && cpData.originalMonthlyPrice"
              class="mt-3 flex items-center gap-2"
            >
              <template v-if="cpData.savingsPercentQuarter > 0">
                <span class="text-zinc-400 line-through text-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
                <span class="px-2.5 py-1 bg-red-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.monthlyPriceForQuarter }}/月</span>
              </template>
              <span v-else class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>

            <!-- 半年付价格 -->
            <div
              v-if="item.id === 'half_year_price' && cpData.originalMonthlyPrice"
              class="mt-3 flex items-center gap-2"
            >
              <template v-if="cpData.savingsPercentHalfYear > 0">
                <span class="text-zinc-400 line-through text-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
                <span class="px-2.5 py-1 bg-red-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.monthlyPriceForHalfYear }}/月</span>
              </template>
              <span v-else class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>

            <!-- 年付价格 -->
            <div
              v-if="item.id === 'year_price' && cpData.originalMonthlyPrice"
              class="mt-3 flex items-center gap-2"
            >
              <template v-if="cpData.savingsPercentYear > 0">
                <span class="text-zinc-400 line-through text-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
                <span class="px-2.5 py-1 bg-red-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.monthlyPriceForYear }}/月</span>
              </template>
              <span v-else class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>

            <!-- 两年付价格 -->
            <div
              v-if="item.id === 'two_year_price' && cpData.originalMonthlyPrice"
              class="mt-3 flex items-center gap-2"
            >
              <template v-if="cpData.savingsPercentTwoYears > 0">
                <span class="text-zinc-400 line-through text-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
                <span class="px-2.5 py-1 bg-red-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.monthlyPriceForTwoYears }}/月</span>
              </template>
              <span v-else class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>

            <!-- 三年付价格 -->
            <div
              v-if="item.id === 'three_year_price' && cpData.originalMonthlyPrice"
              class="mt-3 flex items-center gap-2"
            >
              <template v-if="cpData.savingsPercentThreeYears > 0">
                <span class="text-zinc-400 line-through text-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
                <span class="px-2.5 py-1 bg-red-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.monthlyPriceForThreeYears }}/月</span>
              </template>
              <span v-else class="px-2.5 py-1 bg-zinc-500 text-white text-sm font-bold rounded-md shadow-sm">¥{{ cpData.originalMonthlyPrice }}/月</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 第三步：订单信息 -->
      <div class="mb-8 sm:mb-10">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4 sm:mb-6">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">3</div>
            <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">确认订单</h2>
          </div>

          <!-- 优惠码入口 -->
          <div>
            <div v-if="displayCoupon" class="flex gap-2">
              <div class="relative flex-1">
                <Ticket class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400" />
                <input
                  v-model="couponCode"
                  type="text"
                  placeholder="请输入优惠码"
                  class="w-full pl-10 pr-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <Button @click="couponValidate" size="sm">验证</Button>
            </div>
            <button
              v-else
              @click="displayCoupon = true"
              class="flex items-center gap-2 px-4 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            >
              <Ticket class="w-4 h-4" />
              <span>使用优惠码</span>
            </button>
          </div>
        </div>

        <!-- 订单详情卡片 -->
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <!-- 套餐 -->
            <div class="flex items-center justify-between px-4 sm:px-6 py-4">
              <span class="text-sm text-zinc-500">套餐</span>
              <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ cpData.planName }}</span>
            </div>

            <!-- 套餐周期 -->
            <div class="flex items-center justify-between px-4 sm:px-6 py-4">
              <span class="text-sm text-zinc-500">套餐周期</span>
              <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ cpData.planTime }}</span>
            </div>

            <!-- 原价（月付×周期） -->
            <div v-if="cpData.calculatedOriginalPrice" class="flex items-center justify-between px-4 sm:px-6 py-4">
              <span class="text-sm text-zinc-500">原价</span>
              <span class="font-medium font-[Rubik,ui-sans-serif,system-ui,sans-serif] line-through text-zinc-400">
                {{ cpData.calculatedOriginalPrice.toFixed(2) }} ¥
              </span>
            </div>

            <!-- 套餐价格 -->
            <div class="flex items-center justify-between px-4 sm:px-6 py-4">
              <span class="text-sm text-zinc-500">套餐价格</span>
              <span class="font-medium font-[Rubik,ui-sans-serif,system-ui,sans-serif] text-zinc-900 dark:text-zinc-100">
                {{ cpData.planPrice.toFixed(2) }} ¥
              </span>
            </div>

            <!-- 优惠码优惠 -->
            <div v-if="cpData.couponNum > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
              <span class="text-sm text-zinc-500">优惠码优惠</span>
              <span
                ref="discountElement"
                class="inline-flex items-center gap-1.5 px-3 py-1 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-sm font-bold rounded-lg"
              >
                <Tag class="w-3.5 h-3.5" />
                立减 {{ cpData.couponNum }} ¥
              </span>
            </div>

            <!-- 实付金额 -->
            <div class="flex items-center justify-between px-4 sm:px-6 py-5 bg-zinc-50 dark:bg-zinc-800/50">
              <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100">实付金额</span>
              <div class="flex flex-col items-end gap-1">
                <div v-if="cpData.payMonthlyPrice && selectedPlanTime !== 'month_price'" class="flex items-center gap-2">
                  <span
                    v-if="cpData.savingsPercent > 0"
                    class="inline-flex items-center gap-0.5 px-1.5 py-0.5 bg-green-500 text-white text-xs font-bold rounded"
                  >
                    <Tag class="w-3 h-3" />省{{ cpData.savingsPercent }}%
                  </span>
                  <span class="text-xs text-zinc-400">约 ¥{{ cpData.payMonthlyPrice }}/月</span>
                </div>
                <span class="text-2xl font-bold text-blue-600 dark:text-blue-500 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  {{ cpData.payPrice.toFixed(2) }} ¥
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 固定底部购买按钮 -->
    <div class="fixed bottom-0 left-0 right-0 z-40 bg-white/80 dark:bg-zinc-900/80 backdrop-blur-lg border-t border-zinc-200 dark:border-zinc-800">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-center">
        <Button
          @click="submitOrder"
          size="lg"
          class="px-12 sm:px-16 py-3 text-base sm:text-lg rounded-full"
        >
          <ShoppingCart class="w-5 h-5 mr-2" />
          创建订单
        </Button>
      </div>
    </div>

    <!-- 未支付订单弹窗 -->
    <Dialog v-model:open="checkOrder.open">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <div class="flex justify-center mb-3">
            <img
              src="/assets/illustrations/undraw_pay-with-credit-card_77g6.svg"
              alt="待支付"
              class="w-32 h-32 object-contain"
            />
          </div>
          <DialogTitle class="text-center">存在未支付订单</DialogTitle>
          <DialogDescription class="text-center">
            请先完成以下订单的支付
          </DialogDescription>
        </DialogHeader>

        <!-- 订单信息 -->
        <div class="my-4 p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50">
          <div class="flex items-center justify-between">
            <span class="text-sm text-zinc-500">订单内容</span>
            <span class="font-medium text-zinc-900 dark:text-zinc-100">
              {{ checkOrder.is_recharge ? checkOrder.plan_name : checkOrder.plan_name }}
            </span>
          </div>
          <div class="flex items-center justify-between mt-2">
            <span class="text-sm text-zinc-500">订单号</span>
            <span class="text-sm text-zinc-600 dark:text-zinc-400 font-mono">{{ checkOrder.trade_no }}</span>
          </div>
          <div class="flex items-center justify-between mt-2">
            <span class="text-sm text-zinc-500">创建时间</span>
            <span class="text-sm text-zinc-600 dark:text-zinc-400">{{ moment(checkOrder.created_at * 1000).format('YYYY-MM-DD HH:mm') }}</span>
          </div>
        </div>

        <div class="flex gap-3">
          <Button variant="outline" @click="orderCancel(checkOrder.trade_no)" class="flex-1">
            取消订单
          </Button>
          <Button @click="orderPay(checkOrder.trade_no)" class="flex-1">
            去支付
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
/* 星空背景 */
.stars-container {
  background: radial-gradient(ellipse at bottom, #1a1a2e 0%, #0a0a0f 100%);
}

.stars {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  animation: twinkle 4s ease-in-out infinite;
}

.stars-small {
  background-image:
    radial-gradient(1px 1px at 20px 30px, white, transparent),
    radial-gradient(1px 1px at 40px 70px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 50px 160px, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 90px 40px, white, transparent),
    radial-gradient(1px 1px at 130px 80px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 160px 120px, white, transparent),
    radial-gradient(1px 1px at 200px 50px, rgba(255,255,255,0.5), transparent),
    radial-gradient(1px 1px at 250px 100px, white, transparent),
    radial-gradient(1px 1px at 300px 70px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 350px 150px, white, transparent),
    radial-gradient(1px 1px at 400px 30px, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 450px 90px, white, transparent),
    radial-gradient(1px 1px at 500px 140px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 550px 60px, white, transparent),
    radial-gradient(1px 1px at 600px 120px, rgba(255,255,255,0.5), transparent);
  background-size: 650px 200px;
  animation-delay: 0s;
}

.stars-medium {
  background-image:
    radial-gradient(1.5px 1.5px at 100px 50px, white, transparent),
    radial-gradient(1.5px 1.5px at 200px 120px, rgba(255,255,255,0.9), transparent),
    radial-gradient(1.5px 1.5px at 300px 30px, white, transparent),
    radial-gradient(1.5px 1.5px at 400px 100px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1.5px 1.5px at 500px 70px, white, transparent),
    radial-gradient(1.5px 1.5px at 150px 140px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1.5px 1.5px at 350px 80px, white, transparent),
    radial-gradient(1.5px 1.5px at 550px 130px, rgba(255,255,255,0.6), transparent);
  background-size: 600px 180px;
  animation-delay: -1s;
}

.stars-large {
  background-image:
    radial-gradient(2px 2px at 80px 80px, white, transparent),
    radial-gradient(2px 2px at 240px 40px, rgba(255,255,255,0.9), transparent),
    radial-gradient(2px 2px at 400px 110px, white, transparent),
    radial-gradient(2px 2px at 520px 60px, rgba(255,255,255,0.8), transparent),
    radial-gradient(2.5px 2.5px at 180px 130px, #a5b4fc, transparent),
    radial-gradient(2.5px 2.5px at 460px 90px, #93c5fd, transparent);
  background-size: 580px 160px;
  animation-delay: -2s;
}

@keyframes twinkle {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* 流星 */
.shooting-star {
  position: absolute;
  width: 100px;
  height: 1px;
  background: linear-gradient(90deg, white, transparent);
  opacity: 0;
  transform: rotate(-45deg);
}

.shooting-star-1 {
  top: 20%;
  right: 20%;
  animation: shooting 6s ease-in-out infinite;
}

.shooting-star-2 {
  top: 40%;
  right: 40%;
  animation: shooting 6s ease-in-out infinite 3s;
}

@keyframes shooting {
  0% {
    opacity: 0;
    transform: translateX(0) translateY(0) rotate(-45deg);
  }
  5% {
    opacity: 1;
  }
  15% {
    opacity: 0;
    transform: translateX(-200px) translateY(200px) rotate(-45deg);
  }
  100% {
    opacity: 0;
    transform: translateX(-200px) translateY(200px) rotate(-45deg);
  }
}

/* 火箭动画 */
.rocket-container {
  position: relative;
  animation: rocketFloat 3s ease-in-out infinite;
}

.rocket-img {
  filter: drop-shadow(0 0 20px rgba(59, 130, 246, 0.5));
}

@keyframes rocketFloat {
  0%, 100% {
    transform: translateY(0) translateX(0);
  }
  50% {
    transform: translateY(-10px) translateX(5px);
  }
}
</style>
