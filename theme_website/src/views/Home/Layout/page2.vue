<script setup>
const data=[
  {name:"快如闪电",cont:"高价购入优质网络频宽，精心优化传输算法，只为您上网更爽快。",img:new URL("/img/1.svg",import.meta.url).href},
  {name:"稳定高效",cont:"最先进加密隐藏技术，将穿墙流量化身加密正常流量，免于防火墙干扰。",img:new URL("/img/2.svg",import.meta.url).href},
  {name:"增强安全",cont: "即使通过公共 WiFi 上网，高强度数据加密也能保护你的隐私不被监视。",img:new URL("/img/3.svg",import.meta.url).href},
  {name:"保持匿名",cont: "私密浏览？浏览器无痕模式不够。我们的服务为您隐藏 IP 以掩藏踪迹。",img:new URL("/img/4.svg",import.meta.url).href},
  {name:"解锁内容",cont: "节点遍布各国，解锁本地内容。你可从任何地方欣赏异国限定媒体节目。",img:new URL("/img/5.svg",import.meta.url).href},
  {name:"不限速",cont: "我们的套餐不限速度。您可放心使用，不必担心访问的时候频频卡顿。",img:new URL("/img/6.svg",import.meta.url).href}
]
</script>

<template>
  <div class="py-40 bg-zinc-50 dark:bg-zinc-900 lg:px-0 px-5">
    <div class="max-w-[1080px] m-auto">
      <p class="font-black text-4xl text-zinc-900 dark:text-zinc-100">大陆首选 稳定高速访问全球互联网</p>
      <p class="mt-8 text-xl text-zinc-500 dark:text-zinc-400">历经 3 年研发，为大中华地区用户保护隐私，口碑卓越。</p>
      <div class="grid mt-14 grid-cols-1 lg:grid-cols-3 gap-12">
        <div v-for="item in data" class="flex flex-col gap-y-4">
          <img class="w-[52px]" :src="item.img" alt="">
          <p class="text-2xl font-black text-zinc-900 dark:text-zinc-100">{{ item.name }}</p>
          <p class="text-zinc-500 dark:text-zinc-400">{{item.cont}}</p>
        </div>
      </div>
    </div>
  </div>
</template>
