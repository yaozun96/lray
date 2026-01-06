import axios from 'axios';
import { useInfoStore } from "@/stores/counter.js";
import { verifyApiDomain, guardHttpClient, getAuthorizedApiOrigin } from "./auth.js";

const authorizedOrigin = getAuthorizedApiOrigin();
const defaultBaseURL = authorizedOrigin.endsWith('/') ? authorizedOrigin : `${authorizedOrigin}/`;

export const http = axios.create({
    baseURL: defaultBaseURL,
    headers: {
        "Content-Type": "application/x-www-form-urlencoded",
    },
});

const lockedBaseURL = guardHttpClient(http);

http.interceptors.request.use((config) => {
    // 授权验证：确保API域名未被篡改
    config.baseURL = lockedBaseURL;
    const currentBaseURL = config.baseURL || http.defaults.baseURL;
    if (!verifyApiDomain(currentBaseURL)) {
        return Promise.reject(new Error('API domain verification failed'));
    }

    // 添加授权Token
    config.headers.Authorization = useInfoStore().Token;
    return config;
});

http.interceptors.response.use(
    (response) => {
        return response.data;
    },
    (error) => {
        const tokenStore = useInfoStore();
        if (error.response?.status === 403) {
            if (tokenStore.Token) {
                window.location.hash = '#/login';
            }
            tokenStore.Set_Token(undefined);
            return Promise.reject(error.response || error);
        }
        if (error.response?.status === 401) {
            tokenStore.Set_Token(undefined);
            window.location.hash = '#/login';
            return Promise.reject(error.response || error);
        }

        return Promise.reject(error.response || error);
    }
);
