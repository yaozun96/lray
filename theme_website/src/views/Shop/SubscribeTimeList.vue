<script setup lang="ts">
import {useShop} from "./useShop";
import SubscribeCard1 from "@/components/subscribeCard1.vue";

const { subscribeCpData, subscribeForm, selectSubscribe } = useShop()
</script>
<template>
  <div class="relative flex justify-center py-12">
    <div class="LayoutContainer flex flex-col">
      <div>
        <div class="StepTitle" data-step="1">选择订阅套餐</div>
      </div>
      <div class="grid gap-3 grid-cols-1 md:grid-cols-4 my-6">
        <div v-for="item in subscribeCpData" :key="item.id" @click="selectSubscribe(item)">
          <SubscribeCard1 :item="item" :check="subscribeForm.plan_id === item.id && subscribeForm.period === item.period" />
        </div>
      </div>
    </div>
  </div>
</template>
