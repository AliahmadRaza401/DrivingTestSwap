import 'package:get/get.dart';

import '../../../core/services/coupon_service.dart';
import '../../../core/utils/toast_util.dart';

class AdminCouponManagementController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxList<CouponRecord> coupons = <CouponRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      coupons.assignAll(await CouponService.fetchCoupons());
    } catch (_) {
      hasError.value = true;
      coupons.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveCoupon(CouponRecord coupon) async {
    await CouponService.saveCoupon(coupon);
    ToastUtil.success('Coupon saved');
    await loadCoupons();
  }

  Future<void> deleteCoupon(String couponCode) async {
    await CouponService.deleteCoupon(couponCode);
    ToastUtil.success('Coupon deleted');
    await loadCoupons();
  }
}
