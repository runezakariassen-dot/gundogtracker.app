import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../../domain/subscription/subscription_service.dart';

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({super.key});

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  final SubscriptionService _service = SubscriptionService();
  SubscriptionStatus _status = SubscriptionStatus.unknown;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      await _service.init();
      final status = await _service.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
      });
    } on InAppPurchaseException catch (e) {
      _showError(e.message ?? 'Kunne ikke hente status');
    } catch (e) {
      _showError('Kunne ikke hente status');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchase() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _service.purchaseMonthly();
    } on InAppPurchaseException catch (e) {
      _showError(e.message ?? 'Kunne ikke starte kjøp');
    } catch (_) {
      _showError('Kunne ikke starte kjøp');
    } finally {
      await _refreshStatus();
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _restore() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _service.restorePurchases();
    } on InAppPurchaseException catch (e) {
      _showError(e.message ?? 'Kunne ikke gjenopprette kjøp');
    } catch (_) {
      _showError('Kunne ikke gjenopprette kjøp');
    } finally {
      await _refreshStatus();
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _refreshStatus() async {
    final status = await _service.getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
    });
  }

  String _statusText() {
    switch (_status) {
      case SubscriptionStatus.active:
        return AppLocalizations.of(context)!.subscription_status_active;
      case SubscriptionStatus.inactive:
        return AppLocalizations.of(context)!.subscription_status_inactive;
      case SubscriptionStatus.unknown:
        return AppLocalizations.of(context)!.subscription_status_unknown;
    }
  }

  Future<void> _openManage() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showError('Kunne ikke åpne abonnementssiden');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subscription_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.subscription_status_label),
              trailing: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _statusText(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working ? null : _purchase,
                child: Text(l10n.subscription_subscribe_button),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _working ? null : _restore,
                child: Text(l10n.subscription_restore_button),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _openManage,
                child: Text(l10n.subscription_manage_button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
