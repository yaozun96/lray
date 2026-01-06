<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { useUserStore } from "@/stores/User.js";
import { useInfoStore } from "@/stores/counter.js";
import { Plan_CheckOut, Plan_Coupon, Plan_Save } from "@/api/Store.js";
import { message } from 'ant-design-vue';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';

// Lucide Icons
import { Gift, Loader2, Package, X } from 'lucide-vue-next';

const user = useUserStore();
const tokenStore = useInfoStore();

const cdkey = ref('');
const coupon = ref<any>(null);
const inputDisabled = ref(false);
const isLoading = ref(false);

watch(cdkey, () => {
  if (!cdkey.value) return;
  inputDisabled.value = true;
  Plan_Coupon({
    code: cdkey.value
  }).then((res: any) => {
    if (res.data.type !== 2 || res.data.value !== 100 || !res.data.limit_plan_ids || !res.data.limit_period) {
      coupon.value = null;
      inputDisabled.value = false;
      return message.warning('这是优惠劵，不是兑换码，请到购买套餐页面中使用');
    }
    coupon.value = res.data;
    inputDisabled.value = false;
  }).catch(() => {
    message.error('兑换码验证失败, 无效兑换码');
    coupon.value = null;
    inputDisabled.value = false;
  });
});

const planCp = computed(() => {
  let id;
  let name;
  let periodKey;
  let periodName;
  let price;

  if (coupon.value && coupon.value.limit_period && coupon.value.limit_plan_ids) {
    id = coupon.value.limit_plan_ids[0];
    periodKey = coupon.value.limit_period[0];

    const plan = user.PlanList?.find((plan: any) => plan.id === Number(id));
    if (plan) {
      name = plan.name;
      price = plan[periodKey] / 100;

      const periodMap: Record<string, string> = {
        'month_price': '单月版',
        'quarter_price': '季度版',
        'half_year_price': '半年版',
        'year_price': '一年版',
        'two_year_price': '两年版',
        'three_year_price': '三年版',
        'onetime_price': '一次性流量包',
      };
      periodName = periodMap[periodKey] || '未知';
    }
  }

  return { id, name, periodKey, periodName, price };
});

const submit = async () => {
  if (!cdkey.value) return message.warning('请先输入兑换码');
  if (!coupon.value || !planCp.value.id) return message.warning('请输入有效的兑换码');

  isLoading.value = true;
  try {
    const planId = planCp.value.id;
    const periodKey = planCp.value.periodKey;
    const cdkeyValue = cdkey.value;

    const order = await Plan_Save({ period: periodKey, plan_id: planId, coupon_code: cdkeyValue });
    const orderId = typeof order === 'string' ? order : order.data;

    const payResult = await Plan_CheckOut({ trade_no: orderId });
    if (!payResult.data) {
      return message.error('兑换失败，请联系网站管理员');
    }

    message.success('兑换成功');
    setTimeout(() => reload(), 3200);
  } catch (err) {
    message.error('兑换失败');
  } finally {
    isLoading.value = false;
  }
};

const reload = (url?: string) => {
  if (url) {
    window.location.replace(url);
  }
  window.location.reload();
};

const cpDisplay = computed(() => {
  const { Exchange } = window.config;
  return {
    title: Exchange?.title || '套餐兑换',
    desc: Exchange?.desc || '如果没有兑换码',
    buyText: Exchange?.buyText || '请点击购买',
    placeholder: Exchange?.placeholder || '请输入你的兑换码',
    submitText: Exchange?.submitText || '立即兑换',
  };
});

const closeModal = () => {
  user.ExchangeModal = false;
};

onMounted(() => {
  if (tokenStore.Token && !user.PlanList) {
    user.Set_PlanList().catch((err: any) => {
      console.error('获取套餐列表失败:', err);
    });
  }
});
</script>

<template>
  <Dialog v-model:open="user.ExchangeModal">
    <DialogContent class="sm:max-w-[380px] p-0 gap-0 overflow-hidden border-zinc-200 dark:border-zinc-800">
      <div class="p-8 sm:p-10">
        <!-- 头部 -->
        <DialogHeader class="text-center mb-6">
          <div class="flex justify-center mb-4">
            <div class="w-16 h-16 rounded-2xl bg-primary/10 dark:bg-primary/20 flex items-center justify-center">
              <Gift class="w-8 h-8 text-primary" />
            </div>
          </div>
          <DialogTitle class="text-xl font-bold text-center text-zinc-900 dark:text-zinc-100">{{ cpDisplay.title }}</DialogTitle>
          <DialogDescription class="text-center text-zinc-500 dark:text-zinc-400">
            <span>{{ cpDisplay.desc }},&nbsp;</span>
            <button
              @click="reload('#/store')"
              class="text-primary hover:underline"
            >
              {{ cpDisplay.buyText }}
            </button>
          </DialogDescription>
        </DialogHeader>

        <!-- 输入区域 -->
        <div class="space-y-4">
          <!-- 兑换码输入 -->
          <div class="relative">
            <Package class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-400" />
            <input
              v-model.lazy="cdkey"
              :placeholder="cpDisplay.placeholder"
              :disabled="inputDisabled"
              class="w-full pl-11 pr-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>

          <!-- 套餐信息 -->
          <div
            v-if="coupon"
            class="p-4 rounded-xl border-2 border-primary/50 dark:border-primary/40 bg-primary/5 dark:bg-primary/10"
          >
            <p class="text-lg font-bold text-zinc-900 dark:text-zinc-100">{{ planCp.name }}</p>
            <p class="text-sm text-primary">{{ planCp.periodName }}</p>
            <p class="text-xs text-zinc-500 dark:text-zinc-400 text-right line-through mt-1">
              原价: ¥{{ planCp.price }}
            </p>
          </div>

          <!-- 提交按钮 -->
          <Button
            @click="submit"
            :disabled="inputDisabled || isLoading"
            class="w-full py-3 text-base rounded-xl bg-primary hover:bg-primary/90"
          >
            <Loader2 v-if="isLoading" class="w-5 h-5 mr-2 animate-spin" />
            <Gift v-else class="w-5 h-5 mr-2" />
            {{ cpDisplay.submitText }}
          </Button>
        </div>
      </div>
    </DialogContent>
  </Dialog>
</template>

<style scoped>
</style>
