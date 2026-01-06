export class Minx{
    
    static level(i){
        switch (i){
            case 0:return "低级"
            case 1:return "中级"
            case 2:return "高级"
        }
    }
    
    static reply_status(i){
        switch (i){
            case 0:return  ["已回复","success"]
            case 1:return  ["待回复","processing"]
                
        }
    }
    static status(i){
        switch (i){
            case 0:return ["已开启","success"]
            case 1:return ["已关闭","default"]
        }
    }
}