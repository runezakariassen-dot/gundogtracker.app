import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/subscription/subscription_service.dart';
import '../../../l10n/app_localizations.dart';

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({
    super.key,
    this.service,
  });

  final SubscriptionService? service;

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  static const Duration _restoreTimeout = Duration(seconds: 20);
  static const Duration _refreshTimeout = Duration(seconds: 8);

  bool _loading = true;
  bool _working = false;
  Timer? _restoreTimer;
  Timer? _refreshTimer;

  SubscriptionService get _service =>
      widget.service ?? SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<SubscriptionViewData> _refreshWithTimeout() {
    final completer = Completer<SubscriptionViewData>();
    final timer = Timer(_refreshTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('refresh timed out'));
      }
    });
    _refreshTimer = timer;

    _service.refresh().then((viewData) {
      if (!completer.isCompleted) {
        completer.complete(viewData);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future.whenComplete(() {
      if (identical(_refreshTimer, timer)) {
        _refreshTimer = null;
      }
      timer.cancel();
    });
  }

  Future<void> _restoreWithTimeout() {
    final completer = Completer<void>();
    final timer = Timer(_restoreTimeout, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _restoreTimer = timer;

    _service.restorePurchases().then((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future.whenComplete(() {
      if (identical(_restoreTimer, timer)) {
        _restoreTimer = null;
      }
      timer.cancel();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final viewData = await _refreshWithTimeout();
      if (!viewData.storeAvailable || !viewData.hasMonthlyProduct) {
        debugPrint(
          '[SUBSCRIPTION] product unavailable in settings: '
          'storeAvailable=${viewData.storeAvailable} '
          'hasMonthlyProduct=${viewData.hasMonthlyProduct}',
        );
      }
    } catch (_) {
      _showErrorText((l10n) => l10n.subscription_error_load_status);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      await _refreshWithTimeout();
    } catch (_) {
      // Ignore refresh failures here so the UI never gets stuck in loading.
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

  Future<void> _purchase() async {
    if (_working) {
      return;
    }

    final viewData = _service.state.value;
    if (_loading) {
      _showErrorText((l10n) => l10n.subscription_error_load_status);
      return;
    }
    if (viewData.isPro) {
      _showErrorText((l10n) => l10n.subscription_purchase_success);
      return;
    }
    if (!_canStartPurchase(viewData)) {
      if (_isProductUnavailable(viewData)) {
        debugPrint(
          '[SUBSCRIPTION] blocked purchase attempt: '
          'storeAvailable=${viewData.storeAvailable} '
          'hasMonthlyProduct=${viewData.hasMonthlyProduct}',
        );
        _showUnavailablePurchaseMessage();
      } else {
        _showErrorText((l10n) => l10n.subscription_error_load_status);
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
          _showUnavailablePurchaseMessage();
        } else {
          _showErrorText((loc) => loc.subscription_error_purchase_start);
        }
        break;
    }
  }

  Future<void> _restore() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _restoreWithTimeout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.subscription_restore_success,
          ),
        ),
      );
    } catch (_) {
      _showErrorText((l10n) => l10n.subscription_error_restore_purchase);
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
      await _refreshQuietly();
    }
  }

  String _statusText(SubscriptionViewData viewData) {
    final l10n = AppLocalizations.of(context)!;
    switch (viewData.status) {
      case SubscriptionStatus.active:
        return l10n.subscription_status_active;
      case SubscriptionStatus.inactive:
        return l10n.subscription_status_inactive;
      case SubscriptionStatus.unknown:
        return l10n.subscription_status_unknown;
    }
  }

  String _purchaseButtonLabel(
    AppLocalizations l10n,
    SubscriptionViewData viewData,
  ) {
    if (_working) {
      return l10n.subscription_subscribe_button;
    }
    if (viewData.isPro) {
      return _statusText(viewData);
    }
    return l10n.subscription_subscribe_button;
  }

  Future<void> _openManage() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showErrorText((l10n) => l10n.subscription_error_manage_open);
    }
  }

  void _showErrorText(String Function(AppLocalizations l10n) messageBuilder) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messageBuilder(l10n))),
    );
  }

  void _showUnavailablePurchaseMessage() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_unavailableProductMessage(l10n))),
    );
  }

  String _unavailableProductMessage(AppLocalizations l10n) {
    return l10n.subscription_error_product_unavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<SubscriptionViewData>(
      valueListenable: _service.state,
      builder: (context, viewData, _) {
        final theme = Theme.of(context);
        final productTitle = viewData.productTitle?.trim().isNotEmpty == true
            ? viewData.productTitle!.trim()
            : l10n.subscription_product_title;
        final priceText = viewData.monthlyPrice?.trim().isNotEmpty == true
            ? viewData.monthlyPrice!.trim()
            : l10n.subscription_price_unavailable;
        final isProductUnavailable = _isProductUnavailable(viewData);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.subscription_title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.subscription_description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _SubscriptionProductSummary(
                  productTitle: productTitle,
                  statusText:
                      '${l10n.subscription_status_label}: ${_statusText(viewData)}',
                  priceText: priceText,
                  isLoading: _loading,
                  unavailableMessage: isProductUnavailable
                      ? _unavailableProductMessage(l10n)
                      : null,
                ),
                const SizedBox(height: 18),
                _BenefitRow(text: l10n.subscription_benefit_unlimited_dogs),
                const SizedBox(height: 7),
                _BenefitRow(text: l10n.subscription_benefit_unlimited_sessions),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _purchase,
                    child: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_purchaseButtonLabel(l10n, viewData)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (_working || _loading) ? null : _restore,
                    child: Text(l10n.subscription_restore_button),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _openManage,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.subscription_manage_button,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubscriptionProductSummary extends StatelessWidget {
  const _SubscriptionProductSummary({
    required this.productTitle,
    required this.statusText,
    required this.priceText,
    required this.isLoading,
    required this.unavailableMessage,
  });

  final String productTitle;
  final String statusText;
  final String priceText;
  final bool isLoading;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 11),
          if (isLoading)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _SubscriptionPriceBadge(
              label: priceText,
              isUnavailable: unavailableMessage != null,
            ),
          if (unavailableMessage != null) ...[
            const SizedBox(height: 10),
            _UnavailableProductNotice(message: unavailableMessage!),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionPriceBadge extends StatelessWidget {
  const _SubscriptionPriceBadge({
    required this.label,
    required this.isUnavailable,
  });

  final String label;
  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isUnavailable
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isUnavailable
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _UnavailableProductNotice extends StatelessWidget {
  const _UnavailableProductNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_outline, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
