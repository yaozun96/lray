<script setup>
import { UserPlus, BadgePercent, Clock, Coins } from 'lucide-vue-next';
const pop = defineProps(['list']);
import { useUserStore } from "@/stores/User.js";
const user = useUserStore();
</script>

<template>
  <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 shadow-sm border border-zinc-200 dark:border-zinc-800">
    <div class="flex justify-between items-center">
      <div>
        <p class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">已注册用户数</p>
        <span class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{{ pop.list?.[0] }}</span>
        <span class="text-sm text-zinc-500 dark:text-zinc-400 ml-1">人</span>
      </div>
      <div class="w-12 h-12 bg-primary/10 text-primary rounded-xl p-2 flex items-center justify-center">
        <UserPlus class="w-6 h-6" />
      </div>
    </div>
  </div>
  <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 shadow-sm border border-zinc-200 dark:border-zinc-800">
    <div class="flex justify-between items-center">
      <div>
        <p class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">佣金比例</p>
        <span class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{{ pop.list?.[3] }}</span>
        <span class="text-sm text-zinc-500 dark:text-zinc-400 ml-1">%</span>
      </div>
      <div class="w-12 h-12 bg-primary/10 text-primary rounded-xl p-2 flex items-center justify-center">
        <BadgePercent class="w-6 h-6" />
      </div>
    </div>
  </div>

  <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 shadow-sm border border-zinc-200 dark:border-zinc-800">
    <div class="flex justify-between items-center">
      <div>
        <p class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">确认中的佣金</p>
        <span class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{{ (pop.list?.[2] / 100).toFixed(2) }}</span>
        <span class="text-sm text-zinc-500 dark:text-zinc-400 ml-1">{{ user.Config?.currency }}</span>
      </div>
      <div class="w-12 h-12 bg-primary/10 text-primary rounded-xl p-2 flex items-center justify-center">
        <Clock class="w-6 h-6" />
      </div>
    </div>
  </div>

  <div class="bg-white dark:bg-zinc-900 rounded-xl p-5 shadow-sm border border-zinc-200 dark:border-zinc-800">
    <div class="flex justify-between items-center">
      <div>
        <p class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">累计获得佣金</p>
        <span class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{{ (pop.list?.[1] / 100).toFixed(2) }}</span>
        <span class="text-sm text-zinc-500 dark:text-zinc-400 ml-1">{{ user.Config?.currency }}</span>
      </div>
      <div class="w-12 h-12 bg-primary/10 text-primary rounded-xl p-2 flex items-center justify-center">
        <Coins class="w-6 h-6" />
      </div>
    </div>
  </div>
</template>
