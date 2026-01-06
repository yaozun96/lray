<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, watch } from 'vue';
import ServerNode from '@/views/News/ServerNode.vue';
import { useUserStore } from '@/stores/User.js';
import { useInfoStore } from '@/stores/counter.js';
import { trafficConvertUnit } from '@/utils/traffic.js';
import { message } from 'ant-design-vue';
import { useRouter } from 'vue-router';
import { resetSubscribeLink, getUserInfo, createRechargeOrder, getRechargeBonusConfig, getTelegramBotInfo } from '@/api/User.js';
import { getInviteData } from '@/api/invite.js';
import { fetchTicketList } from '@/api/ticket.js';
import { cancelOrder } from '@/api/orderlist.js';
import QRCode from 'qrcode';
import moment from 'moment';
import { submitOrder, verifyCoupon } from '@/api/shop.js';
import confetti from 'canvas-confetti';

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
import { Separator } from '@/components/ui/separator';

// Lucide Icons
import {
  RefreshCw,
  QrCode,
  Lock,
  LogOut,
  Check,
  ChevronRight,
  Wallet,
  Ticket,
  BarChart3,
  RotateCcw,
  Download,
  Copy,
  Crown,
  User,
  ShoppingBag,
  CreditCard,
  X,
  Gift,
  ArrowRight,
  ArrowRightLeft,
  Zap,
  Rocket,
  Plus,
  Send,
  MessageSquare,
  CheckCircle,
  XCircle,
  AlertCircle,
  Clock,
  Banknote,
  Loader2,
  TriangleAlert,
  Package,
} from 'lucide-vue-next';

// ============ 状态定义 ============
const user = useUserStore();
const Token = useInfoStore();
const router = useRouter();
const balance = ref(0);
// 响应式判断是否为小屏幕 (与 Tailwind sm 断点一致: 640px)
const isMobile = ref(window.innerWidth < 640);
const updateIsMobile = () => {
  isMobile.value = window.innerWidth < 640;
};

// 弹窗状态
const importModalVisible = ref(false);
const qrcodeUrl = ref('');
const renewModalVisible = ref(false);
const resetModalVisible = ref(false);
const welcomeModalVisible = ref(false);

// 续费相关
const selectedRenewPeriod = ref('');
const availablePeriods = ref<Array<{key: string, label: string, price: number}>>([]);
const confirmRenewLoading = ref(false);

// 续费优惠码
const renewCouponCode = ref('');
const renewCouponData = ref<{
  status: boolean;
  type: number;
  value: number;
  name: string;
}>({ status: false, type: 0, value: 0, name: '' });
const renewCouponValidating = ref(false);

// 流量包相关
const trafficPackModalVisible = ref(false);
const trafficPackPrice = ref<number | null>(null);
const trafficPackLoading = ref(false);

// 动态加载组件
const openTicketModal = ref(false);
const TicketComponent = ref(null);
const openPassModal = ref(false);
const ChangepassComponent = ref(null);
const openTrafficLogModal = ref(false);
const TrafficLogComponent = ref(null);

// 邀请数据
const invite = ref({ codes: undefined, stat: undefined });

// 工单数据
const tickets = ref<any[]>([]);
const ticketModalVisible = ref(false);
const ticketLoading = ref(false);

// 未支付订单
const unpaidOrder = ref<{
  trade_no: string;
  plan_name: string;
  is_recharge: boolean;
  total_amount: number;
  created_at: number;
} | null>(null);
const cancelOrderLoading = ref(false);

// 取消未支付订单
const handleCancelOrder = async () => {
  if (!unpaidOrder.value) return;
  cancelOrderLoading.value = true;
  try {
    await cancelOrder(unpaidOrder.value.trade_no);
    message.success('订单已取消');
    unpaidOrder.value = null;
  } catch (error) {
    message.error('取消订单失败');
  } finally {
    cancelOrderLoading.value = false;
  }
};

// 充值相关
const rechargeModalVisible = ref(false);
const rechargeAmount = ref('');
const rechargeAmountOptions = [100, 200, 300, 500, 1000, 2000]; // 与奖励档位对应
const rechargeLoading = ref(false);
const rechargeBonus = ref(0); // 当前选择金额对应的奖励
const rechargeTotal = ref(0); // 实际到账金额
const bonusConfig = ref<Array<{threshold: number, bonus: number, threshold_yuan: number, bonus_yuan: number}>>([]);

// 返佣比例
const commissionRate = computed(() => invite.value.stat?.[3] || 20);

// Telegram 绑定相关
const telegramBotUsername = ref('');
const telegramBound = computed(() => !!user.Info?.telegram_id);
const isTelegramEnabled = ref(false);
const telegramModalVisible = ref(false);

// 用户邮箱
const userEmail = computed(() => user.Subscribe?.email || user.Info?.email || '');

// Gravatar 头像 URL - 使用 d=404 让没有头像时返回404，这样可以显示自定义默认头像
const gravatarUrl = computed(() => {
  const email = userEmail.value.trim().toLowerCase();
  if (!email) return '';
  const hash = md5(email);
  return `https://www.gravatar.com/avatar/${hash}?s=80&d=404`;
});

// 头像加载失败时的状态
const avatarLoadError = ref(false);

// 头像加载失败处理
const handleAvatarError = () => {
  avatarLoadError.value = true;
};

// 简单的 MD5 实现（用于 Gravatar）
function md5(string: string): string {
  function rotateLeft(value: number, shift: number) {
    return (value << shift) | (value >>> (32 - shift));
  }
  function addUnsigned(x: number, y: number) {
    const x4 = x & 0x80000000;
    const y4 = y & 0x80000000;
    const x8 = x & 0x40000000;
    const y8 = y & 0x40000000;
    const result = (x & 0x3fffffff) + (y & 0x3fffffff);
    if (x8 & y8) return result ^ 0x80000000 ^ x4 ^ y4;
    if (x8 | y8) {
      if (result & 0x40000000) return result ^ 0xc0000000 ^ x4 ^ y4;
      else return result ^ 0x40000000 ^ x4 ^ y4;
    } else return result ^ x4 ^ y4;
  }
  function f(x: number, y: number, z: number) { return (x & y) | (~x & z); }
  function g(x: number, y: number, z: number) { return (x & z) | (y & ~z); }
  function h(x: number, y: number, z: number) { return x ^ y ^ z; }
  function i(x: number, y: number, z: number) { return y ^ (x | ~z); }
  function ff(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    a = addUnsigned(a, addUnsigned(addUnsigned(f(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }
  function gg(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    a = addUnsigned(a, addUnsigned(addUnsigned(g(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }
  function hh(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    a = addUnsigned(a, addUnsigned(addUnsigned(h(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }
  function ii(a: number, b: number, c: number, d: number, x: number, s: number, ac: number) {
    a = addUnsigned(a, addUnsigned(addUnsigned(i(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }
  function convertToWordArray(str: string) {
    let wordCount;
    const msgLength = str.length;
    const tempCount1 = msgLength + 8;
    const tempCount2 = (tempCount1 - (tempCount1 % 64)) / 64;
    const numberOfWords = (tempCount2 + 1) * 16;
    const wordArray = Array(numberOfWords - 1);
    let bytePosition = 0;
    let byteCount = 0;
    while (byteCount < msgLength) {
      wordCount = (byteCount - (byteCount % 4)) / 4;
      bytePosition = (byteCount % 4) * 8;
      wordArray[wordCount] = wordArray[wordCount] | (str.charCodeAt(byteCount) << bytePosition);
      byteCount++;
    }
    wordCount = (byteCount - (byteCount % 4)) / 4;
    bytePosition = (byteCount % 4) * 8;
    wordArray[wordCount] = wordArray[wordCount] | (0x80 << bytePosition);
    wordArray[numberOfWords - 2] = msgLength << 3;
    wordArray[numberOfWords - 1] = msgLength >>> 29;
    return wordArray;
  }
  function wordToHex(value: number) {
    let hex = '', temp = '', byte;
    for (let c = 0; c <= 3; c++) {
      byte = (value >>> (c * 8)) & 255;
      temp = '0' + byte.toString(16);
      hex = hex + temp.substr(temp.length - 2, 2);
    }
    return hex;
  }
  const x = convertToWordArray(string);
  let a = 0x67452301, b = 0xefcdab89, c = 0x98badcfe, d = 0x10325476;
  const S11 = 7, S12 = 12, S13 = 17, S14 = 22;
  const S21 = 5, S22 = 9, S23 = 14, S24 = 20;
  const S31 = 4, S32 = 11, S33 = 16, S34 = 23;
  const S41 = 6, S42 = 10, S43 = 15, S44 = 21;
  for (let k = 0; k < x.length; k += 16) {
    const AA = a, BB = b, CC = c, DD = d;
    a = ff(a, b, c, d, x[k], S11, 0xd76aa478);
    d = ff(d, a, b, c, x[k + 1], S12, 0xe8c7b756);
    c = ff(c, d, a, b, x[k + 2], S13, 0x242070db);
    b = ff(b, c, d, a, x[k + 3], S14, 0xc1bdceee);
    a = ff(a, b, c, d, x[k + 4], S11, 0xf57c0faf);
    d = ff(d, a, b, c, x[k + 5], S12, 0x4787c62a);
    c = ff(c, d, a, b, x[k + 6], S13, 0xa8304613);
    b = ff(b, c, d, a, x[k + 7], S14, 0xfd469501);
    a = ff(a, b, c, d, x[k + 8], S11, 0x698098d8);
    d = ff(d, a, b, c, x[k + 9], S12, 0x8b44f7af);
    c = ff(c, d, a, b, x[k + 10], S13, 0xffff5bb1);
    b = ff(b, c, d, a, x[k + 11], S14, 0x895cd7be);
    a = ff(a, b, c, d, x[k + 12], S11, 0x6b901122);
    d = ff(d, a, b, c, x[k + 13], S12, 0xfd987193);
    c = ff(c, d, a, b, x[k + 14], S13, 0xa679438e);
    b = ff(b, c, d, a, x[k + 15], S14, 0x49b40821);
    a = gg(a, b, c, d, x[k + 1], S21, 0xf61e2562);
    d = gg(d, a, b, c, x[k + 6], S22, 0xc040b340);
    c = gg(c, d, a, b, x[k + 11], S23, 0x265e5a51);
    b = gg(b, c, d, a, x[k], S24, 0xe9b6c7aa);
    a = gg(a, b, c, d, x[k + 5], S21, 0xd62f105d);
    d = gg(d, a, b, c, x[k + 10], S22, 0x2441453);
    c = gg(c, d, a, b, x[k + 15], S23, 0xd8a1e681);
    b = gg(b, c, d, a, x[k + 4], S24, 0xe7d3fbc8);
    a = gg(a, b, c, d, x[k + 9], S21, 0x21e1cde6);
    d = gg(d, a, b, c, x[k + 14], S22, 0xc33707d6);
    c = gg(c, d, a, b, x[k + 3], S23, 0xf4d50d87);
    b = gg(b, c, d, a, x[k + 8], S24, 0x455a14ed);
    a = gg(a, b, c, d, x[k + 13], S21, 0xa9e3e905);
    d = gg(d, a, b, c, x[k + 2], S22, 0xfcefa3f8);
    c = gg(c, d, a, b, x[k + 7], S23, 0x676f02d9);
    b = gg(b, c, d, a, x[k + 12], S24, 0x8d2a4c8a);
    a = hh(a, b, c, d, x[k + 5], S31, 0xfffa3942);
    d = hh(d, a, b, c, x[k + 8], S32, 0x8771f681);
    c = hh(c, d, a, b, x[k + 11], S33, 0x6d9d6122);
    b = hh(b, c, d, a, x[k + 14], S34, 0xfde5380c);
    a = hh(a, b, c, d, x[k + 1], S31, 0xa4beea44);
    d = hh(d, a, b, c, x[k + 4], S32, 0x4bdecfa9);
    c = hh(c, d, a, b, x[k + 7], S33, 0xf6bb4b60);
    b = hh(b, c, d, a, x[k + 10], S34, 0xbebfbc70);
    a = hh(a, b, c, d, x[k + 13], S31, 0x289b7ec6);
    d = hh(d, a, b, c, x[k], S32, 0xeaa127fa);
    c = hh(c, d, a, b, x[k + 3], S33, 0xd4ef3085);
    b = hh(b, c, d, a, x[k + 6], S34, 0x4881d05);
    a = hh(a, b, c, d, x[k + 9], S31, 0xd9d4d039);
    d = hh(d, a, b, c, x[k + 12], S32, 0xe6db99e5);
    c = hh(c, d, a, b, x[k + 15], S33, 0x1fa27cf8);
    b = hh(b, c, d, a, x[k + 2], S34, 0xc4ac5665);
    a = ii(a, b, c, d, x[k], S41, 0xf4292244);
    d = ii(d, a, b, c, x[k + 7], S42, 0x432aff97);
    c = ii(c, d, a, b, x[k + 14], S43, 0xab9423a7);
    b = ii(b, c, d, a, x[k + 5], S44, 0xfc93a039);
    a = ii(a, b, c, d, x[k + 12], S41, 0x655b59c3);
    d = ii(d, a, b, c, x[k + 3], S42, 0x8f0ccc92);
    c = ii(c, d, a, b, x[k + 10], S43, 0xffeff47d);
    b = ii(b, c, d, a, x[k + 1], S44, 0x85845dd1);
    a = ii(a, b, c, d, x[k + 8], S41, 0x6fa87e4f);
    d = ii(d, a, b, c, x[k + 15], S42, 0xfe2ce6e0);
    c = ii(c, d, a, b, x[k + 6], S43, 0xa3014314);
    b = ii(b, c, d, a, x[k + 13], S44, 0x4e0811a1);
    a = ii(a, b, c, d, x[k + 4], S41, 0xf7537e82);
    d = ii(d, a, b, c, x[k + 11], S42, 0xbd3af235);
    c = ii(c, d, a, b, x[k + 2], S43, 0x2ad7d2bb);
    b = ii(b, c, d, a, x[k + 9], S44, 0xeb86d391);
    a = addUnsigned(a, AA);
    b = addUnsigned(b, BB);
    c = addUnsigned(c, CC);
    d = addUnsigned(d, DD);
  }
  return (wordToHex(a) + wordToHex(b) + wordToHex(c) + wordToHex(d)).toLowerCase();
}

// ============ 计算属性 ============
const subscribeUrl = computed(() => user.Subscribe?.subscribe_url || '');
const backupSubscribeOrigin = window.config.backupSubscribeOrigin;
const useBackupSubscribe = ref(false);

const modalSubscribeUrl = computed(() => {
  const url = subscribeUrl.value;
  if (!url) return '';
  if (!useBackupSubscribe.value) return url;
  try {
    const originUrl = new URL(url);
    const backupUrl = new URL(backupSubscribeOrigin);
    return `${backupUrl.origin}${originUrl.pathname}${originUrl.search}`;
  } catch {
    return useBackupSubscribe.value ? backupSubscribeOrigin : url;
  }
});
const subscribeName = computed(() => user.Subscribe?.plan?.name || 'Lray');

const greetingText = computed(() => {
  const email = user.Subscribe?.email || user.Info?.email || '';
  return email || '欢迎使用';
});

const planName = computed(() => user.Subscribe?.plan?.name || '未订阅');

// 下次流量重置信息
// reset_day 是后端返回的"距离下次重置还有多少天"
const resetDaysRemaining = computed(() => {
  const resetDay = user.Subscribe?.reset_day;
  if (resetDay === null || resetDay === undefined) return null;
  return resetDay;
});

const stats = computed(() => {
  let remainingDays: string | number = 0;
  let usedTraffic = { value: '0', unit: 'GB' };
  let totalTraffic = { value: '0', unit: 'GB' };
  let usedPercent = 0;

  if (user.Subscribe) {
    const expiredTime = user.Subscribe.expired_at;
    if (expiredTime === null || expiredTime === undefined) {
      remainingDays = '永久';
    } else if (expiredTime === 0) {
      remainingDays = 0;
    } else {
      const now = Date.now();
      remainingDays = Math.max(0, Math.floor((expiredTime * 1000 - now) / 1000 / 60 / 60 / 24));
    }

    const total = user.Subscribe.transfer_enable || 0;
    const used = (user.Subscribe.d || 0) + (user.Subscribe.u || 0);
    usedTraffic = trafficConvertUnit(used);
    totalTraffic = trafficConvertUnit(total);
    usedPercent = total > 0 ? Math.min(100, Math.floor((used / total) * 100)) : 0;
  }

  return {
    balance: balance.value,
    remainingDays,
    usedTraffic,
    totalTraffic,
    usedPercent
  };
});

const hasSubscription = computed(() => !!user.Subscribe?.plan && !!user.Subscribe?.plan_id);

// 公告数据
const allNotices = computed(() => user.Notice?.data || []);
const latestNotice = computed(() => allNotices.value[0] || null);
const noticeModalVisible = ref(false);

// ============ 订阅导入配置 ============
interface ImportApp {
  name: string;
  scheme: string;
  platforms: ('desktop' | 'ios' | 'android')[];
  icon: string;
}

const importApps: ImportApp[] = [
  { name: 'Clash', scheme: 'clash://install-config?url={url:component}', platforms: ['desktop', 'android'], icon: '/assets/app-icons/clash.png' },
  { name: 'Surfboard', scheme: 'surfboard:///install-config?url={url:component}', platforms: ['android'], icon: '/assets/app-icons/surfboard.webp' },
  { name: 'Quantumult X', scheme: 'quantumult-x:///update-configuration?remote-resource=%7B%22server_remote%22%3A%5B%22{url:component}%2C%20tag%3D{name:component}%22%5D%7D', platforms: ['ios'], icon: '/assets/app-icons/quantumult-x.png' },
  { name: 'Shadowrocket', scheme: 'shadowrocket://add/sub://{url:base64}?remarks={name:component}', platforms: ['ios'], icon: '/assets/app-icons/shadowrocket.png' },
  { name: 'Surge', scheme: 'surge:///install-config?url={url:component}', platforms: ['desktop', 'ios'], icon: '/assets/app-icons/surge.png' },
  { name: 'Hiddify', scheme: 'hiddify://import/{url}#{name:component}', platforms: ['desktop', 'ios', 'android'], icon: '/assets/app-icons/hiddify.png' },
  { name: 'Sing Box', scheme: 'sing-box://import-remote-profile?url={url:component}#{name:component}', platforms: ['desktop', 'ios', 'android'], icon: '/assets/app-icons/singbox.png' },
];

const currentPlatform = computed<'desktop' | 'ios' | 'android'>(() => {
  const ua = navigator.userAgent.toLowerCase();
  if (/iphone|ipad|ipod/.test(ua)) return 'ios';
  if (/android/.test(ua)) return 'android';
  return 'desktop';
});

const filteredImportApps = computed(() => {
  return importApps.filter(app => app.platforms.includes(currentPlatform.value));
});

// ============ 方法 ============
const generateQRCode = async () => {
  if (modalSubscribeUrl.value) {
    try {
      qrcodeUrl.value = await QRCode.toDataURL(modalSubscribeUrl.value, { width: 200, margin: 2 });
    } catch (err) {
      console.error(err);
    }
  }
};

const openImportModal = () => {
  importModalVisible.value = true;
  generateQRCode();
};

watch(importModalVisible, (visible) => {
  if (visible) {
    generateQRCode();
  }
});

watch(modalSubscribeUrl, () => {
  if (importModalVisible.value) {
    generateQRCode();
  }
});

const getImportLink = (app: ImportApp): string => {
  const url = modalSubscribeUrl.value;
  const name = subscribeName.value;
  let link = app.scheme;
  link = link.replace('{url}', url);
  link = link.replace('{url:component}', encodeURIComponent(url));
  link = link.replace('{url:base64}', btoa(url));
  link = link.replace('{name}', name);
  link = link.replace('{name:component}', encodeURIComponent(name));
  return link;
};

const handleImport = (app: ImportApp) => {
  window.location.href = getImportLink(app);
};

const copySubscribeLink = async () => {
  try {
    await navigator.clipboard.writeText(modalSubscribeUrl.value);
    message.success('订阅链接已复制');
  } catch {
    message.error('复制失败');
  }
};

const resetSubscribe = async () => {
  try {
    await resetSubscribeLink();
    message.success('订阅链接已重置');
    resetModalVisible.value = false;
  } catch {
    message.error('重置失败');
  }
};

// 续费相关
const handleRenewClick = async () => {
  if (!user.PlanList || user.PlanList.length === 0) {
    const hide = message.loading('加载套餐信息...', 0);
    try {
      await user.Set_PlanList();
      hide();
    } catch {
      hide();
      message.error('加载套餐信息失败');
      return;
    }
  }

  const currentPlan = user.PlanList.find((p: any) => p.id == user.Subscribe.plan_id);
  const plan = currentPlan || user.Subscribe.plan;

  if (!plan) {
    message.error('无法找到当前套餐详情');
    return;
  }

  const getPrice = (flatKey: string, nestedKey: string) => {
    if (plan[flatKey] !== undefined && plan[flatKey] !== null) return plan[flatKey];
    if (plan.prices && plan.prices[nestedKey] !== undefined && plan.prices[nestedKey] !== null) {
      return plan.prices[nestedKey] * 100;
    }
    return null;
  };

  const periodMap = [
    { key: 'month_price', nested: 'monthly', label: '月付' },
    { key: 'quarter_price', nested: 'quarterly', label: '季付' },
    { key: 'half_year_price', nested: 'half_yearly', label: '半年付' },
    { key: 'year_price', nested: 'yearly', label: '年付' },
    { key: 'two_year_price', nested: 'two_yearly', label: '两年付' },
    { key: 'three_year_price', nested: 'three_yearly', label: '三年付' },
    { key: 'onetime_price', nested: 'onetime', label: '一次性' }
  ];

  const periods: Array<{key: string, label: string, price: number}> = [];
  periodMap.forEach(item => {
    const priceInCents = getPrice(item.key, item.nested);
    if (priceInCents !== null) {
      periods.push({ key: item.key, label: item.label, price: priceInCents / 100 });
    }
  });

  if (periods.length === 0) {
    message.warning('该套餐暂时无法续费');
    return;
  }

  availablePeriods.value = periods;
  const defaultPeriod = periods.find(p => p.key === 'year_price') || periods[0];
  selectedRenewPeriod.value = defaultPeriod.key;
  // 重置优惠码
  renewCouponCode.value = '';
  renewCouponData.value = { status: false, type: 0, value: 0, name: '' };
  renewModalVisible.value = true;
};

// 验证续费优惠码
const validateRenewCoupon = async () => {
  if (!renewCouponCode.value.trim()) {
    message.error('请输入优惠码');
    return;
  }

  renewCouponValidating.value = true;
  try {
    const response = await verifyCoupon(renewCouponCode.value.trim(), user.Subscribe.plan_id);
    if (response.data) {
      renewCouponData.value = {
        status: true,
        type: response.data.type,
        value: response.data.value / 100,
        name: response.data.name || renewCouponCode.value
      };
      message.success('优惠码验证成功');
    }
  } catch (err: any) {
    renewCouponData.value = { status: false, type: 0, value: 0, name: '' };
    message.error(err?.data?.message || '优惠码无效');
  } finally {
    renewCouponValidating.value = false;
  }
};

// 计算续费折扣后价格
const renewDiscountedPrice = computed(() => {
  const period = availablePeriods.value.find(p => p.key === selectedRenewPeriod.value);
  if (!period) return null;

  if (!renewCouponData.value.status) {
    return { original: period.price, final: period.price, discount: 0 };
  }

  let discount = 0;
  if (renewCouponData.value.type === 1) {
    // 固定金额折扣 (value 已经是元为单位，原始值/100)
    discount = renewCouponData.value.value;
  } else if (renewCouponData.value.type === 2) {
    // 百分比折扣 (value 已经/100，如原始10变为0.1表示10%)
    discount = period.price * renewCouponData.value.value;
  }

  const final = Math.max(0, period.price - discount);
  return { original: period.price, final: Number(final.toFixed(2)), discount: Number(discount.toFixed(2)) };
});

const confirmRenew = async () => {
  if (!selectedRenewPeriod.value) {
    message.error('请选择续费周期');
    return;
  }

  confirmRenewLoading.value = true;
  try {
    const orderResponse = await submitOrder({
      plan_id: user.Subscribe.plan_id,
      period: selectedRenewPeriod.value,
      coupon_code: renewCouponData.value.status ? renewCouponCode.value.trim() : null
    });

    if (!orderResponse.data) {
      message.error('订单创建失败');
      return;
    }

    renewModalVisible.value = false;
    router.push({ name: 'Order', params: { id: orderResponse.data } });
  } catch {
    message.error('续费失败，请稍后再试');
  } finally {
    confirmRenewLoading.value = false;
  }
};

// 购买流量包
const handleBuyTrafficPack = async () => {
  if (!user.PlanList || user.PlanList.length === 0) {
    const hide = message.loading('加载套餐信息...', 0);
    try {
      await user.Set_PlanList();
      hide();
    } catch {
      hide();
      message.error('加载套餐信息失败');
      return;
    }
  }

  const currentPlan = user.PlanList.find((p: any) => p.id == user.Subscribe.plan_id);
  const plan = currentPlan || user.Subscribe.plan;

  if (!plan) {
    message.error('无法找到当前套餐详情');
    return;
  }

  // 检查是否有重置包价格
  const resetPrice = plan.reset_price;
  if (!resetPrice || resetPrice <= 0) {
    message.warning('当前套餐不支持购买重置包');
    return;
  }

  trafficPackPrice.value = resetPrice / 100;
  trafficPackModalVisible.value = true;
};

// 确认购买流量包
const confirmBuyTrafficPack = async () => {
  trafficPackLoading.value = true;
  try {
    const orderResponse = await submitOrder({
      plan_id: user.Subscribe.plan_id,
      period: 'reset_price'
    });

    if (!orderResponse.data) {
      message.error('订单创建失败');
      return;
    }

    trafficPackModalVisible.value = false;
    router.push({ name: 'Order', params: { id: orderResponse.data } });
  } catch {
    message.error('购买重置包失败，请稍后再试');
  } finally {
    trafficPackLoading.value = false;
  }
};

// 页面跳转
const openTicketPage = async () => {
  if (isMobile.value) {
    router.push('/ticket');
    return;
  }
  openTicketModal.value = true;
  if (!TicketComponent.value) {
    TicketComponent.value = (await import('@/views/Ticket/Ticket.vue')).default;
  }
};

const openTrafficLog = async () => {
  if (isMobile.value) {
    router.push('/trafficLog');
    return;
  }
  openTrafficLogModal.value = true;
  if (!TrafficLogComponent.value) {
    TrafficLogComponent.value = (await import('@/views/News/TrafficLog.vue')).default;
  }
};

const openChangepass = async () => {
  if (isMobile.value) {
    router.push('/changepass');
    return;
  }
  openPassModal.value = true;
  if (!ChangepassComponent.value) {
    ChangepassComponent.value = (await import('@/views/News/Changepass.vue')).default;
  }
};

const logout = () => {
  Token.Set_Token(undefined);
  user.Info = undefined;
  sessionStorage.removeItem('hideWelcomeModal'); // 清除不再显示标记
  window.location.reload();
};

const hideWelcomeModal = () => {
  sessionStorage.setItem('hideWelcomeModal', 'true');
  welcomeModalVisible.value = false;
};

const applyWelcomeCoupon = () => {
  sessionStorage.setItem('appliedCoupon', 'welcome');
  welcomeModalVisible.value = false;
  router.push('/store');
};

// 新人弹窗礼花动画
const triggerWelcomeConfetti = () => {
  confetti({
    particleCount: 80,
    spread: 70,
    origin: { x: 0.3, y: 0.5 },
    zIndex: 10000
  });
  confetti({
    particleCount: 80,
    spread: 70,
    origin: { x: 0.7, y: 0.5 },
    zIndex: 10000
  });
};

// 监听弹窗打开
watch(welcomeModalVisible, (val) => {
  if (val) {
    setTimeout(triggerWelcomeConfetti, 100);
  }
});

// 工单相关方法
const loadTickets = async () => {
  try {
    const res = await fetchTicketList();
    // 最多显示10条
    tickets.value = (res.data || []).slice(0, 10);
  } catch {
    tickets.value = [];
  }
};

const openTicketListModal = async () => {
  ticketModalVisible.value = true;
  ticketLoading.value = true;
  try {
    const res = await fetchTicketList();
    // 最多显示10条
    tickets.value = (res.data || []).slice(0, 10);
  } catch {
    tickets.value = [];
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

// ============ 充值相关方法 ============
const openRechargeModal = async () => {
  rechargeModalVisible.value = true;
  rechargeAmount.value = '';
  rechargeBonus.value = 0;
  rechargeTotal.value = 0;

  // 加载奖励配置
  if (bonusConfig.value.length === 0) {
    try {
      const res = await getRechargeBonusConfig();
      bonusConfig.value = res.data || [];
    } catch {
      // 使用默认配置
      bonusConfig.value = [
        { threshold: 10000, bonus: 1500, threshold_yuan: 100, bonus_yuan: 15 },
        { threshold: 20000, bonus: 5000, threshold_yuan: 200, bonus_yuan: 50 },
        { threshold: 30000, bonus: 10000, threshold_yuan: 300, bonus_yuan: 100 },
        { threshold: 50000, bonus: 20000, threshold_yuan: 500, bonus_yuan: 200 },
        { threshold: 100000, bonus: 50000, threshold_yuan: 1000, bonus_yuan: 500 },
        { threshold: 200000, bonus: 100000, threshold_yuan: 2000, bonus_yuan: 1000 },
      ];
    }
  }
};

// 计算当前金额对应的奖励
const calculateBonus = (amount: number): { bonus: number, total: number } => {
  const amountInCents = amount * 100;
  // 从高到低匹配
  const sortedConfig = [...bonusConfig.value].sort((a, b) => b.threshold - a.threshold);
  for (const item of sortedConfig) {
    if (amountInCents >= item.threshold) {
      return { bonus: item.bonus / 100, total: amount + item.bonus / 100 };
    }
  }
  return { bonus: 0, total: amount };
};

// 获取指定金额的奖励信息（用于快捷按钮显示）
const getBonusForAmount = (amount: number): number => {
  const config = bonusConfig.value.find(c => c.threshold_yuan === amount);
  return config ? config.bonus_yuan : 0;
};

const selectRechargeAmount = (amount: number) => {
  rechargeAmount.value = String(amount);
  const { bonus, total } = calculateBonus(amount);
  rechargeBonus.value = bonus;
  rechargeTotal.value = total;
};

// 监听自定义金额输入
const onRechargeAmountInput = () => {
  const amount = parseFloat(rechargeAmount.value) || 0;
  const { bonus, total } = calculateBonus(amount);
  rechargeBonus.value = bonus;
  rechargeTotal.value = total;
};

const createRecharge = async () => {
  const amount = parseFloat(rechargeAmount.value);
  if (isNaN(amount) || amount < 10) {
    message.error('请输入有效的充值金额（最少10元）');
    return;
  }
  if (amount > 10000) {
    message.error('单次充值金额不能超过10000元');
    return;
  }

  rechargeLoading.value = true;
  try {
    const amountInCents = Math.round(amount * 100); // 转换为分
    const res = await createRechargeOrder(amountInCents);
    if (res.data) {
      // 创建成功，直接跳转到订单详情页
      rechargeModalVisible.value = false;
      router.push({ path: `/order/${res.data.trade_no}` });
    } else {
      message.error('创建充值订单失败');
    }
  } catch (err: any) {
    message.error(err?.data?.message || '创建充值订单失败');
  } finally {
    rechargeLoading.value = false;
  }
};

const closeRechargeModal = () => {
  rechargeModalVisible.value = false;
  rechargeAmount.value = '';
  rechargeBonus.value = 0;
  rechargeTotal.value = 0;
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
  const bindCommand = `/bind ${subscribeUrl.value}`;
  try {
    await navigator.clipboard.writeText(bindCommand);
    message.success('绑定命令已复制');
  } catch {
    message.error('复制失败');
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

// ============ 生命周期 ============
// 监听导航栏触发的修改密码事件
const handleOpenChangepass = () => {
  openChangepass();
};

onMounted(async () => {
  // 监听窗口大小变化
  window.addEventListener('resize', updateIsMobile);
  // 监听修改密码事件
  window.addEventListener('open-changepass', handleOpenChangepass);

  // 获取邀请数据
  getInviteData().then(res => {
    invite.value.codes = res.data.codes;
    invite.value.stat = res.data.stat;
  }).catch(() => {});

  // 获取工单列表
  loadTickets();

  // 加载 Telegram Bot 信息
  loadTelegramBotInfo();

  // 检查未支付订单
  try {
    await user.Set_Order(true);
    if (user.Order && user.Order.length > 0) {
      const order = user.Order.find((o: any) => o.status === 0);
      if (order) {
        unpaidOrder.value = {
          trade_no: order.trade_no,
          is_recharge: order.period === 'recharge',
          plan_name: order.period === 'recharge' ? '余额充值' : (order.plan?.name || '未知套餐'),
          total_amount: order.total_amount,
          created_at: order.created_at,
        };
      }
    }
  } catch {}

  // 获取用户余额
  try {
    const response = await getUserInfo();
    balance.value = response.data.balance / 100;

    // 新用户欢迎（只有没有已应用的优惠码且未选择不再显示时才显示）
    if (!response.data.plan_id && !sessionStorage.getItem('appliedCoupon') && !sessionStorage.getItem('hideWelcomeModal')) {
      setTimeout(() => {
        welcomeModalVisible.value = true;
      }, 500);
    }
  } catch {}
});

onUnmounted(() => {
  window.removeEventListener('resize', updateIsMobile);
  window.removeEventListener('open-changepass', handleOpenChangepass);
});
</script>

<template>
  <div>
    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12 lg:py-16">

      <!-- 未支付订单提醒 -->
      <div
        v-if="unpaidOrder"
        class="relative flex items-center gap-4 px-4 sm:px-5 py-3 sm:py-4 mb-6 rounded-2xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-sm"
      >
        <!-- 呼吸灯小圆点 -->
        <span class="absolute top-3 left-3 flex h-2.5 w-2.5">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
          <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-amber-500"></span>
        </span>

        <img
          src="/assets/illustrations/undraw_pay-with-credit-card_77g6.svg"
          alt="待支付"
          class="w-14 h-14 sm:w-16 sm:h-16 object-contain shrink-0"
        />
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 text-xs text-zinc-400 dark:text-zinc-500 mb-1">
            <span class="font-mono">{{ unpaidOrder.trade_no }}</span>
            <span>·</span>
            <span>{{ moment(unpaidOrder.created_at * 1000).format('YYYY-MM-DD HH:mm') }}</span>
          </div>
          <div class="flex items-center gap-2 mb-0.5">
            <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">
              {{ unpaidOrder.is_recharge ? unpaidOrder.plan_name : unpaidOrder.plan_name }}
            </span>
            <span class="shrink-0 px-1.5 py-0.5 text-xs font-medium rounded bg-amber-100 dark:bg-amber-900/50 text-amber-600 dark:text-amber-400">
              待支付
            </span>
          </div>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
            ¥{{ (unpaidOrder.total_amount / 100).toFixed(2) }}
          </p>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <Button
            variant="ghost"
            size="sm"
            @click="handleCancelOrder"
            :disabled="cancelOrderLoading"
            class="text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
          >
            <Loader2 v-if="cancelOrderLoading" class="w-4 h-4 animate-spin" />
            <span v-else>取消</span>
          </Button>
          <Button
            size="sm"
            @click="router.push(`/order/${unpaidOrder.trade_no}`)"
          >
            去支付
          </Button>
        </div>
      </div>

      <!-- 公告横幅 -->
      <div
        v-if="latestNotice"
        class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 mb-6 sm:mb-8 overflow-hidden"
      >
        <!-- 公告内容区 -->
        <div class="flex items-start gap-4 p-4 sm:p-5">
          <!-- 公告信息 -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1.5 sm:mb-2">
              <span class="px-2 py-0.5 text-xs font-medium rounded bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400 shrink-0">最新公告</span>
              <h3 class="font-medium text-zinc-900 dark:text-zinc-100 text-sm sm:text-base line-clamp-1">{{ latestNotice.title }}</h3>
              <span v-if="latestNotice.created_at" class="text-xs text-zinc-400 shrink-0">
                {{ new Date(latestNotice.created_at * 1000).toLocaleDateString('zh-CN') }}
              </span>
            </div>
            <p v-if="latestNotice.content" class="text-xs sm:text-sm text-zinc-500 line-clamp-2">
              {{ latestNotice.content.replace(/<[^>]+>/g, '').substring(0, 100) }}
            </p>
          </div>
          <!-- 插图 -->
          <div class="relative shrink-0 hidden sm:block">
            <img
              src="/assets/illustrations/bell.svg"
              alt="公告"
              class="relative w-8 h-8 sm:w-10 sm:h-10 object-contain"
            />
          </div>
        </div>

        <!-- 分割线 -->
        <div class="border-t border-zinc-100 dark:border-zinc-800"></div>

        <!-- 防失联地址 -->
        <a
          href="https://lray.dlgisea.com"
          target="_blank"
          class="flex items-center justify-between p-4 sm:p-5 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors group"
        >
          <div class="flex items-center gap-2">
            <span class="px-2 py-0.5 text-xs font-medium rounded bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400 shrink-0">官网</span>
            <span class="font-medium text-zinc-900 dark:text-zinc-100 text-sm sm:text-base">防失联地址，请添加到收藏夹</span>
            <span class="text-xs text-zinc-400 hidden sm:inline">lray.dlgisea.com</span>
          </div>
          <ChevronRight class="w-4 h-4 text-zinc-400 group-hover:translate-x-0.5 transition-transform shrink-0" />
        </a>

        <!-- 查看全部公告 -->
        <button
          v-if="allNotices.length > 1"
          @click="noticeModalVisible = true"
          class="w-full px-4 sm:px-5 py-2.5 sm:py-3 text-xs sm:text-sm text-zinc-500 hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors text-left border-t border-zinc-100 dark:border-zinc-800"
        >
          查看全部 {{ allNotices.length }} 条公告
        </button>
      </div>

      <!-- 顶部：账户卡片 -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6 sm:mb-8">
        <!-- 余额卡片 -->
        <div class="relative overflow-hidden bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4 sm:p-5">
          <div class="flex items-center justify-between gap-3">
            <div class="min-w-0">
              <div class="flex items-center gap-1.5 mb-1">
                <Wallet class="w-4 h-4 text-zinc-400 shrink-0" />
                <span class="text-sm text-zinc-500 dark:text-zinc-400">余额</span>
              </div>
              <span class="text-xl sm:text-2xl font-bold text-zinc-900 dark:text-zinc-100">¥{{ stats.balance.toFixed(2) }}</span>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <button
                @click="openRechargeModal"
                class="flex items-center gap-1 px-3 py-1.5 bg-zinc-900 dark:bg-zinc-100 hover:bg-zinc-800 dark:hover:bg-zinc-200 text-white dark:text-zinc-900 text-sm font-medium rounded-lg transition-colors"
              >
                <Plus class="w-4 h-4" />
                充值
              </button>
              <span class="hidden sm:inline-flex items-center gap-1 text-xs text-orange-600 dark:text-orange-400 font-medium animate-pulse whitespace-nowrap"><Gift class="w-3 h-3" />最高加赠50%</span>
            </div>
          </div>
          <p class="sm:hidden inline-flex items-center gap-1 text-xs text-orange-600 dark:text-orange-400 font-medium mt-2 animate-pulse"><Gift class="w-3 h-3" />最高加赠50%</p>
        </div>
        <!-- 佣金卡片 -->
        <div class="relative overflow-hidden bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4 sm:p-5">
          <div class="flex items-center justify-between gap-3">
            <div class="min-w-0">
              <div class="flex items-center gap-1.5 mb-1">
                <Banknote class="w-4 h-4 text-zinc-400 shrink-0" />
                <span class="text-sm text-zinc-500 dark:text-zinc-400">佣金</span>
              </div>
              <span class="text-xl sm:text-2xl font-bold text-zinc-900 dark:text-zinc-100">¥{{ ((invite.stat?.[4] || 0) / 100).toFixed(2) }}</span>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <router-link
                to="/invite"
                class="flex items-center gap-1 px-3 py-1.5 bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 dark:hover:bg-zinc-700 text-zinc-700 dark:text-zinc-300 text-sm font-medium rounded-lg transition-colors"
              >
                查看
                <ChevronRight class="w-4 h-4" />
              </router-link>
              <span class="hidden sm:inline text-xs text-orange-600 dark:text-orange-400 font-medium whitespace-nowrap">{{ commissionRate }}%返佣可提现</span>
            </div>
          </div>
          <p class="sm:hidden text-xs text-orange-600 dark:text-orange-400 font-medium mt-2">{{ commissionRate }}%返佣可提现</p>
        </div>
      </div>


      <!-- 当前套餐卡片 -->
      <div v-if="hasSubscription" class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden mb-8 sm:mb-10">
        <!-- 套餐信息 -->
        <div class="p-4 sm:p-6 lg:p-8">
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
            <div class="flex items-center gap-3 sm:gap-5">
              <div class="w-12 h-12 sm:w-16 sm:h-16 rounded-xl sm:rounded-2xl bg-gradient-to-br from-zinc-800 via-zinc-900 to-black dark:from-zinc-700 dark:via-zinc-800 dark:to-zinc-900 flex items-center justify-center shrink-0 shadow-lg">
                <Crown class="w-6 h-6 sm:w-8 sm:h-8 text-amber-400" />
              </div>
              <div class="min-w-0">
                <h3 class="text-lg sm:text-xl font-bold text-zinc-900 dark:text-zinc-100 truncate">{{ planName }}</h3>
                <div class="flex items-center gap-2 sm:gap-3 mt-1.5 sm:mt-2 flex-wrap">
                  <span class="inline-flex items-center px-2 sm:px-3 py-0.5 sm:py-1 rounded-full text-xs font-medium bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400">
                    <Clock class="w-3 h-3 mr-1" />
                    有效期：{{ typeof stats.remainingDays === 'number' ? stats.remainingDays + ' 天' : stats.remainingDays }}
                  </span>
                  <span v-if="resetDaysRemaining !== null" class="inline-flex items-center px-2 sm:px-3 py-0.5 sm:py-1 rounded-full text-xs font-medium bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400">
                    <RotateCcw class="w-3 h-3 mr-1" />
                    {{ resetDaysRemaining }} 天后重置流量
                  </span>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2 sm:gap-3 flex-wrap">
              <Button v-if="resetDaysRemaining !== null" variant="outline" size="sm" @click="handleBuyTrafficPack" class="flex-1 sm:flex-none justify-center">
                <RotateCcw class="w-4 h-4 mr-1.5" />
                重置包
              </Button>
              <Button variant="outline" size="sm" as-child class="flex-1 sm:flex-none justify-center">
                <router-link to="/store">
                  <ArrowRightLeft class="w-4 h-4 mr-1.5" />
                  更换套餐
                </router-link>
              </Button>
              <Button size="sm" @click="handleRenewClick" class="flex-1 sm:flex-none justify-center">
                <Zap class="w-4 h-4 mr-1.5" />
                续费
              </Button>
              <Button size="sm" class="!bg-zinc-900 hover:!bg-zinc-800 !text-white dark:!bg-white dark:!text-zinc-900 dark:hover:!bg-zinc-100 flex-1 sm:flex-none justify-center" as-child>
                <router-link to="/download">
                  <Download class="w-4 h-4 mr-1.5" />
                  下载客户端
                </router-link>
              </Button>
            </div>
          </div>

          <!-- 流量进度条 -->
          <div class="mt-4 sm:mt-6">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-0 mb-2 sm:mb-3">
              <div class="flex items-baseline gap-1 sm:gap-1.5 flex-wrap">
                <span class="text-xs sm:text-sm text-zinc-400">已用</span>
                <span class="text-xl sm:text-2xl font-bold text-zinc-900 dark:text-zinc-100">{{ stats.usedTraffic.value }}</span>
                <span class="text-xs sm:text-sm text-zinc-500">{{ stats.usedTraffic.unit }}</span>
                <span class="text-zinc-300 dark:text-zinc-600 mx-0.5 sm:mx-1">/</span>
                <span class="text-xs sm:text-sm text-zinc-400">共</span>
                <span class="text-base sm:text-lg font-medium text-zinc-600 dark:text-zinc-400">{{ stats.totalTraffic.value }}</span>
                <span class="text-xs sm:text-sm text-zinc-400">{{ stats.totalTraffic.unit }}</span>
              </div>
              <span class="text-xs sm:text-sm font-medium text-zinc-500">{{ stats.usedPercent }}%</span>
            </div>
            <div class="h-2 sm:h-3 bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
              <div
                v-if="stats.usedPercent > 0"
                class="h-full rounded-full transition-all duration-500 relative"
                :class="stats.usedPercent > 80 ? 'bg-gradient-to-r from-orange-400 to-red-500' : 'bg-gradient-to-r from-blue-400 to-blue-600'"
                :style="{ width: stats.usedPercent + '%' }"
              >
                <div class="absolute inset-0 bg-gradient-to-b from-white/20 to-transparent"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- 快捷操作 -->
        <div class="grid grid-cols-3 border-t border-zinc-100 dark:border-zinc-800">
          <button
            @click="openImportModal"
            class="flex items-center justify-center gap-1.5 sm:gap-2 py-3 sm:py-4 text-xs sm:text-sm text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            <QrCode class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            导入订阅
          </button>
          <button
            @click="openTrafficLog"
            class="flex items-center justify-center gap-1.5 sm:gap-2 py-3 sm:py-4 text-xs sm:text-sm text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors border-x border-zinc-100 dark:border-zinc-800"
          >
            <BarChart3 class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            流量明细
          </button>
          <button
            @click="resetModalVisible = true"
            class="flex items-center justify-center gap-1.5 sm:gap-2 py-3 sm:py-4 text-xs sm:text-sm text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            <RotateCcw class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            重置链接
          </button>
        </div>
      </div>

      <!-- 未订阅提示 -->
      <div v-else class="relative bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 sm:p-8 mb-8 sm:mb-10 overflow-hidden">
        <div class="relative flex flex-col sm:flex-row sm:items-center sm:justify-between gap-5">
          <div class="flex items-center gap-4 sm:gap-5">
            <!-- 插图 -->
            <div class="w-20 h-20 sm:w-24 sm:h-24 shrink-0">
              <img
                src="/assets/illustrations/undraw_outer-space_qey5.svg"
                alt="开启您的专属网络"
                class="w-full h-full object-contain"
              />
            </div>
            <div>
              <h3 class="text-lg sm:text-xl font-bold text-zinc-900 dark:text-zinc-100">开启您的专属网络</h3>
              <p class="text-sm text-zinc-600 dark:text-zinc-400 mt-1">选择适合您的套餐，畅享高速稳定的网络服务</p>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <Button size="lg" as-child class="!bg-zinc-900 hover:!bg-zinc-800 !text-white shadow-lg px-8">
              <router-link to="/store">
                浏览套餐
                <ArrowRight class="w-4 h-4 ml-2" />
              </router-link>
            </Button>
            <Button variant="ghost" @click="user.ExchangeModal = true" class="text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200 gap-1">
              <Gift class="w-4 h-4" />
              兑换套餐
            </Button>
          </div>
        </div>
      </div>

      <!-- 节点列表 -->
      <div class="mb-8 sm:mb-10">
        <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100 mb-4 sm:mb-6">可用节点</h2>
        <ServerNode />
      </div>

      <!-- 帮助与支持 -->
      <div class="pb-6 sm:pb-8">
        <h2 class="text-lg sm:text-xl font-semibold text-zinc-900 dark:text-zinc-100 mb-4 sm:mb-6">帮助与支持</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <!-- 工单入口卡片 -->
          <button
            @click="openTicketPage"
            class="relative overflow-hidden bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl p-5 sm:p-6 text-left group hover:shadow-lg hover:border-blue-200 dark:hover:border-blue-800 transition-all duration-300 min-h-[160px]"
          >
            <!-- 客服支持插图 -->
            <div class="absolute bottom-2 right-2 w-28 h-28 sm:w-32 sm:h-32">
              <img
                src="/assets/illustrations/in-the-zone.svg"
                alt="客服支持"
                class="w-full h-full object-contain"
              />
            </div>
            <div class="relative z-10">
              <div class="flex items-center gap-2 mb-3">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                  <Ticket class="w-5 h-5 text-white" />
                </div>
                <span class="px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400">
                  24h 响应
                </span>
              </div>
              <h3 class="text-lg sm:text-xl font-bold text-zinc-900 dark:text-zinc-100 mb-1">我的工单</h3>
              <p class="text-sm text-zinc-500 dark:text-zinc-400 max-w-[65%]">遇到问题？我们的技术团队随时为您服务</p>
            </div>
          </button>

          <!-- 下载与教程卡片 -->
          <router-link
            to="/download"
            class="relative overflow-hidden bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl p-5 sm:p-6 text-left group hover:shadow-lg hover:border-blue-200 dark:hover:border-blue-800 transition-all duration-300 min-h-[160px]"
          >
            <!-- 下载应用插图 -->
            <div class="absolute bottom-2 right-2 w-28 h-28 sm:w-32 sm:h-32">
              <img
                src="/assets/illustrations/download.svg"
                alt="下载应用"
                class="w-full h-full object-contain"
              />
            </div>
            <div class="relative z-10">
              <div class="flex items-center gap-2 mb-3">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                  <Download class="w-5 h-5 text-white" />
                </div>
                <span class="px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400">
                  多平台
                </span>
              </div>
              <h3 class="text-lg sm:text-xl font-bold text-zinc-900 dark:text-zinc-100 mb-1">下载与教程</h3>
              <p class="text-sm text-zinc-500 dark:text-zinc-400 max-w-[65%]">获取客户端及详细使用指南</p>
            </div>
          </router-link>
        </div>
      </div>
    </div>

    <!-- ============ 弹窗 ============ -->

    <!-- 一键导入弹窗 -->
    <Dialog v-model:open="importModalVisible">
      <DialogContent class="sm:max-w-md overflow-hidden">
        <DialogHeader>
          <DialogTitle>导入订阅</DialogTitle>
          <DialogDescription>扫描二维码导入到客户端或通过一键导入到客户端</DialogDescription>
        </DialogHeader>

        <div class="py-4 overflow-hidden">
          <div class="flex justify-center mb-6">
            <div class="p-4 bg-white rounded-xl border shadow-sm">
              <img :src="qrcodeUrl" alt="QR Code" class="w-44 h-44" />
            </div>
          </div>

          <!-- 订阅链接 -->
          <div class="mb-4">
            <div class="flex items-start justify-between mb-2 gap-3">
              <div>
                <p class="text-xs text-muted-foreground">通用订阅链接</p>
                <p class="text-[11px] text-zinc-400 dark:text-zinc-500">
                  当前链接：{{ useBackupSubscribe ? '备用订阅源' : '默认订阅源' }}
                </p>
              </div>
              <Button
                variant="outline"
                size="sm"
                class="h-7 px-2 text-xs"
                @click="useBackupSubscribe = !useBackupSubscribe"
              >
                切换为{{ useBackupSubscribe ? '默认链接' : '备用链接' }}
              </Button>
            </div>
            <div class="flex items-center gap-2">
              <input
                type="text"
                :value="modalSubscribeUrl"
                readonly
                class="flex-1 px-3 py-2 bg-muted rounded-lg text-sm font-mono truncate border-0 outline-none"
              />
              <Button variant="outline" size="icon" @click="copySubscribeLink" title="复制链接">
                <Copy class="h-4 w-4" />
              </Button>
            </div>
          </div>

          <Separator class="my-4" />

          <!-- 友情提醒 - 仅桌面端显示 -->
          <div class="hidden sm:block mb-4 p-3 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/50">
            <div class="flex gap-2">
              <TriangleAlert class="w-4 h-4 text-amber-600 dark:text-amber-500 shrink-0 mt-0.5" />
              <div class="text-xs text-amber-700 dark:text-amber-400 leading-relaxed">
                <span class="font-medium">友情提醒：</span>由于 Clash for Windows 早已停止维护，会有无法导入和安全问题。我们建议 Windows、macOS、Linux 都使用 <a href="https://github.com/clash-verge-rev/clash-verge-rev" target="_blank" class="font-medium underline hover:text-amber-800 dark:hover:text-amber-300">Clash Verge Rev</a> 或 <a href="https://github.com/chen08209/FlClash" target="_blank" class="font-medium underline hover:text-amber-800 dark:hover:text-amber-300">FlClash</a> 等仍在维护的衍生版 Clash 客户端。
              </div>
            </div>
          </div>

          <div class="space-y-1">
            <div
              v-for="app in filteredImportApps"
              :key="app.name"
              @click="handleImport(app)"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-muted cursor-pointer transition-colors"
            >
              <img :src="app.icon" :alt="app.name" class="w-6 h-6" />
              <span class="flex-1 text-sm font-medium">{{ app.name }}</span>
              <ChevronRight class="h-4 w-4 text-muted-foreground" />
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 续费弹窗 -->
    <Dialog v-model:open="renewModalVisible">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>续费订阅</DialogTitle>
          <DialogDescription>{{ user.Subscribe?.plan?.name }}</DialogDescription>
        </DialogHeader>

        <div class="py-4 space-y-4">
          <!-- 周期选择 -->
          <div class="grid grid-cols-2 gap-3">
            <div
              v-for="period in availablePeriods"
              :key="period.key"
              @click="selectedRenewPeriod = period.key"
              class="relative p-4 rounded-xl border-2 cursor-pointer transition-all"
              :class="selectedRenewPeriod === period.key
                ? 'border-primary bg-primary/5'
                : 'border-border hover:border-primary/50'"
            >
              <p class="text-sm text-muted-foreground">{{ period.label }}</p>
              <p class="text-2xl font-bold mt-1">¥{{ period.price }}</p>
              <div v-if="selectedRenewPeriod === period.key" class="absolute top-3 right-3">
                <div class="w-5 h-5 rounded-full bg-primary flex items-center justify-center">
                  <Check class="h-3 w-3 text-primary-foreground" />
                </div>
              </div>
            </div>
          </div>

          <!-- 优惠码输入 -->
          <div class="space-y-2">
            <label class="text-sm font-medium text-zinc-700 dark:text-zinc-300">优惠码</label>
            <div class="flex gap-2">
              <div class="relative flex-1">
                <Ticket class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-400" />
                <input
                  v-model="renewCouponCode"
                  type="text"
                  placeholder="输入优惠码（可选）"
                  :disabled="renewCouponData.status"
                  class="w-full pl-10 pr-3 py-2.5 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
                  @keyup.enter="validateRenewCoupon"
                />
              </div>
              <Button
                v-if="!renewCouponData.status"
                @click="validateRenewCoupon"
                :disabled="renewCouponValidating || !renewCouponCode.trim()"
                variant="outline"
                size="default"
              >
                <RefreshCw v-if="renewCouponValidating" class="w-4 h-4 animate-spin" />
                <span v-else>验证</span>
              </Button>
              <Button
                v-else
                @click="renewCouponCode = ''; renewCouponData = { status: false, type: 0, value: 0, name: '' }"
                variant="outline"
                size="default"
              >
                取消
              </Button>
            </div>
            <!-- 优惠码成功提示 -->
            <div v-if="renewCouponData.status" class="flex items-center gap-2 text-sm text-green-600 dark:text-green-400">
              <Check class="w-4 h-4" />
              <span>已应用优惠码：{{ renewCouponData.name }}</span>
            </div>
          </div>

          <!-- 价格汇总 -->
          <div v-if="renewDiscountedPrice" class="bg-zinc-50 dark:bg-zinc-800/50 rounded-lg p-4 space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-zinc-500 dark:text-zinc-400">原价</span>
              <span class="text-zinc-900 dark:text-zinc-100">¥{{ renewDiscountedPrice.original }}</span>
            </div>
            <div v-if="renewCouponData.status && renewDiscountedPrice.discount > 0" class="flex justify-between text-sm">
              <span class="text-zinc-500 dark:text-zinc-400">优惠码优惠</span>
              <span class="text-green-600 dark:text-green-400">-¥{{ renewDiscountedPrice.discount }}</span>
            </div>
            <Separator />
            <div class="flex justify-between">
              <span class="font-medium text-zinc-900 dark:text-zinc-100">实付金额</span>
              <span class="text-xl font-bold text-primary">¥{{ renewDiscountedPrice.final }}</span>
            </div>
          </div>
        </div>

        <div class="flex gap-3">
          <Button variant="outline" class="flex-1" @click="renewModalVisible = false">
            <X class="w-4 h-4 mr-1.5" />
            取消
          </Button>
          <Button class="flex-1" @click="confirmRenew" :disabled="confirmRenewLoading">
            <RefreshCw v-if="confirmRenewLoading" class="h-4 w-4 mr-2 animate-spin" />
            <CreditCard v-else class="w-4 h-4 mr-1.5" />
            {{ confirmRenewLoading ? '处理中' : '确认续费' }}
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 购买重置包弹窗 -->
    <Dialog v-model:open="trafficPackModalVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>购买重置包</DialogTitle>
          <DialogDescription>{{ user.Subscribe?.plan?.name }}</DialogDescription>
        </DialogHeader>

        <div class="py-4 space-y-4">
          <!-- 流量包信息 -->
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950/30 dark:to-indigo-950/30 rounded-xl p-5 text-center">
            <Package class="w-12 h-12 mx-auto mb-3 text-blue-500" />
            <p class="text-sm text-zinc-600 dark:text-zinc-400 mb-2">重置当前套餐流量</p>
            <p class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">
              ¥{{ trafficPackPrice }}
            </p>
          </div>

          <!-- 提醒 -->
          <div class="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/50 rounded-lg p-4 text-sm text-amber-800 dark:text-amber-200">
            <div class="flex items-start gap-2">
              <AlertCircle class="w-4 h-4 mt-0.5 shrink-0" />
              <p>您的套餐流量 {{ resetDaysRemaining ?? 0 }} 天后会自动重置。如果不想等待，可购买此流量包立即重置流量，但不影响 {{ resetDaysRemaining ?? 0 }} 天后的正常流量重置，且流量不会叠加。</p>
            </div>
          </div>
        </div>

        <div class="flex gap-3">
          <Button variant="outline" class="flex-1" @click="trafficPackModalVisible = false">
            <X class="w-4 h-4 mr-1.5" />
            取消
          </Button>
          <Button class="flex-1" @click="confirmBuyTrafficPack" :disabled="trafficPackLoading">
            <RefreshCw v-if="trafficPackLoading" class="h-4 w-4 mr-2 animate-spin" />
            <CreditCard v-else class="w-4 h-4 mr-1.5" />
            {{ trafficPackLoading ? '处理中' : '确认购买' }}
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 重置订阅弹窗 -->
    <Dialog v-model:open="resetModalVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>重置订阅链接</DialogTitle>
          <DialogDescription>
            重置后原链接立即失效，需要重新导入客户端。
          </DialogDescription>
        </DialogHeader>

        <div class="flex gap-3 pt-4">
          <Button variant="outline" class="flex-1" @click="resetModalVisible = false">
            <X class="w-4 h-4 mr-1.5" />
            取消
          </Button>
          <Button variant="destructive" class="flex-1" @click="resetSubscribe">
            <RotateCcw class="w-4 h-4 mr-1.5" />
            确认重置
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 新人优惠弹窗 -->
    <Dialog v-model:open="welcomeModalVisible">
      <DialogContent class="sm:max-w-[280px] p-6">
        <div class="text-center space-y-4">
          <img
            src="/assets/illustrations/undraw_happy-birthday_lmk0.svg"
            alt="新人礼遇"
            class="w-28 h-28 object-contain mx-auto"
          />
          <div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">新人专享礼遇</h3>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">送您一张 9 折优惠券</p>
          </div>
          <div class="bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-600 rounded-lg py-2.5 px-4 grid place-items-center">
            <span class="text-lg font-bold text-white font-mono">welcome</span>
          </div>
          <div class="space-y-2">
            <Button @click="applyWelcomeCoupon" class="w-full">
              立即领取
            </Button>
            <button
              @click="hideWelcomeModal"
              class="text-xs text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300 transition-colors"
            >
              不再显示，直到下次登录
            </button>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 全部公告弹窗 -->
    <Dialog v-model:open="noticeModalVisible">
      <DialogContent class="sm:max-w-2xl max-h-[80vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>全部公告</DialogTitle>
          <DialogDescription>共 {{ allNotices.length }} 条公告</DialogDescription>
        </DialogHeader>

        <div class="flex-1 overflow-y-auto -mx-6 px-6">
          <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <div
              v-for="(notice, index) in allNotices"
              :key="notice.id || index"
              class="py-5 first:pt-0 last:pb-0"
            >
              <div class="flex items-center gap-2 mb-3">
                <span
                  v-if="index === 0"
                  class="shrink-0 px-2 py-0.5 text-xs font-medium rounded-full bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400"
                >
                  最新
                </span>
                <h4 class="text-base font-semibold text-zinc-900 dark:text-zinc-100">{{ notice.title }}</h4>
                <span v-if="notice.created_at" class="text-xs text-zinc-400 ml-auto">
                  {{ new Date(notice.created_at * 1000).toLocaleDateString('zh-CN') }}
                </span>
              </div>
              <div
                v-if="notice.content"
                class="text-sm text-zinc-600 dark:text-zinc-400 prose prose-sm dark:prose-invert max-w-none"
                v-html="notice.content"
              ></div>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    <!-- 工单弹窗 -->
    <Dialog v-model:open="openTicketModal">
      <DialogContent class="sm:max-w-4xl max-h-[85vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>我的工单</DialogTitle>
        </DialogHeader>

        <div class="flex-1 overflow-y-auto -mx-6 px-6">
          <component :is="TicketComponent" v-if="TicketComponent" />
        </div>
      </DialogContent>
    </Dialog>

    <!-- 修改密码弹窗 -->
    <Dialog v-model:open="openPassModal">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>修改密码</DialogTitle>
        </DialogHeader>
        <component :is="ChangepassComponent" v-if="ChangepassComponent" />
      </DialogContent>
    </Dialog>

    <!-- 流量明细弹窗 -->
    <Dialog v-model:open="openTrafficLogModal">
      <DialogContent class="sm:max-w-4xl max-h-[85vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>流量明细</DialogTitle>
        </DialogHeader>
        <div class="flex-1 overflow-y-auto -mx-6 px-6">
          <component :is="TrafficLogComponent" v-if="TrafficLogComponent" />
        </div>
      </DialogContent>
    </Dialog>

    <!-- 充值弹窗 -->
    <Dialog v-model:open="rechargeModalVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>账户充值</DialogTitle>
          <DialogDescription>
            充值到账户余额，可用于购买套餐
          </DialogDescription>
        </DialogHeader>

        <div class="space-y-5">
          <!-- 快捷金额选择 -->
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="amount in rechargeAmountOptions"
              :key="amount"
              @click="selectRechargeAmount(amount)"
              class="relative py-3 rounded-lg border text-center transition-all"
              :class="rechargeAmount === String(amount)
                ? 'border-zinc-900 dark:border-zinc-100 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900'
                : 'border-zinc-200 dark:border-zinc-700 hover:border-zinc-400 dark:hover:border-zinc-500 text-zinc-900 dark:text-zinc-100'"
            >
              <span class="text-base font-semibold">¥{{ amount }}</span>
              <span
                v-if="getBonusForAmount(amount) > 0"
                class="absolute -top-1.5 -right-1.5 px-1.5 py-0.5 text-[10px] font-medium bg-blue-500 text-white rounded"
              >
                +{{ getBonusForAmount(amount) }}
              </span>
            </button>
          </div>

          <!-- 自定义金额 -->
          <div class="space-y-1.5">
            <label class="text-sm text-zinc-500 dark:text-zinc-400">自定义金额</label>
            <div class="relative">
              <span class="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400">¥</span>
              <input
                v-model="rechargeAmount"
                type="number"
                min="10"
                max="10000"
                step="1"
                placeholder="10 - 10000"
                class="w-full pl-7 pr-3 py-2 border border-zinc-200 dark:border-zinc-700 rounded-lg bg-transparent text-zinc-900 dark:text-zinc-100 text-sm focus:outline-none focus:border-zinc-400 dark:focus:border-zinc-500"
                @input="onRechargeAmountInput"
              />
            </div>
          </div>

          <!-- 费用明细 -->
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-zinc-500 dark:text-zinc-400">充值金额</span>
              <span class="text-zinc-900 dark:text-zinc-100">¥{{ (parseFloat(rechargeAmount) || 0).toFixed(2) }}</span>
            </div>
            <div v-if="rechargeBonus > 0" class="flex justify-between">
              <span class="text-zinc-500 dark:text-zinc-400">充值奖励</span>
              <span class="text-blue-500 font-medium">+¥{{ rechargeBonus.toFixed(2) }}</span>
            </div>
            <div v-if="rechargeAmount" class="flex justify-between pt-2 border-t border-zinc-100 dark:border-zinc-800">
              <span class="text-zinc-900 dark:text-zinc-100 font-medium">实际到账</span>
              <span class="text-zinc-900 dark:text-zinc-100 font-semibold">¥{{ rechargeTotal.toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <div class="flex gap-3 pt-2">
          <Button variant="outline" class="flex-1" @click="closeRechargeModal">
            取消
          </Button>
          <Button
            class="flex-1"
            @click="createRecharge"
            :disabled="rechargeLoading || !rechargeAmount"
          >
            <RefreshCw v-if="rechargeLoading" class="h-4 w-4 mr-2 animate-spin" />
            {{ rechargeLoading ? '处理中...' : '确认充值' }}
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Telegram 绑定弹窗 -->
    <Dialog v-model:open="telegramModalVisible">
      <DialogContent class="sm:max-w-sm">
        <DialogHeader>
          <div class="flex justify-center mb-2">
            <div class="w-14 h-14 rounded-full bg-[#2AABEE] flex items-center justify-center">
              <svg class="w-7 h-7 text-white" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20.665 3.717l-17.73 6.837c-1.21.486-1.203 1.161-.222 1.462l4.552 1.42 10.532-6.645c.498-.303.953-.14.579.192l-8.533 7.701h-.002l.002.001-.314 4.692c.46 0 .663-.211.921-.46l2.211-2.15 4.599 3.397c.848.467 1.457.227 1.668-.785l3.019-14.228c.309-1.239-.473-1.8-1.282-1.434z"/>
              </svg>
            </div>
          </div>
          <DialogTitle class="text-center">
            {{ telegramBound ? 'Telegram Bot 已绑定' : '绑定 Telegram Bot' }}
          </DialogTitle>
          <DialogDescription v-if="!telegramBound" class="text-center">
            绑定您的 Lray 账号
          </DialogDescription>
        </DialogHeader>

        <div v-if="!telegramBound" class="space-y-4 py-4">
          <!-- 功能说明 -->
          <div class="space-y-2 text-sm text-zinc-600 dark:text-zinc-400">
            <div class="flex items-center gap-2">
              <Check class="w-4 h-4 text-green-500 shrink-0" />
              <span>查看流量使用情况</span>
            </div>
            <div class="flex items-center gap-2">
              <Check class="w-4 h-4 text-green-500 shrink-0" />
              <span>获取最新订阅链接</span>
            </div>
            <div class="flex items-center gap-2">
              <Check class="w-4 h-4 text-green-500 shrink-0" />
              <span>管理账号绑定状态</span>
            </div>
          </div>

          <Separator />

          <!-- 步骤说明 -->
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
                <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-0.5">复制下方命令，粘贴到 Bot 对话框发送</p>
              </div>
            </div>
          </div>

          <!-- 绑定命令 -->
          <div class="bg-zinc-100 dark:bg-zinc-800 rounded-lg p-3">
            <p class="text-xs text-zinc-500 dark:text-zinc-400 mb-2">绑定命令（含订阅链接）</p>
            <div class="flex items-center gap-2">
              <code class="flex-1 text-xs font-mono text-zinc-900 dark:text-zinc-100 break-all line-clamp-2">/bind {{ subscribeUrl.substring(0, 50) }}...</code>
              <Button variant="outline" size="sm" @click="copyBindCommand" class="h-8 px-3 shrink-0">
                <Copy class="w-4 h-4 mr-1" />
                复制
              </Button>
            </div>
          </div>

          <!-- Bot 用户名 -->
          <div class="text-center text-xs text-zinc-400">
            Bot: @{{ telegramBotUsername }}
          </div>
        </div>

        <div v-else class="py-4">
          <div class="flex items-center justify-center gap-2 text-green-600 dark:text-green-400">
            <Check class="w-5 h-5" />
            <span class="font-medium">绑定成功</span>
          </div>
          <p class="text-center text-sm text-zinc-500 dark:text-zinc-400 mt-2">
            您将通过 Telegram Bot 管理账户
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
          <div v-else-if="tickets.length === 0" class="flex flex-col items-center justify-center py-12">
            <Ticket class="w-12 h-12 text-zinc-200 dark:text-zinc-700 mb-3" />
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-4">暂无工单记录</p>
            <Button size="sm" @click="ticketModalVisible = false; openTicketPage()">
              提交工单
            </Button>
          </div>

          <!-- 工单列表 -->
          <div v-else class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <div
              v-for="ticket in tickets"
              :key="ticket.id"
              @click="ticketModalVisible = false; openTicketPage()"
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
          <Button class="flex-1" @click="ticketModalVisible = false; openTicketPage()">
            提交工单
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
a {
  text-decoration: none;
  color: inherit;
}

/* 公告切换动画 - 左右滑动 */
.notice-slide-enter-active,
.notice-slide-leave-active {
  transition: all 0.4s ease;
}

.notice-slide-enter-from {
  opacity: 0;
  transform: translateX(30px);
}

.notice-slide-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}

.notice-slide-leave-active {
  position: absolute;
}
</style>
