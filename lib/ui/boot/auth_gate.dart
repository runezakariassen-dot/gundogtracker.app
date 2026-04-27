import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../domain/user/app_user.dart';
import '../../l10n/app_localizations.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.loginBuilder,
    required this.appBuilder,
  });

  final WidgetBuilder loginBuilder;
  final WidgetBuilder appBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _profile;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  Timer? _profileTimeout;
  String? _profileError;
  bool _isWaitingForProfile = false;
  User? _lastUser;
  bool _signOutInProgress = false;

  void _clearProfileCache() {
    _cancelProfileSubscription();
    _cancelProfileTimeout();
    _profile = null;
    _profileError = null;
    _isWaitingForProfile = false;
    _lastUser = null;
  }

  void _refreshProfile() {
    final user = _lastUser;
    if (user == null) return;
    _ensureProfileLoaded(user, force: true);
  }

  void _ensureProfileLoaded(User user, {bool force = false}) {
    if (!force &&
        _lastUser?.uid == user.uid &&
        (_isWaitingForProfile || _profile != null)) {
      return;
    }

    _cancelProfileSubscription();
    _cancelProfileTimeout();
    _lastUser = user;
    setState(() {
      _profile = null;
      _profileError = null;
      _isWaitingForProfile = true;
    });

    final ref = _firestore.collection('users').doc(user.uid);
    _profileSubscription = ref.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final profile = AppUser.fromSnapshot(snapshot);
        _cancelProfileTimeout();
        if (!mounted) return;

        setState(() {
          _profile = profile;
          _isWaitingForProfile = false;
          _profileError = null;
        });
      },
      onError: (error) => _handleProfileError(error),
    );
    _startProfileTimeout();
  }

  void _handleProfileError(Object error) {
    _cancelProfileTimeout();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _profileError = l10n.auth_profile_load_failed_body;
      _isWaitingForProfile = false;
    });
  }

  void _startProfileTimeout() {
    _profileTimeout?.cancel();
    _profileTimeout = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isWaitingForProfile = false;
        _profileError = l10n.auth_profile_timeout_error;
      });
    });
  }

  void _cancelProfileTimeout() {
    _profileTimeout?.cancel();
    _profileTimeout = null;
  }

  void _cancelProfileSubscription() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  void _scheduleProfileLoad(User user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureProfileLoaded(user);
    });
  }

  void _requestSignOutForInvalidUser() {
    if (_signOutInProgress) return;
    _signOutInProgress = true;

    FirebaseAuth.instance
        .signOut()
        .catchError((_) {})
        .whenComplete(() => _signOutInProgress = false);
  }

  @override
  void dispose() {
    _cancelProfileSubscription();
    _cancelProfileTimeout();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _AuthLoadingScreen(message: l10n.auth_loading_waiting);
        }

        if (authSnapshot.hasError) {
          return _AuthErrorScreen(
            title: l10n.auth_profile_load_failed_title,
            message: l10n.auth_profile_load_failed_body,
            onRetry: () => setState(() {}),
          );
        }
        final user = authSnapshot.data;
        if (user == null) {
          _clearProfileCache();
          return widget.loginBuilder(context);
        }

        final isAnonymous = user.isAnonymous;
        final hasProviderData = user.providerData.isNotEmpty;

        if (isAnonymous || !hasProviderData) {
          _clearProfileCache();
          _requestSignOutForInvalidUser();
          return widget.loginBuilder(context);
        }

        if ((_lastUser?.uid != user.uid) ||
            (!_isWaitingForProfile &&
                _profile == null &&
                _profileError == null)) {
          _scheduleProfileLoad(user);
        }

        if (_profile != null) {
          return widget.appBuilder(context);
        }

        if (_profileError != null) {
          return _AuthErrorScreen(
            title: l10n.auth_profile_load_failed_title,
            message: _profileError!,
            onRetry: _refreshProfile,
          );
        }

        return _ProfilePendingScreen(onRetry: _refreshProfile);
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.common_retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePendingScreen extends StatelessWidget {
  const _ProfilePendingScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.auth_profile_pending_title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.auth_profile_pending_body,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.common_retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
