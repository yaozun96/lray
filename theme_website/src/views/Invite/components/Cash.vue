<script setup lang="ts">
import { useUserStore } from "@/stores/User.js";
import { transferCommission } from "@/api/invite.js";
import { createTicket, fetchTicketList } from "@/api/ticket.js";
import { message } from 'ant-design-vue';
import { computed, ref } from "vue";
import { useRouter } from "vue-router";

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
import { ArrowRightLeft, Wallet, Coins, Info, Loader2 } from 'lucide-vue-next';

const props = defineProps<{
  cash: number;
  update: () => void;
}>();

const router = useRouter();
const user = useUserStore();
const open = ref(false);
const loading = ref(false);
const cashType = ref<'transfer' | 'withdraw'>('transfer');

const cashTitle = computed(() => {
  return cashType.value === 'transfer' ? '推广佣金划转至余额' : '推广佣金提现';
});

const cashMethods = computed(() => {
  if (user.Config?.withdraw_methods?.length > 0) {
    return user.Config.withdraw_methods.map((item: string) => ({
      label: item,
      value: item
    }));
  }
  return [];
});

const transferMoney = ref(0);
const withdrawMethod = ref('');
const withdrawAccount = ref('');

const cashOpen = (type: 'transfer' | 'withdraw') => {
  open.value = true;
  cashType.value = type;
  transferMoney.value = 0;
  withdrawMethod.value = cashMethods.value[0]?.value || '';
  withdrawAccount.value = '';
};

const handleOk = async () => {
  if (cashType.value === 'transfer') {
    if (transferMoney.value <= 0) {
      message.error('请输入划转金额');
      return;
    }
  } else if (cashType.value === 'withdraw') {
    if (!withdrawMethod.value) {
      message.error('请选择提现方式');
      return;
    }
    if (!withdrawAccount.value) {
      message.error('请输入提现账号');
      return;
    }
  }

  loading.value = true;
  try {
    if (cashType.value === 'transfer') {
      await transferCommission({
        transfer_amount: transferMoney.value * 100
      });
      message.success("划转成功");
      props.update();
      open.value = false;
    } else if (cashType.value === 'withdraw') {
      // 检查是否有未关闭的工单
      const ticketRes = await fetchTicketList();
      const openTickets = (ticketRes.data || []).filter((t: any) => t.status === 0);
      if (openTickets.length > 0) {
        message.warning("您有未关闭的工单，请先处理后再提交提现申请");
        open.value = false;
        router.push('/ticket');
        return;
      }

      // 通过工单系统提交提现申请
      const withdrawAmount = (props.cash / 100).toFixed(2);
      await createTicket({
        subject: '佣金提现申请',
        level: 1,
        message: `提现方式：${withdrawMethod.value}\n提现账号：${withdrawAccount.value}\n提现金额：${withdrawAmount} 元\n\n请审核处理，谢谢！`
      });
      message.success("提现申请已提交，请在工单中查看进度");
      props.update();
      open.value = false;
    }
  } catch (err: any) {
    message.error(err?.data?.message || err?.message || '操作失败');
  } finally {
    loading.value = false;
  }
};

const formattedCash = computed(() => ((props.cash || 0) / 100).toFixed(2));

// 是否可以提现（佣金需要大于等于200元，即 20000 分）
const canWithdraw = computed(() => (props.cash || 0) >= 20000);

// 提现按钮点击处理
const handleWithdrawClick = () => {
  if (!canWithdraw.value) {
    const currentAmount = ((props.cash || 0) / 100).toFixed(2);
    const remaining = (200 - (props.cash || 0) / 100).toFixed(2);
    message.warning(`当前佣金 ${currentAmount} 元，还差 ${remaining} 元即可提现`);
    return;
  }
  cashOpen('withdraw');
};
</script>

<template>
  <div class="mb-6 bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-800 p-5 sm:p-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <!-- 佣金数字 -->
      <div>
        <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400 mb-1">当前可用佣金</p>
        <div class="flex items-baseline gap-1">
          <span class="text-3xl sm:text-4xl font-bold text-zinc-900 dark:text-zinc-100 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
            {{ formattedCash }}
          </span>
          <span class="text-lg text-zinc-500 dark:text-zinc-400">
            {{ user.Config?.currency || '¥' }}
          </span>
        </div>
        <p v-if="!canWithdraw" class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">
          满200元可提现
        </p>
      </div>

      <!-- 操作按钮 -->
      <div class="flex items-center gap-2">
        <Button @click="cashOpen('transfer')" variant="outline" class="gap-2">
          <ArrowRightLeft class="w-4 h-4" />
          划转
        </Button>
        <Button
          @click="handleWithdrawClick"
          :variant="canWithdraw ? 'default' : 'outline'"
          class="gap-2"
        >
          <Wallet class="w-4 h-4" />
          提现
        </Button>
      </div>
    </div>
  </div>

  <!-- 操作弹窗 -->
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <div class="flex justify-center mb-4">
          <div class="w-14 h-14 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
            <ArrowRightLeft v-if="cashType === 'transfer'" class="w-7 h-7 text-blue-600 dark:text-blue-400" />
            <Wallet v-else class="w-7 h-7 text-blue-600 dark:text-blue-400" />
          </div>
        </div>
        <DialogTitle class="text-center">{{ cashTitle }}</DialogTitle>
        <DialogDescription v-if="cashType === 'transfer'" class="text-center">
          划转后的余额仅用于消费使用
        </DialogDescription>
      </DialogHeader>

      <!-- 划转表单 -->
      <div v-if="cashType === 'transfer'" class="space-y-4 mt-4">
        <!-- 提示 -->
        <div class="flex items-start gap-2 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
          <Info class="w-4 h-4 text-blue-600 dark:text-blue-400 shrink-0 mt-0.5" />
          <p class="text-sm text-blue-700 dark:text-blue-300">划转后的余额仅用于消费使用，不可提现</p>
        </div>

        <!-- 当前余额 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">当前推广佣金余额</label>
          <div class="relative">
            <Coins class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-400" />
            <input
              :value="formattedCash"
              disabled
              class="w-full pl-11 pr-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-zinc-100 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 text-sm"
            />
          </div>
        </div>

        <!-- 划转金额 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">划转金额</label>
          <div class="relative">
            <ArrowRightLeft class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-400" />
            <input
              v-model.number="transferMoney"
              type="number"
              placeholder="请输入划转金额"
              class="w-full pl-11 pr-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
          </div>
        </div>
      </div>

      <!-- 提现表单 -->
      <div v-if="cashType === 'withdraw'" class="space-y-4 mt-4">
        <!-- 提现方式 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">提现方式</label>
          <select
            v-model="withdrawMethod"
            class="w-full px-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
          >
            <option v-for="method in cashMethods" :key="method.value" :value="method.value">
              {{ method.label }}
            </option>
          </select>
        </div>

        <!-- 提现账号 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">提现账号</label>
          <div class="relative">
            <Wallet class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-zinc-400" />
            <input
              v-model="withdrawAccount"
              type="text"
              placeholder="请输入提现账号"
              class="w-full pl-11 pr-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
          </div>
        </div>
      </div>

      <!-- 按钮 -->
      <div class="flex gap-3 mt-6">
        <Button variant="outline" @click="open = false" class="flex-1">
          取消
        </Button>
        <Button @click="handleOk" :disabled="loading" class="flex-1">
          <Loader2 v-if="loading" class="w-4 h-4 mr-2 animate-spin" />
          确定
        </Button>
      </div>
    </DialogContent>
  </Dialog>
</template>

<style scoped>
</style>
