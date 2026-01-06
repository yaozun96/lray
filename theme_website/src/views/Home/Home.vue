<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import router from "@/router/index.js"
import { Button } from '@/components/ui/button'
import Footer from "@/views/News/Footer.vue"
import {
  Zap, Shield, Globe, Users, Download, Server, Lock,
  Package, ArrowRight, Check, X, MapPin
} from 'lucide-vue-next'

// 配置
const title = window.config?.title || 'Lray'
const logo = window.config?.logo || '/logo.svg'
const subtitle = window.config?.Sign?.HomeSubtitle || '自由 · 快速 · 稳妥'
const description = window.config?.Sign?.HomeDescription || '高可用的跨境网络互联服务，专业团队研发，自研跳点算法与流量伪装技术，帮助用户安全触达全球内容。'

// 地图配置
const areaConfig = {
  title: window.config?.home?.AreaTitle || `${title}, 专为大陆优化的空中巴士`,
  description: window.config?.home?.AreaDescription || '专为大陆优化，犹如空中巴士，让你的网络体验更加流畅',
  img: window.config?.home?.AreaImg || '/map.png',
}

// 浮动图标配置
const floatingIcons = [
  { name: 'Netflix', image: '/assets/images/netflix-new.png' },
  { name: 'ChatGPT', image: '/assets/images/chatgpt.png' },
  { name: 'Instagram', image: '/assets/images/instagram.png' },
  { name: 'TikTok', image: '/assets/images/tiktok.png' },
  { name: 'YouTube', image: '/assets/images/youtube.png' },
  { name: 'X', image: '/assets/images/x.png' },
  { name: 'Telegram', image: '/assets/images/telegram.png' },
  { name: 'Facebook', image: '/assets/images/facebook.png' },
]

// 平台图标
const platformIcons = [
  { key: 'windows', name: 'Windows', logo: '/assets/images/windows.png' },
  { key: 'chrome', name: 'Chrome', logo: '/assets/images/chrome.png' },
  { key: 'macos', name: 'macOS', logo: '/assets/images/macos.png' },
  { key: 'android', name: 'Android', logo: '/assets/images/android.png' },
  { key: 'appletv', name: 'Apple TV', logo: '/assets/images/appletv.png' },
  { key: 'firetv', name: 'Fire TV', logo: '/assets/images/firetv.png' },
  { key: 'router', name: 'Router', logo: '/assets/images/router.png' },
]

// 特性列表
const features = [
  { icon: Zap, title: '极速连接', description: '专线节点，IEPL 专线直连，延迟低至 30ms' },
  { icon: Shield, title: '隐私保护', description: '金融级加密算法，零日志政策，保护用户隐私' },
  { icon: Globe, title: '全球覆盖', description: '38+ 国家节点，智能路由，自动选择最优线路' },
  { icon: Users, title: '多设备支持', description: '一个账号，多设备同时在线，无缝切换' },
  { icon: Server, title: '高可用性', description: '99.9% 在线率，负载均衡，自动故障转移' },
  { icon: Lock, title: '安全审计', description: '完整审计与监控体系，符合企业安全标准' },
]

// 对比表格数据
const comparisonProviders = [
  { name: title, logo: logo },
  { logo: '/assets/images/competitor-surfshark.svg' },
  { logo: '/assets/images/competitor-purevpn.png' },
  { logo: '/assets/images/competitor-kuailian.png' }
]

const comparisonFeatures = [
  { label: '网络速度', values: ['极快', '一般', '一般', '一般'] },
  { label: '强大的加密', values: [true, false, false, false] },
  { label: '稳定的连接', values: [true, false, false, false] },
  { label: '隐藏IP地址', values: [true, true, true, true] },
  { label: '零日志政策', values: [true, false, false, false] },
  { label: '专线优化', values: [true, false, false, false] },
  { label: '价格', values: ['低至￥19.8', '$12.95/月', '$7.99/月', '$2.29/月'] }
]

// 图标动画 - 单圆形轨道 (soravpn 风格)
const ORBIT_RADIUS = 280  // 圆形轨道半径，围绕手机外侧
const ICON_SPEED = 0.0003

// 8个图标均匀分布在圆上
const iconAngles = ref(floatingIcons.map((_, index) => {
  return (index / floatingIcons.length) * Math.PI * 2
}))
const iconStyles = ref(floatingIcons.map(() => ({})))
let iconsRafId = null
let lastIconTime = null

function updateIconStyles(timestamp) {
  if (!lastIconTime) lastIconTime = timestamp
  const delta = timestamp - lastIconTime
  lastIconTime = timestamp

  // 所有图标同向旋转
  iconAngles.value = iconAngles.value.map((angle) => {
    return (angle + delta * ICON_SPEED) % (Math.PI * 2)
  })

  iconStyles.value = iconAngles.value.map((angle) => {
    const x = Math.cos(angle) * ORBIT_RADIUS
    const y = Math.sin(angle) * ORBIT_RADIUS
    // 深度因子：y 越大（越靠下）越靠前
    const depthFactor = (ORBIT_RADIUS - y) / (ORBIT_RADIUS * 2)
    const scale = 0.82 + depthFactor * 0.18
    const opacity = 0.45 + depthFactor * 0.55
    const zIndex = Math.round(depthFactor * 10)

    return {
      transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px)) scale(${scale.toFixed(2)})`,
      opacity: opacity.toFixed(2),
      zIndex: zIndex
    }
  })

  iconsRafId = requestAnimationFrame(updateIconStyles)
}

// 手机屏幕内容动画
const connectionTime = ref('00:00:00')
const currentNode = ref('香港 IEPL')
const latency = ref(32)
let connectionTimer = null
let seconds = 0

function updateConnectionTime() {
  seconds++
  const h = String(Math.floor(seconds / 3600)).padStart(2, '0')
  const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0')
  const s = String(seconds % 60).padStart(2, '0')
  connectionTime.value = `${h}:${m}:${s}`
}

onMounted(async () => {
  // 初始化图标位置
  iconStyles.value = iconAngles.value.map((angle) => {
    const x = Math.cos(angle) * ORBIT_RADIUS
    const y = Math.sin(angle) * ORBIT_RADIUS
    const depthFactor = (ORBIT_RADIUS - y) / (ORBIT_RADIUS * 2)
    const scale = 0.82 + depthFactor * 0.18
    const opacity = 0.45 + depthFactor * 0.55
    const zIndex = Math.round(depthFactor * 10)
    return {
      transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px)) scale(${scale.toFixed(2)})`,
      opacity: opacity.toFixed(2),
      zIndex: zIndex
    }
  })
  iconsRafId = requestAnimationFrame(updateIconStyles)
  connectionTimer = setInterval(updateConnectionTime, 1000)
})

onUnmounted(() => {
  if (iconsRafId) cancelAnimationFrame(iconsRafId)
  if (connectionTimer) clearInterval(connectionTimer)
})

// 导航
function goToStore() {
  router.push('/dashboard')
}

function goToDownload() {
  router.push('/download')
}

function goToTicket() {
  router.push('/ticket')
}
</script>

<template>
  <div class="home-page">
    <!-- Hero Section -->
    <section class="relative">
      <div class="container mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16 lg:py-20 max-w-7xl relative z-10">
        <div class="grid gap-8 lg:gap-12 lg:grid-cols-2 lg:items-center">
          <!-- 左侧文字 -->
          <div class="space-y-8 lg:pr-8">
            <div class="space-y-3">
              <p class="text-4xl md:text-5xl lg:text-[3.5rem] font-extrabold bg-gradient-to-r from-blue-700 via-blue-500 to-sky-400 bg-clip-text text-transparent">
                {{ subtitle }}
              </p>
            </div>
            <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed max-w-xl">
              {{ description }}
            </p>

            <!-- 按钮组 -->
            <div class="flex flex-col sm:flex-row gap-3 sm:gap-4">
              <Button @click="goToStore" size="lg" class="px-10 md:px-12 py-5 md:py-6 text-lg md:text-xl rounded-xl">
                <Package class="h-6 w-6 md:h-7 md:w-7 mr-2" />
                查看套餐
              </Button>
              <Button @click="goToDownload" variant="outline" size="lg" class="px-10 md:px-12 py-5 md:py-6 text-lg md:text-xl rounded-xl">
                <Download class="h-6 w-6 md:h-7 md:w-7 mr-2" />
                下载客户端
              </Button>
            </div>

            <!-- 平台图标 -->
            <div class="flex items-center gap-4 md:gap-6 pt-2">
              <div
                v-for="platform in platformIcons"
                :key="platform.key"
                class="w-8 h-8 md:w-10 md:h-10 cursor-pointer transition-all duration-200 hover:scale-110 opacity-60 hover:opacity-100"
                :title="platform.name"
              >
                <img :src="platform.logo" :alt="platform.name" class="w-full h-full object-contain" />
              </div>
            </div>
          </div>

          <!-- 右侧手机展示 -->
          <div class="hidden lg:flex relative mx-auto h-[450px] md:h-[550px] lg:h-[600px] w-full max-w-[320px] md:max-w-[360px] items-center justify-center">
            <!-- 浮动图标 -->
            <div
              v-for="(icon, index) in floatingIcons"
              :key="index"
              class="floating-icon"
              :style="iconStyles[index]"
            >
              <div class="icon-card">
                <img :src="icon.image" :alt="icon.name" class="w-full h-full" />
              </div>
            </div>

            <!-- iPhone Mockup -->
            <div class="iphone-mockup">
              <div class="iphone-frame">
                <!-- 侧边按钮 -->
                <div class="iphone-buttons"></div>

                <!-- 灵动岛 -->
                <div class="dynamic-island"></div>

                <!-- 屏幕内容 -->
                <div class="iphone-screen">
                  <!-- 状态栏 -->
                  <div class="status-bar">
                    <span class="status-time">9:41</span>
                    <div class="status-icons">
                      <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 3C7.5 3 3.75 5.25 1.5 9L3.5 11C5.25 8 8.25 6 12 6C15.75 6 18.75 8 20.5 11L22.5 9C20.25 5.25 16.5 3 12 3ZM12 9C9.25 9 6.75 10.5 5.5 12.75L7.5 14.75C8.25 13.25 10 12 12 12C14 12 15.75 13.25 16.5 14.75L18.5 12.75C17.25 10.5 14.75 9 12 9ZM12 15C10.75 15 9.75 16 9.75 17.25C9.75 18.5 10.75 19.5 12 19.5C13.25 19.5 14.25 18.5 14.25 17.25C14.25 16 13.25 15 12 15Z"/>
                      </svg>
                      <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M2 22H4V12H2V22ZM6 22H8V9H6V22ZM10 22H12V6H10V22ZM14 22H16V3H14V22Z"/>
                      </svg>
                      <div class="battery-icon">
                        <div class="battery-level"></div>
                      </div>
                    </div>
                  </div>

                  <!-- 应用内容 -->
                  <div class="app-content">
                    <!-- 顶部 Logo -->
                    <div class="app-header">
                      <img :src="logo" alt="Logo" class="app-logo" />
                      <span class="app-name">{{ title }}</span>
                    </div>

                    <!-- 连接按钮 -->
                    <div class="connect-button">
                      <svg class="power-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                        <path d="M12 2v8M18.4 6.6a9 9 0 1 1-12.8 0"/>
                      </svg>
                    </div>

                    <!-- 速度显示 -->
                    <div class="speed-display">
                      <span class="speed-arrow">↑</span>
                      <span class="speed-num">128.6</span>
                      <span class="speed-divider"></span>
                      <span class="speed-arrow down">↓</span>
                      <span class="speed-num">256.8</span>
                      <span class="speed-unit">MB/s</span>
                    </div>

                    <!-- 底部节点 -->
                    <div class="node-bar">
                      <span class="node-flag">🇭🇰</span>
                      <span class="node-name">香港 IEPL</span>
                      <span class="node-ping">32ms</span>
                    </div>
                  </div>

                  <!-- Home Indicator -->
                  <div class="home-indicator"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- Features Section -->
    <section class="py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-7xl">
        <div class="text-center mb-12 md:mb-16">
          <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400 mb-4">
            <Zap class="w-4 h-4" />
            <span>核心优势</span>
          </div>
          <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">为什么选择 {{ title }}</h2>
          <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400">专业、稳定、安全的网络加速服务</p>
        </div>

        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="(feature, index) in features"
            :key="index"
            class="p-6 md:p-8 border border-zinc-200 dark:border-zinc-800 hover:border-blue-300 dark:hover:border-blue-700 transition-all duration-200 rounded-2xl"
          >
            <component :is="feature.icon" class="h-6 w-6 mb-4 text-blue-600 dark:text-blue-400" />
            <h3 class="text-lg font-semibold mb-2 text-zinc-900 dark:text-zinc-100">{{ feature.title }}</h3>
            <p class="text-sm md:text-base text-zinc-600 dark:text-zinc-400 leading-relaxed">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- 全平台客户端 Section -->
    <section class="py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-7xl">
        <div class="grid gap-12 lg:gap-16 lg:grid-cols-2 lg:items-center">
          <div class="space-y-6 order-2 lg:order-1">
            <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400">
              <Download class="w-4 h-4" />
              <span>多端支持</span>
            </div>
            <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold text-zinc-900 dark:text-zinc-100">全平台客户端</h2>
            <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed">
              为您提供基于不同设备的加密网络服务，您可以在 Windows、macOS、Android、iOS、Chrome 浏览器、Apple TV、Android TV、路由器等设备上使用。
            </p>
            <Button @click="goToStore" variant="outline" class="rounded-xl">
              查看套餐
              <ArrowRight class="h-4 w-4 ml-2" />
            </Button>
          </div>
          <div class="flex justify-center lg:justify-end order-1 lg:order-2">
            <img src="/assets/images/platform-clients.png" alt="全平台客户端" class="h-48 md:h-64 lg:h-80 w-auto object-contain" />
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- IEPL 专线 Section -->
    <section class="py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-7xl">
        <div class="grid gap-12 lg:gap-16 lg:grid-cols-2 lg:items-center">
          <div class="flex justify-center lg:justify-start">
            <img src="/assets/images/iepl-network.png" alt="IEPL专线" class="h-48 md:h-64 lg:h-80 w-auto object-contain" />
          </div>
          <div class="space-y-6">
            <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400">
              <Server class="w-4 h-4" />
              <span>专线直连</span>
            </div>
            <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold text-zinc-900 dark:text-zinc-100">采用 IEPL 线路</h2>
            <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed">
              以太网专线服务 (IEPL) 利用多业务传送节点 (MSTP) 技术，为客户提供具有灵活调整带宽和以太网接入功能的点到点、点到多点的数据专线业务，确保低延迟高稳定。
            </p>
            <Button @click="goToStore" variant="outline" class="rounded-xl">
              立即体验
              <ArrowRight class="h-4 w-4 ml-2" />
            </Button>
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- 解锁服务 Section -->
    <section class="py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-7xl">
        <div class="grid gap-12 lg:gap-16 lg:grid-cols-2 lg:items-center">
          <div class="space-y-6 order-2 lg:order-1">
            <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400">
              <Globe class="w-4 h-4" />
              <span>全球解锁</span>
            </div>
            <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold text-zinc-900 dark:text-zinc-100">解锁服务</h2>
            <div class="space-y-4">
              <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed">
                解锁流媒体服务：通过全球节点，轻松访问 Netflix、Disney+、HBO Max、TikTok 等平台，畅享全球优质影视内容。
              </p>
              <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed">
                解锁 AI 大模型：突破地域限制，自由使用 ChatGPT、Claude、Midjourney 等 AI 工具，提升工作效率。
              </p>
            </div>
            <Button @click="goToStore" variant="outline" class="rounded-xl">
              查看套餐
              <ArrowRight class="h-4 w-4 ml-2" />
            </Button>
          </div>
          <div class="flex justify-center lg:justify-end order-1 lg:order-2">
            <img src="/assets/images/unlock-services.png" alt="解锁服务" class="h-48 md:h-64 lg:h-80 w-auto object-contain" />
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- 对比表格 Section -->
    <section class="hidden lg:block py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-7xl">
        <div class="text-center mb-12 md:mb-16">
          <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400 mb-4">
            <Check class="w-4 h-4" />
            <span>产品对比</span>
          </div>
          <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">为什么选择 {{ title }}？</h2>
          <p class="text-base md:text-lg text-zinc-600 dark:text-zinc-400">与其他服务商的对比</p>
        </div>

        <!-- 对比表格 -->
        <div class="overflow-x-auto -mx-4 sm:mx-0">
          <div class="inline-block min-w-full">
            <div class="grid grid-cols-5 rounded-lg overflow-hidden bg-transparent">
              <!-- 表头 -->
              <div class="p-5 md:p-6 text-sm md:text-base font-semibold text-zinc-800 dark:text-zinc-200 bg-zinc-50/70 dark:bg-zinc-800/40">
                功能
              </div>
              <div
                v-for="(provider, index) in comparisonProviders"
                :key="'header-' + index"
                class="p-5 md:p-6 text-center relative bg-zinc-50 dark:bg-zinc-800"
                :style="index === 0 ? {
                  borderLeft: '1px solid rgba(113,113,122,0.25)',
                  borderRight: '1px solid rgba(113,113,122,0.25)',
                  borderTop: '1px solid rgba(113,113,122,0.25)',
                  borderTopLeftRadius: '12px',
                  borderTopRightRadius: '12px'
                } : {}"
              >
                <div v-if="provider.logo && provider.name" class="flex items-center justify-center gap-2 h-16 md:h-20">
                  <img :src="provider.logo" :alt="provider.name" :class="[index === 0 ? 'w-8 h-8 md:w-10 md:h-10 rounded-lg' : 'w-16 h-16 md:w-20 md:h-20', 'object-contain flex-shrink-0']" />
                  <div v-if="index === 0" class="font-semibold text-sm md:text-base text-zinc-900 dark:text-zinc-100">{{ provider.name }}</div>
                </div>
                <div v-else-if="provider.logo" class="flex items-center justify-center h-16 md:h-20">
                  <img :src="provider.logo" :alt="'Provider ' + index" class="w-16 h-16 md:w-20 md:h-20 object-contain" />
                </div>
              </div>

              <!-- 功能行 -->
              <template v-for="(feature, featureIndex) in comparisonFeatures" :key="'feature-' + featureIndex">
                <div
                  :class="[
                    'p-5 md:p-6 text-sm md:text-base text-zinc-700 dark:text-zinc-300 font-medium',
                    featureIndex % 2 === 1 ? 'bg-zinc-50 dark:bg-zinc-800' : 'bg-white dark:bg-zinc-900/40'
                  ]"
                >
                  {{ feature.label }}
                </div>
                <div
                  v-for="(provider, providerIndex) in comparisonProviders"
                  :key="'cell-' + featureIndex + '-' + providerIndex"
                  :class="[
                    'p-5 md:p-6 text-center relative',
                    providerIndex === 0
                      ? 'bg-zinc-50 dark:bg-zinc-800'
                      : (featureIndex % 2 === 1 ? 'bg-zinc-50 dark:bg-zinc-800' : 'bg-white dark:bg-zinc-900/40')
                  ]"
                  :style="providerIndex === 0 ? {
                    borderLeft: '1px solid rgba(113,113,122,0.25)',
                    borderRight: '1px solid rgba(113,113,122,0.25)'
                  } : {}"
                >
                  <template v-if="feature.values[providerIndex] === true">
                    <div class="flex items-center justify-center">
                      <Check class="h-5 w-5 text-green-600 dark:text-green-400" />
                    </div>
                  </template>
                  <template v-else-if="feature.values[providerIndex] === false">
                    <div class="flex items-center justify-center">
                      <X class="h-5 w-5 text-red-500 dark:text-red-400" />
                    </div>
                  </template>
                  <template v-else>
                    <span
                      :class="[
                        'text-sm md:text-base font-medium',
                        (feature.values[providerIndex] === '极快' || feature.values[providerIndex] === '优惠')
                          ? 'text-zinc-900 dark:text-zinc-100 font-semibold'
                          : 'text-zinc-600 dark:text-zinc-400'
                      ]"
                    >
                      {{ feature.values[providerIndex] }}
                    </span>
                  </template>
                </div>
              </template>

              <!-- 底部按钮行 -->
              <div class="p-5 md:p-6 bg-transparent"></div>
              <div
                class="p-5 md:p-6 text-center bg-zinc-50/70 dark:bg-zinc-800/40 relative"
                :style="{
                  borderLeft: '1px solid rgba(113,113,122,0.25)',
                  borderRight: '1px solid rgba(113,113,122,0.25)',
                  borderBottom: '1px solid rgba(113,113,122,0.25)',
                  borderBottomLeftRadius: '12px',
                  borderBottomRightRadius: '12px'
                }"
              >
                <Button @click="goToStore" class="rounded-full">
                  立即获取
                  <ArrowRight class="h-4 w-4 ml-2" />
                </Button>
              </div>
              <div class="p-5 md:p-6 bg-transparent"></div>
              <div class="p-5 md:p-6 bg-transparent"></div>
              <div class="p-5 md:p-6 bg-transparent"></div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="hidden lg:block">
      <div class="section-divider">
        <div class="divider-line"></div>
        <div class="divider-dot"></div>
        <div class="divider-line"></div>
      </div>
    </div>

    <!-- 全球节点地图 Section -->
    <section class="py-16 md:py-24 relative">
      <div class="container mx-auto px-6 max-w-6xl">
        <!-- 标题区域 -->
        <div class="text-center mb-10 md:mb-12">
          <div class="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 rounded-full text-sm text-blue-600 dark:text-blue-400 mb-4">
            <MapPin class="w-4 h-4" />
            <span>全球节点覆盖</span>
          </div>
          <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-zinc-900 dark:text-zinc-100 mb-4">
            {{ areaConfig.title }}
          </h2>
          <p class="text-sm sm:text-base text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto">
            {{ areaConfig.description }}
          </p>
        </div>

        <!-- 地图区域 -->
        <div class="relative flex justify-center items-center w-full rounded-2xl overflow-hidden p-4 sm:p-8">
          <!-- 节点标记 -->
          <div class="node-dot" style="right: 20%; top: 51%;"></div>
          <div class="node-dot" style="right: 18%; top: 42%;"></div>
          <div class="node-dot" style="right: 14%; top: 42.5%;"></div>
          <div class="node-dot" style="right: 22%; top: 60%;"></div>
          <div class="node-dot" style="right: 48%; top: 22%;"></div>
          <div class="node-dot" style="right: 45%; top: 30%;"></div>
          <div class="node-dot" style="right: 88%; top: 30%;"></div>
          <div class="node-dot" style="right: 85%; top: 40%;"></div>

          <img :src="areaConfig.img" alt="全球节点地图" class="max-w-full h-auto rounded-xl" />
        </div>
      </div>
    </section>

    <!-- 分隔线 -->
    <div class="section-divider">
      <div class="divider-line"></div>
      <div class="divider-dot"></div>
      <div class="divider-line"></div>
    </div>

    <!-- CTA Section -->
    <section class="py-8 md:py-12 px-4 md:px-6 lg:px-8 relative">
      <div class="max-w-7xl mx-auto bg-gradient-to-br from-blue-600 via-blue-700 to-blue-800 rounded-2xl shadow-lg p-5 md:p-6 text-center">
        <h2 class="text-xl md:text-2xl lg:text-3xl font-bold mb-2 text-white">准备好开始了吗？</h2>
        <p class="text-sm text-blue-100 mb-4 max-w-2xl mx-auto">
          选择最适合您的套餐，立即享受安全、快速的全球网络访问体验
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <Button @click="goToStore" size="lg" class="bg-white text-blue-600 hover:bg-blue-50 rounded-xl">
            <Package class="h-4 w-4 md:h-5 md:w-5 mr-2" />
            查看套餐
          </Button>
          <Button @click="goToTicket" size="lg" class="bg-transparent border-2 border-white text-white hover:bg-white/10 rounded-xl">
            <Users class="h-4 w-4 md:h-5 md:w-5 mr-2" />
            联系我们
          </Button>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <Footer />
  </div>
</template>

<style scoped>
.home-page {
  width: 100%;
  overflow-x: hidden;
  position: relative;
}

/* 浮动图标 */
.floating-icon {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 72px;
  height: 72px;
  pointer-events: none;
}

.icon-card {
  width: 72px;
  height: 72px;
}

.icon-card img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* iPhone Mockup */
.iphone-mockup {
  position: relative;
  z-index: 20;
}

.iphone-frame {
  position: relative;
  width: 200px;
  height: 410px;
  background: #1a1a1a;
  border-radius: 36px;
  padding: 4px;
  box-shadow:
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 60px 100px -20px rgba(0, 0, 0, 0.4),
    0 30px 60px -30px rgba(0, 0, 0, 0.5),
    inset 0 1px 1px rgba(255, 255, 255, 0.1);
}

/* 侧边按钮 */
.iphone-frame::before {
  content: '';
  position: absolute;
  right: -2px;
  top: 120px;
  width: 3px;
  height: 32px;
  background: #2a2a2a;
  border-radius: 0 2px 2px 0;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.1);
}

.iphone-frame::after {
  content: '';
  position: absolute;
  right: -2px;
  top: 165px;
  width: 3px;
  height: 56px;
  background: #2a2a2a;
  border-radius: 0 2px 2px 0;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.1);
}

/* 左侧静音键和音量键 */
.iphone-buttons {
  position: absolute;
  left: -2px;
  top: 100px;
}

.iphone-buttons::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  width: 3px;
  height: 24px;
  background: #2a2a2a;
  border-radius: 2px 0 0 2px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.1);
}

.iphone-buttons::after {
  content: '';
  position: absolute;
  left: 0;
  top: 40px;
  width: 3px;
  height: 48px;
  background: #2a2a2a;
  border-radius: 2px 0 0 2px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.1);
}

.dynamic-island {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  width: 62px;
  height: 18px;
  background: #000;
  border-radius: 12px;
  z-index: 30;
}

.iphone-screen {
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 32px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 24px 8px;
  color: #1a1a1a;
}

.status-time {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: -0.3px;
}

.status-icons {
  display: flex;
  align-items: center;
  gap: 4px;
}

.battery-icon {
  width: 22px;
  height: 11px;
  border: 1.5px solid #1a1a1a;
  border-radius: 3px;
  position: relative;
  margin-left: 2px;
}

.battery-icon::after {
  content: '';
  position: absolute;
  right: -4px;
  top: 50%;
  transform: translateY(-50%);
  width: 2px;
  height: 6px;
  background: #1a1a1a;
  border-radius: 0 1px 1px 0;
}

.battery-level {
  position: absolute;
  left: 1.5px;
  top: 1.5px;
  bottom: 1.5px;
  width: 75%;
  background: #1a1a1a;
  border-radius: 1.5px;
}

.app-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px 14px;
}

.app-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

.app-logo {
  width: 24px;
  height: 24px;
  border-radius: 4px;
}

.app-name {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.connect-button {
  width: 76px;
  height: 76px;
  border-radius: 50%;
  background: linear-gradient(145deg, #4a90f7 0%, #2563eb 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow:
    0 8px 32px -8px rgba(59, 130, 246, 0.6),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.power-icon {
  width: 30px;
  height: 30px;
  color: white;
}

.speed-display {
  display: flex;
  align-items: center;
  gap: 5px;
}

.speed-arrow {
  font-size: 11px;
  font-weight: 600;
  color: #3b82f6;
}

.speed-arrow.down {
  color: #10b981;
}

.speed-num {
  font-size: 14px;
  font-weight: 500;
  color: #475569;
  font-variant-numeric: tabular-nums;
}

.speed-divider {
  width: 1px;
  height: 10px;
  background: #e2e8f0;
  margin: 0 3px;
}

.speed-unit {
  font-size: 10px;
  color: #94a3b8;
  font-weight: 500;
  margin-left: 2px;
}

.node-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(0, 0, 0, 0.03);
  border-radius: 16px;
  padding: 8px 12px;
}

.node-flag {
  font-size: 14px;
}

.node-name {
  flex: 1;
  font-size: 11px;
  font-weight: 500;
  color: #334155;
}

.node-ping {
  font-size: 10px;
  font-weight: 600;
  color: #10b981;
}

.home-indicator {
  width: 80px;
  height: 4px;
  background: #1a1a1a;
  border-radius: 2px;
  margin: 6px auto 4px;
}

@media (min-width: 768px) {
  .iphone-frame {
    width: 220px;
    height: 450px;
    border-radius: 40px;
    padding: 5px;
  }

  .iphone-frame::before {
    top: 120px;
    height: 32px;
  }

  .iphone-frame::after {
    top: 160px;
    height: 56px;
  }

  .iphone-buttons::before {
    height: 28px;
  }

  .iphone-buttons::after {
    top: 45px;
    height: 56px;
  }

  .dynamic-island {
    width: 68px;
    height: 20px;
    top: 11px;
    border-radius: 12px;
  }

  .iphone-screen {
    border-radius: 36px;
  }

  .connect-button {
    width: 84px;
    height: 84px;
  }

  .power-icon {
    width: 34px;
    height: 34px;
  }
}

/* 地图节点标记 */
.node-dot {
  position: absolute;
  width: 16px;
  height: 16px;
  z-index: 9;
  background: #3b82f6;
  box-shadow: 0 2px 8px 1px rgba(59, 130, 246, 0.6);
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
  background-color: #3b82f6;
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

/* 分隔线样式 */
.section-divider {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 0 24px;
  max-width: 1280px;
  margin: 0 auto;
}

.divider-line {
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(161, 161, 170, 0.4), transparent);
}

.divider-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3b82f6, #06b6d4);
  box-shadow: 0 0 8px rgba(59, 130, 246, 0.4);
}

:deep(.dark) .divider-line {
  background: linear-gradient(90deg, transparent, rgba(113, 113, 122, 0.4), transparent);
}

:deep(.dark) .divider-dot {
  box-shadow: 0 0 12px rgba(59, 130, 246, 0.5);
}
</style>
