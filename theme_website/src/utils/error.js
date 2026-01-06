import { message } from "ant-design-vue";

export const extractApiError = (error, fallback = "请求失败，请稍后再试") => {
  if (!error) return fallback;

  if (typeof error === "string") {
    return error || fallback;
  }

  const data = error?.response?.data || error?.data || error;
  if (typeof data === "string") {
    return data || fallback;
  }

  return data?.message || error?.message || fallback;
};

export const notifyApiError = (error, fallback) => {
  const msg = extractApiError(error, fallback);
  message.error(msg);
  return msg;
};
