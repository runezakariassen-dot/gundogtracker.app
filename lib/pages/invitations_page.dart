import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/hive_boxes.dart';
import '../domain/domain_errors.dart';
import '../models/dog.dart';
import '../models/dog_membership.dart';
import '../models/share_invitation.dart';
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

  @override
  void initState() {
    super.initState();
    _shareBox = shareInvitesBox();
    _dogsBox = dogsBox();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder(
      valueListenable: _shareBox.listenable(),
      builder: (context, Box<ShareInvitation> box, _) {
        final currentEmail =
            FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
        final invites = currentEmail == null
            ? <ShareInvitation>[]
            : box.values
                .where((invite) =>
                    invite.status == Status.pending &&
                    invite.recipientEmail == currentEmail)
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
                    final dog = _dogsBox.get(invite.dogKey);
                    final trimmedName = dog?.name.trim();
                    final dogName = (trimmedName?.isNotEmpty ?? false)
                        ? trimmedName!
                        : l10n.dog_unnamed;
                    final isProcessing =
                        _processingInvites.contains(invite.inviteId);

                    return Card(
                      child: ListTile(
                        title: Text(dogName),
                        subtitle: Text(l10n.invite_status_invited_as_user(
                          l10n.share_role_user,
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
}
