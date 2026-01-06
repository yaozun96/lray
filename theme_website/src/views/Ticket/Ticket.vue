<template>
  <div class="min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <!-- 页面标题 -->
      <!-- 页面标题 -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100">我的工单</h1>
            <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">如有问题，请提交工单联系我们</p>
          </div>
          <Button @click="showNewTicketModal = true" class="gap-2">
            <Plus class="w-4 h-4" />
            新建工单
          </Button>
        </div>
      </div>

      <Modal v-model:open="showNewTicketModal" @up="update" />
      <Modal_Chat v-model:open="openChatWindow" :chat="chatData" />

      <!-- 加载状态 -->
      <div v-if="loading" class="flex items-center justify-center py-20">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
      </div>

      <!-- 空状态 -->
      <Card v-else-if="tickets.length === 0" class="border-zinc-200 dark:border-zinc-800">
        <CardContent class="flex flex-col items-center justify-center py-12 sm:py-16 text-center">
          <img
            src="/assets/illustrations/undraw_chat-bot_c8iw.svg"
            alt="No Tickets"
            class="w-40 h-40 sm:w-48 sm:h-48 object-contain mb-6 opacity-90"
          />
          <p class="text-zinc-500 dark:text-zinc-400 mb-6">暂无工单，遇到问题？</p>
          <Button @click="showNewTicketModal = true" variant="outline" class="gap-2">
            <Plus class="w-4 h-4" />
            创建第一个工单
          </Button>
        </CardContent>
      </Card>

      <!-- 工单列表 -->
      <div v-else class="space-y-3">
        <Card
          v-for="ticket in tickets"
          :key="ticket.id"
          class="border-zinc-200 dark:border-zinc-800 hover:border-primary/30 dark:hover:border-primary/30 transition-colors"
        >
          <CardContent class="p-4 sm:p-5">
            <!-- 主体内容 -->
            <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
              <!-- 左侧信息 -->
              <div class="flex-1 min-w-0">
                <!-- 标题和状态 -->
                <div class="flex flex-wrap items-center gap-2 mb-2">
                  <h3 class="text-base font-medium text-zinc-900 dark:text-zinc-100 truncate">
                    {{ ticket.subject }}
                  </h3>
                  <span
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                    :class="getStatusClass(ticket.status)"
                  >
                    {{ getStatusText(ticket.status) }}
                  </span>
                  <span
                    v-if="ticket.status === 0"
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                    :class="getReplyStatusClass(ticket.reply_status)"
                  >
                    {{ getReplyStatusText(ticket.reply_status) }}
                  </span>
                </div>

                <!-- 详细信息 -->
                <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-zinc-500 dark:text-zinc-400">
                  <span class="flex items-center gap-1">
                    <AlertCircle class="w-3.5 h-3.5" />
                    {{ getLevelText(ticket.level) }}
                  </span>
                  <span class="flex items-center gap-1">
                    <Clock class="w-3.5 h-3.5" />
                    {{ formatTime(ticket.created_at) }}
                  </span>
                  <span v-if="ticket.updated_at !== ticket.created_at" class="flex items-center gap-1">
                    <RefreshCw class="w-3.5 h-3.5" />
                    最后回复 {{ formatTime(ticket.updated_at) }}
                  </span>
                </div>
              </div>

              <!-- 右侧操作 -->
              <div class="flex items-center gap-2 shrink-0">
                <Button
                  variant="outline"
                  size="sm"
                  @click="handleChat(ticket.id)"
                  class="gap-1.5"
                >
                  <Eye class="w-4 h-4" />
                  查看
                </Button>
                <Button
                  v-if="ticket.status === 0"
                  variant="outline"
                  size="sm"
                  @click="close(ticket.id)"
                  class="gap-1.5 text-red-600 hover:text-red-700 border-red-200 hover:border-red-300 hover:bg-red-50 dark:text-red-400 dark:border-red-800 dark:hover:border-red-700 dark:hover:bg-red-900/20"
                >
                  <XCircle class="w-4 h-4" />
                  关闭
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { fetchTicketList, closeTicket, fetchTicketDetail } from "@/api/ticket.js";
import Modal from "./components/Modal_Add.vue";
import Modal_Chat from "./components/Modal_Chat.vue";
import { message } from 'ant-design-vue';
import moment from "moment";

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

// Lucide Icons
import {
  Plus,
  Loader2,
  MessageSquare,
  Eye,
  XCircle,
  Clock,
  RefreshCw,
  AlertCircle,
} from 'lucide-vue-next';

const loading = ref(false);
const tickets = ref<any[]>([]);
const showNewTicketModal = ref(false);
const openChatWindow = ref(false);
const chatData = ref(null);

const formatTime = (timestamp: number) => {
  return moment(timestamp * 1000).format("YYYY-MM-DD HH:mm");
};

// 状态文本
const getStatusText = (status: number): string => {
  const statusMap: Record<number, string> = {
    0: '已开启',
    1: '已关闭',
  };
  return statusMap[status] || '未知';
};

// 状态样式
const getStatusClass = (status: number): string => {
  const classMap: Record<number, string> = {
    0: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    1: 'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400',
  };
  return classMap[status] || 'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400';
};

// 回复状态文本
const getReplyStatusText = (replyStatus: number): string => {
  const statusMap: Record<number, string> = {
    0: '已回复',
    1: '待回复',
  };
  return statusMap[replyStatus] || '未知';
};

// 回复状态样式
const getReplyStatusClass = (replyStatus: number): string => {
  const classMap: Record<number, string> = {
    0: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    1: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  };
  return classMap[replyStatus] || 'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400';
};

// 级别文本
const getLevelText = (level: number): string => {
  const levelMap: Record<number, string> = {
    0: '低',
    1: '中',
    2: '高',
  };
  return levelMap[level] || '普通';
};

const close = (id: number) => {
  closeTicket(id).then(() => {
    message.success("关闭工单成功");
    update();
  });
};

const handleChat = (id: number) => {
  fetchTicketDetail(id).then((res: any) => {
    chatData.value = res;
    openChatWindow.value = true;
  });
};

const update = () => {
  loading.value = true;
  fetchTicketList().then((res: any) => {
    tickets.value = res.data;
  }).finally(() => {
    loading.value = false;
  });
};

onMounted(() => {
  update();
});
</script>

<style scoped>
</style>
