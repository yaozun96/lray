<script setup>
import { ref } from "vue";
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

const activeKey = ref('trojan');
</script>

<template>
  <div class="py-40 bg-zinc-50 dark:bg-zinc-900 lg:px-0 px-5">
    <div class="max-w-[1080px] m-auto">
      <p class="text-4xl font-black text-center text-zinc-900 dark:text-zinc-100">最先进开源协议和我们的自研秘技</p>
      <p class="mt-10 text-center text-zinc-500 dark:text-zinc-400 text-xl">一个服务，对接多种协议，应对多样网络环境。</p>
      <div class="mt-20 bg-white dark:bg-zinc-800 p-10 rounded-xl border border-zinc-200 dark:border-zinc-700">
        <Tabs v-model="activeKey" class="w-full">
          <TabsList class="grid w-full grid-cols-3 mb-6">
            <TabsTrigger value="trojan" class="text-lg">Trojan</TabsTrigger>
            <TabsTrigger value="shadowsocks" class="text-lg">ShadowSocks</TabsTrigger>
            <TabsTrigger value="custom" class="text-lg">自研秘技</TabsTrigger>
          </TabsList>
          <TabsContent value="trojan" class="text-lg text-zinc-600 dark:text-zinc-300 leading-relaxed">
            Trojan是一种利用TLS加密方式避开防火长城的协议，它基于C++实现。<br><br>
            Trojan通过将通信流量伪装成常见的HTTPS流量，来防止流量被检测和干扰。
          </TabsContent>
          <TabsContent value="shadowsocks" class="text-lg text-zinc-600 dark:text-zinc-300 leading-relaxed">
            ShadowSocks 是一种无连接无状态的代理协议。它承载 TCP UDP 数据，可轻松穿透世界上最强国家管控防火墙。
          </TabsContent>
          <TabsContent value="custom" class="text-lg text-zinc-600 dark:text-zinc-300 leading-relaxed">
            我们自研的私有协议，可以模拟多种网页浏览场景。使得防火墙无法可靠区分数据浏览。如强行阻拦亦会影响正常使用网络，因此连接无法有效拦截。
          </TabsContent>
        </Tabs>
      </div>
      <div class="mt-20 flex justify-center">
        <p class="px-10 py-3 rounded-lg hover:opacity-85 cursor-pointer text-xl text-white bg-primary transition-opacity">立即尝试多协议网络服务</p>
      </div>
    </div>
  </div>
</template>
