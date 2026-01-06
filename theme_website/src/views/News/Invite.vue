<template>
  <div class="min-h-screen">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <!-- 页面标题 -->
      <div class="mb-8 text-center sm:text-left">
        <h1 class="text-2xl sm:text-3xl font-bold text-zinc-900 dark:text-zinc-100">邀请返利</h1>
        <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">邀请好友注册，获得佣金奖励</p>
      </div>

      <!-- 步骤说明 -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <Card
          v-for="(step, index) in steps"
          :key="index"
          class="border-zinc-200 dark:border-zinc-800 hover:border-primary/30 dark:hover:border-primary/30 transition-colors"
        >
          <CardContent class="p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-xl bg-primary/10 dark:bg-primary/20 flex items-center justify-center shrink-0">
                <component :is="step.icon" class="w-5 h-5 text-primary" />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-1">
                  <span class="w-5 h-5 rounded-full bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 flex items-center justify-center text-xs font-semibold">
                    {{ index + 1 }}
                  </span>
                  <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">{{ step.title }}</h3>
                </div>
                <p class="text-xs text-zinc-500 dark:text-zinc-400 leading-relaxed">{{ step.desc }}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- 注意事项 -->
      <Card class="border-zinc-200 dark:border-zinc-800 mb-8">
        <CardHeader class="pb-4">
          <CardTitle class="text-lg flex items-center gap-2">
            <Info class="w-5 h-5" />
            注意事项
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div class="flex flex-col lg:flex-row gap-6 lg:items-center">
            <ul class="flex-1 space-y-2.5 text-sm text-zinc-600 dark:text-zinc-400">
              <li class="flex items-start gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary shrink-0 mt-2"></span>
                同一个邀请链接可以不限次重复使用，最多可以创建5个链接。
              </li>
              <li class="flex items-start gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary shrink-0 mt-2"></span>
                佣金满200元即可提现，也可以转入到您的账户中消费（没有金额要求）。
              </li>
              <li class="flex items-start gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary shrink-0 mt-2"></span>
                我们每周五统一处理提现申请，请在每周四23:59之前提出申请，否则您的申请会延至下一个周五处理。
              </li>
              <li class="flex items-start gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary shrink-0 mt-2"></span>
                如果您是网站主或者拥有稳定的资源，我们欢迎与您展开深入合作并考虑调整您的佣金比例，请联系我们的客服。
              </li>
            </ul>
            <div class="flex justify-center lg:justify-end">
              <img
                src="/assets/illustrations/undraw_having-fun_kkeu.svg"
                alt="邀请"
                class="w-32 h-32 sm:w-40 sm:h-40 object-contain"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- 佣金卡片 -->
      <Cash v-if="invite.stat" :cash="invite.stat[4] || 0" :update="update" />

      <!-- 统计卡片 -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <Card
          v-for="(stat, index) in statCards"
          :key="index"
          class="border-zinc-200 dark:border-zinc-800"
        >
          <CardContent class="p-5">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 mb-1">{{ stat.label }}</p>
                <div class="flex items-baseline gap-1">
                  <span class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 font-[Rubik,ui-sans-serif,system-ui,sans-serif]">
                    {{ stat.value }}
                  </span>
                  <span class="text-sm text-zinc-500 dark:text-zinc-400">{{ stat.unit }}</span>
                </div>
              </div>
              <div class="w-10 h-10 rounded-xl bg-primary/10 dark:bg-primary/20 flex items-center justify-center">
                <component :is="stat.icon" class="w-5 h-5 text-primary" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- 邀请链接管理 -->
      <Card class="border-zinc-200 dark:border-zinc-800 mb-8">
        <CardHeader class="pb-4">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <CardTitle class="text-lg">邀请链接</CardTitle>
              <CardDescription>同一个邀请链接可以不限次重复使用，最多可创建5个</CardDescription>
            </div>
            <TooltipProvider v-if="!canCreateInvite">
              <Tooltip>
                <TooltipTrigger asChild>
                  <span>
                    <Button disabled class="gap-2">
                      <Plus class="w-4 h-4" />
                      创建邀请链接
                    </Button>
                  </span>
                </TooltipTrigger>
                <TooltipContent>
                  <p>您最多只能创建5个邀请链接</p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
            <Button v-else @click="generateCode" class="gap-2">
              <Plus class="w-4 h-4" />
              创建邀请链接
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <!-- 加载状态 -->
          <div v-if="loading" class="flex items-center justify-center py-12">
            <Loader2 class="w-6 h-6 text-primary animate-spin" />
          </div>

          <!-- 空状态 -->
          <div v-else-if="invite.codes.length === 0" class="flex flex-col items-center justify-center py-12 text-center">
            <div class="w-14 h-14 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mb-3">
              <Link2 class="w-7 h-7 text-zinc-400" />
            </div>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-4">暂无邀请链接</p>
            <Button @click="generateCode" variant="outline" class="gap-2">
              <Plus class="w-4 h-4" />
              创建第一个邀请链接
            </Button>
          </div>

          <!-- 链接列表 -->
          <div v-else class="space-y-3">
            <div
              v-for="(item, index) in invite.codes"
              :key="index"
              class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-lg"
            >
              <div class="flex-1 min-w-0">
                <p class="text-sm font-mono text-zinc-900 dark:text-zinc-100 truncate">
                  {{ baseUrl }}{{ item.code }}
                </p>
                <p v-if="item.created_at" class="text-xs text-zinc-500 dark:text-zinc-400 mt-1 flex items-center gap-1">
                  <Calendar class="w-3 h-3" />
                  {{ formatDate(item.created_at) }}
                </p>
              </div>
              <Button variant="outline" size="sm" @click="copyLink(item.code)" class="gap-1.5 shrink-0">
                <Copy class="w-4 h-4" />
                复制链接
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- 邀请明细 -->
      <Card class="border-zinc-200 dark:border-zinc-800 mb-8">
        <CardHeader class="pb-4">
          <CardTitle class="text-lg">邀请明细</CardTitle>
          <CardDescription>查看您邀请的用户及获得的佣金</CardDescription>
        </CardHeader>
        <CardContent>
          <People />
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { message } from 'ant-design-vue';
import moment from 'moment';
import { getInviteData, generateInviteCode } from '@/api/invite.js';
import { useUserStore } from '@/stores/User.js';

// Shadcn Vue 组件
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

// Lucide Icons
import {
  Share2,
  UserPlus,
  Coins,
  Wallet,
  Plus,
  Loader2,
  Link2,
  Copy,
  Calendar,
  Info,
  Users,
  Percent,
  Clock,
} from 'lucide-vue-next';

// 子组件
import Cash from '@/views/Invite/components/Cash.vue';
import People from '@/views/Invite/components/people.vue';

const user = useUserStore();

// 定义基地址
const baseUrl = 'https://lray.dlgisea.com/#/register?code=';

// 数据
const loading = ref(true);
const invite = ref<{
  codes: { code: string; created_at: number }[];
  stat?: number[];
}>({
  codes: [],
  stat: undefined,
});

// 步骤说明
const steps = computed(() => [
  {
    icon: Share2,
    title: '分享邀请链接',
    desc: '向您的亲朋好友或社交平台分享您的邀请链接',
  },
  {
    icon: UserPlus,
    title: '推荐人注册',
    desc: `推荐的新用户首次购买可获得 ${invite.value.stat?.[3] || '--'}% 佣金`,
  },
  {
    icon: Coins,
    title: '收到奖金',
    desc: `我们会在3天内将 ${invite.value.stat?.[3] || '--'}% 佣金计入您的账户`,
  },
  {
    icon: Wallet,
    title: '提现奖金',
    desc: '满200即可提现，我们通过USDT发放您的奖金',
  },
]);

// 统计卡片
const statCards = computed(() => [
  {
    label: '已注册用户数',
    value: invite.value.stat?.[0] || 0,
    unit: '人',
    icon: Users,
  },
  {
    label: '佣金比例',
    value: invite.value.stat?.[3] || 0,
    unit: '%',
    icon: Percent,
  },
  {
    label: '确认中的佣金',
    value: ((invite.value.stat?.[2] || 0) / 100).toFixed(2),
    unit: user.Config?.currency || '¥',
    icon: Clock,
  },
  {
    label: '累计获得佣金',
    value: ((invite.value.stat?.[1] || 0) / 100).toFixed(2),
    unit: user.Config?.currency || '¥',
    icon: Coins,
  },
]);

// 计算是否可以创建新的邀请链接
const canCreateInvite = computed(() => invite.value.codes.length < 5);

// 更新数据
const update = () => {
  loading.value = true;
  getInviteData()
    .then((res: any) => {
      if (res.data.codes) {
        invite.value.codes = res.data.codes.map((codeObj: any) => ({
          code: codeObj.code || codeObj,
          created_at: codeObj.created_at || null,
        }));
      }
      invite.value.stat = res.data.stat;
    })
    .catch(() => {
      message.error('获取邀请数据失败');
    })
    .finally(() => {
      loading.value = false;
    });
};

// 生成邀请码
const generateCode = () => {
  if (!canCreateInvite.value) return;

  generateInviteCode()
    .then(() => {
      message.success('邀请码生成成功');
      update();
    })
    .catch(() => {
      message.error('生成邀请码失败');
    });
};

// 复制链接
const copyLink = async (code: string) => {
  const link = baseUrl + code;
  try {
    await navigator.clipboard.writeText(link);
    message.success('链接已复制到剪贴板');
  } catch {
    message.error('复制失败，请手动复制');
  }
};

// 格式化日期
const formatDate = (timestamp: number) => {
  return moment(timestamp * 1000).format('YYYY-MM-DD HH:mm');
};

onMounted(() => {
  update();
});
</script>

<style scoped>
</style>
