import {http} from "@/utils/request.js";

export const Info=()=>{
  return http({
        url:"api/v1/user/info",
    })
}

export const Notice=()=>{
    return http({
        url:"api/v1/user/notice/fetch"
    })
}

export const Config=()=>{
    return http({
        url:"api/v1/user/comm/config",
    })
}

export const GetSubscribe=()=>{
    return http({
        url:"api/v1/user/getSubscribe"
    })
}