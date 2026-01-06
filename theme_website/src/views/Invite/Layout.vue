<script setup>
import Cards from "@/views/Invite/components/cards.vue";
import Codes from "@/views/Invite/components/Codes.vue";
import { RefreshCw } from 'lucide-vue-next';
import {getInviteData, generateInviteCode} from "@/api/invite.js";
import { message } from 'ant-design-vue';
import {onMounted, ref} from "vue";
import People from "@/views/Invite/components/people.vue";
import Cash from "@/views/Invite/components/Cash.vue";

const invite=ref({
  codes:undefined,
  stat:undefined
})
onMounted(()=>{
  update()
})

const update = () => {
  invite.value.codes = undefined;
  invite.value.stat = undefined;
  getInviteData().then(res => {
    invite.value.codes = res.data.codes;
    invite.value.stat = res.data.stat;

  });
};

const Save=()=>{
  generateInviteCode().then(res=>{
    message.success("邀请码生成成功")
    update()
  })
}
</script>

<template>

<div class="mb-10">
  <cash v-if="true" :cash="invite.stat ? invite.stat[4] : 0" :update="update" />
  <div class="grid lg:grid-cols-4 grid-cols-1 lg:gap-10 gap-5">
    <cards :list="invite.stat"></cards>
  </div>
  <div>
    <div class="mt-10 px-4 py-5 rounded-xl bg-white dark:bg-zinc-900 shadow-sm border border-zinc-200 dark:border-zinc-800">
      <div class="flex justify-between lg:items-center items-end lg:flex-row flex-col">
        <p class="text-zinc-900 dark:text-zinc-100 font-medium">邀请明细</p>
      </div>
      <people class="mt-5"></people>
    </div>
  </div>
</div>
</template>
