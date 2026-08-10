import 'dart:developer' as developer;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_products.dart';
import 'subscription_plan_service.dart';

/// Thin wrapper around the official `in_app_purchase` plugin for Apple
/// StoreKit. Handles loading products, starting purchases, restoring, and
/// completing transactions. Entitlement granting lives in the caller
/// (ChoosePlanController) so it can reuse the existing subscription storage.
class IapService {
  IapService._();

  static final InAppPurchase _iap = InAppPurchase.instance;

  /// True if the device can make payments and the store is reachable.
  static Future<bool> isStoreAvailable() => _iap.isAvailable();

  /// Stream of purchase updates (new purchases, restores, errors). Subscribe
  /// once and keep the subscription for the lifetime of the purchase surface.
  static Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Queries the store for the given product ids and returns the ones that
  /// exist. Missing/invalid ids are logged and skipped.
  static Future<List<ProductDetails>> loadProducts(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      developer.log(
        'IapService.loadProducts error: ${response.error}',
        name: 'IapService',
      );
    }
    if (response.notFoundIDs.isNotEmpty) {
      developer.log(
        'IapService.loadProducts not found: ${response.notFoundIDs}',
        name: 'IapService',
      );
    }
    return response.productDetails;
  }

  /// Starts the purchase flow for [product]. The result is delivered through
  /// [purchaseStream], not returned here.
  static Future<void> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    // Subscriptions are treated as non-consumables by the plugin.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restores previously purchased subscriptions. Restored purchases arrive
  /// through [purchaseStream].
  static Future<void> restore() => _iap.restorePurchases();

  /// Finalises a transaction so StoreKit stops re-delivering it.
  static Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  /// Resolves the App Store product id for a plan: an explicit
  /// [SubscriptionPlan.appleProductId] if set, otherwise a mapping by
  /// duration. Returns null for plans with no matching product (e.g. free
  /// plans or durations you don't sell on iOS).
  static String? productIdForPlan(SubscriptionPlan plan) {
    final explicit = plan.appleProductId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    switch (plan.durationInMonths) {
      case 1:
        return IapProducts.monthly;
      case 3:
        return IapProducts.threeMonths;
      default:
        return null;
    }
  }
}
