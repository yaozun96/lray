<script setup>
const data=[
  {
    title:"960 Mbps",
    cont:"最高客户测速"
  },
  {
    title:"69 Gbps",
    cont:"总频宽",
  },
  {
    title:"125 TB",
    cont:"每周流量",
  },
  {
    title:"99.98 %",
    cont:"服务可用率",
  },
  {
    title:"30000",
    cont:"客户信任之选",
  }
]
</script>

<template>
<div class="py-40 lg:px-0 px-5">
  <div class="max-w-[1080px] m-auto">
    <p class="text-4xl text-center font-black">营运数据</p>
    <p class="mt-10 text-center text-[#616577] text-xl">闪亮的营运数据是我们高速稳定网络服务的注脚。</p>
    <div class="mt-20 grid lg:gap-4 gap-10 lg:grid-cols-5 grid-cols-2">
      <div class="flex flex-col gap-y-2" v-for="item in data">
        <p class="text-4xl text-[#3963ef]">{{item.title}}</p>
        <p class="text-[#9da3b9]">{{ item.cont }}</p>
      </div>
    </div>
  </div>
  
</div>
</template>

<style scoped>

</style>