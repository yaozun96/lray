<script setup lang="ts">
import { ref, watch } from 'vue';
import { message } from 'ant-design-vue';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

const props = defineProps<{
  open: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void;
  (e: 'verified'): void;
}>();

const captchaQuestion = ref('');
const captchaAnswer = ref(0);
const userAnswer = ref('');

const generateCaptcha = () => {
  const num1 = Math.floor(Math.random() * 10);
  const num2 = Math.floor(Math.random() * 10);
  captchaQuestion.value = `${num1} + ${num2} = ?`;
  captchaAnswer.value = num1 + num2;
  userAnswer.value = '';
};

const verifyCaptcha = () => {
  if (parseInt(userAnswer.value) === captchaAnswer.value) {
    emit('update:open', false);
    emit('verified');
  } else {
    message.error('计算错误，请重试');
    generateCaptcha();
  }
};

// 当弹窗打开时，生成新的验证码
watch(() => props.open, (newVal) => {
  if (newVal) {
    generateCaptcha();
  }
});
</script>

<template>
  <Dialog :open="open" @update:open="emit('update:open', $event)">
    <DialogContent class="sm:max-w-[360px]">
      <DialogHeader>
        <DialogTitle>安全验证</DialogTitle>
        <DialogDescription>请计算下面的结果</DialogDescription>
      </DialogHeader>

      <div class="text-center py-4">
        <p class="text-3xl font-bold text-blue-600 dark:text-blue-400 mb-6">{{ captchaQuestion }}</p>
        <div class="flex gap-3">
          <input
            v-model="userAnswer"
            type="text"
            placeholder="请输入答案"
            class="flex-1 px-3 py-2.5 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
            @keyup.enter="verifyCaptcha"
          />
          <Button @click="verifyCaptcha">验证</Button>
        </div>
      </div>
    </DialogContent>
  </Dialog>
</template>
