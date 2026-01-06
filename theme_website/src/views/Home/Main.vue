<script setup lang="ts">
import Header from "@/views/Home/Header.vue";
import Area from "@/views/Home/Area.vue";
import Features from "@/views/Home/Features.vue";
import Footer from "@/views/News/Footer.vue"
</script>
<template>
  <div class="LayoutWrapper">
    <div class="overflow-auto">
      <Header />
      <Features />
      <Area />
      <Footer />
    </div>
  </div>
</template>
