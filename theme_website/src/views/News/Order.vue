<script setup>
import { onMounted, ref, computed, onUnmounted, watch } from "vue";
import { useRoute, useRouter } from "vue-router";

import { cancelOrder } from "@/api/orderlist.js";
import { checkoutOrder, checkOrderStatus, getPaymentMethods } from "@/api/shop.js";
import { useUserStore } from "@/stores/User.js";
import moment from "moment";
import Plan from "@/utils/Plan.js";
import { message } from 'ant-design-vue';
import QRCode from 'qrcode';
import { getAuthorizedApiOrigin } from '@/utils/auth.js';

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
  ArrowLeft,
  Package,
  Calendar,
  Clock,
  CreditCard,
  CheckCircle,
  XCircle,
  Loader2,
  QrCode,
  Wallet,
  Tag,
  Receipt,
  Info,
  Check,
} from 'lucide-vue-next';

const user = useUserStore();
const route = useRoute();
const router = useRouter();
const data = ref(null);
const active = ref(0);
const paylist = ref([]);
const cancelLoading = ref(false);
const payLoading = ref(false);
const qrCodeUrl = ref('');
const isQrCodeVisible = ref(false);
let paymentCheckInterval = null;

// 计算费用详情（含减免逻辑）
const feeStats = computed(() => {
  if (!data.value || !filteredPaylist.value.length) return { fee: data.value?.handling_amount || 0, rawFee: 0, isWaived: false };

  const method = filteredPaylist.value[active.value];
  if (!method) return { fee: 0, rawFee: 0, isWaived: false };

  const fixed = Number(method.handling_fee_fixed) || 0;
  const percent = Number(method.handling_fee_percent) || 0;
  const total = Number(data.value.total_amount) || 0;

  const rawFee = fixed * 100 + (total * percent / 100);

  const thresholdStr = method.config?.handling_fee_free_threshold || method.handling_fee_free_threshold || "50";
  const threshold = Number(thresholdStr) * 100;

  const isWaived = total >= threshold;

  return {
    fee: isWaived ? 0 : rawFee,
    rawFee: rawFee,
    isWaived: isWaived
  };
});

const currentHandlingFee = computed(() => feeStats.value.fee);

const finalTotalAmount = computed(() => {
  if (!data.value) return 0;
  return (Number(data.value.total_amount) || 0) + currentHandlingFee.value;
});

const resolveIconUrl = (icon) => {
  if (!icon || typeof icon !== 'string') return '';
  if (/^(?:[a-z]+:)?\/\//i.test(icon) || icon.startsWith('data:')) return icon;
  const base = getAuthorizedApiOrigin();
  if (!base) return icon;
  const normalizedBase = base.replace(/\/+$/, '');
  const normalizedPath = icon.replace(/^\/+/, '');
  return `${normalizedBase}/${normalizedPath}`;
};

// 根据配置过滤支付方式
const filteredPaylist = computed(() => {
  const rules = window.config?.Buy?.payment_rules;
  if (!rules || !Array.isArray(rules) || rules.length === 0) {
    return paylist.value;
  }

  // 获取订单金额（转换为元）
  const orderAmount = (Number(data.value?.total_amount) || 0) / 100;

  return paylist.value.filter(method => {
    const rule = rules.find(r => r.payment_id === method.id);

    // 如果没有配置规则，默认不显示（只显示配置了的支付方式）
    if (!rule) return false;

    // 检查最小金额限制
    if (rule.min_amount !== undefined && rule.min_amount !== null && orderAmount < rule.min_amount) {
      return false;
    }

    // 检查最大金额限制
    if (rule.max_amount !== undefined && rule.max_amount !== null && orderAmount > rule.max_amount) {
      return false;
    }

    return true;
  });
});

// 当过滤后的支付方式列表变化时，重置选中索引
watch(filteredPaylist, (newList) => {
  if (newList.length > 0 && active.value >= newList.length) {
    active.value = 0;
  }
}, { immediate: true });

// 订单状态
const orderStatus = computed(() => {
  if (!data.value) return { text: '加载中', color: 'zinc', icon: Loader2 };
  switch (data.value.status) {
    case 0: return { text: '待支付', color: 'amber', icon: Clock };
    case 1: return { text: '开通中', color: 'blue', icon: Loader2 };
    case 2: return { text: '已取消', color: 'zinc', icon: XCircle };
    case 3: return { text: '已完成', color: 'green', icon: CheckCircle };
    case -1: return { text: '已取消', color: 'red', icon: XCircle };
    default: return { text: '未知', color: 'zinc', icon: Info };
  }
});

onMounted(() => {
  checkOrderStatus(route.params.id)
    .then((res) => {
      data.value = res.data;
    })
    .catch((error) => {
      console.error("获取订单详情失败:", error);
      message.error("获取订单详情失败");
    });

  getPaymentMethods()
    .then((res) => {
      paylist.value = (res.data || []).map((method) => ({
        ...method,
        icon: resolveIconUrl(method.icon),
      }));
    })
    .catch((error) => {
      console.error("获取支付方式失败:", error);
      message.error("获取支付方式失败");
    });
});

onUnmounted(() => {
  if (paymentCheckInterval) {
    clearInterval(paymentCheckInterval);
  }
});

const cancel = () => {
  cancelLoading.value = true;
  cancelOrder(route.params.id)
    .then(() => {
      message.success("取消订单成功");
      data.value.status = -1;
      cancelLoading.value = false;
    })
    .catch((error) => {
      console.error("取消订单失败:", error);
      message.error("取消订单失败");
      cancelLoading.value = false;
    });
};

const checkPaymentStatus = () => {
  paymentCheckInterval = setInterval(() => {
    checkOrderStatus(route.params.id)
      .then((res) => {
        if (res.data && res.data.status === 3) {
          message.success("支付成功");
          clearInterval(paymentCheckInterval);
          isQrCodeVisible.value = false;
          window.location.reload();
        } else if (res.data && res.data.status === 2) {
          message.error("订单已取消");
          clearInterval(paymentCheckInterval);
          isQrCodeVisible.value = false;
        }
      })
      .catch((error) => {
        console.error("检查支付状态失败:", error);
      });
  }, 3000);
};

const processPayment = () => {
  const isFree = Number(data.value.total_amount) <= 0;

  if (!isFree && !filteredPaylist.value.length) {
    message.error("暂无可用的支付方式");
    return;
  }

  payLoading.value = true;
  const methodId = isFree ? null : filteredPaylist.value[active.value].id;

  checkoutOrder(route.params.id, methodId)
    .then((res) => {
      if (res.type === 0) {
        QRCode.toDataURL(res.data)
          .then((url) => {
            qrCodeUrl.value = url;
            isQrCodeVisible.value = true;
            checkPaymentStatus();
          })
          .catch((error) => {
            console.error("生成二维码失败:", error);
            message.error("生成二维码失败");
          });
      } else {
        if (typeof res.data === 'string' && (res.data.startsWith('http') || res.data.startsWith('/'))) {
          window.location.href = res.data;
        }
        checkPaymentStatus();
      }
      payLoading.value = false;
    })
    .catch((error) => {
      console.error("支付失败:", error);
      message.error("支付失败");
      payLoading.value = false;
    });
};

const goBack = () => {
  router.back();
};
</script>

<template>
  <div class="min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8 sm:py-12">

      <!-- 返回按钮和标题 -->
      <!-- 返回按钮和标题 -->
      <!-- 返回按钮和标题 -->
      <div class="flex items-center justify-between gap-4 mb-8">
        <div class="flex items-center gap-4">
          <button
            @click="goBack"
            class="w-10 h-10 rounded-full bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 flex items-center justify-center hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors shrink-0"
          >
            <ArrowLeft class="w-5 h-5 text-zinc-600 dark:text-zinc-400" />
          </button>
          <div>
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">订单详情</h1>
            <p class="text-sm text-zinc-500 mt-1">订单号：{{ route.params.id }}</p>
          </div>
        </div>
        <img
          src="/assets/illustrations/undraw_payments_nbqu.svg"
          alt="Order"
          class="w-24 h-24 sm:w-32 sm:h-32 object-contain opacity-90 hidden sm:block"
        />
      </div>

      <!-- 加载中 -->
      <div v-if="!data" class="flex items-center justify-center py-20">
        <Loader2 class="w-8 h-8 text-blue-500 animate-spin" />
      </div>

      <div v-else class="space-y-6">

        <!-- 订单状态卡片 -->
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 sm:p-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div
                class="w-14 h-14 rounded-full flex items-center justify-center"
                :class="{
                  'bg-amber-100 dark:bg-amber-900/30': orderStatus.color === 'amber',
                  'bg-green-100 dark:bg-green-900/30': orderStatus.color === 'green',
                  'bg-red-100 dark:bg-red-900/30': orderStatus.color === 'red',
                  'bg-blue-100 dark:bg-blue-900/30': orderStatus.color === 'blue',
                  'bg-zinc-100 dark:bg-zinc-800': orderStatus.color === 'zinc',
                }"
              >
                <component
                  :is="orderStatus.icon"
                  class="w-7 h-7"
                  :class="{
                    'text-amber-600 dark:text-amber-400': orderStatus.color === 'amber',
                    'text-green-600 dark:text-green-400': orderStatus.color === 'green',
                    'text-red-600 dark:text-red-400': orderStatus.color === 'red',
                    'text-blue-600 dark:text-blue-400': orderStatus.color === 'blue',
                    'text-zinc-600 dark:text-zinc-400': orderStatus.color === 'zinc',
                    'animate-spin': orderStatus.icon === Loader2,
                  }"
                />
              </div>
              <div>
                <p
                  class="text-xl font-bold"
                  :class="{
                    'text-amber-600 dark:text-amber-400': orderStatus.color === 'amber',
                    'text-green-600 dark:text-green-400': orderStatus.color === 'green',
                    'text-red-600 dark:text-red-400': orderStatus.color === 'red',
                    'text-blue-600 dark:text-blue-400': orderStatus.color === 'blue',
                    'text-zinc-600 dark:text-zinc-400': orderStatus.color === 'zinc',
                  }"
                >
                  {{ orderStatus.text }}
                </p>
                <p class="text-sm text-zinc-500 mt-1">
                  {{ moment(data.created_at * 1000).format("YYYY-MM-DD HH:mm:ss") }}
                </p>
              </div>
            </div>

            <!-- 金额显示 -->
            <div class="text-right">
              <p class="text-sm text-zinc-500">应付金额</p>
              <p class="text-2xl sm:text-3xl font-bold text-blue-600 dark:text-blue-500 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                {{ ((finalTotalAmount || 0) / 100).toFixed(2) }}
                <span class="text-base font-normal">{{ user.Config?.currency_symbol }}</span>
              </p>
            </div>
          </div>
        </div>

        <!-- 商品信息 -->
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <div class="px-4 sm:px-6 py-4 border-b border-zinc-100 dark:border-zinc-800">
            <h3 class="font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Package class="w-5 h-5" />
              {{ data.period === 'recharge' ? '充值信息' : '商品信息' }}
            </h3>
          </div>
          <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <!-- 充值订单 -->
            <template v-if="data.period === 'recharge'">
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">类型</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100">余额充值</span>
              </div>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">充值金额</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  {{ ((data.total_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>
              <div v-if="data.discount_amount > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">赠送金额</span>
                <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-sm font-bold rounded-lg font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  + {{ ((data.discount_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">到账金额</span>
                <span class="font-medium text-green-600 dark:text-green-400 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  {{ (((data.total_amount || 0) + (data.discount_amount || 0)) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>
            </template>
            <!-- 普通订单 -->
            <template v-else>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">产品名称</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ data.plan?.name }}</span>
              </div>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">类型/周期</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ Plan.Handle_name(data.period) }}</span>
              </div>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">产品流量</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100">{{ data.plan?.transfer_enable }} GB</span>
              </div>
            </template>
          </div>
        </div>

        <!-- 费用明细 -->
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <div class="px-4 sm:px-6 py-4 border-b border-zinc-100 dark:border-zinc-800">
            <h3 class="font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Receipt class="w-5 h-5" />
              费用明细
            </h3>
          </div>
          <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <!-- 充值订单的费用明细 -->
            <template v-if="data.period === 'recharge'">
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">充值金额</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  {{ ((data.total_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>
            </template>
            <!-- 普通订单的费用明细 -->
            <template v-else>
              <div class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">商品价格</span>
                <span class="font-medium text-zinc-900 dark:text-zinc-100 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  {{ ((data.plan?.[data.period] || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>

              <div v-if="data.balance_amount > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">余额支付</span>
                <span class="font-medium text-green-600 dark:text-green-400 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  - {{ ((data.balance_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>

              <div v-if="data.discount_amount > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">优惠金额</span>
                <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-sm font-bold rounded-lg">
                  <Tag class="w-3.5 h-3.5" />
                  - {{ ((data.discount_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>

              <div v-if="data.surplus_amount > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">旧订阅折抵</span>
                <span class="font-medium text-green-600 dark:text-green-400 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  - {{ ((data.surplus_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>

              <div v-if="data.refund_amount > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
                <span class="text-sm text-zinc-500">退回账户金额</span>
                <span class="font-medium text-green-600 dark:text-green-400 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                  - {{ ((data.refund_amount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                </span>
              </div>
            </template>

            <!-- 手续费 -->
            <div v-if="Number(data.total_amount) > 0" class="flex items-center justify-between px-4 sm:px-6 py-4">
              <div class="flex items-center gap-2">
                <span class="text-sm text-zinc-500">支付手续费</span>
                <div v-if="filteredPaylist[active]?.handling_fee_percent > 0" class="group relative">
                  <Info class="w-4 h-4 text-zinc-400 cursor-help" />
                  <div class="absolute bottom-full left-0 mb-2 px-3 py-2 bg-zinc-900 text-white text-xs rounded-lg opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-10">
                    支付宝/微信收取5%手续费，商品价格满50元免手续费
                  </div>
                </div>
              </div>
              <span class="font-medium font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                <template v-if="feeStats.isWaived && feeStats.rawFee > 0">
                  <span class="line-through text-zinc-400 mr-2">
                    {{ (feeStats.rawFee / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                  </span>
                  <span class="text-green-600 dark:text-green-400">已减免</span>
                </template>
                <template v-else>
                  <span class="text-zinc-900 dark:text-zinc-100">
                    {{ ((currentHandlingFee || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
                  </span>
                </template>
              </span>
            </div>

            <!-- 实付金额 -->
            <div class="flex items-center justify-between px-4 sm:px-6 py-5 bg-zinc-50 dark:bg-zinc-800/50">
              <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100">实付金额</span>
              <span class="text-2xl font-bold text-blue-600 dark:text-blue-500 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                {{ ((finalTotalAmount || 0) / 100).toFixed(2) }} {{ user.Config?.currency_symbol }}
              </span>
            </div>
          </div>
        </div>

        <!-- 支付方式选择 (仅待支付且非免费订单显示) -->
        <div v-if="data.status === 0 && Number(data.total_amount) > 0" class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <div class="px-4 sm:px-6 py-4 border-b border-zinc-100 dark:border-zinc-800">
            <h3 class="font-semibold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <CreditCard class="w-5 h-5" />
              选择支付方式
            </h3>
          </div>
          <div class="p-4 sm:p-6">
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <button
                v-for="(item, index) in filteredPaylist"
                :key="item.id"
                @click="active = index"
                class="relative flex items-center gap-3 p-4 rounded-xl border-2 transition-all duration-200"
                :class="index === active
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-zinc-200 dark:border-zinc-700 hover:border-zinc-300 dark:hover:border-zinc-600'"
              >
                <img v-if="item.icon" :src="item.icon" alt="" class="w-8 h-8 object-contain" />
                <span
                  class="text-sm font-medium"
                  :class="index === active ? 'text-blue-600 dark:text-blue-400' : 'text-zinc-700 dark:text-zinc-300'"
                >
                  {{ item.name }}
                </span>
                <!-- 选中标记 -->
                <div
                  v-if="index === active"
                  class="absolute top-2 right-2 w-5 h-5 rounded-full bg-blue-500 flex items-center justify-center"
                >
                  <Check class="w-3 h-3 text-white" />
                </div>
              </button>
            </div>
          </div>
        </div>

        <!-- 操作按钮 -->
        <div v-if="data.status === 0" class="flex gap-3">
          <Button
            variant="outline"
            size="lg"
            @click="cancel"
            :disabled="cancelLoading"
            class="flex-1"
          >
            <Loader2 v-if="cancelLoading" class="w-4 h-4 mr-2 animate-spin" />
            <XCircle v-else class="w-4 h-4 mr-2" />
            取消订单
          </Button>
          <Button
            size="lg"
            @click="processPayment"
            :disabled="payLoading"
            class="flex-1"
          >
            <Loader2 v-if="payLoading" class="w-4 h-4 mr-2 animate-spin" />
            <CreditCard v-else class="w-4 h-4 mr-2" />
            立即支付
          </Button>
        </div>

      </div>
    </div>

    <!-- 二维码弹窗 -->
    <Dialog v-model:open="isQrCodeVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <div class="flex justify-center mb-4">
            <div class="w-16 h-16 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <QrCode class="w-8 h-8 text-blue-600 dark:text-blue-400" />
            </div>
          </div>
          <DialogTitle class="text-center">扫码支付</DialogTitle>
          <DialogDescription class="text-center">
            请使用支付宝或微信扫描二维码完成支付
          </DialogDescription>
        </DialogHeader>

        <div class="flex justify-center my-4">
          <div class="p-4 bg-white rounded-xl border border-zinc-200">
            <img :src="qrCodeUrl" alt="支付二维码" class="w-48 h-48" />
          </div>
        </div>

        <p class="text-center text-sm text-zinc-500">
          <Loader2 class="w-4 h-4 inline mr-1 animate-spin" />
          正在等待支付结果...
        </p>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
</style>
