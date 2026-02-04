import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        const SnackBar(content: Text('Konto opprettet!')),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e));
    } catch (e) {
      _showError('Ukjent feil: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'E-postadressen er allerede i bruk.';
      case 'invalid-email':
        return 'Ugyldig e-postadresse.';
      case 'weak-password':
        return 'Passordet er for svakt. Bruk minst 6 tegn.';
      case 'operation-not-allowed':
        return 'E-post/passord er ikke aktivert i Firebase-prosjektet.';
      case 'network-request-failed':
        return 'Nettverksfeil. Sjekk internett og prøv igjen.';
      default:
        return 'Kunne ikke opprette konto (${e.code}).';
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
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(title: const Text('Opprett konto')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Opprett en konto med e-post og passord.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-post',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Skriv inn e-post.';
                              if (!value.contains('@')) return 'Ugyldig e-post.';
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
                              labelText: 'Passord',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '');
                              if (value.isEmpty) return 'Skriv inn passord.';
                              if (value.length < 6) return 'Minst 6 tegn.';
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
                            decoration: const InputDecoration(
                              labelText: 'Gjenta passord',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final value = (v ?? '');
                              if (value.isEmpty) return 'Gjenta passordet.';
                              if (value != _passwordCtrl.text) {
                                return 'Passordene er ikke like.';
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
                                  : const Text('Opprett konto'),
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
