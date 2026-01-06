<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/User.js';
import Plan from '@/utils/Plan.js';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';

// Lucide Icons
import {
  ArrowLeft,
  FileText,
  Clock,
  CheckCircle,
  XCircle,
  RefreshCw,
  ChevronRight,
} from 'lucide-vue-next';

const router = useRouter();
const user = useUserStore();
const orderList = ref<any[]>([]);
const loading = ref(true);

const loadOrders = async () => {
  loading.value = true;
  try {
    await user.Set_Order(true);
    orderList.value = user.Order || [];
  } catch {
    orderList.value = [];
  } finally {
    loading.value = false;
  }
};

const getOrderStatusInfo = (status: number) => {
  switch (status) {
    case 0: return { text: '待支付', color: 'amber', icon: Clock };
    case 1: return { text: '开通中', color: 'blue', icon: RefreshCw };
    case 2: return { text: '已取消', color: 'zinc', icon: XCircle };
    case 3: return { text: '已完成', color: 'green', icon: CheckCircle };
    case -1: return { text: '已取消', color: 'red', icon: XCircle };
    default: return { text: '未知', color: 'zinc', icon: FileText };
  }
};

const formatOrderTime = (timestamp: number) => {
  const date = new Date(timestamp * 1000);
  return date.toLocaleDateString('zh-CN', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
};

const goBack = () => {
  router.back();
};

onMounted(() => {
  loadOrders();
});
</script>

<template>
  <div class="min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8 sm:py-12">

      <!-- 返回按钮和标题 -->
      <div class="flex items-center gap-4 mb-8">
        <button
          @click="goBack"
          class="w-10 h-10 rounded-full bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
        >
          <ArrowLeft class="w-5 h-5 text-zinc-600 dark:text-zinc-400" />
        </button>
        <div>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">订单历史</h1>
          <p class="text-sm text-zinc-500 mt-1">查看您的所有订单记录</p>
        </div>
      </div>

      <!-- 加载中 -->
      <div v-if="loading" class="flex items-center justify-center py-20">
        <RefreshCw class="w-8 h-8 text-blue-500 animate-spin" />
      </div>

      <!-- 空状态 -->
      <div v-else-if="orderList.length === 0" class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-12">
        <div class="flex flex-col items-center justify-center">
          <FileText class="w-16 h-16 text-zinc-200 dark:text-zinc-700 mb-4" />
          <p class="text-zinc-500 dark:text-zinc-400 mb-4">暂无订单记录</p>
          <Button @click="router.push('/store')">去购买套餐</Button>
        </div>
      </div>

      <!-- 订单列表 -->
      <div v-else class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
        <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <div
            v-for="order in orderList"
            :key="order.trade_no"
            @click="router.push(`/order/${order.trade_no}`)"
            class="flex items-center justify-between gap-4 px-4 sm:px-6 py-4 sm:py-5 cursor-pointer hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
          >
            <div class="flex items-center gap-3 sm:gap-4 min-w-0 flex-1">
              <!-- 状态图标 -->
              <div
                class="w-10 h-10 sm:w-12 sm:h-12 rounded-full flex items-center justify-center shrink-0"
                :class="{
                  'bg-amber-100 dark:bg-amber-900/30': getOrderStatusInfo(order.status).color === 'amber',
                  'bg-green-100 dark:bg-green-900/30': getOrderStatusInfo(order.status).color === 'green',
                  'bg-red-100 dark:bg-red-900/30': getOrderStatusInfo(order.status).color === 'red',
                  'bg-blue-100 dark:bg-blue-900/30': getOrderStatusInfo(order.status).color === 'blue',
                  'bg-zinc-100 dark:bg-zinc-800': getOrderStatusInfo(order.status).color === 'zinc',
                }"
              >
                <component
                  :is="getOrderStatusInfo(order.status).icon"
                  class="w-5 h-5 sm:w-6 sm:h-6"
                  :class="{
                    'text-amber-600 dark:text-amber-400': getOrderStatusInfo(order.status).color === 'amber',
                    'text-green-600 dark:text-green-400': getOrderStatusInfo(order.status).color === 'green',
                    'text-red-600 dark:text-red-400': getOrderStatusInfo(order.status).color === 'red',
                    'text-blue-600 dark:text-blue-400': getOrderStatusInfo(order.status).color === 'blue',
                    'text-zinc-600 dark:text-zinc-400': getOrderStatusInfo(order.status).color === 'zinc',
                  }"
                />
              </div>

              <!-- 订单信息 -->
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="font-medium text-zinc-900 dark:text-zinc-100 truncate">
                    {{ order.period === 'recharge' ? '余额充值' : (order.plan?.name || '未知套餐') }}
                  </span>
                  <span
                    class="px-2 py-0.5 text-xs font-medium rounded-full shrink-0"
                    :class="{
                      'bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400': getOrderStatusInfo(order.status).color === 'amber',
                      'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400': getOrderStatusInfo(order.status).color === 'green',
                      'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400': getOrderStatusInfo(order.status).color === 'red',
                      'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400': getOrderStatusInfo(order.status).color === 'blue',
                      'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400': getOrderStatusInfo(order.status).color === 'zinc',
                    }"
                  >
                    {{ getOrderStatusInfo(order.status).text }}
                  </span>
                </div>
                <div class="flex items-center gap-2 mt-1 text-xs text-zinc-400">
                  <span>{{ formatOrderTime(order.created_at) }}</span>
                  <span v-if="order.period !== 'recharge'">·</span>
                  <span v-if="order.period !== 'recharge'">{{ Plan.Handle_name(order.period) }}</span>
                </div>
              </div>
            </div>

            <!-- 金额和箭头 -->
            <div class="flex items-center gap-3 shrink-0">
              <span class="text-base sm:text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                ¥{{ ((order.total_amount || 0) / 100).toFixed(2) }}
              </span>
              <ChevronRight class="w-5 h-5 text-zinc-300 dark:text-zinc-600" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
