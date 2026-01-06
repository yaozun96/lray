<script setup lang="ts">
import {onMounted} from "vue";
import {useRoute} from "vue-router";
import {useUserStore} from "@/stores/User.js";
import Nav from "@/views/News/Nav.vue";
import Exchange from "@/components/Exchange.vue";
import { message } from 'ant-design-vue';

import {useInfoStore} from "@/stores/counter.js";

const route = useRoute()
const user = useUserStore()
const tokenStore = useInfoStore()

onMounted(() => {
  if (!tokenStore.Token) return;

  user.Init().then(() => {


    // 注册没有套餐的用户，打开兑换弹窗
    const {display, displayTips} = window.config.Exchange
    if (!user.Subscribe.plan_id && display) {

      message.warning(displayTips)
      user.ExchangeModal = true
    }
  }).catch(err => {
    console.error('用户信息初始化失败:', err)
  })
})
</script>
<template>
  <div class="flex flex-col w-full h-full overflow-hidden">
    <Nav />
    <div class="pt-[72px] flex flex-col overflow-auto flex-1 min-h-0">
      <router-view :key="$route.fullPath" />
    </div>
  </div>
  <Exchange />
</template>
