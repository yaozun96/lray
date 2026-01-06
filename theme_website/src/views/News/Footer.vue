<script setup lang="ts">
import { computed } from "vue";

// Lucide Icons
import { ExternalLink } from 'lucide-vue-next';

const cpData = computed(() => {
  const { title, logo, Footer } = window.config;

  return {
    title: title || 'AirBus',
    logo: logo || 'img/localized/logo-fallback.png',
    copyRight: Footer?.copyRight || 'Copyright © 2024 AirBus LTD.',
    help: Footer?.help || [],
    connect: Footer?.connect || [],
  };
});
</script>

<template>
  <footer class="w-full border-t border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <div class="flex flex-col md:flex-row gap-8 md:gap-12">
        <!-- Logo 和版权信息 -->
        <div class="flex-1">
          <div class="flex items-center gap-3 mb-4">
            <img :src="cpData.logo" alt="LOGO" class="h-8 w-auto" />
            <span class="text-xl font-bold text-zinc-900 dark:text-zinc-100 font-['Fredoka_One',ui-sans-serif,system-ui,sans-serif]">
              {{ cpData.title }}
            </span>
          </div>
          <p class="text-sm text-zinc-500 dark:text-zinc-400">
            {{ cpData.copyRight }}
          </p>
        </div>

        <!-- 帮助中心 -->
        <div v-if="cpData.help.length > 0" class="min-w-[140px]">
          <h4 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
            帮助中心
          </h4>
          <ul class="space-y-3">
            <li v-for="item in cpData.help" :key="item.name">
              <a
                :href="item.link"
                target="_blank"
                rel="noopener noreferrer"
                class="group flex items-center gap-1.5 text-sm text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                {{ item.name }}
                <ExternalLink class="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />
              </a>
            </li>
          </ul>
        </div>

        <!-- 联系方式 -->
        <div v-if="cpData.connect.length > 0" class="min-w-[140px]">
          <h4 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
            联系方式
          </h4>
          <ul class="space-y-3">
            <li v-for="item in cpData.connect" :key="item.name">
              <a
                :href="item.link"
                target="_blank"
                rel="noopener noreferrer"
                class="group flex items-center gap-1.5 text-sm text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                {{ item.name }}
                <ExternalLink class="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />
              </a>
            </li>
          </ul>
        </div>
      </div>

    </div>
  </footer>
</template>

<style scoped>
</style>
