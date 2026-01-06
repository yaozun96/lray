<script setup lang="ts">
import { computed } from "vue";
import { MapPin } from 'lucide-vue-next';

const cpData = computed(() => {
  const { AreaTitle, AreaDescription, AreaImg } = window.config.home;

  return {
    AreaTitle: AreaTitle || 'AirBus, 专为大陆优化的空中巴士',
    AreaDescription: AreaDescription || '专为大陆优化，犹如空中巴士，让你的网络体验更加流畅',
    AreaImg: AreaImg || 'img/localized/area-map.png',
  };
});
</script>

<template>
  <div class="flex justify-center py-16 sm:py-20 bg-white dark:bg-zinc-900">
    <div class="w-full max-w-6xl px-6 flex flex-col items-center">
      <!-- 标题区域 -->
      <div class="text-center mb-10 sm:mb-12">
        <div class="inline-flex items-center gap-2 px-4 py-2 bg-primary/10 dark:bg-primary/20 rounded-full text-sm text-primary mb-4">
          <MapPin class="w-4 h-4" />
          <span>全球节点覆盖</span>
        </div>
        <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-zinc-900 dark:text-zinc-100 mb-4">
          {{ cpData.AreaTitle }}
        </h2>
        <p class="text-sm sm:text-base text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto">
          {{ cpData.AreaDescription }}
        </p>
      </div>

      <!-- 地图区域 -->
      <div class="relative flex justify-center items-center w-full rounded-2xl overflow-hidden bg-zinc-50 dark:bg-zinc-800/50 p-4 sm:p-8">
        <!-- 节点标记 -->
        <div class="node-dot" style="right: 20%; top: 51%;"></div>
        <div class="node-dot" style="right: 18%; top: 42%;"></div>
        <div class="node-dot" style="right: 14%; top: 42.5%;"></div>
        <div class="node-dot" style="right: 22%; top: 60%;"></div>
        <div class="node-dot" style="right: 48%; top: 22%;"></div>
        <div class="node-dot" style="right: 45%; top: 30%;"></div>
        <div class="node-dot" style="right: 88%; top: 30%;"></div>
        <div class="node-dot" style="right: 85%; top: 40%;"></div>

        <img :src="cpData.AreaImg" alt="area" class="max-w-full h-auto rounded-xl" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.node-dot {
  position: absolute;
  width: 16px;
  height: 16px;
  z-index: 9;
  background: hsl(var(--primary));
  box-shadow: 0 2px 8px 1px hsl(var(--primary) / 0.6);
  border-radius: 50%;
  border: 3px solid white;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.node-dot:hover {
  transform: scale(1.2);
}

.node-dot::after {
  position: absolute;
  top: 50%;
  left: 50%;
  display: block;
  content: "";
  height: 16px;
  width: 16px;
  margin: -8px 0 0 -8px;
  animation: pulsate 2s linear infinite;
  background-color: hsl(var(--primary));
  border-radius: 100%;
  z-index: 0;
}

@keyframes pulsate {
  0% {
    transform: scale(0);
    opacity: 0.05;
  }
  20% {
    transform: scale(0.7);
    opacity: 0.1;
  }
  40% {
    transform: scale(1.5);
    opacity: 0.2;
  }
  60% {
    transform: scale(2);
    opacity: 0.2;
  }
  100% {
    transform: scale(2.5);
    opacity: 0;
  }
}
</style>
