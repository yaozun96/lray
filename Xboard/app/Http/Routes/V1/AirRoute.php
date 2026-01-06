<?php
namespace App\Http\Routes\V1;
use App\Http\Controllers\V1\Air\OrderController;
use App\Http\Controllers\V1\Air\ShopController;
use Illuminate\Contracts\Routing\Registrar;
class AirRoute
{
    public function map(Registrar $router)
    {
        $router->group([
            'prefix' => 'air',
            'middleware' => 'api' // 使用 api 中间件，允许未登录访问
        ], function ($router) {
            // 订单相关
            $router->post('/order/pay', [OrderController::class, 'pay']);
            // 商店数据相关
            $router->get('/shop/fetch', [ShopController::class, 'fetch']);
            $router->get('/getPaymentMethod', [ShopController::class, 'getPaymentMethod']);
            $router->post('/coupon/check', [ShopController::class, 'checkCoupon']);
        });
    }
}