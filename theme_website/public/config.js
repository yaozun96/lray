window.config = {
    logo: 'logo.svg', // 网站logo
    title: "Lray", // 网站标题
    indexRedirect: '/shop', // 站点首页重定向地址
    backupSubscribeOrigin: 'http://8.219.77.170:8500', // 备用订阅地址

    home: {
        feature: '新用户9折优惠码 welcome',
        title: '我们致力于提供',
        description: '',
        headerElement: '',
        headerBg: 'animated-background-space.svg',
        headerBtnText: '立即购买',
        FeatureTitle: '为您量身定制的网络加速服务',
        FeatureDescription: 'Lray为您提供全球高速网络加速服务，解锁全球网络限制，让您畅游互联网。',
        Features: [
            { title: '高可用跨境链路', desc: '采用IEPL专线，不管是高峰期还是敏感期都能提供优秀的网络体验。' },
            { title: '无审计网络', desc: '我们的服务没有任何审计行为，您可以安全自由无束享受互联网。' },
            { title: '多平台支持', desc: '支持iOS、macOS、Android、Windows、路由器、Linux等多平台' },
            { title: '先进的解锁技术', desc: '全节点解锁Netflix等主流流媒体服务，解锁chatgpt访问' },
        ],
        AreaTitle: '全球多个地区部署30+节点',
        AreaDescription: 'Lray 在全球多个地区部署了30+优质网络节点，入口通过中国大陆IEPL专线为您提供高速稳定的网络加速。',
        AreaImg: 'map.png',
    },

    commonNav: {
        shop: '立即订阅',
        download: '软件下载',
        dashboard: '会员后台',
    },

    // 页面导航，key为导航名称，value为导航显示名称, 请勿修改key
    navMenus: {
        Download: '下载',
        Store: '购买',
        Shop: '商店',
        Profile: '我的',
        Invite: '邀请',
        displayInvite: true, // 是否显示邀请页面
    },
    navNotice: {
        displayName: '通知信息'
    },
    navExchange: {
        displayName: '兑换套餐'
    },
    Footer: {
        copyRight: '© 2021 Lray. All rights reserved.', // 版权信息
        help: [
            { name: '常见问题', link: '/#/faq' },
            { name: '服务协议', link: '/#/tos' },
            //{name: '隐私政策', link: 'https://www.google.com/'},
        ],
        connect: [
            { name: '防失联地址(建议收藏)', link: 'https://lray.dlgisea.com' },
            { name: 'TG频道', link: 'https://t.me/lray_io' },

            //{name: 'Telegram 合作', link: 'https://t.me/themebuddy'},
        ],
    },
    Sign: {
        LoginTitle: '欢迎登录 Lray',
        RegisterTitle: '欢迎注册 Lray',
        ForgetTitle: '忘记密码',
        inviteCodeEdit: true, // 是否允许用户修改邀请码, false 可以，true 不可以
    },
    Download: {
        title: '下载客户端 <br> 解锁精彩世界',
        desc: '高可用的跨境网络互联服务',
        background: 'animated-background-space.svg',
        download: {
            display: true, // 是否显示安装文件中的下载按钮
            btnText: '下载链接',
        },
        Mac: {
            title: 'MacOS 客户端',
            version: '1.0.0',
            link1: {
                title: '官方客户端（推荐）',
                url: 'https://www.apple.com/macos/sonoma/',
                html: `<p aria-status="warning">运行环境： macOS 10.14以上操作系统</p>
<p aria-number="1">点击下方按钮下载客户端，内含amd64和arm64两个芯片版本（苹果系统点击关于本机可以查看CPU芯片）</p>


    <div aria-label="buttonGroup">
    <span aria-label="button" data-url="https://download.lray.io/Lray_client/Lray-5.1.0-macOS.zip">Lray-5.1.0-macOS.zip</span>
</div>


<p aria-number="2">双击打开下载好的<span aria-style="primary">.dmg文件</span>，拖拽到<span aria-style="primary">Applications</span>文件夹，完成安装</p>
<p aria-number="3">第一次打开Lray会被macOS误报为不安全的恶意软件，我们只需打开macOS的<span aria-style="primary">系统设置</span>，然后选择<span aria-style="primary">隐私与安全性</span>最后点击<span aria-style="primary">仍要打开</span>，即可解决无法打开软件的问题，只需要操作一次，后续打开软件无需再次操作。</p>
<div aria-label="img-pc">
    <img src="img/localized/mac-step-1.png" alt="点击完成">
    <img src="img/localized/mac-step-2.png" alt="点击仍要打开">
    <img src="img/localized/mac-step-3.png" alt="继续点击仍要打开">
</div>
<p aria-number="4">软件截图</p>

<div aria-label="img">
    <img src="img/localized/client-screenshot.webp" alt="客户端截图">

</div>
<p aria-number="5">客户端代理模式</p>
客户端分两种代理模式，默认选择是<span aria-style="primary">规则模式</span> <br>

<span aria-style="primary">规则模式</span>：只有外网流量走代理，国内还走本地网络，对流量消耗较小。<br>
<span aria-style="primary">全局模式</span>：所有网络流量，包括国内的流量都走代理，对流量消耗较大。

`
            },
            link2: {
                title: '第三方客户端',
                url: 'https://www.apple.com/macos/sonoma/',
                html: `
                    <div aria-alert>
                    <span>推荐使用Lray官方客户端</span>
<a href="https://download.lray.io/Lray_client/Lray-5.1.0-macOS.zip" target="_blank">下载MacOS客户端</a>
</div>
    <p>第三方客户端基本都是基于 Clash 内核 开发的。由于 Clash for Windows 已经停止更新，会出现各种莫名其妙的订阅不兼容问题。我们强烈推荐使用 Clash Verge Rev，该软件持续更新维护，与 Lray 的兼容性很好，安装后在官网「我的」页面点击「复制订阅链接」，或一键导入Clash订阅即可使用。使用第三方软件需要有良好的动手能力，如果觉得麻烦可以使用Lray官方客户端，免配置一健即可开启使用。</p>
    <span aria-label="button" data-url="https://gh-proxy.com/https://github.com/clash-verge-rev/clash-verge-rev/releases/https://download.lray.io/Lray_client/v2.4.2/Clash.Verge_2.4.2_x64.dmg">下载Clash Verge Rev Intel 版本（v2.4.2）</span>
        <span aria-label="button" data-url="https://gh-proxy.com/https://github.com/clash-verge-rev/clash-verge-rev/releases/https://download.lray.io/Lray_client/v2.4.2/Clash.Verge_2.4.2_aarch64.dmg">下载Clash Verge Rev ARM/M 芯片版本（v2.4.2）</span>

    <span aria-label="button" data-url="https://freeroad.org/clash-verge-rev.html">Clash Verge Rev 详细教程</span>
    `
            },
        },
        Windows: {
            title: 'Windows 客户端下载',
            version: '',
            link1: {
                title: '官方客户端（推荐）',
                url: 'https://www.microsoft.com/zh-cn',
                html: `<p aria-status="warning">运行环境：windows7 x64以上操作系统</p>
<p aria-number="1">点击下方按钮下载客户端</p>
  <div aria-label="buttonGroup">
<span aria-label="button" data-url="https://download.lray.io/Lray_client/Lray-5.1.0-windows-amd64-setup.exe">下载Lray-5.1.0-windows-amd64-setup.exe</span>
</div>
<p aria-number="2">双击打开下载好的<span aria-style="primary">.exe文件</span>，完成安装</p>

<p aria-number="3">软件截图</p>

                        <div aria-label="img">
    <img src="img/localized/client-screenshot.webp" alt="客户端截图">
</div>
<p aria-number="4">客户端代理模式</p>
客户端分两种代理模式，默认选择是<span aria-style="primary">规则模式</span> <br>

<span aria-style="primary">规则模式</span>：只有外网流量走代理，国内还走本地网络，对流量消耗较小。<br>
<span aria-style="primary">全局模式</span>：所有网络流量，包括国内的流量都走代理，对流量消耗较大。
`
            },
            link2: {
                title: '第三方客户端',
                url: 'https://www.microsoft.com/zh-cn',
                html: `
    <div aria-alert>
        <span>推荐使用Lray官方客户端</span>
        <a href="https://download.lray.io/Lray_client/Lray-5.1.0-windows-amd64-setup.exe" target="_blank">下载Windows客户端</a>
    </div>
    <p>第三方客户端基本都是基于 Clash 内核 开发的。由于 Clash for Windows 已经停止更新，会出现各种莫名其妙的订阅不兼容问题。我们强烈推荐使用 Clash Verge Rev，该软件持续更新维护，与 Lray 的兼容性很好，安装后在官网「我的」页面点击「复制订阅链接」，或一键导入Clash订阅即可使用。使用第三方软件需要有良好的动手能力，如果觉得麻烦可以使用Lray官方客户端，免配置一健即可开启使用。</p>
    <span aria-label="button" data-url="https://gh-proxy.com/https://github.com/clash-verge-rev/clash-verge-rev/releases/https://download.lray.io/Lray_client/v2.4.2/Clash.Verge_2.4.2_x64-setup.exe">下载Clash Verge Rev Windows 安装包（v2.4.2）</span>
    <span aria-label="button" data-url="https://freeroad.org/clash-verge-rev.html">Clash Verge Rev 详细教程</span>
`
            },

        },
        Android: {
            title: 'Android 客户端下载',
            version: '1.0.0',
            link1: {
                title: '官方客户端（推荐）',
                url: 'https://www.google.com/',
                html: `<p aria-status="warning">运行环境：Android7以上操作系统</p>
<p aria-number="1">点击下方按钮下载客户端</p>
  <div aria-label="buttonGroup">
<span aria-label="button" data-url="https://download.lray.io/Lray_client/Lray-5.1.0-android-arm64-v8a.apk">下载Lray-5.1.0-android-arm64-v8a.apk</span>
</div>
<p aria-number="2">安装下载好的<span aria-style="primary">.apk文件</span>，完成安装（某些手机安装apk需要到手机设置里面选择允许“未知来源"或者类似操作，国产手机如遇到系统阻拦提示不安全请无视。）</p>

<p aria-number="3">客户端代理模式</p>
客户端分两种代理模式，默认选择是<span aria-style="primary">智能模式</span> <br>

<span aria-style="primary">智能模式</span>：只有外网流量走代理，国内还走本地网络，对流量消耗较小。<br>
<span aria-style="primary">全局模式</span>：所有网络流量，包括国内的流量都走代理，对流量消耗较大。
`

            },
            link2: {
                title: '第三方客户端',
                url: 'https://www.google.com/',
                html: `
    <div aria-alert>
        <span>推荐使用Lray官方客户端</span>
        <a href="https://download.lray.io/Lray_client/Lray-5.1.0-android-arm64-v8a.apk" target="_blank">下载Android客户端</a>

    </div>
    <p>下载Clash Meta for Android，然后在官网「我的」页面点击「复制订阅链接」，或一键导入Clash订阅即可使用。使用第三方软件需要有良好的动手能力，如果觉得麻烦可以使用Lray官方客户端，免配置一健即可开启使用。</p>
    <span aria-label="button" data-url="https://github.com/MetaCubeX/ClashMetaForAndroid/releases">下载Clash Meta for Android</span>
    <span aria-label="button" data-url="https://freeroad.org/clash-meta-for-android.html">Clash Meta for Android 详细教程</span>
`
            },
        },
        IOS: {
            title: 'iOS 客户端下载',
            version: '1.0.0',
            link1: {
                title: '查看教程',
                url: 'https://forest-cn.com/#/ios',
                html: `<p aria-status="warning">注：iOS端我们的订阅支持 Surge/QuantumultX 等，这里仅展示 Shadowrocket 的基础教程。Shadowrocket（俗称小火箭）是外区付费$2.99的软件，尚未在AppStore中国区上架，为方便您使用我们的服务，我们免费提供外区Apple ID，您可以通过ID免费下载此应用。
</p>
    <p aria-number="1">获取苹果Shadowrocket共享ID</p>
      
          <div aria-label="buttonGroup">
<span aria-label="button" data-url="https://shadowrocket.best/">获取免费小火箭Shadowrocket共享账号</span>
</div>
    <p aria-number="2">使用共享 ID下载 Shadowrocket</p>
<p aria-status="error">警告：本站提供的Apple ID是第三方提供的共享ID，本站没有实际管理权，使用请按照本教程，只能在AppStore登录，请勿在设置里的 iCloud 登录！！！若您不听劝告出现被锁机/信息丢失等情况，只能自己去苹果售后解除。Lray不承担任何责任!</p>
<div aria-label="img">
        <p>1. 找到 App Store 并打开。</p>
        <img src="img/localized/ios-step-1.png">
        <p>2: 点击右上角头像退出当前账号。</p>
        <img src="img/localized/ios-step-2.png">
        <p>3: 滑动屏幕到底部点击退出登录。</p>
        <img src="img/localized/ios-step-3.png">
        <p>4: 点击通过 Apple ID 登录。</p>
        <img src="img/localized/ios-step-4.png">
        <p>5: 选着选项 不是xxxxxx?</p>
        <img src="img/localized/ios-step-5.jpg">
        <p>6: 输入上一步获取的共享账号,点击继续</p>
        <img src="img/localized/ios-step-6.png">
        <p>7: 输入获取到的密码,注意大小写,点击继续</p>
        <img src="img/localized/ios-step-7.png">
        <p>8: 如果出现 Apple ID 安全界面,点击其他选项。</p>
        <img src="img/localized/ios-step-8.png">
        <p>9: 选择不升级,请注意不要选错。</p>
        <img src="img/localized/ios-step-9.png">
        <p>10: 登录成功</p>
        <img src="img/localized/ios-step-10.png">
        <p>11: 搜索Shadowrocket</p>
        <img src="img/localized/ios-step-11.png">
    </div>
    <p aria-number="3">导入本站订阅配置</p>
    <p>1.前提你必须在本站持有有效订阅，在官网「我的」页面点击「复制订阅链接」；</p>
    <p>2.打开Shadowrocket，点击右上角的加号，再次点击第一行的「类型」，选择「Subscribe」</p>
    <p>3.在「备注」中输入本站名称Lray，随后在「URL」中粘贴刚才官网复制的订阅链接，随后点击右上角「完成」保存，此时会自动更新获取服务器节点，选择节点即可使用；</p>
    <p>4.如果是第一次使用，则会提示需要添加VPN连接配置。点击“允许”后按系统提示操作，验证锁屏密码或Faceid即可。</p>
        <div aria-label="img">
        <img src="img/localized/ios-subscribe.png">
  
    </div>
`
            },

        },
    },
    Buy: {
        title: '专为大陆用户打造的高速网络',
        description: '',
        background: 'animated-background-space.svg',
        elementImg: 'rocket-animation-modified-minimal.svg',
        features: [
            '30+原生IP节点，包括香港，台湾，日本，美国，新加坡，英国，越南，泰国等地区；',
            '解锁Netflix、Hulu、HBO、TVB、disney+等流媒体视频和ChatGPT；',
            '采用高可用性的专线，高峰期流畅，敏感期可用；',
            '无任何审计访问，您可以自由无束享受互联网；',
            'iOS、macOS、Android、Windows、路由器、Linux全面支持。',
        ],
        plan_feature_display: true, // 是否显示套餐特性
        order_tips: '检查到你还有未支付的订单，点击下方的「支付订单」按钮完成支付，或者点击下方的取消按钮取消订单，重新选择套餐', // 已有订单时的提示信息

        // 套餐类型Tab顺序配置
        // 可选值: 'cycle'(周期套餐), 'onetime'(永久套餐)
        // 动态标签会按后台配置顺序显示在后面
        plan_type_order: ['onetime', 'cycle'], // 默认周期套餐在前

        // ========== 支付方式过滤规则配置 ==========
        // 根据订单金额动态显示/隐藏指定支付方式
        //
        // 参数说明：
        //   payment_id: 支付方式ID（从后台API获取的支付方式id）
        //   min_amount: 最小金额（元），订单金额 >= 该值时显示，不设置表示无下限
        //   max_amount: 最大金额（元），订单金额 <= 该值时显示，不设置表示无上限
        //
        // 使用规则：
        //   1. 设为 null 或 [] 时不启用过滤，显示所有支付方式
        //   2. 启用后，只有在此处配置的支付方式才会显示
        //   3. 同一个支付方式可以设置金额区间，也可以不设置（始终显示）
        //
        // 配置示例：
        //   { payment_id: 1 }                        // 支付方式1: 始终显示
        //   { payment_id: 2, max_amount: 50 }        // 支付方式2: 金额 <= 50 元时显示
        //   { payment_id: 3, min_amount: 50 }        // 支付方式3: 金额 >= 50 元时显示
        //   { payment_id: 4, min_amount: 10, max_amount: 100 }  // 支付方式4: 金额 10-100 元时显示
        //
        // 当前配置效果：
        //   金额 < 20 元: 显示 5, 2
        //   金额 >= 20 元: 显示 6, 1, 2
        payment_rules: [
            { payment_id: 5, max_amount: 20 },  // 支付方式5: 金额 <= 20 元时显示
            { payment_id: 2 },                   // 支付方式2: 始终显示
            { payment_id: 6, min_amount: 20 },  // 支付方式6: 金额 >= 20 元时显示
            { payment_id: 1, min_amount: 20 },  // 支付方式1: 金额 >= 20 元时显示
        ],
    },
    Exchange: {
        title: '兑换套餐',
        desc: '如果没有兑换码',
        buyText: '请点击购买',
        placeholder: '请输入您的兑换码',
        submitText: '立即兑换',

        display: false, // 是否在没有套餐时自动显示
        displayTips: '您还未订阅套餐，请先兑换套餐!', // 没有套餐时的提示信息
    },
    shopForm: {
        comment: '绑定邮箱方便您更快找回账户与管理服务,我们承诺不会泄露您的邮箱信息',
    },
}
