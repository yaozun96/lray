<script setup>
import { ref, watch } from "vue";
import { createTicket } from "@/api/ticket.js";
import { uploadImage } from "@/api/upload.js";
import { notifyApiError } from "@/utils/error.js";
import { message } from 'ant-design-vue';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { X, Send, ImagePlus, Loader2 } from 'lucide-vue-next';

const open = defineModel('open')
const emit = defineEmits(["up"])
const obj = ref({
  level: '0',
  subject: '',
  message: '',
  loading: false
})

const uploading = ref(false);
const uploadedImages = ref([]);
const fileInputRef = ref(null);

// 重置表单
watch(open, (newVal) => {
  if (!newVal) {
    obj.value.subject = '';
    obj.value.message = '';
    obj.value.level = '0';
    uploadedImages.value = [];
  }
});

// 触发文件选择
const triggerFileInput = () => {
  fileInputRef.value?.click();
};

// 处理文件选择
const handleFileSelect = async (event) => {
  const files = event.target.files;
  if (!files || files.length === 0) return;

  uploading.value = true;

  for (const file of files) {
    try {
      const result = await uploadImage(file);
      if (result.success) {
        uploadedImages.value.push({
          url: result.data.url,
          thumbnailUrl: result.data.thumbnailUrl || result.data.url,
          filename: result.data.filename || file.name,
        });
        message.success('图片上传成功');
      }
    } catch (error) {
      message.error(error.message || '图片上传失败');
    }
  }

  uploading.value = false;
  event.target.value = '';
};

// 移除已上传的图片
const removeImage = (index) => {
  uploadedImages.value.splice(index, 1);
};

// 构建消息内容（包含图片）
const buildMessage = () => {
  let content = obj.value.message.trim();

  if (uploadedImages.value.length > 0) {
    const imageLinks = uploadedImages.value
      .map(img => `[图片](${img.url})`)
      .join('\n');
    content = content ? `${content}\n\n${imageLinks}` : imageLinks;
  }

  return content;
};

const sendTicket = async () => {
  if (obj.value.loading) return;

  const messageContent = buildMessage();
  if (!messageContent) {
    message.warning('请输入消息内容或上传图片');
    return;
  }

  obj.value.loading = true;
  try {
    await createTicket({
      level: obj.value.level,
      subject: obj.value.subject,
      message: messageContent
    });
    open.value = false;
    emit('up');
  } catch (error) {
    notifyApiError(error, '提交工单失败');
  } finally {
    obj.value.loading = false;
  }
};
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>新建工单</DialogTitle>
        <DialogDescription>请填写工单信息，我们会尽快回复</DialogDescription>
      </DialogHeader>


      <div class="flex flex-col gap-4 py-4">

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">主题</label>
          <input
            v-model="obj.subject"
            placeholder="请输入主题"
            class="px-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">工单等级</label>
          <select
            v-model="obj.level"
            class="px-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="0">低级</option>
            <option value="1">中级</option>
            <option value="2">高级</option>
          </select>
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">消息</label>
          <textarea
            v-model="obj.message"
            placeholder="请描述你遇到的问题"
            rows="5"
            class="px-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
          />
        </div>

        <!-- 图片上传区域 -->
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-zinc-900 dark:text-zinc-100">附件图片</label>

          <!-- 已上传图片预览 -->
          <div v-if="uploadedImages.length > 0" class="flex flex-wrap gap-2 mb-2">
            <div
              v-for="(img, index) in uploadedImages"
              :key="index"
              class="relative group"
            >
              <img
                :src="img.thumbnailUrl"
                :alt="img.filename"
                class="w-16 h-16 object-cover rounded-lg border border-zinc-200 dark:border-zinc-700"
              />
              <button
                @click="removeImage(index)"
                class="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <X class="w-3 h-3" />
              </button>
            </div>
          </div>

          <!-- 上传按钮 -->
          <div>
            <input
              ref="fileInputRef"
              type="file"
              accept="image/*"
              multiple
              class="hidden"
              @change="handleFileSelect"
            />
            <Button
              variant="outline"
              size="sm"
              @click="triggerFileInput"
              :disabled="uploading"
              class="w-full"
            >
              <Loader2 v-if="uploading" class="w-4 h-4 mr-1.5 animate-spin" />
              <ImagePlus v-else class="w-4 h-4 mr-1.5" />
              {{ uploading ? '上传中...' : '点击上传图片' }}
            </Button>
            <p class="text-xs text-zinc-400 mt-1">支持 JPG、PNG、GIF 等格式，最大 32MB</p>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-3">
        <Button variant="outline" @click="open = false">
          <X class="w-4 h-4 mr-1.5" />
          取消
        </Button>
        <Button @click="sendTicket" :disabled="obj.loading">
          <Send class="w-4 h-4 mr-1.5" />
          {{ obj.loading ? '提交中...' : '提交工单' }}
        </Button>
      </div>
    </DialogContent>
  </Dialog>
</template>

<style scoped>
</style>
