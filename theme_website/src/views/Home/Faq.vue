<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Footer from "@/views/News/Footer.vue"
import { Button } from '@/components/ui/button'
import { ChevronDown, MessageSquarePlus } from 'lucide-vue-next'

const router = useRouter()

// 整合的 FAQ 数据
const faqs = ref([
  { question: '什么是 IEPL 专线？', answer: 'IEPL（International Ethernet Private Line）是国际以太网专线，提供点对点的专用网络连接，具有低延迟、高稳定性和高带宽保障的特点，适合对网络质量要求较高的用户。' },
  { question: '你们安全可靠吗？', answer: '我们的团队来自于海外，我们承诺不记录任何日志，不向第三方提供信息。采用金融级加密算法，严格执行零日志政策，确保您的隐私安全。' },
  { question: '支持哪些设备和平台？', answer: '我们支持 Windows、macOS、iOS、Android、Linux、OpenWRT 等主流操作系统，同时我们也有官方的客户端供您选择使用，让您在任何设备上都能轻松使用。' },
  { question: '支持多少个设备同时使用？', answer: '我们不限制设备的数量使用，你可以共享给家人使用。' },
  { question: '如何选择套餐？', answer: '您可以根据自己的使用需求选择套餐。如果主要用于浏览网页和社交媒体，基础套餐即可；如果需要观看流媒体或进行大量数据传输，建议选择更高流量的套餐。' },
  { question: '可以升/降级套餐吗？', answer: '你可以在用户中心自主升级或降级套餐，系统会计算差价。' },
  { question: '流量用完了怎么办？', answer: '当套餐流量用完后，您可以购买流量包补充，或者等待下个计费周期自动重置。周期套餐每个月的账单日会自动重置流量，且流量不会叠加；永久流量套餐用完为止不重置。' },
  { question: '你们接受哪些付款方式？', answer: '支持支付宝或者 USDT/BTC 等主流支付方式。' },
  { question: '可以解锁哪些服务？', answer: 'Netflix、Hulu、HBO、TVB、Disney+ 等在内的多种流媒体和 ChatGPT、Claude 等 AI 工具。' },
])

const openFaqs = ref({})

function toggleFaq(index) {
  openFaqs.value[index] = !openFaqs.value[index]
}

function goToTicket() {
  router.push('/ticket')
}
</script>

<template>
  <div class="faq-page min-h-screen flex flex-col">
    <!-- Hero -->
    <section class="pt-16 pb-8 md:pt-24 md:pb-12">
      <div class="container mx-auto px-6 max-w-4xl text-center">
        <div class="flex justify-center mb-6">
          <img
            src="/assets/illustrations/undraw_questions_g2px.svg"
            alt="常见问题"
            class="w-48 h-48 md:w-56 md:h-56 object-contain"
          />
        </div>
        <h1 class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">常见问题</h1>
        <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 max-w-xl mx-auto">
          在这里您可以找到关于我们服务的常见问题解答
        </p>
      </div>
    </section>

    <!-- FAQ List -->
    <section class="py-8 md:py-12 flex-1">
      <div class="container mx-auto px-6 max-w-3xl">
        <div class="space-y-3">
          <div
            v-for="(faq, index) in faqs"
            :key="index"
            class="bg-white dark:bg-zinc-900 rounded-xl overflow-hidden shadow-sm"
          >
            <button
              @click="toggleFaq(index)"
              class="w-full px-6 py-5 text-left flex items-center justify-between hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
            >
              <span class="text-base font-medium text-zinc-900 dark:text-zinc-100 pr-4">{{ faq.question }}</span>
              <ChevronDown
                :class="[
                  'h-5 w-5 text-zinc-400 transition-transform duration-200 flex-shrink-0',
                  openFaqs[index] && 'rotate-180'
                ]"
              />
            </button>
            <div
              v-show="openFaqs[index]"
              class="px-6 pb-5 text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed border-t border-zinc-100 dark:border-zinc-800 pt-4"
            >
              {{ faq.answer }}
            </div>
          </div>
        </div>

        <!-- CTA -->
        <div class="mt-10 bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl p-6 md:p-8 text-center">
          <h2 class="text-lg md:text-xl font-bold text-white mb-2">没有找到您的问题？</h2>
          <p class="text-blue-100 mb-4 text-sm">我们的客服团队随时为您提供帮助</p>
          <Button @click="goToTicket" class="bg-white text-blue-600 hover:bg-blue-50 rounded-xl px-6">
            <MessageSquarePlus class="h-4 w-4 mr-2" />
            提交工单
          </Button>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <Footer />
  </div>
</template>

<style scoped>
.faq-page {
  width: 100%;
  overflow-x: hidden;
}
</style>
