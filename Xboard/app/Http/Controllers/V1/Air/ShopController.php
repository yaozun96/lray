<?php
namespace App\Http\Controllers\V1\Air;
use App\Http\Controllers\Controller;
use App\Http\Resources\CouponResource;
use App\Http\Resources\PlanResource;
use App\Models\Payment;
use App\Models\Plan;
use App\Services\CouponService;
use App\Services\PlanService;
use Illuminate\Http\Request;
class ShopController extends Controller
{
    public function fetch(Request $request)
    {
        // 尝试解析 PlanService，如果失败则手动实例化 (更稳健的写法)
        try {
            $planService = app(PlanService::class);
        } catch (\Exception $e) {
            $planService = new PlanService(new Plan());
        }
        $plans = $planService->getAvailablePlans();
        
        // 显式返回 JSON (适配前端)
        return response()->json([
            'data' => PlanResource::collection($plans)
        ]);
    }
    public function getPaymentMethod()
    {
        $methods = Payment::select([
            'id',
            'name',
            'payment',
            'icon',
            'handling_fee_fixed',
            'handling_fee_percent'
        ])
            ->where('enable', 1)
            ->orderBy('sort', 'ASC')
            ->get();
        return response()->json([
            'data' => $methods
        ]);
    }
    
    public function checkCoupon(Request $request)
    {
        if (empty($request->input('code'))) {
            return $this->fail([422, __('Coupon cannot be empty')]);
        }
        
        $couponService = new CouponService($request->input('code'));
        $couponService->setPlanId($request->input('plan_id'));
        $couponService->setPeriod($request->input('period'));
        
        try {
            $couponService->check();
        } catch (\Exception $e) {
             return $this->fail([422, $e->getMessage()]);
        }
        
        return response()->json([
            'data' => CouponResource::make($couponService->getCoupon())
        ]);
    }
}