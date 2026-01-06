<script setup lang="ts">
import { useRoute, useRouter } from "vue-router";
import { computed, ref, onMounted } from "vue";
import { useUserStore } from "@/stores/User.js";
import { useInfoStore } from "@/stores/counter.js";
import { message } from 'ant-design-vue';
import md5 from 'md5';
import { getTelegramBotInfo } from '@/api/User.js';
import { fetchOrderList } from '@/api/orderlist.js';
import { fetchTicketList } from '@/api/ticket.js';
import Plan from '@/utils/Plan.js';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

// Lucide Icons
import {
  Home,
  Download,
  ShoppingCart,
  User,
  Users,
  Menu,
  X,
  Bookmark,
  Ticket,
  Lock,
  LogOut,
  ChevronDown,
  FileText,
  Send,
  Bell,
  CheckCircle,
  Copy,
  Clock,
  XCircle,
  RefreshCw,
  ChevronRight,
  MessageSquare,
  AlertCircle,
} from 'lucide-vue-next';

const route = useRoute();
const router = useRouter();
const user = useUserStore();
const infoStore = useInfoStore();

// 移动端菜单展开状态
const mobileMenuOpen = ref(false);
// 收藏弹窗状态
const bookmarkModalOpen = ref(false);
// 通知详情弹窗
const noticeDetailOpen = ref(false);
const currentNotice = ref<{ title: string; content: string } | null>(null);
// 头像加载错误
const avatarLoadError = ref(false);

// Telegram 绑定相关
const telegramBotUsername = ref('');
const telegramBound = computed(() => !!user.Info?.telegram_id);
const isTelegramEnabled = ref(false);
const telegramModalVisible = ref(false);

// 订单历史弹窗
const orderModalVisible = ref(false);
const orderList = ref<any[]>([]);
const orderLoading = ref(false);

// 工单弹窗
const ticketModalVisible = ref(false);
const ticketList = ref<any[]>([]);
const ticketLoading = ref(false);

// 是否已登录
const isLoggedIn = computed(() => infoStore.Token !== undefined);

// 用户邮箱
const userEmail = computed(() => user.Subscribe?.email || user.Info?.email || '');

// 订阅地址
const subscribeUrl = computed(() => user.Subscribe?.subscribe_url || '');

// Gravatar URL
const gravatarUrl = computed(() => {
  const email = userEmail.value;
  if (!email) return '';
  const hash = md5(email.toLowerCase().trim());
  return `https://cravatar.cn/avatar/${hash}?d=404&s=80`;
});

const handleAvatarError = () => {
  avatarLoadError.value = true;
};

// 修改密码
const openChangepass = () => {
  router.push('/profile');
  // 延迟触发修改密码弹窗
  setTimeout(() => {
    window.dispatchEvent(new CustomEvent('open-changepass'));
  }, 300);
};

// 退出登录
const logout = () => {
  infoStore.Token = undefined;
  user.Subscribe = undefined;
  user.Info = undefined;
  router.push('/login');
  message.success('已退出登录');
};

const iconMap: Record<string, any> = {
  'Home': Home,
  'Download': Download,
  'Store': ShoppingCart,
  'Shop': ShoppingCart,
  'Profile': User,
  'Invite': Users,
};

const defaultMenus = [
  { id: 'Home', name: '首页', path: '/home' },
  { id: 'Download', name: '下载', path: '/download' },
  { id: 'Store', name: '购买', path: '/store' },
  { id: 'Shop', name: '商店', path: '/shop' },
  { id: 'Profile', name: '我的账号', path: '/profile' },
  { id: 'Invite', name: '邀请', path: '/invite' }
];

const cpData = computed(() => {
  const { title, logo, navMenus, navNotice, navExchange } = window.config;
  const state = useInfoStore().Token === undefined;
  const navList = defaultMenus.map(item => {
    return {
      id: item.id,
      name: navMenus[item.id] || item.name,
      path: item.path,
      icon: iconMap[item.id] || Home
    };
  }).filter(item => {
    // 未登录时隐藏 Store
    if (state) {
      return item.id !== 'Store';
    } else {
      return item.id !== 'Shop';
    }
  });

  const noticeList = user.Notice && user.Notice.data ? user.Notice.data : [];

  if (navMenus.displayInvite === false) {
    const inviteIndex = navList.findIndex(item => item.id === 'Invite');
    if (inviteIndex !== -1) {
      navList.splice(inviteIndex, 1);
    }
  }

  return {
    title: title || 'AirBus',
    logo: logo || 'img/localized/logo-fallback.png',
    navList,
    navNotice: navNotice?.displayName || '通知',
    navExchange: navExchange?.displayName || '兑换',
    noticeList,
  };
});

const showBookmarkModal = () => {
  bookmarkModalOpen.value = true;
};

const displayNotice = (notice: { id: string; title: string; content: string }) => {
  currentNotice.value = notice;
  noticeDetailOpen.value = true;
};

const displayExchange = () => {
  if (useInfoStore().Token === undefined) {
    return message.error('请先登录');
  }
  user.ExchangeModal = true;
};

const reloadHome = () => {
  window.location.href = '/';
};

// ============ Telegram 绑定相关方法 ============
const openTelegramModal = () => {
  if (!telegramBotUsername.value) {
    message.error('Telegram 功能未启用');
    return;
  }
  telegramModalVisible.value = true;
};

const openTelegramBot = () => {
  window.open(`https://t.me/${telegramBotUsername.value}`, '_blank');
};

const copyBindCommand = async () => {
  const command = `/bind ${subscribeUrl.value}`;
  try {
    await navigator.clipboard.writeText(command);
    message.success('绑定命令已复制');
  } catch {
    message.error('复制失败，请手动复制');
  }
};

const loadTelegramBotInfo = async () => {
  try {
    const res = await getTelegramBotInfo();
    if (res.data?.username) {
      telegramBotUsername.value = res.data.username;
      isTelegramEnabled.value = true;
    }
  } catch {
    // Telegram 未启用，忽略错误
    isTelegramEnabled.value = false;
  }
};

// ============ 订单历史相关方法 ============
const openOrderModal = async () => {
  orderModalVisible.value = true;
  orderLoading.value = true;
  try {
    const res = await fetchOrderList();
    // 最多显示10条
    orderList.value = (res.data || []).slice(0, 10);
  } catch {
    orderList.value = [];
    message.error('获取订单列表失败');
  } finally {
    orderLoading.value = false;
  }
};

const getOrderStatusInfo = (status: number) => {
  switch (status) {
    case 0: return { text: '待支付', color: 'amber', icon: Clock };
    case 1: return { text: '开通中', color: 'blue', icon: RefreshCw };
    case 2: return { text: '已取消', color: 'zinc', icon: XCircle };
    case 3: return { text: '已完成', color: 'green', icon: CheckCircle };
    case -1: return { text: '已取消', color: 'red', icon: XCircle };
    default: return { text: '未知', color: 'zinc', icon: FileText };
  }
};

const formatOrderTime = (timestamp: number) => {
  const date = new Date(timestamp * 1000);
  return date.toLocaleDateString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
};

// ============ 工单相关方法 ============
const openTicketModal = async () => {
  ticketModalVisible.value = true;
  ticketLoading.value = true;
  try {
    const res = await fetchTicketList();
    // 最多显示10条
    ticketList.value = (res.data || []).slice(0, 10);
  } catch {
    ticketList.value = [];
    message.error('获取工单列表失败');
  } finally {
    ticketLoading.value = false;
  }
};

const getTicketStatusInfo = (status: number) => {
  switch (status) {
    case 0: return { text: '已开启', color: 'blue', icon: MessageSquare };
    case 1: return { text: '已回复', color: 'green', icon: CheckCircle };
    case 2: return { text: '已关闭', color: 'zinc', icon: XCircle };
    default: return { text: '未知', color: 'zinc', icon: AlertCircle };
  }
};

const formatTicketTime = (timestamp: number) => {
  const date = new Date(timestamp * 1000);
  return date.toLocaleDateString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
};

// 页面加载时获取 Telegram Bot 信息
onMounted(() => {
  if (isLoggedIn.value) {
    loadTelegramBotInfo();
  }
});
</script>

<template>
  <header class="fixed top-0 left-0 z-[10000] w-full border-b border-zinc-200/80 dark:border-zinc-800/80 bg-white/90 dark:bg-zinc-900/90 backdrop-blur-xl">
    <div class="flex items-center justify-between w-full h-[72px] max-w-6xl mx-auto px-4 sm:px-6">
      <!-- 左侧: Logo -->
      <div class="flex items-center gap-3">
        <!-- 移动端菜单按钮 -->
        <button
          @click="mobileMenuOpen = !mobileMenuOpen"
          class="lg:hidden w-10 h-10 flex items-center justify-center rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
        >
          <Menu v-if="!mobileMenuOpen" class="w-5 h-5 text-zinc-600 dark:text-zinc-400" />
          <X v-else class="w-5 h-5 text-zinc-600 dark:text-zinc-400" />
        </button>

        <!-- Logo 和标题 -->
        <div class="flex items-center gap-2.5 cursor-pointer" @click="reloadHome">
          <img :src="cpData.logo" alt="LOGO" class="h-9 w-auto" />
          <span class="text-xl font-bold text-zinc-900 dark:text-zinc-100 font-['Fredoka_One',ui-sans-serif,system-ui,sans-serif]">
            {{ cpData.title }}
          </span>
        </div>
      </div>

      <!-- 中间: 桌面端导航菜单 -->
      <nav class="hidden lg:flex items-center gap-1">
        <router-link
          v-for="item in cpData.navList"
          :key="item.id"
          :to="item.path"
          class="flex items-center gap-2 px-4 py-2.5 text-base font-medium rounded-lg transition-all duration-200"
          :class="route.name === item.id
            ? 'text-primary bg-primary/10'
            : 'text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-100 dark:hover:bg-zinc-800'"
        >
          <component :is="item.icon" class="w-5 h-5" />
          <span>{{ item.name }}</span>
        </router-link>
      </nav>

      <!-- 右侧: 用户头像 -->
      <div class="flex items-center gap-3">
        <span v-if="isLoggedIn && userEmail" class="hidden sm:block text-sm font-medium text-zinc-600 dark:text-zinc-400">
          Halo, {{ userEmail }}
        </span>
        <DropdownMenu v-if="isLoggedIn">
          <DropdownMenuTrigger as-child>
            <button class="flex items-center gap-2 p-1 rounded-full hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors">
              <div class="rounded-full h-9 w-9 overflow-hidden border-2 border-zinc-200 dark:border-zinc-700">
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
              </div>
              <ChevronDown class="w-4 h-4 text-zinc-400 hidden sm:block" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="w-48 z-[10001]">
            <div v-if="userEmail" class="sm:hidden px-2 py-1.5 text-xs text-zinc-500 dark:text-zinc-400 border-b border-zinc-100 dark:border-zinc-800 mb-1 break-all">
              Halo, {{ userEmail }}
            </div>
            <DropdownMenuItem @click="openOrderModal" class="cursor-pointer">
              <FileText class="w-4 h-4 mr-2" />
              订单历史
            </DropdownMenuItem>
            <DropdownMenuItem v-if="isTelegramEnabled" @click="openTelegramModal" class="cursor-pointer">
              <Send class="w-4 h-4 mr-2" />
              {{ telegramBound ? 'Telegram 已绑定' : '绑定 Telegram' }}
            </DropdownMenuItem>
            <DropdownMenuItem @click="openChangepass" class="cursor-pointer">
              <Lock class="w-4 h-4 mr-2" />
              修改密码
            </DropdownMenuItem>
            <DropdownMenuItem @click="logout" class="text-red-600 focus:text-red-600 focus:bg-red-50 dark:focus:bg-red-950/30 cursor-pointer">
              <LogOut class="w-4 h-4 mr-2" />
              退出登录
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>

    <!-- 移动端导航菜单 -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 -translate-y-2"
    >
      <div
        v-if="mobileMenuOpen"
        class="lg:hidden border-t border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900"
      >
        <nav class="py-2 px-2">
          <router-link
            v-for="item in cpData.navList"
            :key="item.id"
            :to="item.path"
            @click="mobileMenuOpen = false"
            class="flex items-center gap-3 px-4 py-3 text-base font-medium rounded-xl transition-all duration-200"
            :class="route.name === item.id
              ? 'text-primary bg-primary/10'
              : 'text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800'"
          >
            <component :is="item.icon" class="w-5 h-5" />
            <span>{{ item.name }}</span>
          </router-link>
        </nav>
      </div>
    </Transition>
  </header>

  <!-- 收藏提示弹窗 -->
  <Dialog v-model:open="bookmarkModalOpen">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <div class="flex justify-center mb-4">
          <div class="w-16 h-16 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
            <Bookmark class="w-8 h-8 text-amber-600 dark:text-amber-400" />
          </div>
        </div>
        <DialogTitle class="text-center">收藏防失联网址</DialogTitle>
        <DialogDescription class="text-center">
          请将防失联地址加入到浏览器收藏夹中
        </DialogDescription>
      </DialogHeader>

      <div class="bg-zinc-100 dark:bg-zinc-800 rounded-xl p-4 my-4">
        <p class="text-sm text-zinc-600 dark:text-zinc-400 mb-2">访问以下地址，系统会自动为您选择最佳访问路径：</p>
        <p class="text-base font-mono font-medium text-primary break-all">
          https://lray.dlgisea.com
        </p>
      </div>

      <Button @click="bookmarkModalOpen = false" class="w-full">
        知道了
      </Button>
    </DialogContent>
  </Dialog>

  <!-- 通知详情弹窗 -->
  <Dialog v-model:open="noticeDetailOpen">
    <DialogContent class="sm:max-w-lg">
      <DialogHeader>
        <DialogTitle>{{ currentNotice?.title }}</DialogTitle>
      </DialogHeader>
      <div class="prose prose-zinc dark:prose-invert max-w-none text-sm text-zinc-600 dark:text-zinc-400" v-html="currentNotice?.content"></div>
      <Button @click="noticeDetailOpen = false" class="w-full mt-4">
        我知道了
      </Button>
    </DialogContent>
  </Dialog>

  <!-- Telegram 绑定弹窗 -->
  <Dialog v-model:open="telegramModalVisible">
    <DialogContent class="sm:max-w-sm">
      <DialogHeader>
        <div class="flex justify-center mb-2">
          <div class="relative">
            <div class="w-16 h-16 rounded-full bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg">
              <Send class="w-8 h-8 text-white" />
            </div>
          </div>
        </div>
        <DialogTitle class="text-center">
          {{ telegramBound ? 'Telegram Bot 已绑定' : '绑定 Telegram Bot' }}
        </DialogTitle>
        <DialogDescription v-if="!telegramBound" class="text-center">
          绑定您的账号到 Telegram Bot
        </DialogDescription>
      </DialogHeader>

      <div v-if="!telegramBound" class="space-y-4 py-4">
        <!-- 功能说明 -->
        <div class="space-y-2 text-sm text-zinc-600 dark:text-zinc-400">
          <div class="flex items-center gap-2">
            <Bell class="w-3.5 h-3.5 text-blue-500" />
            <span>接收到期提醒和重要通知</span>
          </div>
          <div class="flex items-center gap-2">
            <CheckCircle class="w-4 h-4 text-green-500" />
            <span>快速查询账户和订阅信息</span>
          </div>
        </div>

        <!-- 绑定步骤 -->
        <div class="space-y-3">
          <div class="flex items-start gap-3">
            <div class="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0 mt-0.5">
              <span class="text-xs font-bold text-blue-600 dark:text-blue-400">1</span>
            </div>
            <div>
              <p class="text-sm font-medium text-zinc-900 dark:text-zinc-100">打开 Telegram Bot</p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-0.5">点击下方按钮打开我们的 Bot</p>
            </div>
          </div>
          <div class="flex items-start gap-3">
            <div class="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0 mt-0.5">
              <span class="text-xs font-bold text-blue-600 dark:text-blue-400">2</span>
            </div>
            <div>
              <p class="text-sm font-medium text-zinc-900 dark:text-zinc-100">发送绑定命令</p>
              <button
                @click="copyBindCommand"
                class="mt-1 flex items-center gap-1.5 px-2.5 py-1.5 bg-zinc-100 dark:bg-zinc-800 rounded-lg text-xs font-mono text-zinc-700 dark:text-zinc-300 hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
              >
                <Copy class="w-3 h-3" />
                /bind {{ subscribeUrl.substring(0, 30) }}...
              </button>
            </div>
          </div>
        </div>

        <!-- Bot 用户名 -->
        <div class="text-center text-xs text-zinc-400">
          Bot: @{{ telegramBotUsername }}
        </div>
      </div>

      <div v-else class="py-6">
        <div class="flex items-center justify-center gap-2 text-green-600 dark:text-green-400">
          <CheckCircle class="w-5 h-5" />
          <span class="font-medium">绑定成功</span>
        </div>
        <p class="text-center text-sm text-zinc-500 dark:text-zinc-400 mt-2">
          您将通过 Telegram Bot 接收通知
        </p>
      </div>

      <div class="flex gap-3">
        <Button variant="outline" class="flex-1" @click="telegramModalVisible = false">
          {{ telegramBound ? '关闭' : '取消' }}
        </Button>
        <Button v-if="!telegramBound" class="flex-1" @click="openTelegramBot">
          <Send class="w-4 h-4 mr-1.5" />
          打开 Telegram
        </Button>
      </div>
    </DialogContent>
  </Dialog>

  <!-- 订单历史弹窗 -->
  <Dialog v-model:open="orderModalVisible">
    <DialogContent class="sm:max-w-lg max-h-[80vh] flex flex-col">
      <DialogHeader>
        <DialogTitle>订单历史</DialogTitle>
        <DialogDescription>最近10条订单记录</DialogDescription>
      </DialogHeader>

      <div class="flex-1 overflow-y-auto -mx-6 px-6">
        <!-- 加载中 -->
        <div v-if="orderLoading" class="flex items-center justify-center py-12">
          <RefreshCw class="w-6 h-6 text-blue-500 animate-spin" />
        </div>

        <!-- 空状态 -->
        <div v-else-if="orderList.length === 0" class="flex flex-col items-center justify-center py-12">
          <FileText class="w-12 h-12 text-zinc-200 dark:text-zinc-700 mb-3" />
          <p class="text-sm text-zinc-500 dark:text-zinc-400">暂无订单记录</p>
        </div>

        <!-- 订单列表 -->
        <div v-else class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <div
            v-for="order in orderList"
            :key="order.trade_no"
            @click="router.push(`/order/${order.trade_no}`); orderModalVisible = false"
            class="flex items-center justify-between gap-3 py-3 cursor-pointer hover:bg-zinc-50 dark:hover:bg-zinc-800/50 -mx-2 px-2 rounded-lg transition-colors"
          >
            <div class="flex items-center gap-3 min-w-0 flex-1">
              <!-- 状态图标 -->
              <div
                class="w-9 h-9 rounded-full flex items-center justify-center shrink-0"
                :class="{
                  'bg-amber-100 dark:bg-amber-900/30': getOrderStatusInfo(order.status).color === 'amber',
                  'bg-green-100 dark:bg-green-900/30': getOrderStatusInfo(order.status).color === 'green',
                  'bg-red-100 dark:bg-red-900/30': getOrderStatusInfo(order.status).color === 'red',
                  'bg-blue-100 dark:bg-blue-900/30': getOrderStatusInfo(order.status).color === 'blue',
                  'bg-zinc-100 dark:bg-zinc-800': getOrderStatusInfo(order.status).color === 'zinc',
                }"
              >
                <component
                  :is="getOrderStatusInfo(order.status).icon"
                  class="w-4 h-4"
                  :class="{
                    'text-amber-600 dark:text-amber-400': getOrderStatusInfo(order.status).color === 'amber',
                    'text-green-600 dark:text-green-400': getOrderStatusInfo(order.status).color === 'green',
                    'text-red-600 dark:text-red-400': getOrderStatusInfo(order.status).color === 'red',
                    'text-blue-600 dark:text-blue-400': getOrderStatusInfo(order.status).color === 'blue',
                    'text-zinc-600 dark:text-zinc-400': getOrderStatusInfo(order.status).color === 'zinc',
                  }"
                />
              </div>

              <!-- 订单信息 -->
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
                    {{ order.period === 'recharge' ? '余额充值' : (order.plan?.name || '未知套餐') }}
                  </span>
                  <span
                    class="px-1.5 py-0.5 text-xs font-medium rounded shrink-0"
                    :class="{
                      'bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400': getOrderStatusInfo(order.status).color === 'amber',
                      'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400': getOrderStatusInfo(order.status).color === 'green',
                      'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400': getOrderStatusInfo(order.status).color === 'red',
                      'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400': getOrderStatusInfo(order.status).color === 'blue',
                      'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400': getOrderStatusInfo(order.status).color === 'zinc',
                    }"
                  >
                    {{ getOrderStatusInfo(order.status).text }}
                  </span>
                </div>
                <div class="flex items-center gap-2 mt-0.5 text-xs text-zinc-400">
                  <span>{{ formatOrderTime(order.created_at) }}</span>
                  <span v-if="order.period !== 'recharge'">·</span>
                  <span v-if="order.period !== 'recharge'">{{ Plan.Handle_name(order.period) }}</span>
                </div>
              </div>
            </div>

            <!-- 金额和箭头 -->
            <div class="flex items-center gap-2 shrink-0">
              <span class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                ¥{{ ((order.total_amount || 0) / 100).toFixed(2) }}
              </span>
              <ChevronRight class="w-4 h-4 text-zinc-300 dark:text-zinc-600" />
            </div>
          </div>
        </div>
      </div>

      <div class="pt-4 border-t border-zinc-100 dark:border-zinc-800 mt-4">
        <Button variant="outline" class="w-full" @click="orderModalVisible = false">
          关闭
        </Button>
      </div>
    </DialogContent>
  </Dialog>

  <!-- 工单弹窗 -->
  <Dialog v-model:open="ticketModalVisible">
    <DialogContent class="sm:max-w-lg max-h-[80vh] flex flex-col">
      <DialogHeader>
        <DialogTitle>我的工单</DialogTitle>
        <DialogDescription>最近10条工单记录</DialogDescription>
      </DialogHeader>

      <div class="flex-1 overflow-y-auto -mx-6 px-6">
        <!-- 加载中 -->
        <div v-if="ticketLoading" class="flex items-center justify-center py-12">
          <RefreshCw class="w-6 h-6 text-blue-500 animate-spin" />
        </div>

        <!-- 空状态 -->
        <div v-else-if="ticketList.length === 0" class="flex flex-col items-center justify-center py-12">
          <Ticket class="w-12 h-12 text-zinc-200 dark:text-zinc-700 mb-3" />
          <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-4">暂无工单记录</p>
          <Button size="sm" @click="router.push('/ticket'); ticketModalVisible = false">
            提交工单
          </Button>
        </div>

        <!-- 工单列表 -->
        <div v-else class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <div
            v-for="ticket in ticketList"
            :key="ticket.id"
            @click="router.push('/ticket'); ticketModalVisible = false"
            class="flex items-center justify-between gap-3 py-3 cursor-pointer hover:bg-zinc-50 dark:hover:bg-zinc-800/50 -mx-2 px-2 rounded-lg transition-colors"
          >
            <div class="flex items-center gap-3 min-w-0 flex-1">
              <!-- 状态图标 -->
              <div
                class="w-9 h-9 rounded-full flex items-center justify-center shrink-0"
                :class="{
                  'bg-blue-100 dark:bg-blue-900/30': getTicketStatusInfo(ticket.status).color === 'blue',
                  'bg-green-100 dark:bg-green-900/30': getTicketStatusInfo(ticket.status).color === 'green',
                  'bg-zinc-100 dark:bg-zinc-800': getTicketStatusInfo(ticket.status).color === 'zinc',
                }"
              >
                <component
                  :is="getTicketStatusInfo(ticket.status).icon"
                  class="w-4 h-4"
                  :class="{
                    'text-blue-600 dark:text-blue-400': getTicketStatusInfo(ticket.status).color === 'blue',
                    'text-green-600 dark:text-green-400': getTicketStatusInfo(ticket.status).color === 'green',
                    'text-zinc-600 dark:text-zinc-400': getTicketStatusInfo(ticket.status).color === 'zinc',
                  }"
                />
              </div>

              <!-- 工单信息 -->
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
                    {{ ticket.subject || '无主题' }}
                  </span>
                  <span
                    class="px-1.5 py-0.5 text-xs font-medium rounded shrink-0"
                    :class="{
                      'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400': getTicketStatusInfo(ticket.status).color === 'blue',
                      'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400': getTicketStatusInfo(ticket.status).color === 'green',
                      'bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400': getTicketStatusInfo(ticket.status).color === 'zinc',
                    }"
                  >
                    {{ getTicketStatusInfo(ticket.status).text }}
                  </span>
                </div>
                <div class="text-xs text-zinc-400 mt-0.5">
                  {{ formatTicketTime(ticket.updated_at || ticket.created_at) }}
                </div>
              </div>
            </div>

            <ChevronRight class="w-4 h-4 text-zinc-300 dark:text-zinc-600 shrink-0" />
          </div>
        </div>
      </div>

      <div class="pt-4 border-t border-zinc-100 dark:border-zinc-800 mt-4 flex gap-3">
        <Button variant="outline" class="flex-1" @click="ticketModalVisible = false">
          关闭
        </Button>
        <Button class="flex-1" @click="router.push('/ticket'); ticketModalVisible = false">
          提交工单
        </Button>
      </div>
    </DialogContent>
  </Dialog>
</template>

<style scoped>
</style>
