import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;

  bool _busy = false;
  bool _resetSent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final l10n = AppLocalizations.of(context)!;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _busy = true;
      _resetSent = false;
    });

    try {
      final email = _emailCtrl.text.trim();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _showMessage(l10n.settings_reset_password_sent);
      setState(() => _resetSent = true);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? l10n.common_unknown);
    } catch (e) {
      _showError('Ukjent feil: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      } else {
        _busy = false;
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgot_password_title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.forgot_password_description,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _sendReset(),
                      decoration: InputDecoration(
                        labelText: l10n.forgot_password_email_label,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) {
                          return l10n.forgot_password_error_missing;
                        }
                        if (!value.contains('@')) {
                          return l10n.forgot_password_error_invalid;
                        }
                        return null;
                      },
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _sendReset,
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.forgot_password_button),
                      ),
                    ),
                    if (_resetSent) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.forgot_password_check_spam_hint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
