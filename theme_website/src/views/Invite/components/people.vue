<script setup lang="ts">
import { onMounted, ref, computed } from "vue";
import { fetchInviteDetails } from "@/api/invite.js";
import moment from "moment";
import { Loader2, Receipt, Calendar, Coins, ChevronLeft, ChevronRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';

const loading = ref(true);
const data = ref<any[]>([]);
const currentPage = ref(1);
const pageSize = 10;

onMounted(() => {
  fetchInviteDetails().then((res: any) => {
    data.value = res.data || [];
  }).finally(() => {
    loading.value = false;
  });
});

// 总页数
const totalPages = computed(() => Math.ceil(data.value.length / pageSize));

// 当前页数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  const end = start + pageSize;
  return data.value.slice(start, end);
});

// 分页
const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--;
  }
};

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
  }
};

const formatAmount = (amount: number) => ((amount ?? 0) / 100).toFixed(2);
const formatTime = (timestamp: number) => moment(timestamp * 1000).format("YYYY-MM-DD HH:mm");
</script>

<template>
  <!-- 加载状态 -->
  <div v-if="loading" class="flex items-center justify-center py-12">
    <Loader2 class="w-6 h-6 text-blue-600 animate-spin" />
  </div>

  <!-- 空状态 -->
  <div v-else-if="data.length === 0" class="flex flex-col items-center justify-center py-12 text-center">
    <div class="w-14 h-14 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mb-3">
      <Receipt class="w-7 h-7 text-zinc-400" />
    </div>
    <p class="text-sm text-zinc-500 dark:text-zinc-400">暂无邀请明细</p>
  </div>

  <!-- 列表 -->
  <div v-else>
    <div class="space-y-3">
      <div
        v-for="(item, index) in paginatedData"
        :key="index"
        class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-lg"
      >
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2 text-sm text-zinc-600 dark:text-zinc-400">
            <Receipt class="w-4 h-4" />
            <span>订单金额:</span>
            <span class="font-medium text-zinc-900 dark:text-zinc-100">¥{{ formatAmount(item.order_amount) }}</span>
          </div>
          <div class="flex items-center gap-2 text-sm text-zinc-600 dark:text-zinc-400">
            <Coins class="w-4 h-4" />
            <span>佣金:</span>
            <span class="font-medium text-green-600 dark:text-green-400">+¥{{ formatAmount(item.get_amount) }}</span>
          </div>
        </div>
        <div class="flex items-center gap-1.5 text-sm text-zinc-500 dark:text-zinc-400">
          <Calendar class="w-4 h-4" />
          {{ formatTime(item.created_at) }}
        </div>
      </div>
    </div>

    <!-- 分页控件 -->
    <div v-if="totalPages > 1" class="flex items-center justify-between mt-4 pt-4 border-t border-zinc-100 dark:border-zinc-800">
      <span class="text-sm text-zinc-500 dark:text-zinc-400">
        共 {{ data.length }} 条，第 {{ currentPage }}/{{ totalPages }} 页
      </span>
      <div class="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          @click="prevPage"
          :disabled="currentPage === 1"
        >
          <ChevronLeft class="w-4 h-4" />
        </Button>
        <Button
          variant="outline"
          size="sm"
          @click="nextPage"
          :disabled="currentPage === totalPages"
        >
          <ChevronRight class="w-4 h-4" />
        </Button>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
