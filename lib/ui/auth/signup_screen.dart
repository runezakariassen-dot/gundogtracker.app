import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _busy = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signup_success)),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e, l10n));
    } catch (_) {
      _showError(l10n.signup_error_generic);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e, AppLocalizations l10n) {
    switch (e.code) {
      case 'email-already-in-use':
        return l10n.signup_error_email_in_use;
      case 'invalid-email':
        return l10n.signup_error_invalid_email;
      case 'weak-password':
        return l10n.signup_error_weak_password;
      case 'operation-not-allowed':
        return l10n.signup_error_operation_not_allowed;
      case 'network-request-failed':
        return l10n.signup_error_network;
      default:
        return l10n.signup_error_generic;
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
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signup_title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.signup_intro,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.signup_email_label,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) {
                                return l10n.signup_validation_email_missing;
                              }
                              if (!value.contains('@')) {
                                return l10n.signup_validation_email_invalid;
                              }
                              return null;
                            },
                            enabled: !_busy,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.signup_password_label,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                        setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '');
                              if (value.isEmpty) {
                                return l10n.signup_validation_password_missing;
                              }
                              if (value.length < 6) {
                                return l10n.signup_validation_password_short;
                              }
                              return null;
                            },
                            enabled: !_busy,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password2Ctrl,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                _busy ? null : _createAccount(),
                            decoration: InputDecoration(
                              labelText: l10n.signup_password_repeat_label,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final value = (v ?? '');
                              if (value.isEmpty) {
                                return l10n
                                    .signup_validation_password_repeat_missing;
                              }
                              if (value != _passwordCtrl.text) {
                                return l10n.signup_validation_password_mismatch;
                              }
                              return null;
                            },
                            enabled: !_busy,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _createAccount,
                              child: _busy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(l10n.signup_create_button),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
