# Xboard API 重构说明

本项目已从 PLray API 迁移到 Xboard API。以下是重构的详细说明。

## 配置 API 地址

在使用前，需要配置 Xboard 后端的 API 地址：

```dart
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';

// 设置 API 基础 URL
XboardConfig.setApiBaseUrl('https://your-xboard-domain.com');
```

## 新增文件结构

### 配置文件
- `lib/soravpn_ui/config/xboard_config.dart` - Xboard API 配置

### 数据模型
- `lib/soravpn_ui/models/xboard_user.dart` - 用户模型
- `lib/soravpn_ui/models/xboard_subscribe.dart` - 订阅模型
- `lib/soravpn_ui/models/xboard_plan.dart` - 套餐模型
- `lib/soravpn_ui/models/xboard_order.dart` - 订单模型
- `lib/soravpn_ui/models/xboard_ticket.dart` - 工单模型
- `lib/soravpn_ui/models/xboard_invite.dart` - 邀请模型
- `lib/soravpn_ui/models/xboard_server.dart` - 服务器节点模型
- `lib/soravpn_ui/models/xboard_notice.dart` - 公告和知识库模型
- `lib/soravpn_ui/models/xboard_models.dart` - 模型导出文件

### 服务层
- `lib/soravpn_ui/services/xboard_http_client.dart` - HTTP 客户端
- `lib/soravpn_ui/services/xboard_auth_service.dart` - 认证服务
- `lib/soravpn_ui/services/xboard_user_service.dart` - 用户服务
- `lib/soravpn_ui/services/xboard_order_service.dart` - 订单服务
- `lib/soravpn_ui/services/xboard_ticket_service.dart` - 工单服务
- `lib/soravpn_ui/services/xboard_invite_service.dart` - 邀请服务
- `lib/soravpn_ui/services/xboard_server_service.dart` - 服务器节点服务
- `lib/soravpn_ui/services/xboard_services.dart` - 服务导出文件
- `lib/soravpn_ui/services/xboard_adapter.dart` - 兼容层适配器

## API 端点对应关系

| 功能 | PLray API | Xboard API |
|------|------------|------------|
| 登录 | `/v1/auth/login` | `/api/v1/passport/auth/login` |
| 注册 | `/v1/auth/register` | `/api/v1/passport/auth/register` |
| 重置密码 | `/v1/auth/reset` | `/api/v1/passport/auth/forget` |
| 发送验证码 | `/v1/common/send_code` | `/api/v1/passport/comm/sendEmailVerify` |
| 用户信息 | `/v1/public/user/info` | `/api/v1/user/info` |
| 订阅信息 | `/v1/public/user/subscribe` | `/api/v1/user/getSubscribe` |
| 套餐列表 | `/v1/public/portal/subscribe` | `/api/v1/user/plan/fetch` |
| 创建订单 | `/v1/public/order/purchase` | `/api/v1/user/order/save` |
| 订单列表 | `/v1/public/order/list` | `/api/v1/user/order/fetch` |
| 支付方式 | `/v1/public/portal/payment-method` | `/api/v1/user/order/getPaymentMethod` |
| 支付订单 | `/v1/public/portal/order/checkout` | `/api/v1/user/order/checkout` |
| 工单列表 | `/v1/public/ticket/list` | `/api/v1/user/ticket/fetch` |
| 创建工单 | `/v1/public/ticket/` | `/api/v1/user/ticket/save` |
| 服务器节点 | `/v1/public/subscribe/node/list` | `/api/v1/user/server/fetch` |
| 邀请信息 | N/A | `/api/v1/user/invite/fetch` |
| 公告列表 | N/A | `/api/v1/user/notice/fetch` |

## 使用新 API

### 方式 1: 直接使用新服务 (推荐)

```dart
import 'package:fl_clash/soravpn_ui/services/xboard_services.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';

// 登录
await XboardAuthService.login(email: 'user@example.com', password: '123456');

// 获取用户信息
final user = await XboardUserService.getUserInfo();
print('余额: ${user.balanceYuan}');
print('流量: ${XboardUser.formatTraffic(user.usedTraffic)} / ${XboardUser.formatTraffic(user.totalTraffic)}');

// 获取订阅信息
final subscribe = await XboardUserService.getSubscribe();
print('订阅链接: ${subscribe.subscribeUrl}');

// 获取套餐列表
final plans = await XboardOrderService.getPlans();
for (final plan in plans) {
  print('${plan.name}: ${plan.availablePeriods.map((p) => p.formattedPrice).join(', ')}');
}

// 创建订单
final order = await XboardOrderService.createOrder(
  planId: 1,
  period: 'month_price',
);
print('订单号: ${order.tradeNo}');

// 支付订单
final payment = await XboardOrderService.checkoutOrder(
  tradeNo: order.tradeNo,
  methodId: 1,
);
if (payment.isRedirectPay) {
  // 跳转到支付链接
  launchUrl(payment.data!);
}
```

### 方式 2: 使用兼容层 (过渡期)

旧的服务类 (AuthService, SubscribeService 等) 已被修改为兼容层，
它们内部调用新的 Xboard 服务。现有代码可以继续工作，但建议逐步迁移到新 API。

```dart
// 旧代码 - 仍然可以工作
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
await AuthService.login('user@example.com', '123456');

// 新代码 - 推荐使用
import 'package:fl_clash/soravpn_ui/services/xboard_auth_service.dart';
await XboardAuthService.login(email: 'user@example.com', password: '123456');
```

## 不支持的功能

以下 PLray 功能在 Xboard 中可能不支持：

1. **OAuth 登录** - Xboard 标准版不支持 OAuth
2. **退订预览** - Xboard 不支持直接退订
3. **充值** - Xboard 使用不同的充值流程
4. **通知设置** - Xboard 可能不支持自定义通知设置

## 数据格式差异

### 金额
- PLray: 以分为单位
- Xboard: 以分为单位
- 转换: 无需转换，但显示时记得除以 100

### 流量
- PLray: bytes
- Xboard: bytes (transfer_enable 可能是 GB)
- 使用 `XboardUser.formatTraffic()` 格式化显示

### 时间戳
- PLray: 毫秒
- Xboard: 秒
- 模型中已处理转换

## 注意事项

1. **Token 格式** - Xboard 返回 `auth_data` 作为 Token，需要在请求头中使用 `Authorization: auth_data_value`

2. **Content-Type** - Xboard API 使用 `application/x-www-form-urlencoded` 而不是 `application/json`

3. **响应格式** - Xboard 响应格式:
   ```json
   {
     "status": "success",
     "message": "...",
     "data": {...}
   }
   ```

4. **订阅链接** - Xboard 的订阅链接可以添加 `flag=clash` 或 `flag=singbox` 参数获取对应格式

## 测试清单

- [ ] 登录/注册功能
- [ ] 用户信息获取
- [ ] 订阅信息获取
- [ ] 节点列表获取
- [ ] 订阅链接同步到 FlClash
- [ ] 套餐列表获取
- [ ] 创建订单
- [ ] 支付流程
- [ ] 工单系统
- [ ] 邀请功能

## 问题排查

如果遇到问题，请检查：

1. API 基础 URL 是否正确配置
2. Token 是否正确保存和发送
3. 请求格式是否正确 (form-urlencoded)
4. 控制台日志中的错误信息
