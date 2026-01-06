<script setup lang="ts">
import { computed, ref } from "vue";
import { resetPassword, sendEmailVerify } from "@/api/auth.js";
import { message } from 'ant-design-vue';
import { useRouter } from "vue-router";

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';

// Lucide Icons
import { Mail, Lock, Eye, EyeOff, Loader2, ArrowRight, Send, ShieldCheck, Globe, Shield, Zap } from 'lucide-vue-next';

const router = useRouter();

const codeTime = ref(0);
let timer: any = null;

const loading = ref(false);
const showPassword = ref(false);

const formData = ref({
  email: '',
  password: '',
  code: '',
});

const cpData = computed(() => {
  const { title, Sign } = window.config;

  return {
    title: title || 'Lray',
  };
});

// 发送验证码
const sendCode = () => {
  if (!formData.value.email) {
    message.error('请先输入邮箱');
    return;
  }

  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  if (!emailRegex.test(formData.value.email)) {
    message.error('请输入正确的邮箱');
    return;
  }

  sendEmailVerify({ email: formData.value.email })
    .then(() => {
      message.success("验证码已发送");
      codeTime.value = 60;
      timer = setInterval(() => {
        codeTime.value--;
        if (codeTime.value <= 0) {
          clearInterval(timer);
        }
      }, 1000);
    })
    .catch((err) => {
      message.error(err.data?.message || '发送失败');
    });
};

// 表单验证
const validateForm = (): boolean => {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

  if (!formData.value.email) {
    message.error('请填写邮箱');
    return false;
  }
  if (!emailRegex.test(formData.value.email)) {
    message.error('请填写正确的邮箱');
    return false;
  }
  if (!formData.value.code) {
    message.error('请填写验证码');
    return false;
  }
  if (!formData.value.password) {
    message.error('请填写新密码');
    return false;
  }
  if (formData.value.password.length < 8) {
    message.error('密码长度不足 8 位');
    return false;
  }
  return true;
};

// 提交重置
const onSubmit = () => {
  if (!validateForm()) return;

  loading.value = true;
  resetPassword({
    email: formData.value.email,
    password: formData.value.password,
    email_code: formData.value.code,
  })
    .then(() => {
      message.success("重置成功，请登录");
      router.push({ path: '/login' });
    })
    .catch((err) => {
      message.error(err.data?.message || '重置失败');
    })
    .finally(() => {
      loading.value = false;
    });
};
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- 重置密码卡片 -->
      <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 sm:p-10 shadow-sm">
        <!-- 标题 -->
        <div class="text-center mb-8">
          <!-- 插图 -->
          <div class="flex justify-center mb-4">
            <img
              src="/assets/illustrations/undraw_forgot-password_nttj.svg"
              alt="忘记密码"
              class="w-32 h-32 object-contain"
            />
          </div>
          <h1 class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100 mb-2">重置密码</h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400">重置您的 {{ cpData.title }} 账户密码</p>
        </div>

        <!-- 表单 -->
        <form @submit.prevent="onSubmit" class="space-y-4">
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

          <!-- 验证码输入 -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">验证码</label>
            <div class="flex gap-2">
              <div class="relative flex-1 flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all">
                <ShieldCheck class="absolute left-3 w-4 h-4 text-zinc-400" />
                <input
                  v-model="formData.code"
                  type="text"
                  placeholder="邮箱验证码"
                  class="flex-1 w-full pl-10 pr-3 py-2.5 bg-transparent text-zinc-900 dark:text-zinc-100 text-sm placeholder:text-zinc-400 focus:outline-none rounded-lg"
                />
              </div>
              <Button
                type="button"
                variant="outline"
                @click="sendCode"
                :disabled="codeTime > 0"
                class="px-4 h-[42px] rounded-lg whitespace-nowrap"
              >
                <Send class="w-4 h-4 mr-1" />
                {{ codeTime > 0 ? `${codeTime}s` : '发送' }}
              </Button>
            </div>
          </div>

          <!-- 新密码输入 -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">新密码</label>
            <div class="relative flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all">
              <Lock class="absolute left-3 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="至少 8 位字符"
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

          <!-- 重置按钮 -->
          <Button
            type="submit"
            :disabled="loading"
            class="w-full h-11 text-sm font-medium rounded-lg mt-2"
            size="lg"
          >
            <template v-if="loading">
              <Loader2 class="w-4 h-4 mr-2 animate-spin" />
              重置中...
            </template>
            <template v-else>
              重置密码
              <ArrowRight class="w-4 h-4 ml-2" />
            </template>
          </Button>
        </form>

        <!-- 底部链接 -->
        <div class="text-center mt-6 pt-6 border-t border-zinc-100 dark:border-zinc-800">
          <router-link
            to="/login"
            class="text-sm text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            返回登录
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
