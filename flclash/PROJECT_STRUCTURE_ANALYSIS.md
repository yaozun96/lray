# FLCLASH 项目完整结构分析

## 项目概览
**项目路径**: `/Users/dylanhu/Desktop/lray/flclash`
**项目类型**: Flutter 跨平台 VPN 客户端 (SoraVPN)
**总计 Dart 文件**: 244 个

---

## 1. 项目顶级目录结构

```
flclash/
├── lib/                    # 主应用代码
├── core/                   # Clash Meta 核心 (Go 语言)
├── services/              # 辅助服务
├── android/               # Android 原生代码
├── ios/                   # iOS 原生代码
├── macos/                 # macOS 原生代码
├── linux/                 # Linux 原生代码
├── windows/               # Windows 原生代码
├── plugins/               # 第三方插件和分发工具
├── pubspec.yaml          # Flutter 依赖配置
└── setup.dart            # 初始化脚本
```

---

## 2. lib 目录详细结构

### 2.1 核心层级
```
lib/
├── main.dart                 # 应用入口
├── application.dart          # 应用程序初始化
├── controller.dart           # 全局控制器 (30KB)
├── state.dart                # 全局状态管理
├── soravpn_ui/              # SoraVPN UI 模块 (新增)
├── views/                   # 主应用 UI 视图
├── pages/                   # 页面层
├── widgets/                 # 通用组件
├── manager/                 # 业务管理层 (13 个管理器)
├── models/                  # 数据模型
├── providers/               # Riverpod 状态管理
├── common/                  # 通用工具和服务 (48 个工具)
├── core/                    # 核心服务
├── enum/                    # 枚举定义
├── plugins/                 # 插件集成
└── l10n/                    # 国际化配置
```

---

## 3. SoraVPN UI 模块详细结构

**路径**: `lib/soravpn_ui/`
**文件数**: 53 个 Dart 文件
**用途**: 完整的 VPN 客户端用户界面和业务逻辑

### 3.1 子目录结构

#### 3.1.1 Services 层 (10 个服务 + 1 个辅助)
```
services/
├── auth_service.dart              # 用户认证 (293 行)
│   ├── Login (邮箱/密码)
│   ├── Register (邮箱注册)
│   ├── Password Reset (邮箱重置)
│   ├── OAuth Support (多平台)
│   └── Token Management (JWT)
│
├── subscribe_service.dart         # 订阅管理 (32KB)
│   ├── Sing-box 配置获取
│   ├── 节点列表获取
│   ├── 分组节点管理
│   ├── Unsubscribe (退订)
│   └── 订阅配置同步到 FlClash
│
├── user_service.dart              # 用户信息服务 (200 行)
│   ├── OAuth 方法查询
│   ├── OAuth 账号绑定/解绑
│   ├── 密码更新
│   ├── 邮箱绑定
│   └── 通知设置更新
│
├── purchase_service.dart          # 购买订阅服务 (362 行)
│   ├── Get Plans (套餐列表)
│   ├── Get Payment Methods (支付方式)
│   ├── Order Preview (订单预览)
│   ├── Purchase (创建订单)
│   ├── Renewal (续费)
│   ├── Order Status (查询订单)
│   └── Payment Checkout (获取支付链接/二维码)
│
├── order_service.dart             # 订单充值服务 (145 行)
│   ├── Payment Methods (支付方式)
│   ├── Create Recharge Order (充值)
│   ├── Order Detail (订单详情)
│   └── Payment Checkout (支付链接)
│
├── ticket_service.dart            # 工单管理 (130+ 行)
│   ├── Get Tickets (获取工单列表)
│   ├── Get Ticket Detail (工单详情)
│   ├── Create Ticket (创建工单)
│   ├── Follow Up (跟进工单)
│   └── Close Ticket (关闭工单)
│
├── announcement_service.dart      # 公告服务 (149 行)
│   ├── Get Announcements (公告列表)
│   ├── Get Pinned Announcement (置顶公告)
│   └── Filter (按置顶/弹窗过滤)
│
├── affiliate_service.dart         # 邀请返利服务 (111 行)
│   ├── Get Summary (返利统计)
│   └── Get Records (邀请记录)
│
├── config_service.dart            # 全局配置服务 (115 行)
│   ├── Load Site Config
│   ├── Currency Symbol & Unit
│   ├── Auth Config
│   ├── Verify Config
│   └── OAuth Methods
│
├── vpn_service.dart               # VPN 操作服务 (146 行)
│   ├── Connect/Disconnect
│   ├── Proxy Mode Selection
│   ├── Group Selection Management
│   └── FlClash 桥接
│
└── platform_proxy_helper.dart    # 平台代理辅助
```

#### 3.1.2 Models 层 (8 个模型)
```
models/
├── plan.dart                    # 套餐模型 (225 行)
│   ├── Plan (套餐信息)
│   ├── PlanCycle (套餐周期)
│   ├── PlanPrice (价格信息)
│   └── OrderPreview (订单预览)
│
├── order.dart                   # 订单模型 (126 行)
│   ├── Order (订单信息)
│   └── 订单状态枚举
│
├── payment_method.dart          # 支付方式模型 (53 行)
│   └── PaymentMethod
│
├── ticket.dart                  # 工单模型 (78 行)
│   ├── Ticket (工单信息)
│   └── 状态枚举 (待处理/处理中/已回复/已关闭)
│
├── ticket_message.dart          # 工单消息模型 (53 行)
│   └── TicketMessage
│
├── node_group.dart              # 节点分组模型 (41 行)
│   └── NodeGroup
│
├── routing_group.dart           # 路由分组模型 (12 行)
│   └── RoutingGroup
│
└── proxy_mode.dart              # 代理模式枚举 (11 行)
    ├── smart (规则代理)
    └── global (全局代理)
```

#### 3.1.3 Screens 层 (11 个屏幕)
```
screens/
├── auth_wrapper.dart              # 认证包装器 (路由守卫)
├── auth_screen.dart               # 认证屏幕 (登录/注册)
├── home_screen.dart               # 主屏幕
├── dashboard_screen.dart          # 仪表板
├── plans_screen.dart              # 套餐列表
├── purchasing_screen.dart         # 购买流程
├── order_payment_screen.dart       # 支付屏幕
├── order_detail_screen.dart        # 订单详情
├── settings_screen.dart           # 设置屏幕
├── invite_screen.dart             # 邀请屏幕
│
└── ticket/
    ├── ticket_list_page.dart      # 工单列表
    ├── ticket_detail_page.dart    # 工单详情
    ├── create_ticket_page.dart    # 创建工单
    └── crisp_web_page.dart        # Crisp 聊天集成
```

#### 3.1.4 Widgets 层 (13 个组件)
```
widgets/
├── auth/                          # 认证相关组件
│   ├── login_form.dart
│   ├── register_form.dart
│   ├── forgot_password_form.dart
│   ├── oauth_buttons.dart
│   └── oauth_webview.dart
│
├── auth_split_layout.dart         # 分割布局 (认证)
├── auth_carousel_panel.dart       # 轮播面板
├── subscription_card.dart         # 订阅卡片
├── announcement_dialog.dart       # 公告对话框
├── popup_announcement_dialog.dart # 弹窗公告
├── node_selection_dialog.dart     # 节点选择对话框
├── sidebar.dart                   # 侧边栏
├── traffic_chart.dart             # 流量图表
├── starry_night_background.dart   # 星夜背景
├── world_map_background.dart      # 世界地图背景
└── world_map_background_v2.dart   # 世界地图背景 v2
```

#### 3.1.5 Config & Theme
```
config/
└── app_config.dart                # API 和网站配置

theme/
└── app_theme.dart                 # 应用主题

soravpn_entry.dart                # SoraVPN 模块入口
```

---

## 4. API 端点汇总 (PLray 相关)

**基础 URL**: `https://apiserver.taptaro.com`

### 4.1 认证相关 (AuthService)
```
POST   /v1/auth/login                  # 登录
POST   /v1/auth/register               # 注册
POST   /v1/auth/reset                  # 重置密码
POST   /v1/common/send_code            # 发送验证码
GET    /v1/public/user/info            # 获取用户信息
POST   /v1/auth/login/oauth            # OAuth 登录初始化
POST   /v1/auth/login/oauth/token      # OAuth Token 交换
```

### 4.2 订阅相关 (SubscribeService)
```
GET    /api/subscribe?token=<token>&type=singbox        # 获取 Sing-box 配置
GET    /v1/public/subscribe/node/list                   # 获取节点列表
GET    /v1/public/user/subscribe                        # 获取订阅信息
POST   /v1/public/user/unsubscribe/pre                  # 退订预检
POST   /v1/public/user/unsubscribe                      # 执行退订
```

### 4.3 购买相关 (PurchaseService)
```
GET    /v1/public/portal/subscribe                      # 获取套餐列表
GET    /v1/public/portal/payment-method                 # 获取支付方式
POST   /v1/public/order/pre                             # 订单预览 (已登录)
POST   /v1/public/portal/pre                            # 订单预览 (游客)
POST   /v1/public/order/purchase                        # 创建订单 (已登录)
POST   /v1/public/portal/purchase                       # 创建订单 (游客)
POST   /v1/public/order/renewal                         # 续费订阅
GET    /v1/public/order/detail?order_no=<no>           # 订单详情
GET    /v1/public/portal/order/status                   # 订单状态 (游客)
POST   /v1/public/portal/order/checkout                 # 获取支付链接/二维码
```

### 4.4 充值相关 (OrderService)
```
GET    /v1/public/portal/payment-method?scene=recharge  # 充值支付方式
POST   /v1/public/order/recharge                        # 创建充值订单
GET    /v1/public/order/detail?order_no=<no>           # 订单详情
POST   /v1/public/portal/order/checkout                 # 支付链接
```

### 4.5 工单相关 (TicketService)
```
GET    /v1/public/ticket/list                           # 获取工单列表
GET    /v1/public/ticket/detail?id=<id>                # 工单详情
POST   /v1/public/ticket/                               # 创建工单
POST   /v1/public/ticket/follow                         # 跟进工单
PUT    /v1/public/ticket/                               # 更新工单
```

### 4.6 用户相关 (UserService)
```
GET    /v1/common/site/config                           # 获取站点配置
GET    /v1/public/user/oauth_methods                    # OAuth 方法列表
POST   /v1/public/user/bind_oauth                       # 绑定 OAuth
POST   /v1/public/user/unbind_oauth                     # 解绑 OAuth
PUT    /v1/user/password                                # 更新密码
PUT    /v1/user/bind/email                              # 绑定邮箱
PUT    /v1/user/notify                                  # 更新通知设置
```

### 4.7 邀请相关 (AffiliateService)
```
GET    /v1/public/user/affiliate/count                  # 返利统计
GET    /v1/public/user/affiliate/list?page=1&size=50   # 邀请记录
```

### 4.8 公告相关 (AnnouncementService)
```
GET    /v1/public/announcement/list                     # 获取公告列表
```

### 4.9 配置相关 (ConfigService)
```
GET    /v1/common/site/config                           # 获取全局配置
```

---

## 5. 远程配置服务

**RemoteConfigService**
- URL: `https://wall-api.oss-cn-shenzhen.aliyuncs.com/config`
- 用途: 获取应用版本、下载链接、API 域名等远程配置
- 数据格式: Base64 编码的 JSON

---

## 6. 通用工具层 (lib/common/)

```
48 个实用工具文件:

网络相关:
├── request.dart                  # 网络请求工具 (Dio 封装)
├── http.dart                     # HTTP 工具
├── remote_config_service.dart    # 远程配置服务
└── network.dart                  # 网络状态

状态和数据:
├── cache.dart                    # 本地缓存
├── preferences.dart              # 共享偏好设置
├── state.dart                    # 状态管理基础
└── context.dart                  # 上下文管理

UI 和渲染:
├── navigator.dart                # 导航管理
├── navigation.dart               # 导航工具
├── scroll.dart                   # 滚动相关
├── text.dart                     # 文本工具
├── render.dart                   # 渲染工具
├── theme.dart                    # 主题工具
└── color.dart                    # 颜色工具

业务逻辑:
├── constant.dart                 # 常量定义
├── system.dart                   # 系统工具 (12KB)
├── utils.dart                    # 通用工具 (10KB)
├── tray.dart                     # 任务栏/托盘管理 (5KB)
├── window.dart                   # 窗口管理
└── keyboard.dart                 # 键盘管理

其他工具:
├── archive.dart                  # 压缩解压
├── compute.dart                  # 计算隔离
├── datetime.dart                 # 日期时间
├── converter.dart                # 类型转换
├── dav_client.dart              # WebDAV 客户端
├── function.dart                 # 函数工具
├── future.dart                   # Future 工具
├── iterable.dart                 # 可迭代工具
├── launch.dart                   # 启动外部应用
├── link.dart                     # 链接处理
├── lock.dart                     # 锁机制
├── measure.dart                  # 测量工具
├── mixin.dart                    # Mixin 基类
├── num.dart                      # 数字工具
├── path.dart                     # 路径处理
├── picker.dart                   # 文件选择器
├── print.dart                    # 打印工具
├── protocol.dart                 # 协议处理
└── proxy.dart                    # 代理工具
```

---

## 7. 业务管理层 (lib/manager/)

```
13 个管理器:

├── app_manager.dart              # 应用管理 (9KB)
├── android_manager.dart          # Android 特定管理
├── connectivity_manager.dart      # 连接状态管理
├── core_manager.dart             # Clash 核心管理
├── hotkey_manager.dart           # 快捷键管理
├── message_manager.dart          # 消息管理
├── proxy_manager.dart            # 代理管理
├── theme_manager.dart            # 主题管理
├── tile_manager.dart             # 快速设置瓦片管理
├── tray_manager.dart             # 托盘管理
├── vpn_manager.dart              # VPN 管理
├── window_manager.dart           # 窗口管理 (7KB)
└── manager.dart                  # 管理器聚合
```

---

## 8. 核心数据模型 (lib/models/)

```
主要模型:
├── app.dart                      # 应用状态模型
├── config.dart                   # Clash 配置模型
├── profile.dart                  # 配置文件模型
├── clash_config.dart             # Clash 配置细节
├── common.dart                   # 通用模型
├── core.dart                     # 核心模型
├── selector.dart                 # 选择器模型
├── widget.dart                   # Widget 模型
└── remote_config.dart            # 远程配置模型 (76 行)
    ├── RemoteConfig (应用配置)
    ├── RemoteVersion (平台版本)
    └── Domain List (API 域名)

生成的模型 (generated/):
├── *.freezed.dart               # Freezed 不可变类
├── *.g.dart                     # JSON 序列化代码
```

---

## 9. 状态管理 (lib/providers/)

```
Riverpod 状态提供者:
├── generated/                   # 生成的代码
└── 多个状态提供者文件
```

---

## 10. 需要重构的关键文件列表

### 高优先级 (核心 API 和认证)
1. **`lib/soravpn_ui/services/auth_service.dart`** (293 行)
   - 直接 http.post/get 调用
   - 硬编码的 API 基础 URL
   - 建议: 创建 LrayAPI 抽象类

2. **`lib/soravpn_ui/services/subscribe_service.dart`** (32KB)
   - 复杂的配置处理逻辑
   - 多个 API 端点调用
   - 建议: 分离配置处理和 API 调用

3. **`lib/soravpn_ui/services/purchase_service.dart`** (362 行)
   - 订单创建和支付流程
   - 多端点管理
   - 建议: 创建 OrderAPI 和 PaymentAPI 类

4. **`lib/soravpn_ui/services/ticket_service.dart`** (130+ 行)
   - 工单管理 API
   - 复杂的数据解析
   - 建议: 创建 TicketAPI 类

### 中优先级 (用户和配置)
5. **`lib/soravpn_ui/services/user_service.dart`** (200 行)
   - 用户信息和 OAuth 管理
   - 建议: 拆分为 UserAPI 和 OAuthAPI

6. **`lib/soravpn_ui/services/order_service.dart`** (145 行)
   - 充值订单逻辑
   - 建议: 与 purchase_service 统一管理

7. **`lib/soravpn_ui/services/config_service.dart`** (115 行)
   - 全局配置获取
   - 建议: 使用单例或 Riverpod 提供者

8. **`lib/soravpn_ui/services/announcement_service.dart`** (149 行)
   - 公告管理
   - 建议: 简化 API 抽象

### 低优先级 (辅助服务)
9. **`lib/soravpn_ui/services/affiliate_service.dart`** (111 行)
   - 邀请返利管理
   - 相对独立

10. **`lib/common/request.dart`** (183 行)
    - Dio 和网络工具
    - 应继续维护

11. **`lib/common/remote_config_service.dart`** (29 行)
    - 远程配置
    - 应继续维护

---

## 11. 与 PLray 的集成点

### API 调用模式
- **基础 URL**: https://apiserver.taptaro.com
- **认证方式**: Bearer Token (JWT)
- **响应格式**: JSON with `{code, msg, data}`
- **错误处理**: code 40004 = Token 过期

### 关键集成业务流程

1. **用户认证流程**
   ```
   AuthService.login() 
   → /v1/auth/login 
   → 存储 Token 
   → AuthService.getUserInfo()
   ```

2. **订阅获取流程**
   ```
   SubscribeService.getSingBoxConfig()
   → /api/subscribe?token=X&type=singbox
   → 解析并修改配置
   → 同步到 FlClash 核心
   ```

3. **购买流程**
   ```
   PurchaseService.getPlans()
   → PurchaseService.getPaymentMethods()
   → PurchaseService.purchase()
   → /v1/public/portal/purchase
   → PurchaseService.getPaymentCheckout()
   ```

4. **工单管理**
   ```
   TicketService.getTickets()
   → /v1/public/ticket/list
   → TicketService.createTicket()
   ```

---

## 12. 技术栈总结

### 网络通信
- **HTTP Client**: http package + Dio
- **JSON 处理**: dart:convert
- **错误处理**: 异常和状态码检查

### 状态管理
- **全局状态**: globalState (controller.dart)
- **Provider 框架**: Riverpod
- **本地存储**: SharedPreferences

### 认证
- **Token 存储**: SharedPreferences
- **OAuth 支持**: 多平台 (Google, GitHub, Facebook 等)

### 配置管理
- **App 配置**: app_config.dart
- **站点配置**: API 获取 (/v1/common/site/config)
- **远程配置**: RemoteConfigService (OSS)

---

## 13. 建议的重构方案

### 创建 LrayAPI 层
```dart
lib/soravpn_ui/api/
├── Lray_client.dart           # HTTP 客户端基类
├── api_config.dart              # API 配置
├── auth_api.dart                # 认证 API
├── subscribe_api.dart           # 订阅 API
├── order_api.dart               # 订单 API
├── payment_api.dart             # 支付 API
├── user_api.dart                # 用户 API
├── ticket_api.dart              # 工单 API
├── announcement_api.dart        # 公告 API
└── affiliate_api.dart           # 邀请 API
```

### 优化 Service 层
- 服务层只关注业务逻辑
- API 调用委托给 API 层
- 实现数据缓存和重试机制

---

## 总结

flclash 是一个功能完整的 VPN 客户端，集成了 SoraVPN 的完整功能：

✅ **已有的良好架构**:
- 清晰的 UI 和业务逻辑分离
- 模块化的 SoraVPN UI 结构
- 完整的 PLray API 集成

⚠️ **需要改进的地方**:
- API 调用分散在多个 Service 中
- 缺乏统一的 API 层和错误处理
- Token 过期处理和重试机制不完善

💡 **关键文件统计**:
- 10 个核心业务服务
- 8 个数据模型
- 11 个 UI 屏幕
- 13 个管理器
- 48 个通用工具

