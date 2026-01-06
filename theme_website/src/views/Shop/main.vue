<script setup lang="ts">
import { onMounted } from "vue";
import { useShop } from "./useShop";
import SubscribeTimeSelector from "@/views/Shop/SubscribeTimeSelector.vue";
import Cycle from "@/views/Shop/Cycle.vue";
import Account from "@/views/Shop/Account.vue";
import Pay from "@/views/Shop/Pay.vue";

// Lucide Icons
import { Check } from 'lucide-vue-next';

// Banner 配置
const bannerConfig = {
  title: window.config?.Buy?.title || '高可用的跨境网络互联服务',
  description: window.config?.Buy?.description || '',
  features: window.config?.Buy?.features || [],
  background: window.config?.Buy?.background,
  elementImg: window.config?.Buy?.elementImg,
};

const shop = useShop();

onMounted(() => {
  shop.fetchInit();
});
</script>

<template>
  <div class="min-h-screen">

    <!-- 顶部 Banner - 星空背景 -->
    <div class="relative hidden sm:block overflow-hidden bg-gradient-to-b from-zinc-950 via-zinc-900 to-zinc-950">
      <!-- 星空动画 -->
      <div class="stars-container absolute inset-0">
        <div class="stars stars-small"></div>
        <div class="stars stars-medium"></div>
        <div class="stars stars-large"></div>
      </div>

      <!-- 流星 -->
      <div class="shooting-star shooting-star-1"></div>
      <div class="shooting-star shooting-star-2"></div>

      <div class="relative max-w-6xl mx-auto px-4 sm:px-6 py-6 lg:py-8 flex items-center justify-between z-10">
        <div class="max-w-xl lg:max-w-2xl">
          <!-- 标题 -->
          <h1 class="text-xl sm:text-2xl lg:text-3xl font-bold text-white mb-4">
            {{ bannerConfig.title }}
          </h1>

          <!-- 特性列表 -->
          <div v-if="bannerConfig.features && bannerConfig.features.length > 0" class="grid grid-cols-1 gap-3.5">
            <div
              v-for="(feature, index) in bannerConfig.features"
              :key="index"
              class="flex items-center gap-3"
            >
              <div class="w-5 h-5 rounded-full border-2 border-blue-400 flex items-center justify-center">
                <Check class="w-3 h-3 text-blue-400" stroke-width="3" />
              </div>
              <span class="text-base text-white font-medium">{{ feature }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧装饰图片 -->
      <div
        v-if="bannerConfig.elementImg"
        class="hidden lg:block absolute right-8 xl:right-16 bottom-1/2 translate-y-1/2 w-[320px] xl:w-[380px] z-10 pointer-events-none"
      >
        <div class="rocket-container">
          <img :src="bannerConfig.elementImg" alt="" class="w-full h-auto drop-shadow-2xl rocket-img" />
        </div>
      </div>
    </div>

    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12 lg:py-16 pb-32">
      <!-- 页面标题 -->
      <div class="mb-8 sm:mb-10">
        <h1 class="text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100">注册订阅</h1>
        <p class="text-sm sm:text-base text-zinc-500 mt-2">选择适合您的订阅计划并创建账户</p>
      </div>

      <!-- 第一步：选择套餐 -->
      <SubscribeTimeSelector />

      <!-- 第二步：选择周期 -->
      <Cycle />

      <!-- 第三步：创建账户 -->
      <Account />

      <!-- 第四步：确认支付 -->
      <Pay />
    </div>
  </div>
</template>

<style scoped>
/* 星空背景 */
.stars-container {
  background: radial-gradient(ellipse at bottom, #1a1a2e 0%, #0a0a0f 100%);
}

.stars {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  animation: twinkle 4s ease-in-out infinite;
}

.stars-small {
  background-image:
    radial-gradient(1px 1px at 20px 30px, white, transparent),
    radial-gradient(1px 1px at 40px 70px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 50px 160px, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 90px 40px, white, transparent),
    radial-gradient(1px 1px at 130px 80px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 160px 120px, white, transparent),
    radial-gradient(1px 1px at 200px 50px, rgba(255,255,255,0.5), transparent),
    radial-gradient(1px 1px at 250px 100px, white, transparent),
    radial-gradient(1px 1px at 300px 70px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1px 1px at 350px 150px, white, transparent),
    radial-gradient(1px 1px at 400px 30px, rgba(255,255,255,0.6), transparent),
    radial-gradient(1px 1px at 450px 90px, white, transparent),
    radial-gradient(1px 1px at 500px 140px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1px 1px at 550px 60px, white, transparent),
    radial-gradient(1px 1px at 600px 120px, rgba(255,255,255,0.5), transparent);
  background-size: 650px 200px;
  animation-delay: 0s;
}

.stars-medium {
  background-image:
    radial-gradient(1.5px 1.5px at 100px 50px, white, transparent),
    radial-gradient(1.5px 1.5px at 200px 120px, rgba(255,255,255,0.9), transparent),
    radial-gradient(1.5px 1.5px at 300px 30px, white, transparent),
    radial-gradient(1.5px 1.5px at 400px 100px, rgba(255,255,255,0.8), transparent),
    radial-gradient(1.5px 1.5px at 500px 70px, white, transparent),
    radial-gradient(1.5px 1.5px at 150px 140px, rgba(255,255,255,0.7), transparent),
    radial-gradient(1.5px 1.5px at 350px 80px, white, transparent),
    radial-gradient(1.5px 1.5px at 550px 130px, rgba(255,255,255,0.6), transparent);
  background-size: 600px 180px;
  animation-delay: -1s;
}

.stars-large {
  background-image:
    radial-gradient(2px 2px at 80px 80px, white, transparent),
    radial-gradient(2px 2px at 240px 40px, rgba(255,255,255,0.9), transparent),
    radial-gradient(2px 2px at 400px 110px, white, transparent),
    radial-gradient(2px 2px at 520px 60px, rgba(255,255,255,0.8), transparent),
    radial-gradient(2.5px 2.5px at 180px 130px, #a5b4fc, transparent),
    radial-gradient(2.5px 2.5px at 460px 90px, #93c5fd, transparent);
  background-size: 580px 160px;
  animation-delay: -2s;
}

@keyframes twinkle {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* 流星 */
.shooting-star {
  position: absolute;
  width: 100px;
  height: 1px;
  background: linear-gradient(90deg, white, transparent);
  opacity: 0;
  transform: rotate(-45deg);
}

.shooting-star-1 {
  top: 20%;
  right: 20%;
  animation: shooting 6s ease-in-out infinite;
}

.shooting-star-2 {
  top: 40%;
  right: 40%;
  animation: shooting 6s ease-in-out infinite 3s;
}

@keyframes shooting {
  0% {
    opacity: 0;
    transform: translateX(0) translateY(0) rotate(-45deg);
  }
  5% {
    opacity: 1;
  }
  15% {
    opacity: 0;
    transform: translateX(-200px) translateY(200px) rotate(-45deg);
  }
  100% {
    opacity: 0;
    transform: translateX(-200px) translateY(200px) rotate(-45deg);
  }
}

/* 火箭动画 */
.rocket-container {
  position: relative;
  animation: rocketFloat 3s ease-in-out infinite;
}

.rocket-img {
  filter: drop-shadow(0 0 20px rgba(59, 130, 246, 0.5));
}

@keyframes rocketFloat {
  0%, 100% {
    transform: translateY(0) translateX(0);
  }
  50% {
    transform: translateY(-10px) translateX(5px);
  }
}
</style>
