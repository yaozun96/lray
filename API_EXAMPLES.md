# V2Board API 使用示例

本文档提供常见场景的 API 调用示例。

## 📦 导入方式

```javascript
// 方式 1: 按需导入具体函数
import { login, register, logout } from '@/api/auth'
import { getUserInfo, changePassword } from '@/api/user'
import { fetchPlans, submitOrder } from '@/api/shop'

// 方式 2: 导入整个模块
import * as authApi from '@/api/auth'
import * as userApi from '@/api/user'
import * as shopApi from '@/api/shop'
```

## 🔐 认证场景

### 1. 用户注册流程

```javascript
import { sendEmailVerify, register } from '@/api/auth'

// 步骤 1: 发送邮箱验证码
async function sendCode() {
  try {
    await sendEmailVerify({
      email: 'user@example.com',
      isForgetPassword: false
    })
    console.log('验证码已发送')
  } catch (error) {
    console.error('发送失败:', error.message)
  }
}

// 步骤 2: 注册账号
async function registerUser() {
  try {
    const response = await register({
      email: 'user@example.com',
      password: 'Password123',
      email_code: '123456',
      invite_code: 'ABC123' // 可选
    })
    console.log('注册成功:', response.data)
    // 注册成功后会自动登录，auth_data 已存储
  } catch (error) {
    console.error('注册失败:', error.message)
  }
}
```

### 2. 用户登录

```javascript
import { login } from '@/api/auth'

async function userLogin() {
  try {
    const response = await login({
      email: 'user@example.com',
      password: 'Password123'
    })
    console.log('登录成功')
    // auth_data 和 token 已自动存储到 localStorage
  } catch (error) {
    console.error('登录失败:', error.message)
  }
}
```

### 3. 重置密码

```javascript
import { sendEmailVerify, resetPassword } from '@/api/auth'

async function resetUserPassword() {
  // 步骤 1: 发送验证码
  await sendEmailVerify({
    email: 'user@example.com',
    isForgetPassword: true
  })

  // 步骤 2: 重置密码
  try {
    await resetPassword({
      email: 'user@example.com',
      password: 'NewPassword123',
      email_code: '123456'
    })
    console.log('密码重置成功')
  } catch (error) {
    console.error('重置失败:', error.message)
  }
}
```

### 4. 登出

```javascript
import { logout } from '@/api/auth'

function userLogout() {
  logout() // 自动清除所有认证数据并刷新页面
}
```

## 👤 用户信息管理

### 1. 获取用户信息

```javascript
import { getUserInfo } from '@/api/user'

async function fetchUser() {
  try {
    const response = await getUserInfo()
    const user = response.data.data
    console.log('用户信息:', {
      email: user.email,
      balance: user.balance,
      commission: user.commission
    })
  } catch (error) {
    console.error('获取失败:', error.message)
  }
}
```

### 2. 修改密码

```javascript
import { changePassword } from '@/api/user'

async function updatePassword() {
  try {
    await changePassword({
      old_password: 'OldPassword123',
      new_password: 'NewPassword123'
    })
    console.log('密码修改成功')
  } catch (error) {
    console.error('修改失败:', error.message)
  }
}
```

### 3. 兑换礼品卡

```javascript
import { redeemGiftCard } from '@/api/user'

async function redeemCard() {
  try {
    await redeemGiftCard('GIFT-CODE-123456')
    console.log('兑换成功')
  } catch (error) {
    console.error('兑换失败:', error.message)
  }
}
```

## 📊 仪表盘数据

### 1. 获取用户统计

```javascript
import { getUserStats, getSubscribe } from '@/api/dashboard'

async function loadDashboard() {
  try {
    // 获取统计数据
    const statsResponse = await getUserStats()
    const stats = statsResponse.data.data
    console.log('统计数据:', stats)

    // 获取订阅信息
    const subResponse = await getSubscribe()
    const subscription = subResponse.data.data
    console.log('订阅信息:', subscription)
  } catch (error) {
    console.error('加载失败:', error.message)
  }
}
```

### 2. 获取公告列表

```javascript
import { getNotices } from '@/api/dashboard'

async function loadNotices() {
  try {
    const response = await getNotices()
    const notices = response.data.data
    notices.forEach(notice => {
      console.log(`${notice.title}: ${notice.content}`)
    })
  } catch (error) {
    console.error('获取公告失败:', error.message)
  }
}
```

## 🛒 购买流程

### 1. 查看套餐列表

```javascript
import { fetchPlans } from '@/api/shop'

async function loadPlans() {
  try {
    const response = await fetchPlans()
    const plans = response.data.data
    plans.forEach(plan => {
      console.log(`${plan.name}: ¥${plan.month_price}/月`)
    })
  } catch (error) {
    console.error('获取套餐失败:', error.message)
  }
}
```

### 2. 验证优惠券

```javascript
import { verifyCoupon } from '@/api/shop'

async function checkCoupon() {
  try {
    const response = await verifyCoupon('DISCOUNT10', 1) // planId = 1
    const coupon = response.data.data
    console.log('优惠券有效，折扣:', coupon.discount)
  } catch (error) {
    console.error('优惠券无效:', error.message)
  }
}
```

### 3. 创建订单

```javascript
import { submitOrder } from '@/api/shop'

async function createOrder() {
  try {
    const response = await submitOrder({
      plan_id: 1,
      period: 'month_price',
      coupon_code: 'DISCOUNT10' // 可选
    })
    const order = response.data.data
    console.log('订单创建成功:', order.trade_no)
    return order.trade_no
  } catch (error) {
    console.error('创建订单失败:', error.message)
  }
}
```

### 4. 获取支付方式

```javascript
import { getPaymentMethods } from '@/api/shop'

async function loadPaymentMethods() {
  try {
    const response = await getPaymentMethods()
    const methods = response.data.data
    methods.forEach(method => {
      console.log(`${method.name} - ${method.id}`)
    })
  } catch (error) {
    console.error('获取支付方式失败:', error.message)
  }
}
```

### 5. 结算订单

```javascript
import { checkoutOrder, checkOrderStatus } from '@/api/shop'

async function payOrder(tradeNo) {
  try {
    // 结算订单（选择支付方式）
    const response = await checkoutOrder(tradeNo, 1) // methodId = 1
    const paymentData = response.data.data
    console.log('支付信息:', paymentData)

    // 轮询检查订单状态
    const checkStatus = setInterval(async () => {
      const statusResponse = await checkOrderStatus(tradeNo)
      const status = statusResponse.data.data.status
      
      if (status === 1) {
        console.log('支付成功')
        clearInterval(checkStatus)
      } else if (status === 2) {
        console.log('支付失败')
        clearInterval(checkStatus)
      }
    }, 2000)
  } catch (error) {
    console.error('结算失败:', error.message)
  }
}
```

### 6. 完整购买流程示例

```javascript
import { fetchPlans, submitOrder, getPaymentMethods, checkoutOrder } from '@/api/shop'

async function completePurchaseFlow() {
  try {
    // 1. 获取套餐列表
    const plansResponse = await fetchPlans()
    const plans = plansResponse.data.data
    const selectedPlan = plans[0] // 选择第一个套餐

    // 2. 创建订单
    const orderResponse = await submitOrder({
      plan_id: selectedPlan.id,
      period: 'month_price'
    })
    const tradeNo = orderResponse.data.data.trade_no

    // 3. 获取支付方式
    const methodsResponse = await getPaymentMethods()
    const methods = methodsResponse.data.data
    const selectedMethod = methods[0] // 选择第一个支付方式

    // 4. 结算订单
    const checkoutResponse = await checkoutOrder(tradeNo, selectedMethod.id)
    const paymentUrl = checkoutResponse.data.data.payment_url

    // 5. 跳转到支付页面
    window.location.href = paymentUrl
  } catch (error) {
    console.error('购买流程失败:', error.message)
  }
}
```

## 📝 订单管理

### 1. 获取订单列表

```javascript
import { fetchOrderList } from '@/api/orderlist'

async function loadOrders() {
  try {
    const response = await fetchOrderList()
    const orders = response.data.data
    orders.forEach(order => {
      console.log(`订单: ${order.trade_no}, 状态: ${order.status}`)
    })
  } catch (error) {
    console.error('获取订单失败:', error.message)
  }
}
```

### 2. 取消订单

```javascript
import { cancelOrder } from '@/api/orderlist'

async function cancelMyOrder(tradeNo) {
  try {
    await cancelOrder(tradeNo)
    console.log('订单已取消')
  } catch (error) {
    console.error('取消失败:', error.message)
  }
}
```

## 🎫 工单系统

### 1. 创建工单

```javascript
import { createTicket } from '@/api/ticket'

async function submitTicket() {
  try {
    await createTicket({
      subject: '无法连接节点',
      level: 1, // 优先级：1=低，2=中，3=高
      message: '节点 HK-01 无法连接，已尝试重启客户端'
    })
    console.log('工单创建成功')
  } catch (error) {
    console.error('创建失败:', error.message)
  }
}
```

### 2. 获取工单列表

```javascript
import { fetchTicketList } from '@/api/ticket'

async function loadTickets() {
  try {
    const response = await fetchTicketList()
    const tickets = response.data.data
    tickets.forEach(ticket => {
      console.log(`${ticket.subject} - 状态: ${ticket.status}`)
    })
  } catch (error) {
    console.error('获取工单失败:', error.message)
  }
}
```

### 3. 回复工单

```javascript
import { replyTicket } from '@/api/ticket'

async function replyToTicket(ticketId) {
  try {
    await replyTicket(ticketId, '已尝试更换节点，问题解决')
    console.log('回复成功')
  } catch (error) {
    console.error('回复失败:', error.message)
  }
}
```

## 🎁 邀请系统

### 1. 获取邀请数据

```javascript
import { getInviteData, generateInviteCode } from '@/api/invite'

async function loadInviteInfo() {
  try {
    // 获取邀请统计
    const response = await getInviteData()
    const data = response.data.data
    console.log('邀请统计:', {
      总数: data.total,
      佣金: data.commission
    })

    // 生成新的邀请码
    const codeResponse = await generateInviteCode()
    const inviteCode = codeResponse.data.data.code
    console.log('邀请码:', inviteCode)
  } catch (error) {
    console.error('获取失败:', error.message)
  }
}
```

### 2. 佣金转账

```javascript
import { transferCommission } from '@/api/invite'

async function transferToBalance() {
  try {
    await transferCommission(100) // 转100元到余额
    console.log('转账成功')
  } catch (error) {
    console.error('转账失败:', error.message)
  }
}
```

## 🌐 服务器节点

### 1. 获取节点列表

```javascript
import { fetchServerNodes } from '@/api/servers'

async function loadNodes() {
  try {
    const response = await fetchServerNodes()
    const nodes = response.data.data
    nodes.forEach(node => {
      console.log(`${node.name} - ${node.rate}`)
    })
  } catch (error) {
    console.error('获取节点失败:', error.message)
  }
}
```

## 📈 流量日志

### 1. 获取流量日志

```javascript
import { getTrafficLog } from '@/api/trafficLog'

async function loadTrafficLog() {
  try {
    const response = await getTrafficLog()
    const logs = response.data.data
    logs.forEach(log => {
      console.log(`${log.date}: ${log.traffic}GB`)
    })
  } catch (error) {
    console.error('获取日志失败:', error.message)
  }
}
```

## 💰 钱包充值

### 1. 创建充值订单

```javascript
import { createOrderDeposit } from '@/api/wallet'

async function depositMoney() {
  try {
    const response = await createOrderDeposit(100) // 充值100元
    const order = response.data.data
    console.log('充值订单:', order.trade_no)
    // 后续流程同购买套餐的支付流程
  } catch (error) {
    console.error('创建充值订单失败:', error.message)
  }
}
```

## 🔧 错误处理

### 标准错误处理模式

```javascript
import { getUserInfo } from '@/api/user'

async function safeGetUserInfo() {
  try {
    const response = await getUserInfo()
    return response.data.data
  } catch (error) {
    // 错误对象包含以下属性：
    // - error.message: 错误消息
    // - error.status: HTTP 状态码
    // - error.data: 响应数据
    // - error.response: 完整响应对象

    if (error.status === 401) {
      console.log('未授权，请重新登录')
      // 跳转到登录页
    } else if (error.status === 403) {
      console.log('无权限')
    } else {
      console.log('错误:', error.message)
    }
    
    return null
  }
}
```

## 📱 在 Vue 组件中使用

### Composition API 示例

```vue
<script setup>
import { ref, onMounted } from 'vue'
import { getUserInfo } from '@/api/user'
import { fetchPlans } from '@/api/shop'

const user = ref(null)
const plans = ref([])
const loading = ref(false)

onMounted(async () => {
  await loadData()
})

async function loadData() {
  loading.value = true
  try {
    // 并发请求
    const [userResponse, plansResponse] = await Promise.all([
      getUserInfo(),
      fetchPlans()
    ])
    
    user.value = userResponse.data.data
    plans.value = plansResponse.data.data
  } catch (error) {
    console.error('加载失败:', error.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div v-if="loading">加载中...</div>
  <div v-else>
    <div>用户: {{ user?.email }}</div>
    <div>套餐数量: {{ plans.length }}</div>
  </div>
</template>
```

## 💡 最佳实践

1. **使用 try-catch**: 始终使用 try-catch 处理 API 调用
2. **显示加载状态**: 在请求期间显示加载指示器
3. **错误提示**: 向用户显示友好的错误消息
4. **并发请求**: 对独立的请求使用 Promise.all
5. **响应式数据**: 在 Vue 组件中使用 ref 存储 API 响应
