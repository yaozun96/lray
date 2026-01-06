<script setup lang="ts">
import { ref, onMounted, computed, nextTick, watch } from 'vue';
import { message } from 'ant-design-vue';
import { useShop } from './useShop';
import confetti from "canvas-confetti";
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Ticket, ShoppingCart, X, Loader2, Gift, Tag } from 'lucide-vue-next';
import CaptchaDialog from '@/components/CaptchaDialog.vue';

const isPaymentReady = ref(false);
const displayCoupon = ref(false);
const discountElement = ref<HTMLElement | null>(null);

const { submitPay, accountForm, couponCode, couponValidate, payCpData, selectedPayMethod, payMethods, couponData } = useShop();

const isCaptchaVisible = ref(false);
const isWelcomeVisible = ref(false);

// 新人弹窗礼花动画
const triggerWelcomeConfetti = () => {
  confetti({
    particleCount: 80,
    spread: 70,
    origin: { x: 0.3, y: 0.5 },
    zIndex: 10000
  });
  confetti({
    particleCount: 80,
    spread: 70,
    origin: { x: 0.7, y: 0.5 },
    zIndex: 10000
  });
};

// 监听弹窗打开
watch(isWelcomeVisible, (val) => {
  if (val) {
    setTimeout(triggerWelcomeConfetti, 100);
  }
});

onMounted(() => {
  setTimeout(() => {
    // 如果没有优惠码，且 sessionStorage 中也没有已应用的优惠码，才显示弹窗
    if (!couponCode.value && !sessionStorage.getItem('appliedCoupon')) {
      isWelcomeVisible.value = true;
    }
  }, 500);
});

const applyWelcomeCoupon = () => {
  couponCode.value = 'welcome';
  isWelcomeVisible.value = false;
  // 立即保存到 sessionStorage，防止重复弹窗
  sessionStorage.setItem('appliedCoupon', 'welcome');
  couponValidate();
};

const initiatePayment = () => {
  if (!accountForm.value.email) {
    message.error("请输入邮箱");
    return;
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(accountForm.value.email)) {
    message.error("邮箱格式不正确");
    return;
  }
  if (!accountForm.value.password) {
    message.error("请输入密码");
    return;
  }
  if (accountForm.value.password.length < 8) {
    message.error("密码长度不少于8位");
    return;
  }

  isCaptchaVisible.value = true;
};

const handleCaptchaVerified = async () => {
  isPaymentReady.value = true;
  try {
    await submitPay();
  } catch (e) {
    message.error('支付失败，请重试');
  } finally {
    isPaymentReady.value = false;
  }
};
</script>

<template>
  <div class="mb-8 sm:mb-10">
    <!-- 新人欢迎弹窗 -->
    <Dialog v-model:open="isWelcomeVisible">
      <DialogContent class="sm:max-w-[280px] p-6">
        <div class="text-center space-y-4">
          <img
            src="/assets/illustrations/undraw_happy-birthday_lmk0.svg"
            alt="新人礼遇"
            class="w-28 h-28 object-contain mx-auto"
          />
          <div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">新人专享礼遇</h3>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">送您一张 9 折优惠券</p>
          </div>
          <div class="bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 rounded-lg py-2.5 px-4 grid place-items-center">
            <span class="text-lg font-bold text-white font-mono">welcome</span>
          </div>
          <Button @click="applyWelcomeCoupon" class="w-full">
            立即领取
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 验证码弹窗组件 -->
    <CaptchaDialog v-model:open="isCaptchaVisible" @verified="handleCaptchaVerified" />

    <!-- 标题和优惠码入口 -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4 sm:mb-6">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">4</div>
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
          <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ payCpData?.name || '-' }}</span>
        </div>

        <!-- 套餐周期 -->
        <div class="flex items-center justify-between px-4 sm:px-6 py-4">
          <span class="text-sm text-zinc-500">套餐周期</span>
          <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ payCpData?.period || '-' }}</span>
        </div>

        <!-- 原价（月付×周期） -->
        <div v-if="payCpData?.originalPrice" class="flex items-center justify-between px-4 sm:px-6 py-4">
          <span class="text-sm text-zinc-500">原价</span>
          <span class="font-medium font-[Rubik,ui-sans-serif,system-ui,sans-serif] line-through text-zinc-400">
            {{ payCpData.originalPrice }}
          </span>
        </div>

        <!-- 套餐价格 -->
        <div class="flex items-center justify-between px-4 sm:px-6 py-4">
          <span class="text-sm text-zinc-500">套餐价格</span>
          <span class="font-medium font-[Rubik,ui-sans-serif,system-ui,sans-serif] text-zinc-900 dark:text-zinc-100">
            {{ payCpData?.price || '-' }}
          </span>
        </div>

        <!-- 优惠码优惠 -->
        <div v-if="payCpData && parseFloat(payCpData.couponPrice) > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
          <span class="text-sm text-zinc-500">优惠码优惠</span>
          <span
            ref="discountElement"
            class="inline-flex items-center gap-1.5 px-3 py-1 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-sm font-bold rounded-lg"
          >
            <Tag class="w-3.5 h-3.5" />
            立减 {{ payCpData.couponPrice }}
          </span>
        </div>

        <!-- 实付金额 -->
        <div class="flex items-center justify-between px-4 sm:px-6 py-5 bg-zinc-50 dark:bg-zinc-800/50">
          <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100">实付金额</span>
          <div class="flex flex-col items-end gap-1">
            <div v-if="payCpData?.payMonthlyPrice && payCpData?.period !== '月付'" class="flex items-center gap-2">
              <span
                v-if="payCpData?.savingsPercent > 0"
                class="inline-flex items-center gap-0.5 px-1.5 py-0.5 bg-green-500 text-white text-xs font-bold rounded"
              >
                <Tag class="w-3 h-3" />省{{ payCpData.savingsPercent }}%
              </span>
              <span class="text-xs text-zinc-400">约 ¥{{ payCpData.payMonthlyPrice }}/月</span>
            </div>
            <span class="text-2xl font-bold text-blue-600 dark:text-blue-500 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
              {{ payCpData?.payPrice || '-' }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 固定底部购买按钮 -->
  <div class="fixed bottom-0 left-0 right-0 z-40 bg-white/80 dark:bg-zinc-900/80 backdrop-blur-lg border-t border-zinc-200 dark:border-zinc-800">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-3 sm:py-4 flex items-center justify-center">
      <Button
        @click="initiatePayment"
        :disabled="isPaymentReady"
        size="lg"
        class="px-12 sm:px-16 py-3 text-base sm:text-lg rounded-full"
      >
        <Loader2 v-if="isPaymentReady" class="w-5 h-5 mr-2 animate-spin" />
        <ShoppingCart v-else class="w-5 h-5 mr-2" />
        {{ isPaymentReady ? '正在处理中...' : '创建订单' }}
      </Button>
    </div>
  </div>
</template>

<style scoped>
</style>
