<script setup lang="ts">
import { useShop } from "./useShop";
import { computed } from "vue";
import { Check, Tag } from 'lucide-vue-next';

const { subscribeForm, subscribeFilterPlans, subscribeFilterPlanTimes, couponData } = useShop();

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

// 计算月均价格和节省百分比
const cpData = computed(() => {
  const plan = subscribeFilterPlans.value.find((p) => p.id === subscribeForm.value.plan_id);

  let originalMonthlyPrice = null;
  let monthlyPriceForQuarter = null;
  let monthlyPriceForHalfYear = null;
  let monthlyPriceForYear = null;
  let monthlyPriceForTwoYears = null;
  let monthlyPriceForThreeYears = null;
  let savingsPercentQuarter = null;
  let savingsPercentHalfYear = null;
  let savingsPercentYear = null;
  let savingsPercentTwoYears = null;
  let savingsPercentThreeYears = null;

  if (plan) {
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

  return {
    originalMonthlyPrice,
    monthlyPriceForQuarter,
    monthlyPriceForHalfYear,
    monthlyPriceForYear,
    monthlyPriceForTwoYears,
    monthlyPriceForThreeYears,
    savingsPercentQuarter,
    savingsPercentHalfYear,
    savingsPercentYear,
    savingsPercentTwoYears,
    savingsPercentThreeYears,
  };
});
</script>

<template>
  <div class="mb-8 sm:mb-10">
    <div class="flex items-center gap-3 mb-4 sm:mb-6">
      <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">2</div>
      <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">选择周期</h2>
    </div>

    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
      <div
        v-for="item in subscribeFilterPlanTimes"
        :key="item.id"
        @click="subscribeForm.period = item.id"
        class="relative bg-white dark:bg-zinc-900 rounded-xl border-2 p-4 cursor-pointer transition-all duration-200"
        :class="subscribeForm.period === item.id
          ? 'border-blue-500'
          : 'border-zinc-200 dark:border-zinc-800 hover:border-zinc-300 dark:hover:border-zinc-700'"
      >
        <div class="flex items-center justify-between">
          <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ item.display }}</span>
          <div
            class="w-5 h-5 rounded-full border-2 flex items-center justify-center"
            :class="subscribeForm.period === item.id
              ? 'border-blue-500 bg-blue-500'
              : 'border-zinc-300 dark:border-zinc-600'"
          >
            <Check v-if="subscribeForm.period === item.id" class="w-3 h-3 text-white" />
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
</template>

<style scoped>
</style>
