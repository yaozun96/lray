<script setup>
import { onMounted, ref } from "vue";
import { fetchServerNodes } from '@/api/servers.js'
import Country from "@/components/Country.vue";
import { useRouter } from 'vue-router';
import { Button } from '@/components/ui/button';
import { Package, AlertCircle } from 'lucide-vue-next';

import { Icon } from "@iconify/vue";

const router = useRouter();
const serverNodes = ref([])
const loading = ref(true)

onMounted(() => {
  fetchServerNodes().then(res => {
    serverNodes.value = res.data || []
    loading.value = false
  }).catch(err => {
    console.error('获取节点信息失败:', err)
    loading.value = false
  })
})

const goToStore = () => {
  router.push('/store')
}
</script>

<template>
  <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
    <!-- 加载中骨架屏 -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2">
      <div v-for="i in 6" :key="i" class="flex items-center gap-4 px-5 py-4 border-b border-zinc-100 dark:border-zinc-800 sm:odd:border-r">
        <div class="w-7 h-7 bg-zinc-100 dark:bg-zinc-800 rounded animate-pulse"></div>
        <div class="flex-1">
          <div class="h-4 bg-zinc-100 dark:bg-zinc-800 rounded w-24 animate-pulse"></div>
        </div>
        <div class="h-4 bg-zinc-100 dark:bg-zinc-800 rounded w-12 animate-pulse"></div>
      </div>
    </div>

    <!-- 无有效订阅提示 -->
    <div v-else-if="serverNodes.length === 0" class="flex flex-col items-center justify-center py-12 px-6 text-center">
      <!-- 国旗展示 -->
      <div class="grid grid-cols-8 gap-2 mb-5">
        <Icon icon="emojione:flag-for-united-states" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-japan" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-united-kingdom" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-singapore" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-germany" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-south-korea" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-hong-kong-sar-china" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-taiwan" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-france" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-canada" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-australia" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-netherlands" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-switzerland" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-ireland" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-sweden" :width="28" :height="28" />
        <Icon icon="emojione:flag-for-italy" :width="28" :height="28" />
      </div>
      <p class="text-base font-medium text-zinc-900 dark:text-zinc-100 mb-2">还没有可用的节点</p>
      <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">订阅套餐后即可解锁全球加速节点</p>
      <Button @click="goToStore" size="sm">
        <Package class="w-4 h-4 mr-2" />
        购买套餐
      </Button>
    </div>

    <!-- 节点列表 -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-2">
      <div
        v-for="(item, index) in serverNodes"
        :key="item.id || item.name"
        class="flex items-center gap-4 px-5 py-4 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors border-b border-zinc-100 dark:border-zinc-800 sm:odd:border-r"
        :class="{ 'sm:border-b-0': index >= serverNodes.length - 2 && serverNodes.length % 2 === 0, 'sm:last:border-b-0': serverNodes.length % 2 !== 0 }"
      >
        <div class="w-7 h-7 shrink-0 flex items-center justify-center">
          <Country :country="item.name" :size="24" />
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">{{ item.name }}</p>
        </div>
        <span class="text-xs text-zinc-400">{{ item.type }}</span>
        <span
          class="text-xs font-medium tabular-nums"
          :class="item.rate <= 1 ? 'text-zinc-900 dark:text-zinc-100' : 'text-zinc-400'"
        >
          {{ item.rate }}x
        </span>
      </div>
    </div>
  </div>
</template>
