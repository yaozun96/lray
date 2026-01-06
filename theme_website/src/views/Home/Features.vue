<script setup lang="ts">
import { computed } from "vue";
import { Card, CardContent } from '@/components/ui/card';
import { Zap, Shield, Globe, Rocket } from 'lucide-vue-next';

const cpData = computed(() => {
  const { FeatureTitle, FeatureDescription, Features } = window.config.home;

  return {
    FeatureTitle: FeatureTitle || 'AirBus, 专为大陆优化的空中巴士',
    FeatureDescription: FeatureDescription || '专为大陆优化，犹如空中巴士，让你的网络体验更加流畅',
    Features: Features || [
      {
        title: '专为大陆用户打造的高速网络',
        desc: '专为大陆用户打造的高速网络，让你的网络体验更加流畅',
      },
      {
        title: '专为大陆用户打造的高速网络',
        desc: '专为大陆用户打造的高速网络，让你的网络体验更加流畅',
      },
      {
        title: '专为大陆用户打造的高速网络',
        desc: '专为大陆用户打造的高速网络，让你的网络体验更加流畅',
      },
      {
        title: '专为大陆用户打造的高速网络',
        desc: '专为大陆用户打造的高速网络，让你的网络体验更加流畅',
      },
    ],
  };
});

// 图标映射
const icons = [Zap, Shield, Globe, Rocket];
</script>

<template>
  <div class="flex justify-center py-16 sm:py-20">
    <div class="w-full max-w-6xl px-6">
      <!-- 标题区域 -->
      <div class="text-center mb-12 sm:mb-16">
        <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-zinc-900 dark:text-zinc-100 mb-4">
          {{ cpData.FeatureTitle }}
        </h2>
        <p class="text-sm sm:text-base text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto">
          {{ cpData.FeatureDescription }}
        </p>
      </div>

      <!-- 特性卡片网格 - 使用 Shadcn Card -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-5 sm:gap-6">
        <Card
          v-for="(item, index) in cpData.Features"
          :key="index"
          class="group relative overflow-hidden border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 hover:border-primary/50 dark:hover:border-primary/50 transition-all duration-300 hover:shadow-lg hover:shadow-primary/5"
        >
          <CardContent class="p-6 sm:p-8">
            <div class="flex items-start gap-4">
              <!-- 图标 -->
              <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-primary/10 dark:bg-primary/20 flex items-center justify-center group-hover:bg-primary/20 dark:group-hover:bg-primary/30 transition-colors">
                <component :is="icons[index % icons.length]" class="w-6 h-6 text-primary" />
              </div>

              <!-- 内容 -->
              <div class="flex-1 min-w-0">
                <h3 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100 mb-2 group-hover:text-primary transition-colors">
                  {{ item.title }}
                </h3>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 leading-relaxed">
                  {{ item.desc }}
                </p>
              </div>
            </div>
          </CardContent>

          <!-- 悬浮装饰线 -->
          <div class="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-primary to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
        </Card>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
