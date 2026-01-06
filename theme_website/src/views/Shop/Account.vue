<script setup lang="ts">
import { ref, onBeforeMount, watch } from "vue";
import { useShop } from "./useShop";
import { getCommConfig } from "@/api/auth.js";
import { Mail, Lock, Eye, EyeOff, ChevronDown } from 'lucide-vue-next';

const { accountForm } = useShop();

// 表单数据
const formData = ref({
  username: '',
  email_whitelist_suffix_value: '',
});

// 邮箱后缀选项
const emailSuffixOptions = ref<string[]>([]);
const showSuffixDropdown = ref(false);
const showPassword = ref(false);

// 获取邮箱后缀列表
const fetchEmailSuffixOptions = async () => {
  try {
    const response = await getCommConfig();
    emailSuffixOptions.value = response.data.email_whitelist_suffix || [];
    formData.value.email_whitelist_suffix_value = emailSuffixOptions.value[0] || '@example.com';
  } catch (error) {
    console.error("Failed to fetch email suffix options:", error);
  }
};

onBeforeMount(fetchEmailSuffixOptions);

// 更新 accountForm.email
const updateAccountEmail = () => {
  if (!formData.value.email_whitelist_suffix_value.startsWith('@')) {
    formData.value.email_whitelist_suffix_value = '@' + formData.value.email_whitelist_suffix_value;
  }
  accountForm.value.email = `${formData.value.username}${formData.value.email_whitelist_suffix_value}`;
};

// 选择邮箱后缀
const selectSuffix = (suffix: string) => {
  formData.value.email_whitelist_suffix_value = suffix;
  showSuffixDropdown.value = false;
};

watch([() => formData.value.username, () => formData.value.email_whitelist_suffix_value], updateAccountEmail);
</script>

<template>
  <div class="mb-8 sm:mb-10">
    <div class="flex items-center gap-3 mb-4 sm:mb-6">
      <div class="w-8 h-8 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-sm font-semibold">3</div>
      <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100">创建你的账户</h2>
    </div>

    <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4 sm:p-6">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
        <!-- 邮箱输入 -->
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">邮箱</label>
          <div class="flex gap-2">
            <div class="relative flex-1">
              <Mail class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400" />
              <input
                v-model="formData.username"
                type="text"
                placeholder="请输入邮箱前缀"
                class="w-full pl-10 pr-3 py-2.5 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <!-- 邮箱后缀下拉 -->
            <div class="relative">
              <button
                type="button"
                @click="showSuffixDropdown = !showSuffixDropdown"
                class="flex items-center gap-1 px-3 py-2.5 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm hover:bg-zinc-50 dark:hover:bg-zinc-700"
              >
                <span>{{ formData.email_whitelist_suffix_value }}</span>
                <ChevronDown class="w-4 h-4" />
              </button>
              <!-- 下拉菜单 -->
              <div
                v-if="showSuffixDropdown"
                class="absolute top-full left-0 mt-1 w-full min-w-[140px] bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg shadow-lg z-10 py-1"
              >
                <button
                  v-for="suffix in emailSuffixOptions"
                  :key="suffix"
                  type="button"
                  @click="selectSuffix(suffix)"
                  class="w-full px-3 py-2 text-left text-sm text-zinc-900 dark:text-zinc-100 hover:bg-zinc-100 dark:hover:bg-zinc-700"
                >
                  {{ suffix }}
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 密码输入 -->
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">密码</label>
          <div class="relative">
            <Lock class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400" />
            <input
              v-model="accountForm.password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="请输入你的密码"
              class="w-full pl-10 pr-10 py-2.5 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <button
              type="button"
              @click="showPassword = !showPassword"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600"
            >
              <EyeOff v-if="showPassword" class="w-4 h-4" />
              <Eye v-else class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>
