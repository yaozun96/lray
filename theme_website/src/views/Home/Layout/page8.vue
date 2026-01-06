<script setup>
import { ref } from 'vue';
import { ChevronDown } from 'lucide-vue-next';

const activeKey = ref('');
const activeKey1 = ref('');

const toggle = (key, group) => {
  if (group === 1) {
    activeKey.value = activeKey.value === key ? '' : key;
  } else {
    activeKey1.value = activeKey1.value === key ? '' : key;
  }
};

const faqsLeft = [
  {
    key: '1',
    title: '我们的服务是什么？它有何帮助？',
    content: `<p>我们提供的是是虚拟专用网络（Virtual Private Network）。它通过在公共网络上建立专用隧道并加密其中传输的数据来保护两个或多个设备之间的通信。</p>
      <p>它提供了一系列好处：通过加密，通讯数据变得难以破解；藉由隧道，线上活动的细节内容被掩藏；借助转发，网络流量看似来自无关的 IP 地址和地理位置。</p>`
  },
  {
    key: '2',
    title: '什么是 ShadowSocks 和 ShadowSocksR？',
    content: `<p>ShadowSocks（简称 SS，又称影梭）是一种加密的无状态代理协议。它在传输层工作，中继 TCP 和 UDP 流量。它可以轻松穿透最强大的国家级管控防火墙。</p>
      <p>ShadowSocksR（简称 SSR）是 SS 的主要分支。在 SS 的基础上，SSR 修补了安全漏洞，扩展了密码套件选项，增加了流量混淆，并提高了运营商级别的 QoS 优先级。</p>`
  },
  {
    key: '3',
    title: '为什么你们的私有协议能做到稳定高速？',
    content: `<p>我们理解互联网自由的原理，并在我们的代码中付诸实践。</p>
      <p>交通混淆和质押自由是有效规避互联网封锁的基石。将流量伪装成常规的 Web 浏览，审查者无从分辨；质押自由意味着，由于误封的成本过高，审查机构不会阻止无法明确分辨的流量。</p>`
  },
  {
    key: '4',
    title: '有提供不限速套餐吗？',
    content: `<p>我们所有套餐都没有速度限制。</p>
      <p>但是，一个套餐每个月有500G的流量上限。</p>
      <p>我们相信我们的定价结构是公平和合理的。无上限不限速的套餐会扭曲价格并招致滥用。例如，BT 下载者支付与您相同的价格，但消耗大量的资源和频宽，减慢您的上网速度。实际上，普通用户为滥用者做补贴。</p>`
  }
];

const faqsRight = [
  {
    key: '1',
    title: '你们的服务能在哪些设备上运作？',
    content: `<p>几乎所有的设备都可以！</p>
      <p>市面上几乎所有的电子设备，我们都能支持。鉴于我们支援多种开源和自研的加密协议，我们相信您可以在几乎任何市售设备上轻松连接到我们的网络。</p>
      <p>支持ios、andriod、Windows、Mac等，并免费提供各终端的对应软件。</p>`
  },
  {
    key: '2',
    title: '你们接受哪些付款方式？',
    content: `<p>支持支付宝和微信，通过中国银联官方接口，安全放心轻松支付。</p>
      <p>对于来自中国的客户，我们的支付宝接口将支付流程简化为二维码扫描。轻松一秒过。</p>
      <p>我们也照顾来自世界其他地方的客户，接受 PayPal 付款。</p>
      <p>对于那些注重私隐的朋友，我们没忽略您的需求：我们接受数十种加密货币，您可以放心匿名付款。</p>`
  },
  {
    key: '3',
    title: '你们记录我的上网流量日志吗？',
    content: `<p>记，也不记。我们会在短时间内记录您的流量元数据，并定期对删除老数据。</p>
      <p>我们不记录用户流量内容。但是，为了解决滥用问题，我们会记录您的部分活动信息。日志条目包括时间，源地址，目标地址和流量。我们不会实时监控您的网络通讯内容，但我们会进行事后审核。如果您的数据被司法传召，我们可能会与执法部门配合。</p>`
  }
];
</script>

<template>
  <div class="py-40 lg:px-0 px-5">
    <div class="max-w-[1080px] m-auto">
      <p class="text-4xl font-black">客户最常问的 7 个问题</p>
      <div class="mt-20 lg:flex gap-10">
        <!-- 左侧 FAQ -->
        <div class="lg:w-[50%] space-y-4">
          <div v-for="faq in faqsLeft" :key="faq.key" class="bg-zinc-50 dark:bg-zinc-800 rounded-lg overflow-hidden">
            <button
              @click="toggle(faq.key, 1)"
              class="w-full px-5 py-4 flex items-center justify-between text-left font-bold text-lg hover:text-blue-600 transition-colors"
            >
              <span>{{ faq.title }}</span>
              <ChevronDown
                class="w-5 h-5 transition-transform duration-200"
                :class="{ 'rotate-180': activeKey === faq.key }"
              />
            </button>
            <div
              v-show="activeKey === faq.key"
              class="px-5 pb-4 text-zinc-600 dark:text-zinc-400 faq-content"
              v-html="faq.content"
            />
          </div>
        </div>

        <!-- 右侧 FAQ -->
        <div class="lg:w-[50%] space-y-4 mt-4 lg:mt-0">
          <div v-for="faq in faqsRight" :key="faq.key" class="bg-zinc-50 dark:bg-zinc-800 rounded-lg overflow-hidden">
            <button
              @click="toggle(faq.key, 2)"
              class="w-full px-5 py-4 flex items-center justify-between text-left font-bold text-lg hover:text-blue-600 transition-colors"
            >
              <span>{{ faq.title }}</span>
              <ChevronDown
                class="w-5 h-5 transition-transform duration-200"
                :class="{ 'rotate-180': activeKey1 === faq.key }"
              />
            </button>
            <div
              v-show="activeKey1 === faq.key"
              class="px-5 pb-4 text-zinc-600 dark:text-zinc-400 faq-content"
              v-html="faq.content"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
  <hr class="border-zinc-200 dark:border-zinc-700">
</template>

<style scoped>
.faq-content :deep(p) {
  margin: 10px 0;
  font-size: 16px;
  line-height: 1.6;
}
</style>
