<script setup lang="ts">
import {Icon} from "@iconify/vue";
import {computed} from "vue";
import { Star } from 'lucide-vue-next';

interface Item {
  id: number;
  name: string;
  period: 'month_price' | 'quarter_price' | 'half_year_price' | 'year_price' | 'two_year_price' | 'three_year_price' | 'onetime_price';
  period_pay: string
  period_num: string;
  price: number;
  content: string;
  _hidden?: string;
}
interface IProps {
  item: Item;
  button?: boolean;
  check?: boolean;
}

const p = defineProps<IProps>()

// 获取套餐的徽章信息
const getPlanBadge = (item: Item) => {
  if (item._hidden) return item._hidden;
  try {
    const json = JSON.parse(item.content);
    if (json && typeof json === 'object' && !Array.isArray(json) && json._hidden) {
      return json._hidden;
    }
    if (Array.isArray(json)) {
      for (const obj of json) {
        if (obj && typeof obj === 'object' && obj._hidden) {
          return obj._hidden;
        }
      }
    }
  } catch (e) {}
  return null;
};

const cpData = computed(() => {

  const content = p.item.content
  let json
  try {
    json = JSON.parse(content)
  } catch (e) {
    json = null
  }
  let features
  if (json instanceof Array) {
    features = json
  }
  else {
    features = content
  }

  // 将价格*0.01并转换为只有两位小数的数字
  const price = (p.item.price * 0.01).toFixed(2)

  // 获取徽章
  const badge = getPlanBadge(p.item)

  return {
    features,
    price,
    badge,
  }
})
</script>
<template>
  <div
    class="relative cursor-pointer border rounded-xl p-4 transition-all duration-300 bg-white dark:bg-zinc-900 overflow-hidden"
    :class="check
      ? 'border-primary shadow-lg -translate-y-1'
      : 'border-zinc-200 dark:border-zinc-800 hover:-translate-y-1 hover:shadow-md hover:border-zinc-300 dark:hover:border-zinc-700'"
  >
    <!-- 徽章 - 斜角样式 -->
    <div
      v-if="cpData.badge"
      class="absolute top-4 -right-8 bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 text-white text-xs font-bold px-8 py-1 rotate-45 shadow-lg"
    >
      <Star class="w-3 h-3 inline mr-0.5" />
      {{ cpData.badge }}
    </div>

    <div class="flex items-center">
      <Icon icon="tabler:circle-check-filled" :width="32" v-if="check" class="text-primary" />
      <Icon icon="ph:planet-fill" :width="32" v-else class="text-zinc-400 dark:text-zinc-500" />
      <span class="flex-grow px-1 font-medium text-zinc-900 dark:text-zinc-100">{{ item.name }}</span>
      <span class="text-sm text-zinc-500 dark:text-zinc-400">{{ item.period_num }}</span>
    </div>
    <div class="flex justify-center items-end my-6 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
      <span class="text-sm text-zinc-500 dark:text-zinc-400">¥</span>
      <span class="text-3xl font-bold mx-1 leading-none" :class="check ? 'text-primary' : 'text-zinc-900 dark:text-zinc-100'">{{cpData.price}}</span>
      <span class="text-sm text-zinc-500 dark:text-zinc-400">/{{ item.period_pay }}</span>
    </div>
    <div>
      <div class="grid gap-2">
        <div v-for="(item, index) in cpData.features" :key="index" class="flex items-start" :class="item.support ? 'text-zinc-700 dark:text-zinc-300' : 'text-zinc-400 dark:text-zinc-500'">
          <Icon v-if="item.support" :width="24" icon="tabler:circle-check-filled" class="text-green-500 dark:text-green-400 shrink-0 mr-1" />
          <Icon v-else :width="24" icon="tabler:circle-x-filled" class="text-zinc-300 dark:text-zinc-600 shrink-0 mr-1" />
          <div class="text-sm">{{item.feature}}</div>
        </div>
      </div>
    </div>
    <div v-if="button" class="flex justify-center items-center py-2 mt-4 font-bold text-white bg-primary rounded-lg hover:bg-primary/90 transition-colors">
      <router-link :to="`/dashboard/store/plan/${item.id}?period=${item.period}`" class="text-white no-underline">立即购买</router-link>
    </div>
  </div>
</template>
