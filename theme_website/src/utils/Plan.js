import moment from "moment";

class Plan {
    static Handle_name(type) {
        switch (type) {
            case "month_price":
                return "月付";
            case "quarter_price":
                return "季付";
            case "half_year_price":
                return "半年";
            case "year_price":
                return "年付";
            case "two_year_price":
                return "两年";
            case "three_year_price":
                return "三年";
            case "onetime_price":
                return "一次性";
            case "reset_price":
                return "重置流量包";
            default:
                return "";
        }
    }

    static Handle_status(number) {
        switch (number) {
            case 0:
                return [0, "待支付", "warning"];
            case 1:
                return [1, "开通中", "processing"];
            case 2:
                return [2, "已取消", "error"];
            case 3:
                return [3, "已完成", "success"];
            case 4:
                return [4, "已折抵", "success"];
            default:
                return [number, "未知状态", "default"];
        }
    }

    static Handle_One(obj) {
        for (const item of Plan.List) {
            if (Object.keys(obj).includes(item) && obj[item] !== null) {
                return item;
            }
        }
        return null;
    }

    static Handle_Time_name(expired_at) {
        switch (expired_at) {
            case null:
                return "无限期";
            case 0:
                return "尚未购买订阅";
            default:
                return moment(expired_at * 1000).format("YYYY-MM-DD");
        }
    }

    static Handle_Time_day(expired_at, reset_day) {
        if (expired_at === null) {
            if (reset_day === null) {
                return "无限期";
            } else {
                return reset_day - 1;
            }
        } else {
            return reset_day - 1;
        }
    }

    static Handle_Plan(html) {
        try {
            let h = JSON.parse(html);
            let div_item = '';
            for (const item of h) {
                if (item.support) {
                    div_item += `<p class="p-1 text-green-500">${item.feature}</p>`;
                } else {
                    div_item += `<p class="p-1 text-gray-500 line-through">${item.feature}</p>`;
                }
            }
            return `
        <div class="grid grid-cols-2 w-full gap-4 whitespace-nowrap overflow-x-scroll">
          ${div_item}
        </div>
      `;
        } catch (e) { // 修改了这里，添加了 (e)
            return html;
        }
    }
}

// 在类外部定义静态属性
Plan.List = [
    'month_price',
    'quarter_price',
    'half_year_price',
    'year_price',
    'two_year_price',
    'three_year_price',
    'onetime_price',
    'reset_price'
];

export default Plan;
