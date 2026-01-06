<?php

namespace App\Http\Controllers\V1\User;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentService;
use App\Services\UserService;
use App\Utils\Helper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RechargeController extends Controller
{
    /**
     * 充值奖励配置（单位：分）
     * 格式：[充值金额 => 赠送金额]
     * 按金额从高到低排序
     */
    private const RECHARGE_BONUS = [
        200000 => 100000, // 充2000送1000
        100000 => 50000,  // 充1000送500
        50000 => 20000,   // 充500送200
        30000 => 10000,   // 充300送100
        20000 => 5000,    // 充200送50
        10000 => 1500,    // 充100送15
    ];

    /**
     * 计算充值奖励金额
     * @param int $amount 充值金额（分）
     * @return int 奖励金额（分）
     */
    private function calculateBonus(int $amount): int
    {
        foreach (self::RECHARGE_BONUS as $threshold => $bonus) {
            if ($amount >= $threshold) {
                return $bonus;
            }
        }
        return 0;
    }

    /**
     * 获取充值奖励配置
     * GET /api/v1/user/recharge/bonus-config
     */
    public function bonusConfig()
    {
        $config = [];
        foreach (self::RECHARGE_BONUS as $threshold => $bonus) {
            $config[] = [
                'threshold' => $threshold,      // 充值门槛（分）
                'bonus' => $bonus,              // 奖励金额（分）
                'threshold_yuan' => $threshold / 100,  // 充值门槛（元）
                'bonus_yuan' => $bonus / 100,          // 奖励金额（元）
            ];
        }
        // 按门槛从低到高排序
        usort($config, fn($a, $b) => $a['threshold'] - $b['threshold']);
        return $this->success($config);
    }

    /**
     * 创建充值订单
     * POST /api/v1/user/recharge/create
     */
    public function create(Request $request)
    {
        $request->validate([
            'amount' => 'required|integer|min:1000|max:1000000', // 金额单位：分，最少10元，最多1万
        ]);

        $user = $request->user();
        $userService = app(UserService::class);

        // 检查是否有未完成的订单
        if ($userService->isNotCompleteOrderByUserId($user->id)) {
            return $this->fail([400, __('You have an unpaid or pending order, please try again later or cancel it')]);
        }

        $amount = $request->input('amount');
        $bonus = $this->calculateBonus($amount);

        try {
            $tradeNo = Helper::generateOrderNo();
            $now = time();

            DB::table('v2_order')->insert([
                'user_id' => $user->id,
                'plan_id' => 0,
                'period' => 'recharge',
                'trade_no' => $tradeNo,
                'total_amount' => $amount,
                'discount_amount' => $bonus,
                'type' => Order::TYPE_RECHARGE,
                'status' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            return $this->success([
                'trade_no' => $tradeNo,
                'amount' => $amount,
                'bonus' => $bonus,
                'total' => $amount + $bonus,
            ]);
        } catch (\Exception $e) {
            return $this->fail([500, $e->getMessage()]);
        }
    }

    /**
     * 结算充值订单
     * POST /api/v1/user/recharge/checkout
     */
    public function checkout(Request $request)
    {
        try {
            $request->validate([
                'trade_no' => 'required|string',
                'method' => 'required|integer',
            ]);

            $order = Order::where('trade_no', $request->input('trade_no'))
                ->where('user_id', $request->user()->id)
                ->where('status', Order::STATUS_PENDING)
                ->where('period', 'recharge')
                ->first();

            if (!$order) {
                return $this->fail([400, __('Order does not exist or has been paid')]);
            }

            $payment = Payment::find($request->input('method'));
            if (!$payment || !$payment->enable) {
                return $this->fail([400, __('Payment method is not available')]);
            }

            $paymentService = new PaymentService($payment->payment, $payment->id);

            // 计算手续费
            $order->handling_amount = null;
            if ($payment->handling_fee_fixed || $payment->handling_fee_percent) {
                $order->handling_amount = (int) round(
                    ($order->total_amount * ($payment->handling_fee_percent / 100)) + $payment->handling_fee_fixed
                );
            }

            $order->payment_id = $payment->id;
            if (!$order->save()) {
                return $this->fail([400, __('Request failed, please try again later')]);
            }

            $result = $paymentService->pay([
                'trade_no' => $order->trade_no,
                'total_amount' => isset($order->handling_amount)
                    ? ($order->total_amount + $order->handling_amount)
                    : $order->total_amount,
                'user_id' => $order->user_id,
                'stripe_token' => $request->input('token'),
            ]);

            return response()->json([
                'data' => $result['data'] ?? null,
                'type' => $result['type'] ?? 0,
            ]);
        } catch (\Exception $e) {
            return $this->fail([500, 'Checkout error: ' . $e->getMessage()]);
        }
    }

    /**
     * 检查充值订单状态
     * GET /api/v1/user/recharge/check
     */
    public function check(Request $request)
    {
        $request->validate([
            'trade_no' => 'required|string',
        ]);

        $order = Order::where('trade_no', $request->input('trade_no'))
            ->where('user_id', $request->user()->id)
            ->where('period', 'recharge')
            ->first();

        if (!$order) {
            return $this->fail([400, __('Order does not exist')]);
        }

        return $this->success($order->status);
    }
}
