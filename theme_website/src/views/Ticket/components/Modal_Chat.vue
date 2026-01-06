<script setup>
import { ref, computed } from "vue";
import moment from "moment";
import md5 from "md5";
import { replyTicket } from "@/api/ticket.js";
import { uploadImage } from "@/api/upload.js";
import { message } from 'ant-design-vue';
import { useUserStore } from "@/stores/User.js";
import { Minx } from "../Minx";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { User, Send, ImagePlus, X, Loader2 } from 'lucide-vue-next';

const emit = defineEmits(["chat"]);
const open = defineModel('open');
const data = defineProps(['chat']);

const user = useUserStore();

const msg = ref('');
const loading = ref(false);
const uploading = ref(false);
const uploadedImages = ref([]);
const fileInputRef = ref(null);
const avatarLoadError = ref(false);

// 网站 logo（客服头像）
const siteLogo = computed(() => window.config?.logo || 'img/localized/logo-fallback.png');

// 用户邮箱
const userEmail = computed(() => user.Subscribe?.email || user.Info?.email || '');

// Gravatar URL（用户头像）
const gravatarUrl = computed(() => {
  const email = userEmail.value;
  if (!email) return '';
  const hash = md5(email.toLowerCase().trim());
  return `https://cravatar.cn/avatar/${hash}?d=404&s=80`;
});

const handleAvatarError = () => {
  avatarLoadError.value = true;
};

// 检查是否可以回复（最后一条消息不是自己发的才能回复）
const canReply = computed(() => {
  if (!data.chat?.data?.message?.length) return true;
  const lastMessage = data.chat.data.message[data.chat.data.message.length - 1];
  return !lastMessage.is_me;
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
  // 清空 input 以便重复选择同一文件
  event.target.value = '';
};

// 移除已上传的图片
const removeImage = (index) => {
  uploadedImages.value.splice(index, 1);
};

// 构建消息内容（包含图片）
const buildMessage = () => {
  let content = msg.value.trim();

  if (uploadedImages.value.length > 0) {
    const imageLinks = uploadedImages.value
      .map(img => `[图片](${img.url})`)
      .join('\n');
    content = content ? `${content}\n\n${imageLinks}` : imageLinks;
  }

  return content;
};

const ok = () => {
  const content = buildMessage();
  if (!content || loading.value) return;

  loading.value = true;
  replyTicket(data.chat.data.id, content)
    .then(response => {
      // xboard API 成功时返回 { data: true } 或直接返回 true
      if (response === true || response?.data === true || response?.status === 'success') {
        message.success('回复成功');
        const newMessage = {
          message: content,
          is_me: true,
          created_at: Math.floor(Date.now() / 1000),
        };
        data.chat.data.message.push(newMessage);
        msg.value = "";
        uploadedImages.value = [];
        emit('chat');
      } else {
        message.error(response?.message || "回复失败，请重试");
      }
    })
    .catch(err => {
      console.error("回复失败:", err);
      // 处理后端返回的错误消息
      const errorMsg = err?.data?.message || err?.message || "回复失败，请重试";
      // 如果是连续回复限制，显示更友好的提示
      if (errorMsg.includes('wait') || errorMsg.includes('等待')) {
        message.error("请等待客服回复后再发送消息");
      } else {
        message.error(errorMsg);
      }
    })
    .finally(() => {
      loading.value = false;
    });
};

// 解析消息中的图片链接
const parseMessageImages = (text) => {
  const imageRegex = /\[图片\]\((https?:\/\/[^\)]+)\)/g;
  const images = [];
  let match;
  while ((match = imageRegex.exec(text)) !== null) {
    images.push(match[1]);
  }
  // 移除图片标记后的文本
  const cleanText = text.replace(imageRegex, '').trim();
  return { text: cleanText, images };
};
</script>

<template>
  <Dialog v-model:open="open">
    <DialogContent class="sm:max-w-2xl max-h-[85vh] overflow-hidden flex flex-col">
      <DialogHeader>
        <DialogTitle>工单详情</DialogTitle>
      </DialogHeader>

      <!-- 消息列表 -->
      <div v-if="data.chat" class="flex-1 overflow-y-auto -mx-6 px-6 py-4 space-y-4">
        <div
          v-for="(item, index) in data.chat?.data.message"
          :key="index"
          class="flex gap-3"
          :class="item.is_me ? 'flex-row-reverse' : ''"
        >
          <!-- 头像 -->
          <div class="w-9 h-9 rounded-full overflow-hidden shrink-0 border-2 border-zinc-200 dark:border-zinc-700">
            <!-- 用户头像 -->
            <template v-if="item.is_me">
              <img
                v-if="gravatarUrl && !avatarLoadError"
                :src="gravatarUrl"
                alt="用户头像"
                class="w-full h-full object-cover"
                @error="handleAvatarError"
              />
              <img
                v-else
                src="/assets/illustrations/undraw_cat_lqdj.svg"
                alt="默认头像"
                class="w-full h-full object-contain bg-indigo-50 dark:bg-indigo-900/30 scale-[1.8]"
              />
            </template>
            <!-- 客服头像（网站logo） -->
            <template v-else>
              <img
                :src="siteLogo"
                alt="客服"
                class="w-full h-full object-contain bg-white dark:bg-zinc-800 p-0.5"
              />
            </template>
          </div>
          <!-- 消息内容 -->
          <div class="max-w-[75%]">
            <div class="flex items-center gap-2 mb-1" :class="item.is_me ? 'flex-row-reverse' : ''">
              <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                {{ item.is_me ? '我' : '客服' }}
              </span>
              <span class="text-xs text-zinc-400">
                {{ moment(item.created_at * 1000).format("MM-DD HH:mm") }}
              </span>
            </div>
            <div
              class="px-4 py-2.5 rounded-2xl text-sm"
              :class="item.is_me
                ? 'bg-blue-500 text-white rounded-tr-sm'
                : 'bg-zinc-100 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 rounded-tl-sm'"
            >
              <!-- 解析消息文本 -->
              <template v-if="parseMessageImages(item.message).text">
                {{ parseMessageImages(item.message).text }}
              </template>
              <!-- 显示消息中的图片 -->
              <div v-if="parseMessageImages(item.message).images.length > 0" class="mt-2 space-y-2">
                <a
                  v-for="(imgUrl, imgIndex) in parseMessageImages(item.message).images"
                  :key="imgIndex"
                  :href="imgUrl"
                  target="_blank"
                  class="block"
                >
                  <img
                    :src="imgUrl"
                    alt="上传的图片"
                    class="max-w-full max-h-48 rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
                  />
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 回复区域 -->
      <div v-if="data.chat && Minx.status(data.chat.data.status)[0] !== '已关闭'" class="border-t border-zinc-200 dark:border-zinc-700 pt-4 -mx-6 px-6">
        <!-- 已上传图片预览 -->
        <div v-if="uploadedImages.length > 0" class="flex flex-wrap gap-2 mb-3">
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

        <div class="flex gap-3">
          <textarea
            v-model="msg"
            :placeholder="canReply ? '输入回复内容...' : '请等待客服回复后再发送消息'"
            rows="3"
            :disabled="!canReply"
            class="flex-1 px-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none disabled:opacity-50 disabled:cursor-not-allowed"
          />
        </div>
        <div class="flex justify-between items-center mt-3">
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
              :disabled="uploading || !canReply"
            >
              <Loader2 v-if="uploading" class="w-4 h-4 mr-1.5 animate-spin" />
              <ImagePlus v-else class="w-4 h-4 mr-1.5" />
              {{ uploading ? '上传中...' : '上传图片' }}
            </Button>
          </div>
          <!-- 发送按钮 -->
          <div class="relative group">
            <Button @click="ok" :disabled="loading || !canReply || (!msg.trim() && uploadedImages.length === 0)">
              <Send class="w-4 h-4 mr-1.5" />
              {{ loading ? '发送中...' : '发送回复' }}
            </Button>
            <!-- 悬浮提示 -->
            <div
              v-if="!canReply"
              class="absolute bottom-full right-0 mb-2 px-3 py-1.5 bg-zinc-800 text-white text-xs rounded-lg whitespace-nowrap opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 pointer-events-none"
            >
              请等待客服回复
              <div class="absolute top-full right-4 border-4 border-transparent border-t-zinc-800"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- 已关闭提示 -->
      <div v-else-if="data.chat && Minx.status(data.chat.data.status)[0] === '已关闭'" class="border-t border-zinc-200 dark:border-zinc-700 pt-4 -mx-6 px-6">
        <p class="text-center text-sm text-red-500">
          该工单已关闭，无法回复。如有需要请新建工单。
        </p>
      </div>
    </DialogContent>
  </Dialog>
</template>

<style scoped>
</style>
