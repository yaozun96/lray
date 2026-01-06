<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Flame, ArrowRight, Sparkles } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';

const cpData = computed(() => {
  const { feature, title, description, headerElement, headerBg, headerBtnText } = window.config.home;
  const { shop, dashboard, download } = window.config.commonNav;

  return {
    feature: feature || '专为大陆用户打造的高速网络',
    title: title || 'AirBus, 专为大陆优化的空中巴士',
    description: description || '',
    headerElement: headerElement || 'responsive-web-animation.png',
    headerBg: headerBg || 'img/localized/header-bg.webp',
    headerBtnText: headerBtnText || '立即购买',
    btn1: shop || '立即购买',
    btn2: download || '软件下载',
    btn3: dashboard || '控制台',
  };
});

// 标题内容
const typedTitle = ref(cpData.value.title);

// 循环显示的文字内容
const phrases = ['稳如泰山', '快如闪电', '高性价比', '安全隐私'];
const currentPhrase = ref('');
const typingSpeed = 300;
const delayAfterFullText = 1000;
let phraseIndex = 0;

const typePhrase = (index: number) => {
  if (index < phrases[phraseIndex].length) {
    currentPhrase.value += phrases[phraseIndex].charAt(index);
    setTimeout(() => typePhrase(index + 1), typingSpeed);
  } else {
    setTimeout(() => {
      currentPhrase.value = '';
      phraseIndex = (phraseIndex + 1) % phrases.length;
      typePhrase(0);
    }, delayAfterFullText);
  }
};

onMounted(() => {
  typePhrase(0);
});
</script>

<template>
  <div
    class="relative flex justify-center bg-cover bg-center bg-no-repeat min-h-[480px] sm:min-h-[520px]"
    :style="{ backgroundImage: `url(${cpData.headerBg})` }"
  >
    <!-- 背景遮罩 - 更柔和的渐变 -->
    <div class="absolute inset-0 bg-gradient-to-b from-black/50 via-black/40 to-black/60 backdrop-blur-[2px]"></div>

    <!-- 内容区域 -->
    <div class="relative z-10 w-full max-w-6xl px-6 flex flex-col md:flex-row justify-between items-center py-16 md:py-0 text-white">
      <!-- 左侧文字 -->
      <div class="max-w-xl z-20">
        <!-- Feature 标签 - Shadcn 风格 Badge -->
        <div
          v-if="cpData.feature"
          class="inline-flex items-center gap-2 px-4 py-2 bg-white/10 border border-white/20 rounded-full text-sm text-white/90 mb-6 backdrop-blur-sm"
        >
          <Sparkles class="w-4 h-4 text-amber-400" />
          <span>{{ cpData.feature }}</span>
        </div>

        <!-- 标题 - 更统一的设计 -->
        <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold leading-tight mb-2 text-white">
          {{ typedTitle }}
        </h1>
        <div class="flex items-baseline gap-2 mb-2">
          <span class="text-3xl sm:text-4xl lg:text-5xl font-bold text-primary min-w-[4em]">
            {{ currentPhrase }}<span class="animate-pulse">|</span>
          </span>
        </div>
        <h2 class="text-2xl sm:text-3xl lg:text-4xl font-semibold text-white/90 mb-6">
          的跨境网络互联服务
        </h2>

        <!-- 描述 -->
        <p v-if="cpData.description" class="text-base text-white/70 mb-8 max-w-md leading-relaxed">
          {{ cpData.description }}
        </p>

        <!-- 按钮 - 使用 Shadcn Button -->
        <div class="flex flex-col sm:flex-row gap-3">
          <router-link to="/shop?coupon=welcome">
            <Button size="lg" class="w-full sm:w-auto px-8 py-6 text-base font-medium rounded-xl bg-primary hover:bg-primary/90 shadow-lg shadow-primary/25">
              {{ cpData.btn1 }}
              <ArrowRight class="w-5 h-5 ml-2" />
            </Button>
          </router-link>
        </div>
      </div>

      <!-- 右侧图片 -->
      <div class="flex-1 hidden md:flex justify-end items-center">
        <img :src="cpData.headerElement" alt="ele" class="w-2/3 max-w-md h-auto object-contain drop-shadow-2xl" />
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
