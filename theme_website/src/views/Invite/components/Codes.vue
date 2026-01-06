<script setup>
import moment from "moment";
import ClipboardJS from "clipboard";
import { message } from 'ant-design-vue';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Loader2 } from 'lucide-vue-next';

const pop = defineProps(['codes']);

const copyLink = async (e, code) => {
  const link = window.location.host + '/#/login?code=' + code;
  const res = ClipboardJS.copy(link);

  if (res === link) {
    message.success('复制成功');
  } else {
    message.error('复制失败');
  }
};
</script>

<template>
  <div v-if="!codes" class="flex items-center justify-center py-8">
    <Loader2 class="w-6 h-6 animate-spin text-primary" />
  </div>
  <Table v-else>
    <TableHeader>
      <TableRow>
        <TableHead>邀请链接</TableHead>
        <TableHead>创建时间</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow v-for="record in codes" :key="record.code">
        <TableCell>
          <span
            @click="copyLink($event, record.code)"
            class="text-primary hover:opacity-85 cursor-pointer font-medium"
          >
            复制链接
          </span>
        </TableCell>
        <TableCell class="text-zinc-500 dark:text-zinc-400">
          {{ moment(record.created_at * 1000).format('YYYY-MM-DD HH:mm:ss') }}
        </TableCell>
      </TableRow>
      <TableRow v-if="codes.length === 0">
        <TableCell colspan="2" class="text-center text-zinc-500 dark:text-zinc-400 py-8">
          暂无邀请链接
        </TableCell>
      </TableRow>
    </TableBody>
  </Table>
</template>
