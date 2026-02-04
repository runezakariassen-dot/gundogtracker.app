import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/hive_boxes.dart';
import '../domain/domain_errors.dart';
import '../models/dog.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/sharing_service.dart';
import 'dog_detail_page.dart';
import 'qr_scan_page.dart';
import '../l10n/app_localizations.dart';

class AcceptSharePage extends StatefulWidget {
  const AcceptSharePage({super.key});

  @override
  State<AcceptSharePage> createState() => _AcceptSharePageState();
}

class _AcceptSharePageState extends State<AcceptSharePage> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  late final Box<Dog> _dogsBox;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
  }

  Future<void> _showMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.common_ok),
            ),
          ],
        );
      },
    );
  }

  String _errorMessage(AppLocalizations l10n, ShareError code) {
    switch (code) {
      case ShareError.notOwner:
        return l10n.share_error_not_owner;
      case ShareError.inviteNotFound:
        return l10n.share_error_invite_not_found;
      case ShareError.inviteExpired:
        return l10n.share_error_invite_expired;
      case ShareError.inviteRevoked:
        return l10n.share_error_invite_revoked;
      case ShareError.inviteInactive:
        return l10n.share_error_invite_inactive;
      case ShareError.alreadyHasAccess:
        return l10n.share_error_already_has_access;
      case ShareError.invalidRole:
        return l10n.share_error_invalid_role;
      case ShareError.invalidEmail:
        return l10n.share_error_invalid_email;
    }
  }

  Future<void> _accept() async {
    var token = _controller.text.trim();
    const prefix = 'JAKTHUND_INVITE:';
    if (token.toUpperCase().startsWith(prefix)) {
      token = token.substring(prefix.length);
    }
    if (token.isEmpty) return;
    setState(() {
      _busy = true;
    });
    try {
      final membership = await SharingService().acceptShareInvite(token: token);
      final dogs = _dogsBox;
      final dog = dogs.values.cast<Dog?>().firstWhere(
          (d) => d?.dogKey == membership.dogKey,
          orElse: () => null);
      if (!mounted) return;
      if (dog == null) {
        final l10n = AppLocalizations.of(context)!;
        await _showMessage(
          l10n.share_error_dog_not_found_title,
          l10n.share_error_dog_not_found_detail,
        );
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DogDetailPage(dog: dog)),
      );
    } on ShareException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await _showMessage(
        l10n.share_error_dialog_title,
        _errorMessage(l10n, e.code),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (!mounted || result == null || result.trim().isEmpty) return;
    setState(() {
      _controller.text = result.trim();
    });
    await _accept();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.share_accept_title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.share_accept_code_label,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _scanQr,
              child: Text(l10n.share_accept_scan_qr),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _accept,
              child: Text(l10n.share_accept_button),
            ),
          ],
        ),
      ),
    );
  }
}
