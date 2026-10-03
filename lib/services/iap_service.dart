import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score_tracker/services/room_analytics_service.dart';

class IAPService extends ChangeNotifier {
  IAPService({InAppPurchase? store}) : _store = store ?? InAppPurchase.instance;

  static const removeAdsProductId = 'remove_ads';
  static const multiViewerProductId = 'premium_multi_viewer';
  static const premiumPlusProductId = 'premium_plus_monthly';
  static const productId = removeAdsProductId;
  static const _removeAdsEntitlementKey = 'has_remove_ads_entitlement';
  static const _multiViewerEntitlementKey = 'has_multi_viewer_entitlement';
  static const _removeAdsAnalyticsTransactionKey =
      'last_remove_ads_analytics_transaction';

  final InAppPurchase _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final Map<String, ProductDetails> _products = {};
  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _isAvailable = false;
  bool _hasRemoveAdsEntitlement = false;
  bool _hasMultiViewerEntitlement = false;
  bool _hasPremiumPlusEntitlement = false;
  bool _isEntitlementResolved = false;
  bool _isLoading = true;
  String? _purchasingProductId;
  String? _statusMessage;

  bool get isPurchased => _hasRemoveAdsEntitlement;
  bool get hasRemoveAdsEntitlement => _hasRemoveAdsEntitlement;
  bool get hasMultiViewerEntitlement => _hasMultiViewerEntitlement;
  bool get hasPremiumPlusEntitlement => _hasPremiumPlusEntitlement;
  bool get isEntitlementResolved => _isEntitlementResolved;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _purchasingProductId != null;
  String? get statusMessage => _statusMessage;
  String? get localizedPrice => localizedPriceFor(removeAdsProductId);

  String? localizedPriceFor(String id) => _products[id]?.price;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _preferences = await SharedPreferences.getInstance();
      _hasRemoveAdsEntitlement =
          _preferences?.getBool(_removeAdsEntitlementKey) ?? false;
      _hasMultiViewerEntitlement =
          _preferences?.getBool(_multiViewerEntitlementKey) ?? false;
    } catch (error) {
      debugPrint('Unable to read IAP cache: $error');
    }
    notifyListeners();

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _statusMessage = 'purchase_stream_error';
        _purchasingProductId = null;
        notifyListeners();
        debugPrint('Purchase stream error: $error');
      },
    );

    unawaited(_initializeStore());
  }

  Future<void> _initializeStore() async {
    try {
      await _loadProducts();
      if (_isAvailable && defaultTargetPlatform == TargetPlatform.android) {
        await _syncAndroidEntitlement();
      }
    } finally {
      _isEntitlementResolved = true;
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _isAvailable = await _store.isAvailable();
      if (!_isAvailable) {
        _statusMessage = 'store_unavailable';
        return;
      }

      final response = await _store.queryProductDetails({
        removeAdsProductId,
        multiViewerProductId,
        premiumPlusProductId,
      });
      if (response.error != null) {
        _statusMessage = _isNetworkError(response.error)
            ? 'network_error'
            : 'product_query_error';
        debugPrint('Product query failed: ${response.error}');
      } else if (response.productDetails.isEmpty) {
        _statusMessage = 'product_not_found';
        debugPrint('IAP product not found: ${response.notFoundIDs}');
      } else {
        _products
          ..clear()
          ..addEntries(
            response.productDetails.map(
              (product) => MapEntry(product.id, product),
            ),
          );
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('IAP products not found: ${response.notFoundIDs}');
        }
        _statusMessage = null;
      }
    } catch (error) {
      _statusMessage = 'product_query_error';
      debugPrint('Unable to query IAP product: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseRemoveAds() async {
    return purchaseProduct(removeAdsProductId);
  }

  Future<bool> purchaseProduct(String id) async {
    if (_hasEntitlementFor(id) || isPurchasing) return false;
    _statusMessage = null;
    if (!_isAvailable || !_products.containsKey(id)) {
      await _loadProducts();
    }
    final product = _products[id];
    if (!_isAvailable || product == null) {
      _statusMessage ??= 'product_not_found';
      notifyListeners();
      return false;
    }

    _purchasingProductId = id;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _purchasingProductId = null;
        _statusMessage = 'purchase_not_started';
        notifyListeners();
      } else {
        await RoomAnalyticsService.logEvent(
          'purchase_started',
          parameters: {'product_id': id},
        );
      }
      return started;
    } catch (error) {
      _purchasingProductId = null;
      _statusMessage = 'purchase_error';
      debugPrint('Unable to start IAP purchase: $error');
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    _statusMessage = null;
    notifyListeners();
    try {
      if (!await _store.isAvailable()) {
        _statusMessage = 'store_unavailable';
        notifyListeners();
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _syncAndroidEntitlement(isManualRestore: true);
      } else {
        await _store.restorePurchases();
        _statusMessage = 'restore_requested';
      }
    } catch (error) {
      _statusMessage = 'restore_error';
      debugPrint('Unable to restore purchases: $error');
    }
    notifyListeners();
  }

  Future<void> _syncAndroidEntitlement({bool isManualRestore = false}) async {
    try {
      final response = await _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      if (response.error != null) {
        _statusMessage = isManualRestore
            ? (_isNetworkError(response.error)
                  ? 'network_error'
                  : 'restore_error')
            : null;
        debugPrint('Google Play ownership query failed: ${response.error}');
        return;
      }

      final ownedPurchases = response.pastPurchases
          .where(
            (purchase) =>
                _knownProductIds.contains(purchase.productID) &&
                (purchase.status == PurchaseStatus.purchased ||
                    purchase.status == PurchaseStatus.restored),
          )
          .toList();
      final ownedProductIds = ownedPurchases
          .map((purchase) => purchase.productID)
          .toSet();
      await _setRemoveAdsEntitlement(
        ownedProductIds.contains(removeAdsProductId),
      );
      await _setMultiViewerEntitlement(
        ownedProductIds.contains(multiViewerProductId),
      );
      _hasPremiumPlusEntitlement = ownedProductIds.contains(
        premiumPlusProductId,
      );
      for (final purchase in ownedPurchases) {
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
      }
      if (isManualRestore) {
        _statusMessage = ownedPurchases.isEmpty
            ? 'restore_no_purchases'
            : 'restore_success';
      }
    } catch (error) {
      _statusMessage = isManualRestore ? 'restore_error' : null;
      debugPrint('Google Play ownership query failed: $error');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (_knownProductIds.contains(purchase.productID)) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
            await _grantEntitlement(purchase.productID);
            _purchasingProductId = null;
            _statusMessage = 'purchase_success';
            await _logPurchase(purchase);
            await RoomAnalyticsService.logEvent(
              'purchase_completed',
              parameters: {'product_id': purchase.productID},
            );
          case PurchaseStatus.restored:
            await _grantEntitlement(purchase.productID);
            _purchasingProductId = null;
            _statusMessage = 'restore_success';
          case PurchaseStatus.error:
            _purchasingProductId = null;
            _statusMessage = _isNetworkError(purchase.error)
                ? 'network_error'
                : 'purchase_error';
            debugPrint('IAP transaction failed: ${purchase.error}');
          case PurchaseStatus.canceled:
            _purchasingProductId = null;
            _statusMessage = 'purchase_canceled';
          case PurchaseStatus.pending:
            _purchasingProductId = purchase.productID;
        }
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _purchasingProductId = null;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (error) {
          debugPrint('Unable to complete IAP transaction: $error');
        }
      }
    }
    notifyListeners();
  }

  Future<void> _grantEntitlement(String id) async {
    switch (id) {
      case removeAdsProductId:
        await _setRemoveAdsEntitlement(true);
      case multiViewerProductId:
        await _setMultiViewerEntitlement(true);
      case premiumPlusProductId:
        _hasPremiumPlusEntitlement = true;
    }
  }

  bool _hasEntitlementFor(String id) => switch (id) {
    removeAdsProductId => _hasRemoveAdsEntitlement,
    multiViewerProductId => _hasMultiViewerEntitlement,
    premiumPlusProductId => _hasPremiumPlusEntitlement,
    _ => false,
  };

  Set<String> get _knownProductIds => const {
    removeAdsProductId,
    multiViewerProductId,
    premiumPlusProductId,
  };

  Future<void> _setRemoveAdsEntitlement(bool purchased) async {
    _hasRemoveAdsEntitlement = purchased;
    try {
      await (_preferences ??= await SharedPreferences.getInstance()).setBool(
        _removeAdsEntitlementKey,
        purchased,
      );
    } catch (error) {
      debugPrint('Unable to persist IAP entitlement: $error');
    }
  }

  Future<void> _setMultiViewerEntitlement(bool purchased) async {
    _hasMultiViewerEntitlement = purchased;
    try {
      await (_preferences ??= await SharedPreferences.getInstance()).setBool(
        _multiViewerEntitlementKey,
        purchased,
      );
    } catch (error) {
      debugPrint('Unable to persist IAP entitlement: $error');
    }
  }

  bool _isNetworkError(IAPError? error) {
    if (error == null) return false;
    final details = '${error.code} ${error.message}'.toLowerCase();
    return details.contains('network') ||
        details.contains('timeout') ||
        details.contains('service_unavailable');
  }

  Future<void> _logPurchase(PurchaseDetails purchase) async {
    if (Firebase.apps.isEmpty) return;
    final product = _products[purchase.productID];
    if (product == null) return;
    final transactionId = purchase.purchaseID;
    final transactionKey = purchase.productID == removeAdsProductId
        ? _removeAdsAnalyticsTransactionKey
        : 'last_iap_analytics_${purchase.productID}';
    if (transactionId != null &&
        _preferences?.getString(transactionKey) == transactionId) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logPurchase(
        currency: product.currencyCode,
        value: product.rawPrice,
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemId: purchase.productID,
            itemName: product.title,
            price: product.rawPrice,
            currency: product.currencyCode,
          ),
        ],
      );
      if (transactionId != null) {
        await (_preferences ??= await SharedPreferences.getInstance())
            .setString(transactionKey, transactionId);
      }
    } catch (error) {
      debugPrint('Unable to log IAP purchase: $error');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
