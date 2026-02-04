import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/community_links.dart';
import '../data/hive_boxes.dart';
import '../domain/services/backup_export_service.dart';
import '../domain/services/backup_restore_service.dart';
import '../models/dog.dart';
import '../models/gps_track.dart';
import '../models/hunt_session.dart';
import '../models/track.dart';
import '../services/dog_photo_storage.dart';
import '../services/hive_lifecycle_service.dart';
import '../ui/settings/feedback/feedback_service.dart';
import '../ui/settings/subscription/subscription_section.dart';
import '../ui/locale/locale_controller.dart';
import '../ui/theme/season_theme_controller.dart';
import '../pages/invitations_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _versionText;
  final FeedbackService _feedbackService = FeedbackService();

  // Backup
  final BackupExportService _backupService = const BackupExportService();
  final BackupRestoreService _restoreService = const BackupRestoreService();

  bool _isExportingBackup = false;
  bool _isRestoringBackup = false;
  String? _backupStatus;
  bool _isSigningOut = false;
  bool _isResettingPassword = false;
  late final Box<dynamic> _settingsBox;
  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;
  late final Box<Track> _tracksBox;
  late final Box<GpsTrack> _gpsTracksBox;
  late final Box<String> _birdSpeciesBox;

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du er logget ut')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(message.isNotEmpty ? message : 'Kunne ikke logge ut')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (_isResettingPassword) return;
    final l10n = AppLocalizations.of(context)!;
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_reset_password_no_email)),
      );
      return;
    }

    setState(() => _isResettingPassword = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_reset_password_sent)),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? l10n.common_unknown)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(email: email),
    );
  }

  @override
  void initState() {
    super.initState();
    _settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _tracksBox = HiveLifecycleService.getBox<Track>(tracksBoxName);
    _gpsTracksBox = HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName);
    _birdSpeciesBox = HiveLifecycleService.getBox<String>(birdSpeciesBoxName);
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final base = 'v${info.version}';
      final build = kDebugMode ? ' (build ${info.buildNumber})' : '';
      if (!mounted) return;
      setState(() {
        _versionText = '$base$build';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionText = null;
      });
    }
  }

  Future<void> _exportBackupZip() async {
    if (_isExportingBackup) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isExportingBackup = true;
      _backupStatus = l10n.settings_backup_status_collectingData;
    });

    try {
      final sessionsBox = _sessionsBox;
      final dogsBox = _dogsBox;
      final milestoneStateBox = dogMilestoneStateBox();
      final tracksStore = _tracksBox;
      final gpsTracks = _gpsTracksBox;
      final birdSpecies = _birdSpeciesBox;

      final boxes = <Box<dynamic>>[
        sessionsBox,
        dogsBox,
        milestoneStateBox,
        tracksStore,
        gpsTracks,
        birdSpecies,
      ];

      setState(
        () => _backupStatus = l10n.settings_backup_status_collectingMedia,
      );

      final filePaths = <String>{};
      for (final s in sessionsBox.values) {
        for (final p in s.mediaPaths) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) filePaths.add(trimmed);
        }
      }
      for (final d in dogsBox.values) {
        final stored = d.imagePath?.trim();
        if (stored == null || stored.isEmpty) continue;
        final resolved = DogPhotoStorage.resolveAbsolutePath(stored);
        if (resolved != null) {
          filePaths.add(resolved);
        }
      }

      setState(() => _backupStatus = l10n.settings_backup_status_creatingZip);

      final zip = await _backupService.exportAll(
        boxes: boxes,
        filePaths: filePaths.toList(),
      );

      setState(() => _backupStatus = l10n.settings_backup_status_sharing);

      await Share.shareXFiles(
        [XFile(zip.path)],
        text: l10n.settings_backup_share_subject,
        sharePositionOrigin: _sharePositionOrigin(context),
      );

      if (!mounted) return;
      final fileName = zip.path.split('/').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_backup_ready(fileName))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_backup_failed(e.toString()))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExportingBackup = false;
        _backupStatus = null;
      });
    }
  }

  Rect _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    }

    final mq = MediaQuery.of(context);
    final center = mq.size.center(Offset.zero);
    return Rect.fromCenter(center: center, width: 1, height: 1);
  }

  Future<void> _restoreBackupZip() async {
    if (_isRestoringBackup) return;
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.settings_backup_restore_dialog_title),
            content: Text(l10n.settings_backup_restore_dialog_content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.settings_backup_restore_dialog_confirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isRestoringBackup = true;
      _backupStatus = l10n.settings_backup_status_selectZip;
    });

    try {
      // Box-navn vi forventer i backup (rå Hive-filer)
      final expectedBoxNames = <String>[
        sessionsBoxName,
        dogsBoxName,
        dogMilestoneStateLegacyBoxName,
        tracksBoxName,
        gpsTracksBoxName,
        birdSpeciesBoxName,
      ];

      setState(() => _backupStatus = l10n.settings_backup_status_restoring);

      debugPrint('[RESTORE][SIGNATURE] SettingsPage calling restoreFromZip');
      final result = await _restoreService.restoreFromZip(
        expectedBoxNames: expectedBoxNames,
      );

      if (!mounted) return;

      if (result.cancelled) {
        return;
      }

      if (!result.ok) {
        final message =
            result.errorMessage ?? l10n.settings_backup_failed_unknown;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_backup_import_failed(message))),
        );
      } else if (result.requiresRestart) {
        final restartNow = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.settings_backup_restore_prompt_title),
                content: Text(l10n.settings_backup_restore_prompt_message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.common_no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.common_yes),
                  ),
                ],
              ),
            ) ??
            false;

        if (restartNow) {
          await HiveLifecycleService.closeAll(reason: 'restart_after_restore');
          Phoenix.rebirth(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settings_backup_restore_saved)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_backup_restore_complete)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_backup_import_failed(e.toString())),
        ),
      );
    } finally {
      _isRestoringBackup = false;
      _backupStatus = null;
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _showBackupFolderInfo() async {
    final l10n = AppLocalizations.of(context)!;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/backups';
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settings_backup_storage_title),
        content: Text(l10n.settings_backup_storage_description(path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BackupRestoreService.isRestoring,
      builder: (context, restoring, _) {
        final shouldBlock = restoring || !HiveLifecycleService.isReady;
        if (shouldBlock) {
          return const _SettingsRestorePendingView();
        }

        final settingsBox = _settingsBox;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settings_title),
          ),
          body: ValueListenableBuilder(
            valueListenable: settingsBox.listenable(
              keys: const [
                'themeMode',
                milestonesEnabledKey,
                hapticsEnabledKey,
                themeSeasonOverrideKey,
              ],
            ),
            builder: (context, Box<dynamic> box, _) {
              final l10n = AppLocalizations.of(context)!;
              final theme = Theme.of(context);

              // Null-safe: titleMedium can be null depending on theme/textTheme setup.
              final sectionStyle = theme.textTheme.titleMedium?.copyWith() ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  );

              final current = box.get('themeMode') ?? 'dark';
              final seasonController = SeasonThemeController(box);
              final seasonOverride = seasonController.getOverride();
              final milestonesEnabled =
                  (box.get(milestonesEnabledKey) as bool?) ?? true;
              final hapticsEnabled =
                  (box.get(hapticsEnabledKey) as bool?) ?? true;
              final preferredLocaleCode =
                  box.get(preferredLocaleCodeKey) as String?;

              final currentUser = FirebaseAuth.instance.currentUser;
              final userEmail = currentUser?.email;
              final hasEmailProvider = currentUser?.providerData
                      .any((provider) => provider.providerId == 'password') ??
                  false;

              final backupSubtitle =
                  _backupStatus ?? l10n.settings_backup_subtitle;

              final busy = _isExportingBackup || _isRestoringBackup;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SubscriptionSection(),
                  const SizedBox(height: 24),

                  // Backup
                  Text(l10n.settings_section_backup, style: sectionStyle),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: Text(
                        _isExportingBackup
                            ? l10n.settings_backup_exporting
                            : l10n.settings_backup_export_action,
                      ),
                      subtitle: Text(backupSubtitle),
                      trailing: _isExportingBackup
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: busy ? null : _exportBackupZip,
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.unarchive_outlined),
                      title: Text(
                        _isRestoringBackup
                            ? l10n.settings_backup_importing
                            : l10n.settings_backup_import_action,
                      ),
                      subtitle: Text(l10n.settings_backup_import_description),
                      trailing: _isRestoringBackup
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: busy ? null : _restoreBackupZip,
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(l10n.settings_backup_where_title),
                      subtitle: Text(l10n.settings_backup_where_action),
                      onTap: _showBackupFolderInfo,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Utseende
                  Text(l10n.settings_section_appearance, style: sectionStyle),
                  const SizedBox(height: 12),
                  _ThemeTile(
                    label: l10n.settings_theme_system,
                    value: 'system',
                    groupValue: current,
                    onSelected: () => box.put('themeMode', 'system'),
                  ),
                  const SizedBox(height: 8),
                  _ThemeTile(
                    label: l10n.settings_theme_light,
                    value: 'light',
                    groupValue: current,
                    onSelected: () => box.put('themeMode', 'light'),
                  ),
                  const SizedBox(height: 8),
                  _ThemeTile(
                    label: l10n.settings_theme_dark,
                    value: 'dark',
                    groupValue: current,
                    onSelected: () => box.put('themeMode', 'dark'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n.settings_season_title),
                    subtitle: Text(l10n.settings_season_subtitle),
                    trailing: DropdownButton<String>(
                      value: seasonOverride,
                      onChanged: (value) {
                        if (value == null) return;
                        seasonController.setOverride(value);
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'auto',
                          child: Text(l10n.settings_season_auto),
                        ),
                        DropdownMenuItem(
                          value: 'spring',
                          child: Text(l10n.settings_season_spring),
                        ),
                        DropdownMenuItem(
                          value: 'summer',
                          child: Text(l10n.settings_season_summer),
                        ),
                        DropdownMenuItem(
                          value: 'autumn',
                          child: Text(l10n.settings_season_autumn),
                        ),
                        DropdownMenuItem(
                          value: 'winter',
                          child: Text(l10n.settings_season_winter),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Milepæler
                  Text(l10n.settings_section_milestones, style: sectionStyle),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(l10n.settings_milestones_enabled_title),
                    subtitle: Text(l10n.settings_milestones_enabled_subtitle),
                    value: milestonesEnabled,
                    onChanged: (value) => box.put(milestonesEnabledKey, value),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settings_haptics_enabled_title),
                    subtitle: Text(l10n.settings_haptics_enabled_subtitle),
                    value: hapticsEnabled,
                    onChanged: (value) => box.put(hapticsEnabledKey, value),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  const SizedBox(height: 24),

                  // Feedback
                  Text(l10n.settings_section_feedback, style: sectionStyle),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n.feedback_send_title),
                    subtitle: Text(l10n.settings_feedback_send_subtitle),
                    leading: const Icon(Icons.mail_outline),
                    onTap: () async {
                      try {
                        final supportEmail =
                            AppLocalizations.of(context)!.supportEmail;
                        await _feedbackService.openFeedbackEmail(
                          box,
                          supportEmail,
                          l10n,
                        );
                      } on PlatformException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.message ??
                                  l10n.settings_feedback_error_open_email,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: Text(l10n.feedback_bug_title),
                    subtitle: Text(l10n.settings_feedback_bug_subtitle),
                    leading: const Icon(Icons.bug_report_outlined),
                    onTap: () async {
                      try {
                        final supportEmail =
                            AppLocalizations.of(context)!.supportEmail;
                        await _feedbackService.openBugReportEmail(
                          box,
                          supportEmail,
                          l10n,
                        );
                      } on PlatformException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.message ??
                                  l10n.settings_feedback_error_open_email,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: Text(l10n.feedback_copy_diagnostics_title),
                    subtitle: Text(l10n.settings_feedback_copy_subtitle),
                    leading: const Icon(Icons.copy),
                    onTap: () async {
                      try {
                        await _feedbackService.copyDiagnostics(box);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.common_copied)),
                        );
                      } on PlatformException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.message ?? l10n.settings_feedback_error_copy,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: Text(l10n.feedback_suggest_milestone_title),
                    subtitle: Text(l10n.settings_feedback_suggest_subtitle),
                    leading: const Icon(Icons.emoji_events_outlined),
                    onTap: () async {
                      try {
                        final supportEmail =
                            AppLocalizations.of(context)!.supportEmail;
                        await _feedbackService.openMilestoneSuggestionEmail(
                          supportEmail,
                          l10n,
                        );
                      } on PlatformException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.message ??
                                  l10n.settings_feedback_error_open_email,
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  Text(l10n.invitations_title, style: sectionStyle),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text(l10n.invitations_title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InvitationsPage(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Community
                  Text(l10n.settings_section_community, style: sectionStyle),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n.community_open_discord),
                    leading: const Icon(Icons.forum_outlined),
                    onTap: () => _openCommunityLink(context, discordUrl),
                  ),
                  ListTile(
                    title: Text(l10n.community_open_facebook),
                    leading: const Icon(Icons.groups_outlined),
                    onTap: () => _openCommunityLink(context, facebookUrl),
                  ),

                  const SizedBox(height: 24),
                  if (hasEmailProvider || userEmail != null) ...[
                    Text(l10n.settings_section_security, style: sectionStyle),
                    const SizedBox(height: 12),
                    if (hasEmailProvider)
                      FilledButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_outline),
                        label: Text(l10n.settings_change_password_title),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    if (hasEmailProvider && userEmail != null)
                      const SizedBox(height: 8),
                    if (userEmail != null)
                      OutlinedButton.icon(
                        onPressed:
                            _isResettingPassword ? null : _handleResetPassword,
                        icon: const Icon(Icons.help_outline),
                        label: Text(l10n.settings_reset_password_button),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _isSigningOut ? null : _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logg ut'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language
                  Text(l10n.settings_section_language, style: sectionStyle),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n.settings_language_followSystem),
                    leading: Radio<String?>(
                      value: null,
                      groupValue: preferredLocaleCode,
                      onChanged: (_) => LocaleController.instance
                          .setPreferredLocaleCode(null),
                    ),
                    onTap: () =>
                        LocaleController.instance.setPreferredLocaleCode(null),
                  ),
                  ListTile(
                    title: Text(l10n.settings_language_nb),
                    leading: Radio<String?>(
                      value: 'nb',
                      groupValue: preferredLocaleCode,
                      onChanged: (_) => LocaleController.instance
                          .setPreferredLocaleCode('nb'),
                    ),
                    onTap: () =>
                        LocaleController.instance.setPreferredLocaleCode('nb'),
                  ),
                  ListTile(
                    title: Text(l10n.settings_language_sv),
                    leading: Radio<String?>(
                      value: 'sv',
                      groupValue: preferredLocaleCode,
                      onChanged: (_) => LocaleController.instance
                          .setPreferredLocaleCode('sv'),
                    ),
                    onTap: () =>
                        LocaleController.instance.setPreferredLocaleCode('sv'),
                  ),
                  ListTile(
                    title: Text(l10n.settings_language_da),
                    leading: Radio<String?>(
                      value: 'da',
                      groupValue: preferredLocaleCode,
                      onChanged: (_) => LocaleController.instance
                          .setPreferredLocaleCode('da'),
                    ),
                    onTap: () =>
                        LocaleController.instance.setPreferredLocaleCode('da'),
                  ),
                  ListTile(
                    title: Text(l10n.settings_language_en),
                    leading: Radio<String?>(
                      value: 'en',
                      groupValue: preferredLocaleCode,
                      onChanged: (_) => LocaleController.instance
                          .setPreferredLocaleCode('en'),
                    ),
                    onTap: () =>
                        LocaleController.instance.setPreferredLocaleCode('en'),
                  ),

                  if (_versionText != null) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        _versionText!,
                        // Null-safe: bodySmall can be null.
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith() ??
                                const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsRestorePendingView extends StatelessWidget {
  const _SettingsRestorePendingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.settings_backup_restore_pending_message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onSelected,
      leading: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (_) => onSelected(),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.email});

  final String email;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(
        () => _errorMessage = l10n.settings_change_password_error_fields,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      setState(
        () => _errorMessage = l10n.settings_change_password_error_mismatch,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: l10n.common_unknown,
        );
      }
      final credential = EmailAuthProvider.credential(
        email: widget.email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_change_password_success)),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? l10n.common_unknown;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settings_change_password_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_change_password_current_password,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_change_password_new_password,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settings_change_password_confirm_password,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(l10n.settings_change_password_submit),
        ),
      ],
    );
  }
}

Future<void> _openCommunityLink(BuildContext context, String? url) async {
  final l10n = AppLocalizations.of(context)!;
  if (url == null || url.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.common_comingSoon)),
    );
    return;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.common_invalid_link)),
    );
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.common_could_not_open_link)),
    );
  }
}
