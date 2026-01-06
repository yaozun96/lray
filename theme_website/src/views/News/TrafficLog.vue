<script setup>
import { ref, onMounted } from 'vue';
import { getTrafficLog } from '@/api/trafficLog.js';
import { Info } from 'lucide-vue-next';

const trafficData = ref([]);
const loading = ref(true);

const formatDataSize = (size) => {
  if (size < 1024) return size + ' B';
  if (size < 1024 * 1024) return (size / 1024).toFixed(2) + ' KB';
  if (size < 1024 * 1024 * 1024) return (size / (1024 * 1024)).toFixed(2) + ' MB';
  return (size / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
};

const fetchTrafficData = async () => {
  loading.value = true;
  try {
    const response = await getTrafficLog();
    if ((response.status === 'success' || response.data) && response.data) {
      trafficData.value = response.data.map(item => ({
        recordTime: new Date(item.record_at * 1000).toLocaleDateString(),
        upload: formatDataSize(item.u),
        download: formatDataSize(item.d),
        rate: `${item.server_rate}x`,
        total: formatDataSize(item.d + item.u),
      }));
    }
  } catch (error) {
    console.error('获取流量数据失败', error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchTrafficData();
});
</script>

<template>
  <div class="py-2">
    <!-- 提示信息 -->
    <div class="flex items-center gap-2 px-4 py-3 mb-4 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 rounded-lg text-sm">
      <Info class="w-4 h-4 shrink-0" />
      <span>流量明细仅保留近一个月数据以供查询</span>
    </div>

    <!-- 表格 -->
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-zinc-200 dark:border-zinc-700">
            <th class="text-left py-3 px-4 font-medium text-zinc-500 dark:text-zinc-400">记录时间</th>
            <th class="text-left py-3 px-4 font-medium text-zinc-500 dark:text-zinc-400 hidden sm:table-cell">实际上行</th>
            <th class="text-left py-3 px-4 font-medium text-zinc-500 dark:text-zinc-400">实际下行</th>
            <th class="text-left py-3 px-4 font-medium text-zinc-500 dark:text-zinc-400 hidden sm:table-cell">扣费倍率</th>
            <th class="text-left py-3 px-4 font-medium text-zinc-500 dark:text-zinc-400">总计</th>
          </tr>
        </thead>
        <tbody v-if="!loading">
          <tr
            v-for="(item, index) in trafficData"
            :key="index"
            class="border-b border-zinc-100 dark:border-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-800/50"
          >
            <td class="py-3 px-4 text-zinc-900 dark:text-zinc-100">{{ item.recordTime }}</td>
            <td class="py-3 px-4 text-zinc-600 dark:text-zinc-400 hidden sm:table-cell">{{ item.upload }}</td>
            <td class="py-3 px-4 text-zinc-600 dark:text-zinc-400">{{ item.download }}</td>
            <td class="py-3 px-4 text-zinc-600 dark:text-zinc-400 hidden sm:table-cell">{{ item.rate }}</td>
            <td class="py-3 px-4 font-medium text-zinc-900 dark:text-zinc-100">{{ item.total }}</td>
          </tr>
        </tbody>
      </table>

      <!-- Loading -->
      <div v-if="loading" class="py-12 text-center text-zinc-400">
        加载中...
      </div>

      <!-- Empty -->
      <div v-else-if="trafficData.length === 0" class="py-12 text-center text-zinc-400">
        暂无流量记录
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
