import { createRouter, createWebHashHistory } from 'vue-router';
import { useInfoStore } from "@/stores/counter.js";
import { message } from "ant-design-vue";
import Layout from "@/views/News/Layout.vue";

const router = createRouter({
    history: createWebHashHistory(import.meta.env.BASE_URL),
    routes: [
        {
            path: "/",
            redirect: () => {
                if (window.config.indexRedirect.startsWith('/')) return window.config.indexRedirect;
                window.location.href = window.config.indexRedirect;
            },
            component: Layout,
            children: [
                {
                    path: 'home',
                    name: 'Home',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/Home/Home.vue"),
                },
                {
                    path: 'faq',
                    name: 'Faq',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/Home/Faq.vue"),
                },
                {
                    path: 'tos',
                    name: 'Tos',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/Home/Tos.vue"),
                },
                {
                    path: 'login',
                    name: 'Login',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/News/Login.vue"),
                },
                {
                    path: 'register',
                    name: 'Register',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/News/Register.vue"),
                },
                {
                    path: 'forget',
                    name: 'Forget',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/News/Forget.vue"),
                },
                {
                    path: "download",
                    name: "Download",
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/News/Download.vue"),
                },
                {
                    path: 'store',
                    name: 'Store',
                    meta: {
                        auth: true
                    },
                    component: () => import("@/views/News/Store.vue"),
                },
                {
                    path: 'shop',
                    name: 'Shop',
                    meta: {
                        auth: false
                    },
                    component: () => import("@/views/Shop/main.vue"),
                },
                {
                    path: 'profile',
                    name: 'Profile',
                    meta: {
                        auth: true
                    },
                    component: () => import("@/views/News/Profile.vue"),
                },
                {
                    path: 'changepass',
                    name: 'Changepass',
                    meta: {
                        auth: true
                    },
                    component: () => import("@/views/News/Changepass.vue"),
                },
                {
                    path: 'invite',
                    name: 'Invite',
                    meta: {
                        auth: true
                    },
                    component: () => import("@/views/News/Invite.vue"),
                },
                {
                    path: '/order/:id', // 注意这里要有 :id 表示动态参数
                    name: 'Order',
                    component: () => import('@/views/News/Order.vue'),
                },
                {
                    path: 'orders',
                    name: 'Orders',
                    meta: {
                        auth: true
                    },
                    component: () => import('@/views/News/Orders.vue'),
                },
                {
                    path: 'trafficLog',
                    name: 'TrafficLog',
                    component: () => import('@/views/News/TrafficLog.vue'),
                },
                {
                    path: 'ticket',
                    name: 'Ticket',
                    meta: {
                        auth: true
                    },
                    component: () => import("@/views/Ticket/Ticket.vue"),
                }            ]
        },
        // 处理 aff.php 路径并重定向到主域名
        {
            path: '/aff.php',
            redirect: () => {
                const url = new URL(window.location.href);
                url.search = ''; // 移除参数
                window.location.replace(url.origin); // 跳转到主域名
            }
        },
        {
            path: '/:catchAll(.*)', // 处理所有未匹配的路径
            redirect: '/'
        }
    ]
});

router.beforeEach((to, from, next) => {
    const url = new URL(window.location.href);
    if (url.pathname === '/aff.php' && url.search) {
        url.search = ''; // 移除参数
        window.location.replace(url.origin); // 重定向到主域名
    } else if (to.meta.auth === true && useInfoStore().Token === undefined) {
        console.error('请先登录 / 注册账号');
        message.error("请先登录 / 注册账号");
        next("/login");
    } else if ((to.name === 'Login' || to.name === 'Register') && useInfoStore().Token !== undefined) {
        next("/profile");
    } else if (to.name === 'Shop' && useInfoStore().Token !== undefined) {
        // 保留 URL 参数（如优惠码）
        next({ path: "/store", query: to.query });
    } else {
        next();
    }
});

export default router;
