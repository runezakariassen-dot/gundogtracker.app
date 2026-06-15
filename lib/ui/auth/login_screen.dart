// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _busy = false;
    _autoValidateMode = AutovalidateMode.disabled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetBusy();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _setBusy(bool value) {
    if (mounted) {
      setState(() {
        _busy = value;
      });
    } else {
      _busy = value;
    }
  }

  void _resetBusy() {
    if (_busy) {
      _setBusy(false);
    }
    if (_autoValidateMode != AutovalidateMode.disabled) {
      setState(() {
        _autoValidateMode = AutovalidateMode.disabled;
      });
    }
  }

  Future<void> _signIn() async {
    debugPrint('[AUTH] Login pressed. submitting=$_busy');
    final formState = _formKey.currentState;
    debugPrint('[AUTH] formState=${formState == null ? "null" : "present"}');
    final valid = formState?.validate() ?? false;
    debugPrint('[AUTH] submit start valid=$valid');

    if (!valid) {
      setState(() {
        _autoValidateMode = AutovalidateMode.always;
      });
      _showError(AppLocalizations.of(context)?.common_unknown ??
          'Sjekk feltene og prøv igjen.');
      return;
    }

    FocusScope.of(context).unfocus();
    _setBusy(true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AUTH] signIn ok uid=${result.user?.uid}');
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context);
      _showError(e.message ?? l10n?.common_unknown ?? 'Innlogging feilet');
    } catch (e) {
      _showError('Ukjent feil: $e');
    } finally {
      _setBusy(false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openSignUp() async {
    if (_busy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpScreen(
          initialEmail: _emailCtrl.text.trim(),
        ),
      ),
    );
    _resetBusy();
  }

  Future<void> _openForgotPassword() async {
    if (_busy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _emailCtrl.text.trim(),
        ),
      ),
    );
    _resetBusy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsets = MediaQuery.of(context).viewInsets;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsets.bottom, top: 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 56,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Logg inn',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Logg inn med e-post og passord for å fortsette.',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  autovalidateMode: _autoValidateMode,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'E-post',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (v) {
                                          final value = (v ?? '').trim();
                                          if (value.isEmpty) {
                                            return 'Skriv inn e-post.';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Ugyldig e-post.';
                                          }
                                          return null;
                                        },
                                        enabled: !_busy,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        obscureText: _obscure,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) =>
                                            _busy ? null : _signIn(),
                                        decoration: InputDecoration(
                                          labelText: 'Passord',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            onPressed: _busy
                                                ? null
                                                : () => setState(
                                                      () =>
                                                          _obscure = !_obscure,
                                                    ),
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
                                            return 'Skriv inn passord.';
                                          }
                                          if (value.length < 6) {
                                            return 'Passordet må være minst 6 tegn.';
                                          }
                                          return null;
                                        },
                                        enabled: !_busy,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _busy ? null : _signIn,
                                    child: _busy
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Logg inn'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _busy ? null : _openSignUp,
                              child: const Text('Opprett konto'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _busy ? null : _openForgotPassword,
                              child: const Text('Glemt passord'),
                            ),
                          ],
                        ),
                      ],
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
