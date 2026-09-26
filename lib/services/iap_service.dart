import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService extends ChangeNotifier {
  IAPService({InAppPurchase? store}) : _store = store ?? InAppPurchase.instance;

  static const productId = 'remove_ads';
  static const _entitlementKey = 'has_remove_ads_entitlement';
  static const _analyticsTransactionKey =
      'last_remove_ads_analytics_transaction';

  final InAppPurchase _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _isAvailable = false;
  bool _isPurchased = false;
  bool _isEntitlementResolved = false;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _statusMessage;

  bool get isPurchased => _isPurchased;
  bool get isEntitlementResolved => _isEntitlementResolved;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get statusMessage => _statusMessage;
  String? get localizedPrice => _product?.price;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _preferences = await SharedPreferences.getInstance();
      _isPurchased = _preferences?.getBool(_entitlementKey) ?? false;
    } catch (error) {
      debugPrint('Unable to read IAP cache: $error');
    }
    notifyListeners();

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _statusMessage = 'purchase_stream_error';
        _isPurchasing = false;
        notifyListeners();
        debugPrint('Purchase stream error: $error');
      },
    );

    unawaited(_initializeStore());
  }

  Future<void> _initializeStore() async {
    try {
      await _loadProduct();
      if (_isAvailable && defaultTargetPlatform == TargetPlatform.android) {
        await _syncAndroidEntitlement();
      }
    } finally {
      _isEntitlementResolved = true;
      notifyListeners();
    }
  }

  Future<void> _loadProduct() async {
    _isLoading = true;
    notifyListeners();
    try {
      _isAvailable = await _store.isAvailable();
      if (!_isAvailable) {
        _statusMessage = 'store_unavailable';
        return;
      }

      final response = await _store.queryProductDetails({productId});
      if (response.error != null) {
        _statusMessage = _isNetworkError(response.error)
            ? 'network_error'
            : 'product_query_error';
        debugPrint('Product query failed: ${response.error}');
      } else if (response.productDetails.isEmpty) {
        _statusMessage = 'product_not_found';
        debugPrint('IAP product not found: ${response.notFoundIDs}');
      } else {
        _product = response.productDetails.first;
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
    if (_isPurchased || _isPurchasing) return false;
    _statusMessage = null;
    if (!_isAvailable || _product == null) {
      await _loadProduct();
    }
    final product = _product;
    if (!_isAvailable || product == null) {
      _statusMessage ??= 'product_not_found';
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _isPurchasing = false;
        _statusMessage = 'purchase_not_started';
        notifyListeners();
      }
      return started;
    } catch (error) {
      _isPurchasing = false;
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
                purchase.productID == productId &&
                (purchase.status == PurchaseStatus.purchased ||
                    purchase.status == PurchaseStatus.restored),
          )
          .toList();
      await _setEntitlement(ownedPurchases.isNotEmpty);
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
      if (purchase.productID == productId) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
            await _grantEntitlement();
            _isPurchasing = false;
            _statusMessage = 'purchase_success';
            await _logPurchase(purchase);
          case PurchaseStatus.restored:
            await _grantEntitlement();
            _isPurchasing = false;
            _statusMessage = 'restore_success';
          case PurchaseStatus.error:
            _isPurchasing = false;
            _statusMessage = _isNetworkError(purchase.error)
                ? 'network_error'
                : 'purchase_error';
            debugPrint('IAP transaction failed: ${purchase.error}');
          case PurchaseStatus.canceled:
            _isPurchasing = false;
            _statusMessage = 'purchase_canceled';
          case PurchaseStatus.pending:
            _isPurchasing = true;
        }
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _isPurchasing = false;
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

  Future<void> _grantEntitlement() async {
    await _setEntitlement(true);
  }

  Future<void> _setEntitlement(bool purchased) async {
    _isPurchased = purchased;
    try {
      await (_preferences ??= await SharedPreferences.getInstance()).setBool(
        _entitlementKey,
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
    final transactionId = purchase.purchaseID;
    if (transactionId != null &&
        _preferences?.getString(_analyticsTransactionKey) == transactionId) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logPurchase(
        currency: _product?.currencyCode,
        value: _product?.rawPrice,
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: 'Remove ads',
            price: _product?.rawPrice,
            currency: _product?.currencyCode,
          ),
        ],
      );
      if (transactionId != null) {
        await (_preferences ??= await SharedPreferences.getInstance())
            .setString(_analyticsTransactionKey, transactionId);
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
