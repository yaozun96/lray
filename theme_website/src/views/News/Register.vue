<script setup lang="ts">
import { ref, computed, onBeforeMount, onMounted } from "vue";
import { useRoute } from "vue-router";
import { getCommConfig, register, sendEmailVerify } from "@/api/auth.js";
import { message } from 'ant-design-vue';
import { useInfoStore } from "@/stores/counter.js";
import confetti from "canvas-confetti";

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

// Lucide Icons
import { Mail, Lock, Eye, EyeOff, Loader2, ArrowRight, Ticket, ChevronDown, ShieldCheck, Send, Check, Globe, Shield, Zap } from 'lucide-vue-next';

// 路由和状态管理
const route = useRoute();
const Token = useInfoStore();

// 验证码倒计时
const codeTime = ref(0);
let timer: any = null;

// 控制验证码弹窗的显示
const isVerifyModalVisible = ref(false);

// 存储每个格子的验证码字符
const verificationCode = ref(["", "", "", "", "", ""]);

// 密码显示控制
const showPassword = ref(false);

// 邮箱后缀下拉
const showSuffixDropdown = ref(false);

// 加载状态
const loading = ref(false);

// 表单数据
const formData = ref({
  username: "",
  password: "",
  email_whitelist_suffix: [] as string[],
  email_whitelist_suffix_value: "",
  is_email_verify: 0,
  is_invite_force: 0,
  inviteCode: "",
  email() {
    return this.username + this.email_whitelist_suffix_value;
  },
});

// 表单默认值设置
const cpData = computed(() => {
  const config = window.config || {};
  const { Sign = {} } = config;
  return {
    title: config.title || 'Lray',
    logo: config.logo || 'img/localized/logo-fallback.png',
    inviteCodeEdit: Sign.inviteCodeEdit || false,
  };
});

// 选择邮箱后缀
const selectSuffix = (suffix: string) => {
  formData.value.email_whitelist_suffix_value = suffix;
  showSuffixDropdown.value = false;
};

// 发送邮箱验证码
const sendEmailCode = () => {
  const email = formData.value.email();
  sendEmailVerify({ email })
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
      let msg = err.data?.message || "发送验证码失败";
      if (msg === "The given data was invalid.") {
        msg = "请检查邮箱是否正确";
      }
      message.error(msg);
    });
};

// 表单验证
const validateForm = (): boolean => {
  const email = formData.value.email();
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

  if (!formData.value.username) {
    message.error("请填写邮箱");
    return false;
  }
  if (!emailRegex.test(email)) {
    message.error("请填写正确的邮箱");
    return false;
  }
  if (!formData.value.password) {
    message.error("请填写密码");
    return false;
  }
  if (formData.value.password.length < 8) {
    message.error("密码长度不足 8 位");
    return false;
  }
  if (formData.value.is_invite_force === 1 && !formData.value.inviteCode) {
    message.error("请填写邀请码");
    return false;
  }
  return true;
};

// 提交表单
const onSubmit = () => {
  if (!validateForm()) return;

  if (formData.value.is_email_verify === 1) {
    isVerifyModalVisible.value = true;
    sendEmailCode();
  } else {
    doRegister();
  }
};

// 执行注册
const doRegister = (emailCode?: string) => {
  loading.value = true;
  register({
    email: formData.value.email(),
    password: formData.value.password,
    invite_code: formData.value.inviteCode,
    ...(emailCode ? { email_code: emailCode } : {}),
  })
    .then((res) => {
      message.success("注册成功");
      // 注册成功后清除保存的邀请码
      localStorage.removeItem('invite_code');
      Token.Set_Token(res.data.auth_data);
      setTimeout(() => {
        window.location.reload();
      }, 1500);
    })
    .catch((err) => {
      let msg = err.data?.message || "注册失败";
      if (msg === "The given data was invalid.") {
        msg = "请检查邮箱或密码是否正确";
      }
      message.error(msg);
    })
    .finally(() => {
      loading.value = false;
    });
};

// 验证验证码并完成注册
const handleVerify = () => {
  const code = verificationCode.value.join("");
  if (code.length !== 6) {
    message.error("请输入完整的验证码");
    return;
  }
  isVerifyModalVisible.value = false;
  doRegister(code);
};

// 处理验证码输入
const handleInput = (index: number, event: Event) => {
  const input = event.target as HTMLInputElement;
  if (input.value.length > 1) {
    input.value = input.value.slice(0, 1);
  }
  verificationCode.value[index] = input.value;

  if (input.value && index < verificationCode.value.length - 1) {
    (document.getElementById(`code-input-${index + 1}`) as HTMLInputElement)?.focus();
  }

  if (verificationCode.value.every((val) => val.length === 1)) {
    handleVerify();
  }
};

// 处理退格键
const handleKeydown = (index: number, event: KeyboardEvent) => {
  const input = event.target as HTMLInputElement;
  if (event.key === "Backspace" && !input.value && index > 0) {
    (document.getElementById(`code-input-${index - 1}`) as HTMLInputElement)?.focus();
  }
};

// 处理粘贴事件
const handlePaste = (event: ClipboardEvent) => {
  const clipboardData = event.clipboardData || (window as any).clipboardData;
  const pasteText = clipboardData?.getData("text") || "";

  if (pasteText.length === verificationCode.value.length) {
    pasteText.split("").forEach((char: string, idx: number) => {
      verificationCode.value[idx] = char;
    });
    handleVerify();
  }
};

// 初始化配置
onBeforeMount(() => {
  // 邀请码持久化：优先使用 URL 参数，否则从 localStorage 读取
  const urlCode = route.query.code as string;
  if (urlCode) {
    // URL 中有邀请码，保存到 localStorage
    formData.value.inviteCode = urlCode;
    localStorage.setItem('invite_code', urlCode);
  } else {
    // URL 中没有邀请码，尝试从 localStorage 读取
    formData.value.inviteCode = localStorage.getItem('invite_code') || "";
  }

  getCommConfig().then((res) => {
    formData.value.is_email_verify = res.data.is_email_verify;
    formData.value.is_invite_force = res.data.is_invite_force;

    if (res.data.email_whitelist_suffix && res.data.email_whitelist_suffix.length > 0) {
      formData.value.email_whitelist_suffix = res.data.email_whitelist_suffix.map((item: string) => "@" + item);
      formData.value.email_whitelist_suffix_value = formData.value.email_whitelist_suffix[0];
    }
  });
});

// 如果有邀请码，播放礼花动画
onMounted(() => {
  if (formData.value.inviteCode) {
    setTimeout(() => {
      // 左侧礼花
      confetti({
        particleCount: 80,
        spread: 60,
        origin: { x: 0.2, y: 0.4 },
        zIndex: 2000
      });
      // 右侧礼花
      confetti({
        particleCount: 80,
        spread: 60,
        origin: { x: 0.8, y: 0.4 },
        zIndex: 2000
      });
      // 中间礼花
      setTimeout(() => {
        confetti({
          particleCount: 120,
          spread: 100,
          origin: { x: 0.5, y: 0.3 },
          zIndex: 2000
        });
      }, 150);
    }, 300);
  }
});
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- 注册卡片 -->
      <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8 sm:p-10 shadow-sm">
        <!-- 头部 -->
        <div class="text-center mb-8">
          <!-- 邀请状态徽章 -->
          <div v-if="formData.inviteCode" class="inline-flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 mb-4 shadow-lg shadow-purple-500/25">
            <span class="text-base">🎉</span>
            <span class="text-sm font-semibold text-white tracking-wide">你已被邀请加入专属通道</span>
          </div>

          <!-- 插图 -->
          <div class="flex justify-center mb-4">
            <img
              src="/assets/illustrations/undraw_launch-event_aur1.svg"
              alt="注册"
              class="w-32 h-32 object-contain"
            />
          </div>

          <h1 class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100 mb-2">
            创建账户
          </h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400">
            只需 10 秒，即可开始使用 {{ cpData.title }} 连接世界🚀
          </p>
        </div>

        <!-- 三步流程提示 -->
        <div class="flex items-center justify-center gap-2 mb-8">
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-zinc-100 dark:bg-zinc-800 text-xs text-zinc-600 dark:text-zinc-400">
            <div class="w-4 h-4 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-[10px] font-medium">1</div>
            <span>邮箱</span>
          </div>
          <div class="w-4 h-px bg-zinc-300 dark:bg-zinc-600"></div>
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-zinc-100 dark:bg-zinc-800 text-xs text-zinc-600 dark:text-zinc-400">
            <div class="w-4 h-4 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-[10px] font-medium">2</div>
            <span>密码</span>
          </div>
          <div class="w-4 h-px bg-zinc-300 dark:bg-zinc-600"></div>
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-zinc-100 dark:bg-zinc-800 text-xs text-zinc-600 dark:text-zinc-400">
            <Check class="w-4 h-4" />
            <span>完成</span>
          </div>
        </div>

        <!-- 表单 -->
        <form @submit.prevent="onSubmit" class="space-y-4">
          <!-- 邮箱输入 -->
          <div class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">邮箱</label>
            <div class="relative flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all">
              <Mail class="absolute left-3 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.username"
                type="text"
                placeholder="your@email.com"
                class="flex-1 w-full pl-10 pr-3 py-2.5 bg-transparent text-zinc-900 dark:text-zinc-100 text-sm placeholder:text-zinc-400 focus:outline-none rounded-lg"
              />
              <!-- 邮箱后缀下拉 -->
              <div v-if="formData.email_whitelist_suffix.length > 0" class="relative shrink-0">
                <button
                  type="button"
                  @click="showSuffixDropdown = !showSuffixDropdown"
                  class="flex items-center gap-1 px-2 py-1 mr-2 rounded text-zinc-600 dark:text-zinc-300 text-sm hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
                >
                  <span>{{ formData.email_whitelist_suffix_value }}</span>
                  <ChevronDown class="w-3 h-3" />
                </button>
                <div
                  v-if="showSuffixDropdown"
                  class="absolute top-full right-0 mt-1 min-w-[120px] bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg shadow-lg z-10 py-1 overflow-hidden"
                >
                  <button
                    v-for="suffix in formData.email_whitelist_suffix"
                    :key="suffix"
                    type="button"
                    @click="selectSuffix(suffix)"
                    class="w-full px-3 py-2 text-left text-sm text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-700 transition-colors"
                  >
                    {{ suffix }}
                  </button>
                </div>
              </div>
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

          <!-- 邀请码输入 -->
          <div v-if="formData.inviteCode || formData.is_invite_force === 1" class="space-y-1.5">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">
              邀请码
              <span v-if="formData.is_invite_force === 1" class="text-red-500">*</span>
            </label>
            <div
              class="relative flex items-center rounded-lg border border-zinc-300 dark:border-zinc-700 focus-within:border-zinc-900 dark:focus-within:border-zinc-400 focus-within:ring-1 focus-within:ring-zinc-900 dark:focus-within:ring-zinc-400 transition-all"
              :class="{ 'opacity-60': cpData.inviteCodeEdit }"
            >
              <Ticket class="absolute left-3 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.inviteCode"
                type="text"
                placeholder="输入邀请码"
                :disabled="cpData.inviteCodeEdit"
                class="flex-1 w-full pl-10 pr-4 py-2.5 bg-transparent text-zinc-900 dark:text-zinc-100 text-sm placeholder:text-zinc-400 focus:outline-none disabled:cursor-not-allowed rounded-lg"
              />
            </div>
          </div>

          <!-- 注册按钮 -->
          <Button
            type="submit"
            :disabled="loading"
            class="w-full h-11 text-sm font-medium rounded-lg mt-2"
            size="lg"
          >
            <template v-if="loading">
              <Loader2 class="w-4 h-4 mr-2 animate-spin" />
              创建中...
            </template>
            <template v-else>
              创建账户
              <ArrowRight class="w-4 h-4 ml-2" />
            </template>
          </Button>
        </form>

        <!-- 底部链接 -->
        <div class="text-center mt-6 pt-6 border-t border-zinc-100 dark:border-zinc-800">
          <span class="text-sm text-zinc-500 dark:text-zinc-400">已有账户？</span>
          <router-link
            to="/login"
            class="text-sm font-medium text-zinc-900 dark:text-zinc-100 hover:underline ml-1"
          >
            立即登录
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

    <!-- 邮箱验证弹窗 -->
    <Dialog v-model:open="isVerifyModalVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <div class="flex justify-center mb-4">
            <div class="w-12 h-12 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
              <ShieldCheck class="w-6 h-6 text-zinc-600 dark:text-zinc-400" />
            </div>
          </div>
          <DialogTitle class="text-center text-lg">验证邮箱</DialogTitle>
          <DialogDescription class="text-center text-sm">
            请输入发送至您邮箱的 6 位验证码
          </DialogDescription>
        </DialogHeader>

        <div class="flex gap-2 justify-center my-6">
          <input
            v-for="(code, index) in verificationCode"
            :key="index"
            :id="`code-input-${index}`"
            v-model="verificationCode[index]"
            maxlength="1"
            class="w-10 h-12 text-center text-lg font-medium border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:border-zinc-900 dark:focus:border-zinc-400 focus:ring-1 focus:ring-zinc-900 dark:focus:ring-zinc-400 transition-all"
            @input="handleInput(index, $event)"
            @keydown="handleKeydown(index, $event)"
            @paste="handlePaste"
          />
        </div>

        <div class="flex justify-center">
          <button
            @click="sendEmailCode"
            :disabled="codeTime > 0"
            class="text-sm text-zinc-500 hover:text-zinc-900 dark:hover:text-zinc-100 disabled:opacity-50 transition-colors"
          >
            {{ codeTime > 0 ? `${codeTime}s 后重发` : '重新发送验证码' }}
          </button>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
</style>
