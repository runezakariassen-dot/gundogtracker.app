import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/hive_boxes.dart';
import '../domain/domain_errors.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/share_invitation.dart';
import '../services/cloud/firestore_share_invitation_sync_service.dart';
import '../services/sharing_service.dart';
import '../l10n/app_localizations.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  late final Box<ShareInvitation> _shareBox;
  late final Box<Dog> _dogsBox;
  final Set<String> _processingInvites = <String>{};
  final SharingService _sharingService = SharingService();
  final FirestoreShareInvitationSyncService _cloudInviteSyncService =
      FirestoreShareInvitationSyncService.instance;

  @override
  void initState() {
    super.initState();
    _shareBox = shareInvitesBox();
    _dogsBox = dogsBox();
    if (Firebase.apps.isNotEmpty) {
      unawaited(_pullIncomingInvites());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder(
      valueListenable: _shareBox.listenable(),
      builder: (context, Box<ShareInvitation> box, _) {
        final currentEmail = _currentUserEmail();
        final currentUid = _currentUserId();
        final invites = box.values
            .where((invite) =>
                invite.status == Status.pending &&
                ((currentEmail != null &&
                        currentEmail.isNotEmpty &&
                        invite.recipientEmail == currentEmail) ||
                    ((currentUid?.isNotEmpty ?? false) &&
                        invite.recipientUserId == currentUid)))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return Scaffold(
          appBar: AppBar(title: Text(l10n.invitations_title)),
          body: invites.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text(l10n.invitations_empty)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: invites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final invite = invites[index];
                    final dog = _findDogByDogKey(invite.dogKey);
                    final dogName = _resolveDogName(invite, dog);
                    final senderName = _resolveSenderName(invite);
                    final isProcessing =
                        _processingInvites.contains(invite.inviteId);

                    return Card(
                      child: ListTile(
                        title: Text(
                          _inviteSummary(
                            l10n,
                            senderName: senderName,
                            dogName: dogName,
                          ),
                        ),
                        subtitle: Text(l10n.invite_status_invited_as_user(
                          _roleLabel(l10n, invite.role),
                        )),
                        trailing: SizedBox(
                          width: 160,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _acceptInvite(invite),
                                  child: Text(l10n.invite_accept),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _declineInvite(invite),
                                  child: Text(l10n.invite_decline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _acceptInvite(ShareInvitation invite) async {
    if (_processingInvites.contains(invite.inviteId)) return;
    setState(() => _processingInvites.add(invite.inviteId));
    try {
      await _sharingService.acceptShareInvite(token: invite.token);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_invite_accepted)),
      );
    } on ShareException catch (error) {
      _showShareError(error);
    } finally {
      if (mounted) {
        setState(() => _processingInvites.remove(invite.inviteId));
      }
    }
  }

  Future<void> _declineInvite(ShareInvitation invite) async {
    if (_processingInvites.contains(invite.inviteId)) return;
    setState(() => _processingInvites.add(invite.inviteId));
    try {
      await _sharingService.declineShareInvite(inviteId: invite.inviteId);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dog_detail_snackbar_invite_declined)),
      );
    } on ShareException catch (error) {
      _showShareError(error);
    } finally {
      if (mounted) {
        setState(() => _processingInvites.remove(invite.inviteId));
      }
    }
  }

  void _showShareError(ShareException error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_shareErrorMessage(l10n, error.code))),
    );
  }

  String _shareErrorMessage(AppLocalizations l10n, ShareError code) {
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
      case ShareError.alreadyInvited:
        return l10n.share_error_already_invited;
      case ShareError.invalidRole:
        return l10n.share_error_invalid_role;
      case ShareError.invalidEmail:
        return l10n.share_error_invalid_email;
    }
  }

  Future<void> _pullIncomingInvites() async {
    final count = await _cloudInviteSyncService
        .pullPendingInvitesForCurrentUserIntoLocalBox();
    if (!mounted) return;
    debugPrint('[INVITES] pulled incoming invites from cloud: $count');
  }

  String? _currentUserEmail() {
    try {
      final email = FirebaseAuth.instance.currentUser?.email?.trim();
      if (email != null && email.isNotEmpty) {
        return email.toLowerCase();
      }
    } catch (_) {
      // Firebase may be unavailable in local-only startup/tests.
    }
    return null;
  }

  String? _currentUserId() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid.trim();
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    } catch (_) {
      // Firebase may be unavailable in local-only startup/tests.
    }
    return null;
  }

  Dog? _findDogByDogKey(String dogKey) {
    for (final dog in _dogsBox.values) {
      if (dog.dogKey == dogKey) {
        return dog;
      }
    }
    return null;
  }

  String? _resolveDogName(ShareInvitation invite, Dog? dog) {
    final inviteDogName = invite.dogName?.trim();
    if (inviteDogName != null && inviteDogName.isNotEmpty) {
      return inviteDogName;
    }
    final localDogName = dog?.displayName.trim();
    if (localDogName != null && localDogName.isNotEmpty) {
      return localDogName;
    }
    return null;
  }

  String? _resolveSenderName(ShareInvitation invite) {
    final displayName = invite.senderDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = invite.senderEmail?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return null;
  }

  String _inviteSummary(
    AppLocalizations l10n, {
    required String? senderName,
    required String? dogName,
  }) {
    if (dogName == null || dogName.isEmpty) {
      return l10n.invitation_summary_generic;
    }
    if (senderName == null || senderName.isEmpty) {
      return l10n.invitation_summary_with_dog(dogName);
    }
    return l10n.invitation_summary_with_sender_and_dog(senderName, dogName);
  }

  String _roleLabel(AppLocalizations l10n, Role role) {
    switch (role.canonical) {
      case CanonicalRole.admin:
        return l10n.share_role_admin;
      case CanonicalRole.user:
        return l10n.share_role_user;
    }
  }
}
