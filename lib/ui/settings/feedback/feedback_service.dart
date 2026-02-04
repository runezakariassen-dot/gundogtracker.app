import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/hive_boxes.dart';
import '../../../l10n/app_localizations.dart';

class FeedbackService {
  Future<void> openFeedbackEmail(
    Box<dynamic> settingsBox,
    String supportEmail,
    AppLocalizations l10n,
  ) async {
    final diagnostics = await buildDiagnosticsText(settingsBox);
    final body = [
      l10n.feedback_email_body_intro,
      '',
      '---',
      diagnostics,
    ].join('\n');
    await _launchEmail(
      subject: 'Fuglehund - Tilbakemelding',
      body: body,
      email: supportEmail,
      failureMessage: l10n.feedback_error_email_not_available,
    );
  }

  Future<void> openBugReportEmail(
    Box<dynamic> settingsBox,
    String supportEmail,
    AppLocalizations l10n,
  ) async {
    final diagnostics = await buildDiagnosticsText(settingsBox);
    final body = [
      l10n.feedback_bug_prompt,
      '',
      l10n.feedback_bug_reproduce,
      '',
      '---',
      diagnostics,
    ].join('\n');
    await _launchEmail(
      subject: 'Fuglehund - Feilrapport',
      body: body,
      email: supportEmail,
      failureMessage: l10n.feedback_error_email_not_available,
    );
  }

  Future<void> openMilestoneSuggestionEmail(
    String supportEmail,
    AppLocalizations l10n,
  ) async {
    final body = await _buildMilestoneSuggestionBody(l10n);
    await _launchEmail(
      subject: 'Fuglehund - Forslag til milepæl',
      body: body,
      email: supportEmail,
      failureMessage: l10n.feedback_error_email_not_available,
    );
  }

  Future<void> copyDiagnostics(Box<dynamic> settingsBox) async {
    final diagnostics = await buildDiagnosticsText(settingsBox);
    await Clipboard.setData(ClipboardData(text: diagnostics));
  }

  Future<String> buildDiagnosticsText(Box<dynamic> settingsBox) async {
    final info = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final locale = Platform.localeName;
    final milestonesEnabled =
        (settingsBox.get(milestonesEnabledKey) as bool?) ?? true;
    final hapticsEnabled =
        (settingsBox.get(hapticsEnabledKey) as bool?) ?? true;

    String platform = Platform.operatingSystem;
    String osVersion = 'ukjent';
    String deviceModel = 'ukjent';

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      platform = 'iOS';
      osVersion = ios.systemVersion;
      deviceModel = ios.model;
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      platform = 'Android';
      osVersion = android.version.release;
      deviceModel = android.model;
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      platform = 'macOS';
      osVersion = mac.osRelease;
      deviceModel = mac.model;
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      platform = 'Windows';
      osVersion = windows.displayVersion;
      deviceModel = windows.computerName;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      platform = 'Linux';
      osVersion = linux.version ?? 'ukjent';
      deviceModel = linux.machineId ?? 'ukjent';
    }

    final versionText = 'v${info.version} (build ${info.buildNumber})';
    return [
      'App: Fuglehund $versionText',
      'Platform: $platform',
      'OS: $osVersion',
      'Enhet: $deviceModel',
      'Locale: $locale',
      'milestonesEnabled: $milestonesEnabled',
      'hapticsEnabled: $hapticsEnabled',
    ].join('\n');
  }

  Future<String> _buildMilestoneSuggestionBody(AppLocalizations l10n) async {
    final info = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String platform = Platform.operatingSystem;
    String deviceModel = 'ukjent';

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      platform = 'iOS';
      deviceModel = ios.model;
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      platform = 'Android';
      deviceModel = android.model;
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      platform = 'macOS';
      deviceModel = mac.model;
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      platform = 'Windows';
      deviceModel = windows.computerName;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      platform = 'Linux';
      deviceModel = linux.machineId ?? 'ukjent';
    }

    return [
      l10n.feedback_suggest_title,
      '-----------------------',
      l10n.feedback_suggest_question_what_to_celebrate,
      '(f.eks. antall stand, fuglekontakt, tid, kvalitet, annet)',
      '',
      l10n.feedback_suggest_question_why_important,
      '',
      l10n.feedback_suggest_question_when_should_trigger,
      l10n.feedback_suggest_trigger_hint,
      '',
      l10n.feedback_suggest_comments,
      '',
      '---',
      'Appversjon: ${info.version} (${info.buildNumber})',
      'Plattform: $platform',
      'Enhet: $deviceModel',
    ].join('\n');
  }

  Future<void> _launchEmail({
    required String subject,
    required String body,
    required String email,
    required String failureMessage,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    if (!await canLaunchUrl(uri)) {
      throw PlatformException(
        code: 'email_not_available',
        message: failureMessage,
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
