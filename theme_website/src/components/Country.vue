<script lang="ts" setup>
import {Icon} from "@iconify/vue";
import {computed} from "vue";

interface IProps {
  country: string
  size?: number
}
const p = withDefaults(defineProps<IProps>(), {
  size: 28
})

const icon = computed(() => {
  if (p.country.includes('美国')) return 'emojione:flag-for-united-states'
  if (p.country.includes('荷兰')) return 'emojione:flag-for-netherlands'
  if (p.country.includes('香港')) return 'emojione:flag-for-hong-kong-sar-china'
  if (p.country.includes('日本')) return 'emojione:flag-for-japan'
  if (p.country.includes('韩国')) return 'emojione:flag-for-south-korea'
  if (p.country.includes('新加坡')) return 'emojione:flag-for-singapore'
  if (p.country.includes('澳大利亚')) return 'emojione:flag-for-australia'
  if (p.country.includes('英国')) return 'emojione:flag-for-united-kingdom'
  if (p.country.includes('法国')) return 'emojione:flag-for-france'
  if (p.country.includes('德国')) return 'emojione:flag-for-germany'
  if (p.country.includes('意大利')) return 'emojione:flag-for-italy'
  if (p.country.includes('西班牙')) return 'emojione:flag-for-spain'
  if (p.country.includes('加拿大')) return 'emojione:flag-for-canada'
  if (p.country.includes('瑞士')) return 'emojione:flag-for-switzerland'
  if (p.country.includes('瑞典')) return 'emojione:flag-for-sweden'
  if (p.country.includes('挪威')) return 'emojione:flag-for-norway'
  if (p.country.includes('丹麦')) return 'emojione:flag-for-denmark'
  if (p.country.includes('芬兰')) return 'emojione:flag-for-finland'
  if (p.country.includes('奥地利')) return 'emojione:flag-for-austria'
  if (p.country.includes('比利时')) return 'emojione:flag-for-belgium'
  if (p.country.includes('爱尔兰')) return 'emojione:flag-for-ireland'
  if (p.country.includes('葡萄牙')) return 'emojione:flag-for-portugal'
  if (p.country.includes('希腊')) return 'emojione:flag-for-greece'
  if (p.country.includes('新西兰')) return 'emojione:flag-for-new-zealand'
  if (p.country.includes('卢森堡')) return 'emojione:flag-for-luxembourg'
  if (p.country.includes('冰岛')) return 'emojione:flag-for-iceland'
  if (p.country.includes('匈牙利')) return 'emojione:flag-for-hungary'
  if (p.country.includes('捷克')) return 'emojione:flag-for-czech-republic'
  if (p.country.includes('越南')) return 'emojione:flag-for-vietnam'
  if (p.country.includes('泰国')) return 'emojione:flag-for-thailand'
  if (p.country.includes('马来西亚')) return 'emojione:flag-for-malaysia'
  if (p.country.includes('印度尼西亚')) return 'emojione:flag-for-indonesia'
  if (p.country.includes('菲律宾')) return 'emojione:flag-for-philippines'
  if (p.country.includes('印度')) return 'emojione:flag-for-india'
  if (p.country.includes('巴西')) return 'emojione:flag-for-brazil'
  if (p.country.includes('墨西哥')) return 'emojione:flag-for-mexico'
  if (p.country.includes('阿根廷')) return 'emojione:flag-for-argentina'
  if (p.country.includes('智利')) return 'emojione:flag-for-chile'
  if (p.country.includes('南非')) return 'emojione:flag-for-south-africa'
  if (p.country.includes('埃及')) return 'emojione:flag-for-egypt'
  if (p.country.includes('罗马尼亚')) return 'emojione:flag-for-romania'
  if (p.country.includes('柬埔寨')) return 'emojione:flag-for-cambodia'
  if (p.country.includes('朝鲜')) return 'emojione:flag-for-north-korea'
  if (p.country.includes('伊朗')) return 'emojione:flag-for-iran'
  if (p.country.includes('哈萨克斯坦')) return 'emojione:flag-for-kazakhstan'
  if (p.country.includes('土耳其')) return 'emojione:flag-for-turkey'
  if (p.country.includes('南极')) return 'emojione:flag-for-antarctica'
  if (p.country.includes('台湾')) return 'emojione:flag-for-taiwan'
  return 'emojione:flag-for-china'
})
</script>
<template>
  <Icon :icon="icon" :width="size" :height="size" />
</template>