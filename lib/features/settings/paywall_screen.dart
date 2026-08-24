import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/providers/entitlement_provider.dart';
import '../../core/services/purchase_service.dart';
import '../../shared/widgets/tv_focusable.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProductDetails? _proProduct;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final available = await PurchaseService.instance.isAvailable();
      if (!available) {
        setState(() {
          _error = 'The store is unavailable right now.';
          _loading = false;
        });
        return;
      }
      final response = await PurchaseService.instance.queryProducts();
      final matches = response.productDetails.where((p) => p.id == kProProductId);
      setState(() {
        _proProduct = matches.isEmpty ? null : matches.first;
        if (_proProduct == null) _error = 'Pro isn\'t available right now.';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Couldn\'t load Pro right now.';
        _loading = false;
      });
    }
  }

  Future<void> _buy() async {
    final product = _proProduct;
    if (product == null) return;
    setState(() => _busy = true);
    try {
      await PurchaseService.instance.buyPro(product);
      // Success/failure arrives asynchronously via the purchase stream,
      // which entitlementProvider is listening to — this screen just waits
      // for that state to flip and pops itself once it does (see build()).
    } catch (_) {
      if (mounted) setState(() => _error = 'Purchase failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await PurchaseService.instance.restorePurchases();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final isPro = ref.watch(entitlementProvider).valueOrNull ?? false;

    ref.listen(entitlementProvider, (previous, next) {
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Clock Pro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.workspace_premium_outlined, size: 56, color: color),
              const SizedBox(height: 24),
              Text(
                isPro ? 'You\'re a Pro' : 'Unlock Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: color),
              ),
              const SizedBox(height: 16),
              _Benefit(text: 'The full font library', color: color),
              _Benefit(text: 'Unlimited world clocks', color: color),
              const SizedBox(height: 32),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (isPro)
                Center(
                  child: Text(
                    'Thanks for supporting Minimal Clock!',
                    style: TextStyle(color: color.withOpacity(0.6)),
                  ),
                )
              else ...[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                TvFocusable(
                  onTap: (_busy || _proProduct == null) ? null : _buy,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _proProduct == null ? color.withOpacity(0.3) : color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _proProduct == null
                            ? '...'
                            : 'Unlock for ${_proProduct!.price}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(
                    'Restore Purchases',
                    style: TextStyle(color: color.withOpacity(0.5), fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  final Color color;

  const _Benefit({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: color.withOpacity(0.7)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 15, color: color.withOpacity(0.85))),
        ],
      ),
    );
  }
}
