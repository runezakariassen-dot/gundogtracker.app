// ignore_for_file: control_flow_in_finally, deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/community_links.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import '../domain/settings/birthday_greeting.dart';
import '../domain/settings/personal_stand_goal_celebration.dart';
import '../domain/settings/personal_stand_goal_progress.dart';
import '../domain/settings/settings_repository.dart';
import '../domain/services/backup_export_service.dart';
import '../domain/services/backup_restore_service.dart';
import '../models/dog.dart';
import '../models/gps_track.dart';
import '../models/hunt_session.dart';
import '../models/track.dart';
import '../services/cloud/firestore_dog_sync_service.dart';
import '../services/cloud/firestore_session_sync_service.dart';
import '../services/cloud/sync_outbox_processor.dart';
import '../data/local/sync_outbox_service.dart';
import '../services/dog_photo_storage.dart';
import '../services/hive_lifecycle_service.dart';
import '../services/notification_service.dart';
import '../ui/settings/feedback/feedback_service.dart';
import '../ui/settings/subscription/subscription_section.dart';
import '../ui/locale/locale_controller.dart';
import '../ui/theme/season_theme_controller.dart';
import '../pages/invitations_page.dart';
import '../domain/subscription/subscription_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.subscriptionService,
    this.notificationService,
  });

  final SubscriptionService? subscriptionService;
  final AppNotificationService? notificationService;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Key _profileNameFieldKey = Key('settings_profile_name');
  static const Key _profilePhoneFieldKey = Key('settings_profile_phone');
  static const Key _profileEmailFieldKey = Key('settings_profile_email');
  static const Key _profileStandGoalFieldKey =
      Key('settings_profile_stand_goal');
  static const Key _profileBirthDateTileKey =
      Key('settings_profile_birth_date');
  static const Key _profileClearBirthDateKey =
      Key('settings_profile_birth_date_clear');
  static const Key _profileSaveButtonKey = Key('settings_profile_save');
  static const Key _diagnosticsSectionKey = Key('settings_diagnostics_section');
  static const Key _diagnosticsExpandKey = Key('settings_diagnostics_expand');
  static const Key _debugDogRestoreKey = Key('settings_debug_dog_restore');
  static const Key _debugSessionFetchKey = Key('settings_debug_session_fetch');
  static const Key _debugSessionRestoreKey =
      Key('settings_debug_session_restore');
  static const Key _debugProcessOutboxKey =
      Key('settings_debug_process_outbox');
  static const Key _debugRetryFailedOutboxKey =
      Key('settings_debug_retry_failed_outbox');
  final FeedbackService _feedbackService = FeedbackService();
  final SyncOutboxService _syncOutboxService =
      SyncOutboxService(enableAutoSync: false);

  // Backup
  final BackupExportService _backupService = const BackupExportService();
  final BackupRestoreService _restoreService = const BackupRestoreService();

  bool _isExportingBackup = false;
  bool _isRestoringBackup = false;
  String? _backupStatus;
  bool _isSigningOut = false;
  bool _isResettingPassword = false;
  bool _isSavingProfile = false;
  String? _profileEmailError;
  DateTime? _profileBirthDate;
  late final Box<dynamic> _settingsBox;
  late final SettingsRepository _settingsRepository;
  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;
  late final Box<Track> _tracksBox;
  late final Box<GpsTrack> _gpsTracksBox;
  late final Box<String> _birdSpeciesBox;
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  final TextEditingController _profileEmailController = TextEditingController();
  final TextEditingController _profileStandGoalController =
      TextEditingController();
  bool _isPersistingGoalCelebration = false;
  bool _isPersistingBirthdayGreeting = false;
  late final AppNotificationService _notificationService;

  Future<void> _triggerDebugDogRestore() async {
    if (!kDebugMode) return;
    final l10n = AppLocalizations.of(context)!;
    // ignore: avoid_print
    print('[UI][DOG] debug restore triggered');
    try {
      final inserted =
          await FirestoreDogSyncService.instance.restoreAccessibleDogsToHive();
      // ignore: avoid_print
      print('[UI][DOG] debug restore completed: inserted=$inserted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l10n.settings_diagnostics_dog_restore_success(inserted))),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[UI][DOG] debug restore failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_dog_restore_failed('$e')),
        ),
      );
    }
  }

  Future<void> _triggerDebugSessionFetch() async {
    if (!kDebugMode) return;
    final l10n = AppLocalizations.of(context)!;

    final dogCloudId = _firstLocalDogCloudId();

    if (dogCloudId == null) {
      // ignore: avoid_print
      print('[UI][SESSION] manual fetch skipped, no local dog with cloudId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_diagnostics_missing_cloud_dog)),
      );
      return;
    }

    // ignore: avoid_print
    print('[UI][SESSION] manual fetch triggered for dog: $dogCloudId');
    try {
      final sessions = await FirestoreSessionSyncService.instance
          .fetchSessionsForDogAsModels(dogCloudId);
      // ignore: avoid_print
      print('[UI][SESSION] manual fetch completed count: ${sessions.length}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settings_diagnostics_session_fetch_success(sessions.length),
          ),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[UI][SESSION] manual fetch failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_session_fetch_failed('$e')),
        ),
      );
    }
  }

  Future<void> _triggerDebugSessionRestore() async {
    if (!kDebugMode) return;
    final l10n = AppLocalizations.of(context)!;

    final dogCloudId = _firstLocalDogCloudId();

    if (dogCloudId == null) {
      // ignore: avoid_print
      print('[UI][SESSION] manual restore skipped, no local dog with cloudId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_diagnostics_missing_cloud_dog)),
      );
      return;
    }

    // ignore: avoid_print
    print('[UI][SESSION] manual restore triggered for dog: $dogCloudId');
    try {
      final inserted = await FirestoreSessionSyncService.instance
          .restoreSessionsForDogToHive(dogCloudId);
      // ignore: avoid_print
      print('[UI][SESSION] manual restore completed inserted: $inserted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settings_diagnostics_session_restore_success(inserted),
          ),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[UI][SESSION] manual restore failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settings_diagnostics_session_restore_failed('$e'),
          ),
        ),
      );
    }
  }

  Future<void> _triggerDebugProcessOutbox() async {
    if (!kDebugMode) return;
    final l10n = AppLocalizations.of(context)!;
    // ignore: avoid_print
    print('[UI][SYNC] manual outbox processing triggered');
    try {
      await SyncOutboxProcessor().runOnce();
      // ignore: avoid_print
      print('[UI][SYNC] manual outbox processing completed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_outbox_process_success),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[UI][SYNC] manual outbox processing failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_outbox_process_failed('$e')),
        ),
      );
    }
  }

  Future<void> _triggerDebugRetryFailedOutbox() async {
    if (!kDebugMode) return;
    final l10n = AppLocalizations.of(context)!;
    // ignore: avoid_print
    print('[UI][SYNC] manual outbox retry reset triggered');
    try {
      final resetCount = await SyncOutboxService().resetFailedTasksForRetry();
      // ignore: avoid_print
      print(
          '[UI][SYNC] manual outbox retry reset completed count: $resetCount');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_retry_success(resetCount)),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[UI][SYNC] manual outbox retry reset failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settings_diagnostics_retry_failed('$e')),
        ),
      );
    }
  }

  String? _firstLocalDogCloudId() {
    for (final dog in _dogsBox.values) {
      final cloudId = dog.cloudId;
      if (cloudId != null && cloudId.isNotEmpty) {
        return cloudId;
      }
    }
    return null;
  }

  User? _currentUserOrNull() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Widget _buildDebugActionTile({
    Key? tileKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  Widget _buildCloudDebugSummary() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<SyncOutboxTaskCounts>(
      stream: _syncOutboxService.watchTaskCounts(),
      initialData: _syncOutboxService.taskCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? const SyncOutboxTaskCounts();
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _DebugCountItem(
                    label: l10n.settings_diagnostics_count_pending,
                    value: counts.pending,
                    color: colorScheme.outline,
                  ),
                ),
                Expanded(
                  child: _DebugCountItem(
                    label: l10n.settings_diagnostics_count_inProgress,
                    value: counts.inProgress,
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _DebugCountItem(
                    label: l10n.settings_diagnostics_count_failed,
                    value: counts.failed,
                    color: colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _DebugCountItem(
                    label: l10n.settings_diagnostics_count_sent,
                    value: counts.sent,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.settings_diagnostics_outbox_label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticsSection(TextStyle sectionStyle) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: _diagnosticsSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settings_diagnostics_section_title, style: sectionStyle),
        const SizedBox(height: 8),
        Card(
          child: ExpansionTile(
            key: _diagnosticsExpandKey,
            title: Text(l10n.settings_diagnostics_title),
            subtitle: Text(l10n.settings_diagnostics_subtitle),
            leading: const Icon(Icons.developer_mode_outlined),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCloudDebugSummary(),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildDebugActionTile(
                      tileKey: _debugDogRestoreKey,
                      icon: Icons.cloud_download_outlined,
                      title: l10n.settings_diagnostics_action_dog_restore_title,
                      subtitle:
                          l10n.settings_diagnostics_action_dog_restore_subtitle,
                      onTap: _triggerDebugDogRestore,
                    ),
                    const Divider(height: 1),
                    _buildDebugActionTile(
                      tileKey: _debugSessionFetchKey,
                      icon: Icons.cloud_sync_outlined,
                      title:
                          l10n.settings_diagnostics_action_session_fetch_title,
                      subtitle: l10n
                          .settings_diagnostics_action_session_fetch_subtitle,
                      onTap: _triggerDebugSessionFetch,
                    ),
                    const Divider(height: 1),
                    _buildDebugActionTile(
                      tileKey: _debugSessionRestoreKey,
                      icon: Icons.restore_outlined,
                      title: l10n
                          .settings_diagnostics_action_session_restore_title,
                      subtitle: l10n
                          .settings_diagnostics_action_session_restore_subtitle,
                      onTap: _triggerDebugSessionRestore,
                    ),
                    const Divider(height: 1),
                    _buildDebugActionTile(
                      tileKey: _debugProcessOutboxKey,
                      icon: Icons.sync_outlined,
                      title:
                          l10n.settings_diagnostics_action_process_outbox_title,
                      subtitle: l10n
                          .settings_diagnostics_action_process_outbox_subtitle,
                      onTap: _triggerDebugProcessOutbox,
                    ),
                    const Divider(height: 1),
                    _buildDebugActionTile(
                      tileKey: _debugRetryFailedOutboxKey,
                      icon: Icons.refresh_outlined,
                      title:
                          l10n.settings_diagnostics_action_retry_outbox_title,
                      subtitle: l10n
                          .settings_diagnostics_action_retry_outbox_subtitle,
                      onTap: _triggerDebugRetryFailedOutbox,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _loadProfileDraft() {
    final profile = _settingsRepository.getUserProfile();
    _profileNameController.text = profile.name ?? '';
    _profilePhoneController.text = profile.phone ?? '';
    _profileEmailController.text = profile.email ?? '';
    _profileStandGoalController.text =
        profile.personalStandGoal?.toString() ?? '';
    _profileBirthDate = profile.birthDate;
    _profileEmailError = null;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _formatProfileBirthDate(DateTime value) {
    return MaterialLocalizations.of(context).formatShortDate(value);
  }

  Future<void> _pickProfileBirthDate() async {
    final now = DateTime.now();
    final initialDate = _profileBirthDate ?? DateTime(now.year - 18, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _profileBirthDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _clearProfileBirthDate() {
    setState(() {
      _profileBirthDate = null;
    });
  }

  int? _parseProfileStandGoal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    final l10n = AppLocalizations.of(context)!;
    final email = _profileEmailController.text.trim();

    if (email.isNotEmpty && !_isValidEmail(email)) {
      setState(() {
        _profileEmailError = l10n.settings_profile_email_invalid;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingProfile = true;
      _profileEmailError = null;
    });

    try {
      await _settingsRepository.setUserProfile(
        UserProfileSettings(
          name: _profileNameController.text,
          phone: _profilePhoneController.text,
          email: email,
          birthDate: _profileBirthDate,
          personalStandGoal: _parseProfileStandGoal(
            _profileStandGoalController.text,
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_profile_saved)),
      );
      _scheduleBirthdayReminderNotification();
      _schedulePersonalGoalCelebrationCheck();
      _scheduleBirthdayGreetingCheck();
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  void _schedulePersonalGoalCelebrationCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _checkPersonalGoalCelebration();
    });
  }

  Future<void> _checkPersonalGoalCelebration() async {
    if (_isSavingProfile || _isPersistingGoalCelebration || !mounted) {
      return;
    }

    final profile = _settingsRepository.getUserProfile();
    final progress = PersonalStandGoalProgress.fromSessions(
      sessions: _sessionsBox.values,
      goal: profile.personalStandGoal,
    );
    final lastCelebratedGoal =
        _settingsRepository.getLastCelebratedPersonalStandGoal();
    if (!progress.shouldCelebrate(lastCelebratedGoal: lastCelebratedGoal)) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = PersonalStandGoalCelebration.resolveMessage(
      name: profile.name,
      genericMessage: l10n.settings_profile_personal_goal_celebration_generic,
      namedMessage: l10n.settings_profile_personal_goal_celebration_named,
    );

    _isPersistingGoalCelebration = true;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _notificationService.showGoalReachedNotification(
        goal: progress.goal!,
        title: l10n.settings_notification_goal_title,
        body: l10n.settings_notification_goal_body,
      );
      await _settingsRepository.setLastCelebratedPersonalStandGoal(
        progress.goal,
      );
    } finally {
      _isPersistingGoalCelebration = false;
    }
  }

  void _scheduleBirthdayGreetingCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _checkBirthdayGreeting();
    });
  }

  void _scheduleBirthdayReminderNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncBirthdayReminderNotification();
    });
  }

  Future<void> _syncBirthdayReminderNotification() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = _settingsRepository.getUserProfile();

    await _notificationService.scheduleBirthdayReminder(
      birthDate: profile.birthDate,
      title: l10n.settings_notification_birthday_title,
      body: l10n.settings_notification_birthday_body,
    );
  }

  Future<void> _checkBirthdayGreeting() async {
    if (_isSavingProfile || _isPersistingBirthdayGreeting || !mounted) {
      return;
    }

    final today = DateTime.now();
    final birthdayDogs = _dogsBox.values
        .where((dog) =>
            !dog.isDeleted &&
            BirthdayGreeting.isBirthdayToday(
              birthDate: dog.birthDate,
              today: today,
            ))
        .toList(growable: false);
    if (birthdayDogs.isEmpty) {
      return;
    }

    final lastShownDate =
        _settingsRepository.getLastBirthdayGreetingShownDate();
    final alreadyShownToday = lastShownDate != null &&
        lastShownDate.year == today.year &&
        lastShownDate.month == today.month &&
        lastShownDate.day == today.day;
    if (alreadyShownToday) {
      return;
    }

    _isPersistingBirthdayGreeting = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext)!;
          final title = birthdayDogs.length == 1
              ? '${l10n.settings_notification_birthday_title} ${birthdayDogs.first.displayName}'
              : l10n.settings_notification_birthday_title;
          final subtitle = birthdayDogs.length == 1
              ? birthdayDogs.first.displayName
              : BirthdayGreeting.formatDogNames(
                    dogNames: birthdayDogs.map((dog) => dog.displayName),
                    andWord: l10n.settings_profile_birthday_greeting_and,
                  ) ??
                  '';

          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (birthdayDogs.length == 1)
                    _BirthdayHeroDogTile(dog: birthdayDogs.first)
                  else
                    _BirthdayDogGrid(dogs: birthdayDogs),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.common_ok),
                  ),
                ],
              ),
            ),
          );
        },
      );
      await _settingsRepository.setLastBirthdayGreetingShownDate(today);
    } finally {
      _isPersistingBirthdayGreeting = false;
    }
  }

  Widget _buildAccountSection(TextStyle sectionStyle) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = _currentUserOrNull();

    String displayValue;
    if (currentUser == null) {
      displayValue = l10n.settings_not_signed_in;
    } else {
      displayValue =
          currentUser.email ?? currentUser.displayName ?? currentUser.uid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settings_section_account, style: sectionStyle),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.settings_signed_in_as),
            subtitle: Text(
              displayValue,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(TextStyle sectionStyle) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = _parseProfileStandGoal(_profileStandGoalController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settings_section_profile, style: sectionStyle),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: _profileNameFieldKey,
                  controller: _profileNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: l10n.settings_profile_name_label,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: _profilePhoneFieldKey,
                  controller: _profilePhoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: l10n.settings_profile_phone_label,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: _profileEmailFieldKey,
                  controller: _profileEmailController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) {
                    if (_profileEmailError == null) return;
                    setState(() {
                      _profileEmailError = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: l10n.settings_profile_email_label,
                    prefixIcon: const Icon(Icons.mail_outline),
                    errorText: _profileEmailError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: _profileStandGoalFieldKey,
                  controller: _profileStandGoalController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.settings_profile_personal_goal_stands_label,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    key: _profileBirthDateTileKey,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.cake_outlined),
                    title: Text(l10n.settings_profile_birth_date_label),
                    subtitle: Text(
                      _profileBirthDate == null
                          ? l10n.settings_profile_birth_date_empty
                          : _formatProfileBirthDate(_profileBirthDate!),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_profileBirthDate != null)
                          IconButton(
                            key: _profileClearBirthDateKey,
                            onPressed: _clearProfileBirthDate,
                            icon: const Icon(Icons.close),
                            tooltip: l10n.settings_profile_birth_date_clear,
                          ),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                    onTap: _pickProfileBirthDate,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: _sessionsBox.listenable(),
                  builder: (context, Box<HuntSession> sessionsBox, _) {
                    final progress = PersonalStandGoalProgress.fromSessions(
                      sessions: sessionsBox.values,
                      goal: goal,
                    );

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settings_profile_personal_goal_section_title,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            if (!progress.hasGoal) ...[
                              Text(
                                l10n.settings_profile_personal_goal_prompt(
                                  progress.totalStands,
                                ),
                              ),
                            ] else ...[
                              Text(
                                l10n.settings_profile_personal_goal_progress(
                                  progress.totalStands,
                                  progress.goal!,
                                ),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.settings_profile_personal_goal_percent(
                                  progress.progressPercent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress.progressValue,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: _profileSaveButtonKey,
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSavingProfile
                        ? l10n.settings_profile_saving
                        : l10n.common_save,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_sign_out_success)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[UI][SETTINGS] sign out failed: $error');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_sign_out_failed)),
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
    _notificationService =
        widget.notificationService ?? NotificationService.instance;
    _settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _settingsRepository = SettingsRepository(_settingsBox);
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _tracksBox = HiveLifecycleService.getBox<Track>(tracksBoxName);
    _gpsTracksBox = HiveLifecycleService.getBox<GpsTrack>(gpsTracksBoxName);
    _birdSpeciesBox = HiveLifecycleService.getBox<String>(birdSpeciesBoxName);
    _loadProfileDraft();
    _scheduleBirthdayReminderNotification();
    _schedulePersonalGoalCelebrationCheck();
    _scheduleBirthdayGreetingCheck();
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
  void dispose() {
    _profileNameController.dispose();
    _profilePhoneController.dispose();
    _profileEmailController.dispose();
    _profileStandGoalController.dispose();
    super.dispose();
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
                soundOnAppStartKey,
                soundOnMilestoneKey,
                profileNameKey,
                profilePhoneKey,
                profileEmailKey,
                profilePersonalStandGoalKey,
                profileBirthDateKey,
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

              final currentUser = _currentUserOrNull();
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
                  SubscriptionSection(service: widget.subscriptionService),
                  const SizedBox(height: 24),

                  _buildAccountSection(sectionStyle),
                  const SizedBox(height: 24),

                  _buildProfileSection(sectionStyle),
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
                    title: Text(
                      l10n.settings_season_title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.settings_season_subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: DropdownButton<String>(
                      isDense: true,
                      value: seasonOverride,
                      onChanged: (value) {
                        if (value == null) return;
                        seasonController.setOverride(value);
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'auto',
                          child: Text(
                            l10n.settings_season_auto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'spring',
                          child: Text(
                            l10n.settings_season_spring,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'summer',
                          child: Text(
                            l10n.settings_season_summer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'autumn',
                          child: Text(
                            l10n.settings_season_autumn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'winter',
                          child: Text(
                            l10n.settings_season_winter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  SwitchListTile(
                    title: Text(l10n.settings_sound_on_app_start_title),
                    subtitle: Text(l10n.settings_sound_on_app_start_subtitle),
                    value: (box.get(soundOnAppStartKey) as bool?) ?? false,
                    onChanged: (value) => box.put(soundOnAppStartKey, value),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settings_sound_on_milestone_title),
                    subtitle: Text(l10n.settings_sound_on_milestone_subtitle),
                    value: (box.get(soundOnMilestoneKey) as bool?) ?? false,
                    onChanged: (value) => box.put(soundOnMilestoneKey, value),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.settings_milestones_goal_title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _MilestoneGoalSlider(
                    label: l10n.settings_milestones_season_goal_title,
                    value: (box.get(milestoneSeasonGoalPointsKey) as int?) ?? 0,
                    min: 0,
                    max: 2000,
                    onChanged: (value) =>
                        box.put(milestoneSeasonGoalPointsKey, value),
                  ),
                  const SizedBox(height: 8),
                  _MilestoneGoalSlider(
                    label: l10n.settings_milestones_personal_goal_title,
                    value:
                        (box.get(milestonePersonalGoalPointsKey) as int?) ?? 0,
                    min: 0,
                    max: 2000,
                    onChanged: (value) =>
                        box.put(milestonePersonalGoalPointsKey, value),
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
                    label: Text(l10n.settings_sign_out_button),
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

                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    _buildDiagnosticsSection(sectionStyle),
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

class _BirthdayHeroDogTile extends StatelessWidget {
  const _BirthdayHeroDogTile({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final imageFile = _resolvedDogImage(dog.imagePath);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: imageFile != null
                ? Image.file(imageFile, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Center(
                      child: Icon(Icons.pets, size: 72),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BirthdayDogGrid extends StatelessWidget {
  const _BirthdayDogGrid({required this.dogs});

  final List<Dog> dogs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: dogs
          .map(
            (dog) => SizedBox(
              width: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: () {
                      final file = _resolvedDogImage(dog.imagePath);
                      return file != null ? FileImage(file) : null;
                    }(),
                    child: _resolvedDogImage(dog.imagePath) == null
                        ? const Icon(Icons.pets)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dog.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

File? _resolvedDogImage(String? imagePath) {
  if (imagePath == null || imagePath.trim().isEmpty) {
    return null;
  }
  final resolved = DogPhotoStorage.resolveAbsolutePath(imagePath.trim());
  if (resolved == null) {
    return null;
  }
  final file = File(resolved);
  return file.existsSync() ? file : null;
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

class _MilestoneGoalSlider extends StatefulWidget {
  const _MilestoneGoalSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_MilestoneGoalSlider> createState() => _MilestoneGoalSliderState();
}

class _MilestoneGoalSliderState extends State<_MilestoneGoalSlider> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _MilestoneGoalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _value.toDouble(),
                min: widget.min.toDouble(),
                max: widget.max.toDouble(),
                divisions: (widget.max - widget.min) ~/ 10,
                label: '$_value',
                onChanged: (double newValue) {
                  setState(() => _value = newValue.round());
                  widget.onChanged(_value);
                },
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 68,
              child: Text(
                '$_value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ],
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
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

class _DebugCountItem extends StatelessWidget {
  const _DebugCountItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ],
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
