<script setup>
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
</script>

<template>
<div class="pt-40 lg:px-0 px-5 bg-[#3963ef]">
  <div class="max-w-[1080px] m-auto flex lg:flex-row  flex-col items-end">
    <div class="lg:w-[40%]">
      <p class="text-4xl text-white font-black ">免费获取各终端软件和教程</p>
      <p style="color: hsla(0,0%,100%,.8)" class="mt-5 text-[21px]">支持windows/安卓/ios/macOS等多终端， 并免费提供各终端软件。ios用户在付费后， 可以免费使用包含Shadowrocket的美区共享Apple id,网站内免费提供各终端的软件和教程,付费后只需按教程操作。</p>
      <div class="mt-20 flex gap-10 pb-10">
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger as-child>
              <p class="cursor-pointer bg-[#242c45] px-10 py-3 text-white rounded-lg">App Store</p>
            </TooltipTrigger>
            <TooltipContent>
              <p>请先登录网站，然后按对应教程来操作获取</p>
            </TooltipContent>
          </Tooltip>
          <Tooltip>
            <TooltipTrigger as-child>
              <p class="cursor-pointer text-[#242c45] px-10 py-3 rounded-lg bg-white">Play Store</p>
            </TooltipTrigger>
            <TooltipContent>
              <p>请先登录网站，然后按对应教程来操作获取</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>
    </div>
    <div class="flex-1 relative">
      <img class="lg:absolute bottom-0 right-0" src="/img/android-ios.png" alt="">
    </div>
  </div>

</div>
</template>

<style scoped>

</style>