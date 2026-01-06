<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from "vue";
import { useClipboard } from "@vueuse/core";
import { message } from 'ant-design-vue';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

// Lucide Icons
import { Download, ExternalLink } from 'lucide-vue-next';

// Iconify for OS logos
import { Icon } from '@iconify/vue';

// 平台图标映射 (使用 Iconify 图标名称)
const platformIconNames: Record<string, string> = {
  Windows: 'mdi:microsoft-windows',
  Android: 'mdi:android',
  IOS: 'mdi:apple',
  Mac: 'mdi:apple',
};

const getOS = () => {
  const userAgent = window.navigator.userAgent;

  if (/Windows/i.test(userAgent)) {
    return 'Windows';
  } else if (/Macintosh/i.test(userAgent)) {
    return 'Mac';
  } else if (/Android/i.test(userAgent)) {
    return 'Android';
  } else if (/iPhone|iPad/i.test(userAgent)) {
    return 'IOS';
  } else {
    return 'Windows';
  }
};

const knowledge = ref({
  display: false,
  title: 'MacOS 官方客户端教程',
  url: 'https://www.baidu.com',
  content: ''
});

const currentOS = ref('');

const cpData = computed(() => {
  const { logo, Download } = window.config;
  let title = '下载客户端';
  let desc = '全球最快的 VPN 解决方案';

  const platforms = [
    { id: 'Windows', title: 'Windows 客户端下载', version: '1.0.0', link1: null, link2: null },
    { id: 'Android', title: 'Android 客户端下载', version: '1.0.0', link1: null, link2: null },
    { id: 'IOS', title: 'IOS 客户端下载', version: '1.0.0', link1: null, link2: null },
    { id: 'Mac', title: 'MacOS 客户端下载', version: '1.0.0', link1: null, link2: null },
  ];

  if (Download) {
    platforms.forEach(item => {
      const obj = Download[item.id];
      if (obj) {
        item.title = obj.title || item.title;
        item.version = obj.version || item.version;
        item.link1 = obj.link1 || null;
        item.link2 = obj.link2 || null;
      }
    });

    title = Download.title || title;
    desc = Download.desc || desc;
  }

  const currentPlatform = platforms.find(item => item.id === currentOS.value) || platforms[0];

  return {
    title,
    desc,
    logo: logo || '/images/default-logo.svg',
    platforms,
    currentPlatform,
  };
});

// 平台渐变背景色
const platformGradients: Record<string, string> = {
  Windows: 'from-blue-500 to-blue-600',
  Android: 'from-green-500 to-green-600',
  IOS: 'from-zinc-800 to-zinc-900',
  Mac: 'from-zinc-500 to-zinc-600',
};

// 平台阴影色
const platformShadows: Record<string, string> = {
  Windows: 'shadow-blue-500/30',
  Android: 'shadow-green-500/30',
  IOS: 'shadow-zinc-800/30',
  Mac: 'shadow-zinc-500/30',
};

onMounted(() => {
  currentOS.value = getOS();
});

const openKnowledge = (link: any) => {
  knowledge.value.title = link.title;
  knowledge.value.url = link.url;
  knowledge.value.content = link.html;
  knowledge.value.display = true;
};

const { copy, copied } = useClipboard();

watch(copied, (v) => {
  if (v) {
    message.success("复制成功");
  }
});

const handleClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (target.getAttribute('aria-label') !== 'button') return;
  const dataUrl = target.getAttribute('data-url');
  const dataClipboardText = target.getAttribute('data-clipboard-text');
  if (dataUrl) {
    window.open(dataUrl);
  } else if (dataClipboardText) {
    copy(dataClipboardText);
  }
};

onMounted(() => {
  document.addEventListener('click', handleClick);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClick);
});
</script>

<template>
  <div class="relative min-h-screen flex items-center justify-center overflow-hidden">
    <!-- 动画背景 -->
    <div class="absolute inset-0 pointer-events-none overflow-hidden">
      <div class="floating-shape shape-1"></div>
      <div class="floating-shape shape-2"></div>
      <div class="floating-shape shape-3"></div>
      <div class="floating-shape shape-4"></div>
      <div class="floating-shape shape-5"></div>
    </div>

    <!-- 主内容 -->
    <div class="relative z-10 w-full max-w-xl px-4 sm:px-6 py-12 sm:py-16 flex flex-col items-center">
      <!-- Logo -->
      <div class="w-20 h-20 p-4 rounded-2xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 shadow-lg flex items-center justify-center mb-8">
        <img :src="cpData.logo" alt="LOGO" class="w-full h-full object-contain" />
      </div>

      <!-- 标题描述 -->
      <div class="text-center mb-10">
        <h1 class="download-title text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100 mb-5" v-html="cpData.title"></h1>
        <p class="text-zinc-500 dark:text-zinc-400 text-base" v-html="cpData.desc"></p>
      </div>

      <!-- 当前平台卡片 -->
      <Card
        class="w-full relative overflow-hidden border-0 text-white shadow-xl mb-6"
        :class="[
          `bg-gradient-to-br ${platformGradients[cpData.currentPlatform.id] || platformGradients.Windows}`,
          platformShadows[cpData.currentPlatform.id] || platformShadows.Windows
        ]"
      >
        <CardContent class="p-8 sm:p-10 relative min-h-[220px] flex flex-col justify-between">
          <!-- 平台图标 (右上角) -->
          <div class="absolute top-8 right-8 opacity-20">
            <Icon
              :icon="platformIconNames[cpData.currentPlatform.id] || 'mdi:microsoft-windows'"
              class="w-24 h-24 sm:w-28 sm:h-28"
            />
          </div>

          <!-- 标题 -->
          <h2 class="text-2xl sm:text-3xl font-bold mb-auto pr-28">
            {{ cpData.currentPlatform.title }}
          </h2>

          <!-- 下载按钮 -->
          <div class="flex flex-wrap gap-4 mt-8">
            <Button
              v-if="cpData.currentPlatform.link1"
              @click="openKnowledge(cpData.currentPlatform.link1)"
              variant="secondary"
              size="lg"
              class="bg-white/20 hover:bg-white/30 text-white border-0 gap-2"
            >
              <Download class="w-5 h-5" />
              {{ cpData.currentPlatform.link1.title }}
            </Button>
            <Button
              v-if="cpData.currentPlatform.link2"
              @click="openKnowledge(cpData.currentPlatform.link2)"
              variant="secondary"
              size="lg"
              class="bg-white/20 hover:bg-white/30 text-white border-0 gap-2"
            >
              <ExternalLink class="w-5 h-5" />
              {{ cpData.currentPlatform.link2.title }}
            </Button>
            <p v-if="!cpData.currentPlatform.link1 && !cpData.currentPlatform.link2" class="text-white/70 text-sm">
              暂无下载链接
            </p>
          </div>
        </CardContent>
      </Card>

      <!-- 其他平台选择 -->
      <Card class="w-full border-zinc-200 dark:border-zinc-800">
        <CardContent class="p-5 flex items-center">
          <span class="text-sm text-zinc-500 dark:text-zinc-400 flex-1">其它版本:</span>
          <TooltipProvider>
            <div class="flex items-center gap-3">
              <Tooltip v-for="item in cpData.platforms" :key="item.id">
                <TooltipTrigger as-child>
                  <button
                    @click="currentOS = item.id"
                    class="p-2.5 rounded-lg transition-all duration-200"
                    :class="[
                      currentOS === item.id
                        ? 'bg-zinc-900 dark:bg-white text-white dark:text-zinc-900'
                        : 'text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800'
                    ]"
                  >
                    <Icon :icon="platformIconNames[item.id] || 'mdi:microsoft-windows'" class="w-6 h-6" />
                  </button>
                </TooltipTrigger>
                <TooltipContent>
                  <p>{{ item.title }}</p>
                </TooltipContent>
              </Tooltip>
            </div>
          </TooltipProvider>
        </CardContent>
      </Card>
    </div>

    <!-- 教程弹窗 -->
    <Dialog v-model:open="knowledge.display">
      <DialogContent class="max-w-2xl max-h-[85vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>{{ knowledge.title }}</DialogTitle>
        </DialogHeader>
        <div class="flex-1 overflow-y-auto pr-2">
          <div class="html-content" v-html="knowledge.content"></div>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
/* 标题换行间距 */
.download-title {
  line-height: 1.8 !important;
}

/* 浮动动画背景 */
.floating-shape {
  position: absolute;
  border-radius: 50%;
  opacity: 0.06;
  filter: blur(40px);
  animation: float-around 20s ease-in-out infinite;
}

.floating-shape.shape-1 {
  width: 400px;
  height: 400px;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  top: -100px;
  right: -100px;
  animation-delay: 0s;
  animation-duration: 25s;
}

.floating-shape.shape-2 {
  width: 300px;
  height: 300px;
  background: linear-gradient(135deg, #06b6d4, #3b82f6);
  bottom: -50px;
  left: -50px;
  animation-delay: -5s;
  animation-duration: 20s;
}

.floating-shape.shape-3 {
  width: 200px;
  height: 200px;
  background: linear-gradient(135deg, #8b5cf6, #ec4899);
  top: 40%;
  left: 30%;
  animation-delay: -10s;
  animation-duration: 22s;
}

.floating-shape.shape-4 {
  width: 250px;
  height: 250px;
  background: linear-gradient(135deg, #10b981, #06b6d4);
  top: 20%;
  right: 20%;
  animation-delay: -7s;
  animation-duration: 18s;
}

.floating-shape.shape-5 {
  width: 180px;
  height: 180px;
  background: linear-gradient(135deg, #f59e0b, #ef4444);
  bottom: 20%;
  right: 30%;
  animation-delay: -12s;
  animation-duration: 23s;
}

@keyframes float-around {
  0%, 100% {
    transform: translate(0, 0) scale(1);
  }
  25% {
    transform: translate(30px, -30px) scale(1.05);
  }
  50% {
    transform: translate(-20px, 20px) scale(0.95);
  }
  75% {
    transform: translate(-30px, -20px) scale(1.02);
  }
}

/* HTML 内容样式 */
.html-content :deep(h1) {
  font-size: 1.75rem;
  font-weight: 700;
  line-height: 1.4;
  border-left: 4px solid hsl(var(--primary));
  padding-left: 12px;
  margin-bottom: 16px;
}

.html-content :deep(h2) {
  font-size: 1.375rem;
  font-weight: 700;
  line-height: 1.4;
  margin-bottom: 12px;
}

.html-content :deep(h3) {
  font-size: 1.125rem;
  font-weight: 600;
  line-height: 1.4;
  margin-bottom: 8px;
}

.html-content :deep(p) {
  font-size: 1rem;
  line-height: 1.8;
  margin-bottom: 12px;
}

.html-content :deep(div[aria-label="section"]) {
  margin-bottom: 32px;
}

.html-content :deep(div[aria-label="buttonGroup"]) {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.html-content :deep(div[aria-alert]) {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  color: #dc2626;
  background-color: #fef2f2;
  border: 1px dashed #dc2626;
  margin: 12px 0;
  border-radius: 12px;
  gap: 12px;
}

@media (max-width: 640px) {
  .html-content :deep(div[aria-alert]) {
    flex-direction: column;
    text-align: center;
  }
}

.html-content :deep(div[aria-alert] > a) {
  text-decoration: none;
  color: white;
  background-color: #dc2626;
  padding: 8px 16px;
  border-radius: 8px;
  white-space: nowrap;
}

/* 默认图片样式 - 居中显示 */
.html-content :deep(img) {
  display: block;
  max-width: 100%;
  margin: 16px auto;
  border-radius: 8px;
}

/* 特定容器内的图片覆盖默认样式 */
/* 只有纯图片的 div[aria-label="img"] 才使用 grid，有 p 标签的使用普通布局 */
.html-content :deep(div[aria-label="img"]:not(:has(p))) {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
  margin: 16px 0;
}

/* 包含 p 标签的图片容器使用普通块级布局 */
.html-content :deep(div[aria-label="img"]:has(p)) {
  width: 100%;
  display: block;
  margin: 16px 0;
}

.html-content :deep(div[aria-label="img"]:has(p) p) {
  margin: 12px 0 8px 0;
  font-weight: 500;
}

.html-content :deep(div[aria-label="img"] img) {
  width: 100%;
  border-radius: 8px;
  margin: 0;
}

.html-content :deep(div[aria-label="img-scroll"]) {
  position: relative;
  width: 100%;
  overflow-x: auto;
  display: flex;
  padding: 20px 20px 48px 20px;
  background-color: #18181b;
  border-radius: 12px;
  gap: 12px;
}

.html-content :deep(div[aria-label="img-scroll"])::after {
  content: '<<< 左滑查看完整操作图文';
  position: absolute;
  bottom: 12px;
  left: 20px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 12px;
}

.html-content :deep(div[aria-label="img-scroll"] img) {
  max-width: 260px;
  width: 100%;
  border-radius: 8px;
  margin: 0;
}

.html-content :deep(div[aria-label="img-pc"]) {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.html-content :deep(div[aria-label="img-pc"] img) {
  width: auto;
  height: 320px;
  border-radius: 8px;
  margin: 0;
}

.html-content :deep(p[aria-status]) {
  border-left: 4px solid;
  padding: 8px 16px;
  margin: 12px 0;
  border-radius: 0 8px 8px 0;
}

.html-content :deep(p[aria-status="warning"]) {
  background: #fefce8;
  border-color: #eab308;
}

.html-content :deep(p[aria-status="success"]) {
  background: #f0fdf4;
  border-color: #22c55e;
}

.html-content :deep(p[aria-status="error"]) {
  background: #fef2f2;
  border-color: #ef4444;
}

.html-content :deep(p[aria-number]) {
  position: relative;
  margin: 8px 0;
  padding-left: 36px;
}

.html-content :deep(p[aria-number])::before {
  content: attr(aria-number);
  position: absolute;
  left: 0;
  top: 2px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: white;
  font-size: 12px;
  font-weight: 600;
  background: hsl(var(--primary));
}

.html-content :deep([aria-style="primary"]) {
  color: hsl(var(--primary));
}

.html-content :deep([aria-label="button"]) {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  margin: 12px 4px 12px 0;
  padding: 10px 20px;
  border-radius: 8px;
  background-color: hsl(var(--primary));
  color: white;
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.html-content :deep([aria-label="button"]:hover) {
  opacity: 0.9;
}

.html-content :deep([aria-label="buttonSecondary"]) {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  margin: 12px 4px 12px 0;
  padding: 10px 20px;
  border-radius: 8px;
  background-color: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
  font-weight: 600;
  text-decoration: none;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.html-content :deep([aria-label="buttonSecondary"]:hover) {
  background-color: hsl(var(--accent));
}
</style>
