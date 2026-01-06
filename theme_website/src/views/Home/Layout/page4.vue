<script setup>
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

const nodes = [
  { name: '东京', nodes: 5, bandwidth: '5 Gbps', position: 'top-[43%] right-[13%]' },
  { name: '首尔', nodes: 3, bandwidth: '3 Gbps', position: 'top-[35%] right-[15%]' },
  { name: '台北', nodes: 8, bandwidth: '5 Gbps', position: 'top-[45%] right-[15%]' },
  { name: '新加坡', nodes: 4, bandwidth: '2 Gbps', position: 'top-[55%] right-[18%]' },
  { name: '圣彼得堡', nodes: 1, bandwidth: '2 Gbps', position: 'top-[10%] right-[28%]' },
  { name: '法兰克福', nodes: 3, bandwidth: '2 Gbps', position: 'top-[30%] right-[50%]' },
  { name: '伦敦', nodes: 3, bandwidth: '3 Gbps', position: 'top-[30%] right-[55%]' },
  { name: '洛杉矶', nodes: 4, bandwidth: '5 Gbps', position: 'top-[35%] right-[85%]' },
];
</script>

<template>
  <div class="py-40 lg:px-0 px-5">
    <div class="max-w-[1080px] m-auto">
      <p class="text-4xl font-black text-center">38 组服务器集群覆盖 8 个国家地区</p>
      <p class="text-xl text-[#616577] mt-5 text-center">从 8 个国家地区的 38
        组服务器集群中任意选择。您可到达网络上任何地方。</p>

      <div class="relative mt-10 lg:h-[500px] h-52">
        <img class="absolute top-0 w-full h-full" src="/img/index-node-map-bg.dd4c11cd.png" alt="">
        <TooltipProvider>
          <Tooltip v-for="node in nodes" :key="node.name">
            <TooltipTrigger as-child>
              <div :class="['absolute cursor-pointer', node.position]">
                <span class="relative flex h-3 w-3">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                  <span class="relative inline-flex rounded-full h-3 w-3 bg-blue-500"></span>
                </span>
              </div>
            </TooltipTrigger>
            <TooltipContent>
              <p class="font-medium">{{ node.name }}</p>
              <p class="text-xs text-zinc-400">{{ node.nodes }} 节点</p>
              <p class="text-xs text-zinc-400">{{ node.bandwidth }}</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>
    </div>

  </div>
</template>

<style scoped>

</style>
