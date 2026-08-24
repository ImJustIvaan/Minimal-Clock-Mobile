import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'supabase_service.dart';

const kProProductId = 'pro_unlock';
const kTipProductIds = ['tip_small', 'tip_medium', 'tip_large'];

class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Fires with `true` once a Pro purchase has been verified server-side —
  /// entitlement_provider listens to this to refresh state without polling.
  final proUnlockedController = StreamController<void>.broadcast();

  void init() {
    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProducts() {
    return _iap.queryProductDetails({kProProductId, ...kTipProductIds});
  }

  Future<void> buyPro(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> buyTip(ProductDetails product) {
    return _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      final isPro = purchase.productID == kProProductId;
      final isSuccess = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;

      if (isSuccess && isPro) {
        final verified = await _verifyProPurchase(purchase);
        if (verified) proUnlockedController.add(null);
      }
      // Tip purchases need no server verification — there's no entitlement
      // to protect, just complete them so the store clears the transaction.

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyProPurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    try {
      final response = await SupabaseService.client.functions.invoke(
        'verify-purchase',
        body: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'productId': purchase.productID,
          'token': token,
        },
      );
      return response.data is Map && response.data['is_pro'] == true;
    } catch (_) {
      return false;
    }
  }
}
