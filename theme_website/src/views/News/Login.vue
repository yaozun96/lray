<script setup lang="ts">
import { computed, onBeforeMount, ref } from "vue";
import { message } from 'ant-design-vue';
import { login } from "@/api/auth.js";
import { useInfoStore } from "@/stores/counter.js";
import { useRoute, useRouter } from "vue-router";
import { notifyApiError } from "@/utils/error.js";

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';

// Lucide Icons
import { Mail, Lock, Eye, EyeOff, Loader2, ArrowRight, Globe, Shield, Zap } from 'lucide-vue-next';

const route = useRoute();
const router = useRouter();

const formData = ref({
  email: '',
  password: '',
});
const loading = ref(false);
const showPassword = ref(false);

const cpData = computed(() => {
  const { title, logo, Sign } = window.config;

  return {
    title: Sign.LoginTitle || title || 'Lray',
    logo: logo || 'img/localized/logo-fallback.png',
  };
});

const userInfo = useInfoStore();

const submit = async () => {
  if (loading.value) return;
  console.group('登录提交');

  // SP1.校验邮箱
  const emailReg = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailReg.test(formData.value.email)) {
    console.error('邮箱格式错误');
    message.error('请输入正确的邮箱');
    return console.groupEnd();
  }

  // SP2.校验密码
  if (formData.value.password.length < 8) {
    console.error('密码长度不足');
    message.error('密码长度不足 8 位');
    return console.groupEnd();
  }

  // SP3.提交登录
  console.log('登录信息:', formData.value);
  loading.value = true;
  try {
    const res = await login({
      email: formData.value.email,
      password: formData.value.password,
    });
    userInfo.Set_Token(res.data.auth_data);
    window.location.reload();
  } catch (error) {
    notifyApiError(error, '邮箱或密码错误');
  } finally {
    loading.value = false;
    console.groupEnd();
  }
};

onBeforeMount(() => {
  if (route.query && route.query.code) {
    router.push({ path: '/register', query: { code: route.query.code } });
  }
});
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- 登录卡片 -->
      <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 sm:p-10 shadow-sm">
        <!-- 标题 -->
        <div class="text-center mb-8">
          <!-- 插图 -->
          <div class="flex justify-center mb-4">
            <img
              src="/assets/illustrations/undraw_login_weas.svg"
              alt="登录"
              class="w-32 h-32 object-contain"
            />
          </div>
          <h1 class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100 mb-2">欢迎回来 🥳</h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400">登录您的 Lray 账户</p>
        </div>

        <!-- 表单 -->
        <form @submit.prevent="submit" class="space-y-4">
          <!-- 邮箱输入 -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">邮箱</label>
            <div class="relative flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all">
              <Mail class="absolute left-3 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.email"
                type="email"
                placeholder="your@email.com"
                class="flex-1 w-full pl-10 pr-3 py-2.5 bg-transparent text-zinc-900 dark:text-zinc-100 text-sm placeholder:text-zinc-400 focus:outline-none rounded-lg"
              />
            </div>
          </div>

          <!-- 密码输入 -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">密码</label>
            <div class="relative flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all">
              <Lock class="absolute left-3 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="请输入密码"
                class="flex-1 w-full pl-10 pr-10 py-2.5 bg-transparent text-zinc-900 dark:text-zinc-100 text-sm placeholder:text-zinc-400 focus:outline-none rounded-lg"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300 transition-colors"
              >
                <EyeOff v-if="showPassword" class="w-4 h-4" />
                <Eye v-else class="w-4 h-4" />
              </button>
            </div>
          </div>

          <!-- 登录按钮 -->
          <Button
            type="submit"
            :disabled="loading"
            class="w-full h-11 text-sm font-medium rounded-lg mt-2"
            size="lg"
          >
            <template v-if="loading">
              <Loader2 class="w-4 h-4 mr-2 animate-spin" />
              登录中...
            </template>
            <template v-else>
              登录
              <ArrowRight class="w-4 h-4 ml-2" />
            </template>
          </Button>
        </form>

        <!-- 底部链接 -->
        <div class="flex items-center justify-between mt-6 pt-6 border-t border-zinc-100 dark:border-zinc-800">
          <router-link
            to="/register"
            class="text-sm text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            注册账户
          </router-link>
          <router-link
            to="/forget"
            class="text-sm text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            忘记密码
          </router-link>
        </div>
      </div>

      <!-- 特性标签 -->
      <div class="flex items-center justify-center gap-6 mt-8">
        <div class="flex items-center gap-2 text-zinc-500 dark:text-zinc-400">
          <Globe class="w-4 h-4" />
          <span class="text-xs">全球加速</span>
        </div>
        <div class="flex items-center gap-2 text-zinc-500 dark:text-zinc-400">
          <Shield class="w-4 h-4" />
          <span class="text-xs">安全加密</span>
        </div>
        <div class="flex items-center gap-2 text-zinc-500 dark:text-zinc-400">
          <Zap class="w-4 h-4" />
          <span class="text-xs">极速连接</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
