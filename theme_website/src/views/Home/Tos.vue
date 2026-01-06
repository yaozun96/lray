<script setup lang="ts">
import Footer from "@/views/News/Footer.vue";

// Shadcn Vue 组件
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

// Lucide Icons
import { AlertCircle } from 'lucide-vue-next';
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <!-- 动画背景 -->
    <div class="fixed inset-0 pointer-events-none overflow-hidden -z-10">
      <div class="floating-shape shape-1"></div>
      <div class="floating-shape shape-2"></div>
      <div class="floating-shape shape-3"></div>
      <div class="floating-shape shape-4"></div>
      <div class="floating-shape shape-5"></div>
    </div>

    <!-- 主内容 -->
    <div class="flex-1 py-12 sm:py-16 px-4 sm:px-6">
      <div class="max-w-3xl mx-auto">
        <!-- 标题区域 -->
        <div class="text-center mb-8">
          <img
            src="/assets/illustrations/undraw_knowledge_0ty5.svg"
            alt="服务条款"
            class="w-32 h-32 md:w-40 md:h-40 object-contain mx-auto mb-2"
          />
          <h1 class="text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100">
            服务条款
          </h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">Terms Of Service</p>
        </div>

        <!-- 内容卡片 -->
        <Card class="border-zinc-200 dark:border-zinc-800">
          <CardContent class="p-6 sm:p-8 space-y-6">
            <!-- 欢迎段落 -->
            <div class="space-y-4 text-zinc-600 dark:text-zinc-400 leading-relaxed">
              <p>
                欢迎您访问我们的产品 <strong class="text-zinc-900 dark:text-zinc-100">Lray</strong>（包括网站等产品提供的服务，以下简称「产品和服务」），由 <strong class="text-zinc-900 dark:text-zinc-100">Lray Team</strong>（以下简称「我们」）开发并运营。
              </p>
              <p>
                请在使用我们的产品和服务之前仔细阅读以下服务条款。通过访问或使用我们提供的产品和服务，即表示您同意并接受本协议中的所有条款和条件。如果您不同意此服务条款，请立即停止使用我们的产品和服务。我们只会在您同意本服务条款后向您提供服务。此协议受全球和国内商业法律的约束。任何使用我们提供的服务的行为，将被视为您已知悉并同意遵守以下服务条款。
              </p>
            </div>

            <!-- 条款标题 -->
            <div class="flex items-center gap-2 pt-4">
              <AlertCircle class="w-5 h-5 text-primary" />
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                可接受的服务条款（TOS）
              </h2>
            </div>
            <p class="text-zinc-600 dark:text-zinc-400">
              请注意，以下服务条款（TOS）用于约束用户的行为，以保障我们服务的质量。
            </p>

            <!-- 条款列表 -->
            <ul class="space-y-3">
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">1</span>
                <span>一旦购买完成，我们将不提供任何形式的退款，购买即表示您同意此条款。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">2</span>
                <span>禁止使用我们的服务传输 BT/P2P 流量。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">3</span>
                <span>禁止长期超出合理范围使用共享资源服务（如采集、爬虫、大量自动化脚本），以免影响其他用户的使用体验。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">4</span>
                <span>禁止使用我们的服务发送垃圾邮件。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">5</span>
                <span>禁止在使用我们的服务时违反当地运营商法律的内容。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">6</span>
                <span>禁止共享您的账户给他人使用。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">7</span>
                <span>禁止转卖您的账户给他人。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">8</span>
                <span>在中国大陆，禁止在任何社区、网站或其他媒体上讨论与我们服务相关的内容。一旦发现并核实，我们有权随时终止您的服务。</span>
              </li>
              <li class="flex gap-3 text-zinc-600 dark:text-zinc-400">
                <span class="flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium flex items-center justify-center">9</span>
                <span>禁止使用我们的 AFF 推广服务自己邀请自己获得返利，套取平台折扣。如果发现，我们有权终止您的服务，并且不退款。</span>
              </li>
            </ul>

            <!-- 结尾 -->
            <div class="pt-4 space-y-2 text-zinc-600 dark:text-zinc-400">
              <p>我们保留随时更改服务条款的权利，且条款更改后即刻生效。</p>
              <p class="text-sm text-zinc-500 dark:text-zinc-500">
                最后修订日期：2024/09/24
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>

    <!-- 页脚 -->
    <Footer />
  </div>
</template>

<style scoped>
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
</style>
