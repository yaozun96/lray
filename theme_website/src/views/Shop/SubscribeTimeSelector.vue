<script setup lang="ts">
import { computed } from "vue";
import { useShop } from "./useShop";
import { Check, Star, X, Infinity, CalendarClock, MessageSquareText, Radio, Rocket } from 'lucide-vue-next';

const { selectedPlanType, planTypeOptions, hasBothPlanTypes, subscribeForm, subscribeFilterPlans, couponData } = useShop();

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

// 获取套餐的徽章信息
const getPlanBadge = (plan: any) => {
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
const getPlanMonthlyPrice = (plan: any) => {
  // 永久套餐显示一次性价格
  if (selectedPlanType.value === 'onetime') {
    const price = plan.onetime_price ? plan.onetime_price / 100 : 0;
    return applyCouponDiscount(price);
  }

  // 根据当前选择的周期计算月均价
  const period = subscribeForm.value.period;

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

  return 0;
};

// 获取套餐的第一个可用周期名称
const getPlanFirstPeriod = (plan: any) => {
  // 根据当前选择的套餐类型显示对应周期
  if (selectedPlanType.value === 'onetime') {
    return '永久';
  } else {
    // 周期套餐统一显示"月"，因为价格已经是月均价
    return '月';
  }
};

// 获取套餐的特性列表
const getPlanFeatures = (plan: any) => {
  const planFeatureDisplay = window.config?.Buy?.plan_feature_display;
  if (!planFeatureDisplay) return [];

  try {
    const json = JSON.parse(plan.content);
    if (Array.isArray(json)) {
      return json.filter(item => item && typeof item === 'object' && item.feature);
    }
  } catch (e) {}
  return [];
};
</script>

<template>
  <div class="mb-8 sm:mb-10">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4 sm:mb-6">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">1</div>
        <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">选择订阅套餐</h2>
      </div>

      <!-- 套餐类型切换 Tab -->
      <div v-if="hasBothPlanTypes" class="flex flex-wrap gap-2">
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

    <div v-if="subscribeFilterPlans.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
      <div
        v-for="item in subscribeFilterPlans"
        :key="item.id"
        @click="subscribeForm.plan_id = item.id"
        class="relative bg-white dark:bg-zinc-900 rounded-2xl border-2 p-6 sm:p-7 cursor-pointer transition-all duration-300 overflow-hidden hover:-translate-y-1"
        :class="subscribeForm.plan_id === item.id
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
          v-if="subscribeForm.plan_id === item.id"
          class="absolute bottom-0 left-0 right-0 h-1 bg-blue-500"
        ></div>
      </div>
    </div>


  </div>
</template>

<style scoped>
</style>
