import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/subscription_products.dart';
import '../../domain/subscription/subscription_service.dart';
import '../../l10n/app_localizations.dart';

/// Shows the Pro upgrade bottom sheet and triggers the purchase flow
/// when the store data is ready.
///
/// Call this instead of showing a snackbar when a free-tier limit is hit.
Future<void> showProUpgradeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _ProUpgradeSheetContent(),
  );
}

class _ProUpgradeSheetContent extends StatefulWidget {
  const _ProUpgradeSheetContent();

  @override
  State<_ProUpgradeSheetContent> createState() =>
      _ProUpgradeSheetContentState();
}

class _ProUpgradeSheetContentState extends State<_ProUpgradeSheetContent> {
  static const Duration _refreshTimeout = Duration(seconds: 8);

  bool _loading = true;
  bool _working = false;

  SubscriptionService get _service => SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _service.refresh().timeout(_refreshTimeout);
    } catch (_) {
      // Keep UI responsive and let the sheet show the current state.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isProductUnavailable(SubscriptionViewData viewData) {
    return !_loading &&
        (!viewData.storeAvailable || !viewData.hasMonthlyProduct);
  }

  bool _canStartPurchase(SubscriptionViewData viewData) {
    return !_loading &&
        !_working &&
        !viewData.isPro &&
        viewData.storeAvailable &&
        viewData.hasMonthlyProduct;
  }

  Future<void> _refreshQuietly() async {
    try {
      await _service.refresh().timeout(_refreshTimeout);
    } catch (_) {
      // Ignore refresh failures here so UI does not get stuck.
    }
  }

  Future<void> _onUpgrade() async {
    if (_working) {
      return;
    }

    final viewData = _service.state.value;
    if (_loading) {
      _showLoadStatusMessage();
      return;
    }
    if (viewData.isPro) {
      _showSuccessMessage();
      return;
    }
    if (!_canStartPurchase(viewData)) {
      if (_isProductUnavailable(viewData)) {
        _showUnavailableMessage();
      } else {
        _showLoadStatusMessage();
      }
      return;
    }

    setState(() => _working = true);

    SubscriptionPurchaseResult result;
    try {
      result = await _service.purchaseMonthly();
    } catch (_) {
      result = SubscriptionPurchaseResult.error;
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }

    if (result != SubscriptionPurchaseResult.started) {
      await _refreshQuietly();
    }

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    switch (result) {
      case SubscriptionPurchaseResult.started:
        break;
      case SubscriptionPurchaseResult.success:
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.subscription_purchase_success)),
        );
        break;
      case SubscriptionPurchaseResult.cancelled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.subscription_purchase_cancelled)),
        );
        break;
      case SubscriptionPurchaseResult.error:
        if (_isProductUnavailable(_service.state.value)) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.subscription_error_product_unavailable),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.subscription_error_purchase_start),
            ),
          );
        }
        break;
    }
  }

  void _showUnavailableMessage() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.subscription_error_product_unavailable)),
    );
  }

  void _showLoadStatusMessage() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.subscription_error_load_status)),
    );
  }

  void _showSuccessMessage() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.subscription_purchase_success)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ValueListenableBuilder<SubscriptionViewData>(
      valueListenable: _service.state,
      builder: (context, viewData, _) {
        final productTitle = viewData.productTitle?.trim().isNotEmpty == true
            ? viewData.productTitle!.trim()
            : l10n.subscription_product_title;
        final priceText = viewData.monthlyPrice?.trim().isNotEmpty == true
            ? viewData.monthlyPrice!.trim()
            : l10n.subscription_price_unavailable;
        final isUnavailable = _isProductUnavailable(viewData);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oppgrader til Pro 🐕',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Du har nå nådd maks $freeDogLimit hunder i gratisversjonen.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              ..._benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      productTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        priceText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isUnavailable
                              ? scheme.onSurfaceVariant
                              : scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (isUnavailable) ...[
                const SizedBox(height: 16),
                _UnavailableNotice(
                  message: l10n.subscription_error_product_unavailable,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _onUpgrade,
                  child: _working
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.subscription_subscribe_button,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed:
                      _working ? null : () => Navigator.of(context).pop(),
                  child: const Text('Ikke nå', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _benefits = [
  'Ubegrenset antall hunder',
  'Full treningshistorikk',
  'Synkronisering og backup',
  'Fremtidige funksjoner',
];
