/// Apple In-App Purchase product identifiers.
///
/// These must exactly match the Product IDs of the auto-renewable subscriptions
/// created in App Store Connect. Free plans (e.g. the "Founder" plan) are NOT
/// In-App Purchases — they are granted for free inside the app and have no
/// product here.
abstract class IapProducts {
  IapProducts._();

  /// Monthly auto-renewable subscription (1 month).
  static const String monthly = 'com.softsolvix.drivingtestswap.monthly';

  /// 3-month auto-renewable subscription.
  static const String threeMonths = 'com.softsolvix.drivingtestswap.3months';

  /// All product ids the app queries from the store.
  static const Set<String> all = {monthly, threeMonths};
}
