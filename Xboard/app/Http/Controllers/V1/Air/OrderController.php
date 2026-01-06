<?php
namespace App\Http\Controllers\V1\Air;
use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Services\Auth\RegisterService;
use App\Services\OrderService;
use Illuminate\Http\Request;
class OrderController extends Controller
{
    public function pay(Request $request)
    {
        $user = $request->user('api'); // 尝试从 Token 获取用户
        // 1. 如果未登录，执行注册流程
        if (!$user) {
            $registerService = app(RegisterService::class);
            
            // 验证注册数据 (邮箱、验证码、IP限制等)
            [$valid, $error] = $registerService->validateRegister($request);
            if (!$valid) {
                 return $this->fail($error);
            }
            // 执行注册
            [$success, $result] = $registerService->register($request);
            if (!$success) {
                return $this->fail($result);
            }
            $user = $result;
        }
        // 2. 验证订单参数
        $request->validate([
            'plan_id' => 'required|integer',
            'period' => 'required|string'
        ]);
        
        $plan = Plan::find($request->input('plan_id'));
        if (!$plan) {
            return $this->fail([400, 'Subscription plan does not exist']);
        }
        // 3. 创建订单
        try {
            $order = OrderService::createFromRequest(
                $user,
                $plan,
                $request->input('period'),
                $request->input('coupon_code')
            );
        } catch (\Exception $e) {
            return $this->fail([500, $e->getMessage()]);
        }
        // 4. 返回 trade_no (扁平化 JSON 格式，适配前端 useShop.js)
        return response()->json([
            'trade_no' => $order->trade_no,
            'auth_data' => null 
        ]);
    }
}