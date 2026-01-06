<script setup>
import { ref } from "vue";
import { changePassword } from '@/api/User.js';
import { message } from 'ant-design-vue';
import { Button } from '@/components/ui/button';
import { Eye, EyeOff, Save } from 'lucide-vue-next';

const form = ref({
  oldPassword: "",
  newPassword: "",
  confirmPassword: "",
});

const loading = ref(false);
const showOldPassword = ref(false);
const showNewPassword = ref(false);
const showConfirmPassword = ref(false);

const handleChangePassword = async () => {
  if (!form.value.oldPassword) {
    message.error("请输入旧密码");
    return;
  }

  if (!form.value.newPassword) {
    message.error("请输入新密码");
    return;
  }

  if (form.value.newPassword !== form.value.confirmPassword) {
    message.error("新密码与确认密码不一致");
    return;
  }

  if (form.value.newPassword === form.value.oldPassword) {
    message.error("新密码不能与旧密码相同");
    return;
  }

  loading.value = true;

  try {
    const response = await changePassword({
      old_password: form.value.oldPassword,
      new_password: form.value.newPassword,
    });

    if (response && response.data) {
      message.success("密码修改成功");
      form.value.oldPassword = "";
      form.value.newPassword = "";
      form.value.confirmPassword = "";
    } else {
      message.error("密码修改失败，请稍后再试");
    }
  } catch (error) {
    message.error("发生错误: " + (error.response?.data?.message || error.message));
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-4 py-2">
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">旧密码</label>
      <div class="relative">
        <input
          v-model="form.oldPassword"
          :type="showOldPassword ? 'text' : 'password'"
          placeholder="请输入旧密码"
          class="w-full px-3 py-2 pr-10 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="button"
          @click="showOldPassword = !showOldPassword"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600"
        >
          <EyeOff v-if="showOldPassword" class="w-4 h-4" />
          <Eye v-else class="w-4 h-4" />
        </button>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">新密码</label>
      <div class="relative">
        <input
          v-model="form.newPassword"
          :type="showNewPassword ? 'text' : 'password'"
          placeholder="请输入新密码"
          class="w-full px-3 py-2 pr-10 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="button"
          @click="showNewPassword = !showNewPassword"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600"
        >
          <EyeOff v-if="showNewPassword" class="w-4 h-4" />
          <Eye v-else class="w-4 h-4" />
        </button>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">确认新密码</label>
      <div class="relative">
        <input
          v-model="form.confirmPassword"
          :type="showConfirmPassword ? 'text' : 'password'"
          placeholder="请再次输入新密码"
          class="w-full px-3 py-2 pr-10 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="button"
          @click="showConfirmPassword = !showConfirmPassword"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600"
        >
          <EyeOff v-if="showConfirmPassword" class="w-4 h-4" />
          <Eye v-else class="w-4 h-4" />
        </button>
      </div>
    </div>

    <div class="flex justify-end pt-2">
      <Button @click="handleChangePassword" :disabled="loading">
        <Save class="w-4 h-4 mr-1.5" />
        {{ loading ? '保存中...' : '保存修改' }}
      </Button>
    </div>
  </div>
</template>

<style scoped>
</style>
