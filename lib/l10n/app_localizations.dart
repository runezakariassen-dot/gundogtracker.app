import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
    Locale('nb'),
    Locale('sv')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fuglehund'**
  String get appName;

  /// No description provided for @app_store_identity_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline hunting log for pointing dogs'**
  String get app_store_identity_subtitle;

  /// No description provided for @app_store_identity_short_description.
  ///
  /// In en, this message translates to:
  /// **'Log sessions, track progress, and build your dog\'s history – even offline.'**
  String get app_store_identity_short_description;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get common_copy;

  /// No description provided for @common_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied ✅'**
  String get common_copied;

  /// No description provided for @common_comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get common_comingSoon;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_invalid_link.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get common_invalid_link;

  /// No description provided for @common_could_not_open_link.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get common_could_not_open_link;

  /// No description provided for @common_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get common_unknown;

  /// No description provided for @common_unknown_email.
  ///
  /// In en, this message translates to:
  /// **'Unknown email'**
  String get common_unknown_email;

  /// No description provided for @common_unknown_member.
  ///
  /// In en, this message translates to:
  /// **'Unknown member'**
  String get common_unknown_member;

  /// Displayed when the user lacks rights to perform the requested action.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this action.'**
  String get common_no_permission;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_retry;

  /// No description provided for @age_unknown.
  ///
  /// In en, this message translates to:
  /// **'Age unknown'**
  String get age_unknown;

  /// No description provided for @boot_error_title.
  ///
  /// In en, this message translates to:
  /// **'Startup failed'**
  String get boot_error_title;

  /// Body text for boot error screen.
  ///
  /// In en, this message translates to:
  /// **'Check the terminal for details.\n{message}'**
  String boot_error_body(Object message);

  /// No description provided for @boot_error_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get boot_error_unknown;

  /// No description provided for @boot_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup…'**
  String get boot_restore_title;

  /// No description provided for @boot_restore_body.
  ///
  /// In en, this message translates to:
  /// **'Do not close the app.\n\nWe block data access while the restore runs to avoid Hive issues.'**
  String get boot_restore_body;

  /// No description provided for @boot_restart_title.
  ///
  /// In en, this message translates to:
  /// **'Backup restored ✅'**
  String get boot_restart_title;

  /// No description provided for @boot_restart_body.
  ///
  /// In en, this message translates to:
  /// **'The app will close now so changes can load.\n\nReopen the app afterwards.'**
  String get boot_restart_body;

  /// No description provided for @qr_scan_title.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qr_scan_title;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @advanced_statistics.
  ///
  /// In en, this message translates to:
  /// **'Advanced statistics'**
  String get advanced_statistics;

  /// No description provided for @advanced_statistics_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get advanced_statistics_overview;

  /// No description provided for @advanced_statistics_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get advanced_statistics_progress;

  /// No description provided for @advanced_statistics_season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get advanced_statistics_season;

  /// No description provided for @advanced_statistics_comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get advanced_statistics_comparison;

  /// No description provided for @advanced_statistics_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get advanced_statistics_export;

  /// No description provided for @advanced_statistics_no_progress_data.
  ///
  /// In en, this message translates to:
  /// **'No progress data available'**
  String get advanced_statistics_no_progress_data;

  /// No description provided for @advanced_statistics_no_season_data.
  ///
  /// In en, this message translates to:
  /// **'No seasonal data available'**
  String get advanced_statistics_no_season_data;

  /// No description provided for @advanced_statistics_need_two_dogs.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 dogs to compare'**
  String get advanced_statistics_need_two_dogs;

  /// No description provided for @advanced_statistics_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get advanced_statistics_exporting;

  /// No description provided for @advanced_statistics_export_stats.
  ///
  /// In en, this message translates to:
  /// **'Export statistics'**
  String get advanced_statistics_export_stats;

  /// No description provided for @advanced_statistics_export_sessions.
  ///
  /// In en, this message translates to:
  /// **'Export sessions'**
  String get advanced_statistics_export_sessions;

  /// No description provided for @advanced_statistics_generate_text_report.
  ///
  /// In en, this message translates to:
  /// **'Generate text report'**
  String get advanced_statistics_generate_text_report;

  /// No description provided for @advanced_statistics_key_metrics_for.
  ///
  /// In en, this message translates to:
  /// **'Key metrics for {dogName}'**
  String advanced_statistics_key_metrics_for(Object dogName);

  /// No description provided for @advanced_statistics_stand_rate_per_hour.
  ///
  /// In en, this message translates to:
  /// **'Stand-rate per hour'**
  String get advanced_statistics_stand_rate_per_hour;

  /// No description provided for @advanced_statistics_bird_contacts_per_session.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts per session'**
  String get advanced_statistics_bird_contacts_per_session;

  /// No description provided for @advanced_statistics_average_flushes_per_session.
  ///
  /// In en, this message translates to:
  /// **'Average flushes per session'**
  String get advanced_statistics_average_flushes_per_session;

  /// No description provided for @advanced_statistics_success_rate.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get advanced_statistics_success_rate;

  /// No description provided for @advanced_statistics_totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get advanced_statistics_totals;

  /// No description provided for @advanced_statistics_sessions_total.
  ///
  /// In en, this message translates to:
  /// **'Sessions total'**
  String get advanced_statistics_sessions_total;

  /// No description provided for @advanced_statistics_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get advanced_statistics_active_time;

  /// No description provided for @advanced_statistics_total_points.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get advanced_statistics_total_points;

  /// No description provided for @advanced_statistics_total_flushes.
  ///
  /// In en, this message translates to:
  /// **'Total flushes'**
  String get advanced_statistics_total_flushes;

  /// No description provided for @advanced_statistics_bird_contacts.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts'**
  String get advanced_statistics_bird_contacts;

  /// No description provided for @advanced_statistics_birds_shot.
  ///
  /// In en, this message translates to:
  /// **'Birds shot'**
  String get advanced_statistics_birds_shot;

  /// No description provided for @advanced_statistics_progress_over_time.
  ///
  /// In en, this message translates to:
  /// **'Progress over time - {dogName}'**
  String advanced_statistics_progress_over_time(Object dogName);

  /// No description provided for @advanced_statistics_average_points_per_session_over_time.
  ///
  /// In en, this message translates to:
  /// **'Average points per session over time'**
  String get advanced_statistics_average_points_per_session_over_time;

  /// No description provided for @advanced_statistics_trend_analysis.
  ///
  /// In en, this message translates to:
  /// **'Trend analysis'**
  String get advanced_statistics_trend_analysis;

  /// No description provided for @advanced_statistics_improvement.
  ///
  /// In en, this message translates to:
  /// **'Improvement!'**
  String get advanced_statistics_improvement;

  /// No description provided for @advanced_statistics_declining.
  ///
  /// In en, this message translates to:
  /// **'Declining'**
  String get advanced_statistics_declining;

  /// No description provided for @advanced_statistics_stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get advanced_statistics_stable;

  /// No description provided for @advanced_statistics_seasonal_analysis.
  ///
  /// In en, this message translates to:
  /// **'Seasonal analysis - {dogName}'**
  String advanced_statistics_seasonal_analysis(Object dogName);

  /// No description provided for @advanced_statistics_sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get advanced_statistics_sessions;

  /// No description provided for @advanced_statistics_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get advanced_statistics_points;

  /// No description provided for @advanced_statistics_points_per_hour.
  ///
  /// In en, this message translates to:
  /// **'Points per hour'**
  String get advanced_statistics_points_per_hour;

  /// No description provided for @advanced_statistics_dog_comparison.
  ///
  /// In en, this message translates to:
  /// **'Dog comparison'**
  String get advanced_statistics_dog_comparison;

  /// No description provided for @advanced_statistics_success_rate_percent.
  ///
  /// In en, this message translates to:
  /// **'Success rate (%)'**
  String get advanced_statistics_success_rate_percent;

  /// No description provided for @advanced_statistics_export_reports.
  ///
  /// In en, this message translates to:
  /// **'Export reports'**
  String get advanced_statistics_export_reports;

  /// No description provided for @advanced_statistics_export_statistics_csv.
  ///
  /// In en, this message translates to:
  /// **'Export statistics as CSV'**
  String get advanced_statistics_export_statistics_csv;

  /// No description provided for @advanced_statistics_contains_comparison_all_dogs.
  ///
  /// In en, this message translates to:
  /// **'Contains comparison of all dogs with key figures.'**
  String get advanced_statistics_contains_comparison_all_dogs;

  /// No description provided for @advanced_statistics_export_sessions_csv.
  ///
  /// In en, this message translates to:
  /// **'Export all session data as CSV'**
  String get advanced_statistics_export_sessions_csv;

  /// No description provided for @advanced_statistics_sessions_csv_description.
  ///
  /// In en, this message translates to:
  /// **'Detailed overview of all hunt sessions with all fields.'**
  String get advanced_statistics_sessions_csv_description;

  /// No description provided for @advanced_statistics_generate_text_report_description.
  ///
  /// In en, this message translates to:
  /// **'Generate a text summary of all statistics.'**
  String get advanced_statistics_generate_text_report_description;

  /// No description provided for @advanced_statistics_export_session_data.
  ///
  /// In en, this message translates to:
  /// **'Export session data'**
  String get advanced_statistics_export_session_data;

  /// No description provided for @advanced_statistics_text_report_for.
  ///
  /// In en, this message translates to:
  /// **'Text report for {dogName}'**
  String advanced_statistics_text_report_for(Object dogName);

  /// No description provided for @advanced_statistics_generate_readable_text_report.
  ///
  /// In en, this message translates to:
  /// **'Generate a readable text report with all statistics.'**
  String get advanced_statistics_generate_readable_text_report;

  /// Week number label.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String stats_week_label(int week);

  /// No description provided for @common_conjunction_and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get common_conjunction_and;

  /// No description provided for @stats_stands_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} point} other{{count} points}}'**
  String stats_stands_count(num count);

  /// No description provided for @stats_sessions_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} session} other{{count} sessions}}'**
  String stats_sessions_count(num count);

  /// No description provided for @stats_birds_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} bird} other{{count} birds}}'**
  String stats_birds_count(num count);

  /// No description provided for @stats_flushes_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} flush} other{{count} flushes}}'**
  String stats_flushes_count(num count);

  /// No description provided for @common_years.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year} other{{count} years}}'**
  String common_years(num count);

  /// No description provided for @common_months.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} month} other{{count} months}}'**
  String common_months(num count);

  /// No description provided for @common_days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String common_days(num count);

  /// No description provided for @common_months_short.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get common_months_short;

  /// No description provided for @stats_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats_screen_title;

  /// No description provided for @stats_period_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get stats_period_daily;

  /// No description provided for @stats_period_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get stats_period_weekly;

  /// No description provided for @stats_period_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get stats_period_monthly;

  /// No description provided for @stats_no_sessions_registered.
  ///
  /// In en, this message translates to:
  /// **'No sessions registered yet'**
  String get stats_no_sessions_registered;

  /// No description provided for @stats_no_sessions_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Log your first session to see trends and statistics over time.'**
  String get stats_no_sessions_empty_body;

  /// No description provided for @stats_no_sessions_empty_cta.
  ///
  /// In en, this message translates to:
  /// **'Start a session'**
  String get stats_no_sessions_empty_cta;

  /// No description provided for @statistics_no_dogs_body.
  ///
  /// In en, this message translates to:
  /// **'Add a dog to see statistics here.'**
  String get statistics_no_dogs_body;

  /// No description provided for @stats_filter_all_dogs.
  ///
  /// In en, this message translates to:
  /// **'All dogs'**
  String get stats_filter_all_dogs;

  /// No description provided for @stats_filter_dynamic_period.
  ///
  /// In en, this message translates to:
  /// **'Dynamic period'**
  String get stats_filter_dynamic_period;

  /// No description provided for @stats_trendline_title.
  ///
  /// In en, this message translates to:
  /// **'Trendline'**
  String get stats_trendline_title;

  /// No description provided for @stats_period_range.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String stats_period_range(Object from, Object to);

  /// No description provided for @stats_bucket_title.
  ///
  /// In en, this message translates to:
  /// **'{title}'**
  String stats_bucket_title(Object title);

  /// No description provided for @stats_buckets_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} bucket} other{{count} buckets}}'**
  String stats_buckets_count(num count);

  /// No description provided for @stats_total_label.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String stats_total_label(Object count);

  /// No description provided for @stats_more_points.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} more point} other{{count} more points}}'**
  String stats_more_points(num count);

  /// No description provided for @stats_trend_point_label.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String stats_trend_point_label(Object label, Object value);

  /// No description provided for @dogs.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get dogs;

  /// No description provided for @dog_sex_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get dog_sex_male;

  /// No description provided for @dog_sex_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get dog_sex_female;

  /// Fallback label when a dog has no name.
  ///
  /// In en, this message translates to:
  /// **'Unnamed dog'**
  String get dog_unnamed;

  /// Prefix for dog card subtitle showing birth date.
  ///
  /// In en, this message translates to:
  /// **'Born: {date}'**
  String dog_subtitle_born_prefix(String date);

  /// No description provided for @dog_editor_error_name_missing.
  ///
  /// In en, this message translates to:
  /// **'Name is missing'**
  String get dog_editor_error_name_missing;

  /// No description provided for @dog_editor_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dog_editor_save;

  /// No description provided for @dog_editor_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get dog_editor_saving;

  /// No description provided for @dog_editor_delete_dog.
  ///
  /// In en, this message translates to:
  /// **'Delete dog'**
  String get dog_editor_delete_dog;

  /// No description provided for @dog_editor_deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get dog_editor_deleting;

  /// No description provided for @dog_editor_delete_dog_title.
  ///
  /// In en, this message translates to:
  /// **'Delete dog'**
  String get dog_editor_delete_dog_title;

  /// No description provided for @dog_editor_delete_dog_body.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the dog? This can\'t be undone.'**
  String get dog_editor_delete_dog_body;

  /// No description provided for @dog_editor_remove_shared_dog.
  ///
  /// In en, this message translates to:
  /// **'Remove from my dogs'**
  String get dog_editor_remove_shared_dog;

  /// No description provided for @dog_editor_removing_shared_dog.
  ///
  /// In en, this message translates to:
  /// **'Removing…'**
  String get dog_editor_removing_shared_dog;

  /// No description provided for @dog_editor_remove_shared_dog_title.
  ///
  /// In en, this message translates to:
  /// **'Remove from my dogs'**
  String get dog_editor_remove_shared_dog_title;

  /// No description provided for @dog_editor_remove_shared_dog_body.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove this shared dog from your list?'**
  String get dog_editor_remove_shared_dog_body;

  /// No description provided for @dog_editor_remove_shared_dog_explanation.
  ///
  /// In en, this message translates to:
  /// **'The dog will only be removed for you. The owner and other shared users will keep access.'**
  String get dog_editor_remove_shared_dog_explanation;

  /// No description provided for @dog_editor_remove_shared_dog_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dog_editor_remove_shared_dog_confirm;

  /// No description provided for @dog_editor_discard_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get dog_editor_discard_changes_title;

  /// No description provided for @dog_editor_discard_changes_body.
  ///
  /// In en, this message translates to:
  /// **'Your changes haven\'t been saved yet.'**
  String get dog_editor_discard_changes_body;

  /// No description provided for @dog_editor_discard_changes_confirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get dog_editor_discard_changes_confirm;

  /// No description provided for @dog_editor_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Add your dog'**
  String get dog_editor_intro_title;

  /// No description provided for @dog_editor_intro_body.
  ///
  /// In en, this message translates to:
  /// **'You can start simple now. A name is enough to get going, and you can fill in more details later.'**
  String get dog_editor_intro_body;

  /// No description provided for @dog_editor_button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dog_editor_button_cancel;

  /// No description provided for @dog_editor_button_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dog_editor_button_delete;

  /// No description provided for @dog_editor_new_breed_title.
  ///
  /// In en, this message translates to:
  /// **'New breed'**
  String get dog_editor_new_breed_title;

  /// No description provided for @dog_editor_new_breed_hint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Gordon Setter'**
  String get dog_editor_new_breed_hint;

  /// No description provided for @dog_editor_button_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dog_editor_button_add;

  /// No description provided for @dog_editor_select_breed_label.
  ///
  /// In en, this message translates to:
  /// **'Select breed'**
  String get dog_editor_select_breed_label;

  /// No description provided for @dog_editor_select_breed_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select breed'**
  String get dog_editor_select_breed_placeholder;

  /// No description provided for @dog_editor_new_breed_option.
  ///
  /// In en, this message translates to:
  /// **'New breed…'**
  String get dog_editor_new_breed_option;

  /// No description provided for @dog_editor_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dog_editor_name_label;

  /// No description provided for @dog_editor_nickname_label.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get dog_editor_nickname_label;

  /// No description provided for @dog_editor_nickname_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional (e.g. Zoë, Bowie)'**
  String get dog_editor_nickname_hint;

  /// No description provided for @dog_editor_birthdate_label.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get dog_editor_birthdate_label;

  /// No description provided for @dog_editor_birthdate_not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dog_editor_birthdate_not_set;

  /// No description provided for @dog_editor_regnr_label.
  ///
  /// In en, this message translates to:
  /// **'Reg. no.'**
  String get dog_editor_regnr_label;

  /// No description provided for @dog_editor_pedigree_url_label.
  ///
  /// In en, this message translates to:
  /// **'Pedigree URL'**
  String get dog_editor_pedigree_url_label;

  /// No description provided for @dog_editor_memory_words_label.
  ///
  /// In en, this message translates to:
  /// **'Memorial note'**
  String get dog_editor_memory_words_label;

  /// No description provided for @dog_editor_image_text_anchor_label.
  ///
  /// In en, this message translates to:
  /// **'Text placement on photo'**
  String get dog_editor_image_text_anchor_label;

  /// No description provided for @dog_editor_death_registered_title.
  ///
  /// In en, this message translates to:
  /// **'Registered deceased'**
  String get dog_editor_death_registered_title;

  /// No description provided for @dog_editor_section_breed_title.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get dog_editor_section_breed_title;

  /// No description provided for @dog_editor_section_sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get dog_editor_section_sex;

  /// No description provided for @dog_editor_role_section_title.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get dog_editor_role_section_title;

  /// No description provided for @dog_editor_role_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get dog_editor_role_owner;

  /// No description provided for @dog_editor_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get dog_editor_role_admin;

  /// No description provided for @dog_editor_role_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get dog_editor_role_user;

  /// No description provided for @dog_editor_section_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Hero text'**
  String get dog_editor_section_hero_title;

  /// No description provided for @dog_editor_anchor_bottom_left.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get dog_editor_anchor_bottom_left;

  /// No description provided for @dog_editor_anchor_bottom_center.
  ///
  /// In en, this message translates to:
  /// **'Bottom center'**
  String get dog_editor_anchor_bottom_center;

  /// No description provided for @dog_editor_anchor_top_left.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get dog_editor_anchor_top_left;

  /// No description provided for @dog_editor_text_size_label.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get dog_editor_text_size_label;

  /// No description provided for @dog_editor_text_size_small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get dog_editor_text_size_small;

  /// No description provided for @dog_editor_text_size_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get dog_editor_text_size_normal;

  /// No description provided for @dog_editor_text_size_large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get dog_editor_text_size_large;

  /// No description provided for @dog_editor_section_lifecycle_title.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get dog_editor_section_lifecycle_title;

  /// No description provided for @dog_editor_death_date_label.
  ///
  /// In en, this message translates to:
  /// **'Death date'**
  String get dog_editor_death_date_label;

  /// No description provided for @dog_editor_death_date_picker_hint.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get dog_editor_death_date_picker_hint;

  /// No description provided for @dog_memorial_story_label.
  ///
  /// In en, this message translates to:
  /// **'Story / memories'**
  String get dog_memorial_story_label;

  /// No description provided for @dog_memorial_story_hint.
  ///
  /// In en, this message translates to:
  /// **'Write more about the dog, hunting memories, awards or personality'**
  String get dog_memorial_story_hint;

  /// No description provided for @dog_detail_snackbar_invite_accepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted'**
  String get dog_detail_snackbar_invite_accepted;

  /// No description provided for @dog_detail_snackbar_invite_declined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get dog_detail_snackbar_invite_declined;

  /// No description provided for @dog_detail_snackbar_invite_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get dog_detail_snackbar_invite_sent;

  /// No description provided for @dog_detail_snackbar_ownership_accepted.
  ///
  /// In en, this message translates to:
  /// **'Ownership accepted'**
  String get dog_detail_snackbar_ownership_accepted;

  /// No description provided for @dog_detail_snackbar_request_declined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get dog_detail_snackbar_request_declined;

  /// No description provided for @dog_detail_snackbar_request_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get dog_detail_snackbar_request_cancelled;

  /// No description provided for @dog_detail_snackbar_image_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the photo.'**
  String get dog_detail_snackbar_image_save_failed;

  /// No description provided for @dog_detail_snackbar_pedigree_invalid.
  ///
  /// In en, this message translates to:
  /// **'The pedigree link is invalid or can’t be opened.'**
  String get dog_detail_snackbar_pedigree_invalid;

  /// No description provided for @dog_detail_photo_source_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get dog_detail_photo_source_gallery;

  /// No description provided for @dog_detail_photo_source_camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get dog_detail_photo_source_camera;

  /// No description provided for @dog_detail_button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dog_detail_button_cancel;

  /// No description provided for @dog_detail_pedigree_section_title.
  ///
  /// In en, this message translates to:
  /// **'Pedigree'**
  String get dog_detail_pedigree_section_title;

  /// No description provided for @dog_detail_button_open_pedigree.
  ///
  /// In en, this message translates to:
  /// **'Open pedigree'**
  String get dog_detail_button_open_pedigree;

  /// No description provided for @dog_pedigree_no_link.
  ///
  /// In en, this message translates to:
  /// **'No link registered'**
  String get dog_pedigree_no_link;

  /// No description provided for @dog_detail_appbar_title.
  ///
  /// In en, this message translates to:
  /// **'Dog profile'**
  String get dog_detail_appbar_title;

  /// No description provided for @dog_detail_error_dog_not_found.
  ///
  /// In en, this message translates to:
  /// **'Dog not found'**
  String get dog_detail_error_dog_not_found;

  /// No description provided for @dog_detail_title_add_dog.
  ///
  /// In en, this message translates to:
  /// **'Add dog'**
  String get dog_detail_title_add_dog;

  /// No description provided for @dog_editor_title_add_dog.
  ///
  /// In en, this message translates to:
  /// **'Add dog'**
  String get dog_editor_title_add_dog;

  /// No description provided for @dog_editor_title_edit_dog.
  ///
  /// In en, this message translates to:
  /// **'Edit dog'**
  String get dog_editor_title_edit_dog;

  /// No description provided for @dog_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get dog_profile_title;

  /// No description provided for @dog_profile_subtitle_breed_age.
  ///
  /// In en, this message translates to:
  /// **'Breed · Age'**
  String get dog_profile_subtitle_breed_age;

  /// No description provided for @dog_generic_name.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get dog_generic_name;

  /// No description provided for @dog_detail_section_access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get dog_detail_section_access;

  /// No description provided for @dog_detail_button_send_invite.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get dog_detail_button_send_invite;

  /// No description provided for @dog_detail_section_invites.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get dog_detail_section_invites;

  /// No description provided for @invite_send_email_label.
  ///
  /// In en, this message translates to:
  /// **'Recipient email'**
  String get invite_send_email_label;

  /// No description provided for @invite_send_button.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get invite_send_button;

  /// Toast shown after sending an invite.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}'**
  String invite_sent_to(Object email);

  /// No description provided for @invite_revoke_button.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get invite_revoke_button;

  /// No description provided for @invite_status_invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invite_status_invited;

  /// Status text that includes the canonical role.
  ///
  /// In en, this message translates to:
  /// **'Invited as {role}'**
  String invite_status_invited_as_user(Object role);

  /// Invitation text showing sender and dog.
  ///
  /// In en, this message translates to:
  /// **'{sender} invited you to {dogName}.'**
  String invitation_summary_with_sender_and_dog(Object sender, Object dogName);

  /// Invitation text showing dog when sender is missing.
  ///
  /// In en, this message translates to:
  /// **'You were invited to {dogName}.'**
  String invitation_summary_with_dog(Object dogName);

  /// No description provided for @invitation_summary_generic.
  ///
  /// In en, this message translates to:
  /// **'You have received a dog invitation.'**
  String get invitation_summary_generic;

  /// No description provided for @invite_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get invite_accept;

  /// No description provided for @invite_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get invite_decline;

  /// No description provided for @dog_share_section_title.
  ///
  /// In en, this message translates to:
  /// **'Shared with'**
  String get dog_share_section_title;

  /// No description provided for @dog_detail_access_section_title.
  ///
  /// In en, this message translates to:
  /// **'Access to this dog'**
  String get dog_detail_access_section_title;

  /// No description provided for @dog_detail_member_action_change_role.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get dog_detail_member_action_change_role;

  /// No description provided for @dog_detail_member_action_set_reader.
  ///
  /// In en, this message translates to:
  /// **'Set as reader'**
  String get dog_detail_member_action_set_reader;

  /// No description provided for @dog_detail_member_action_set_user.
  ///
  /// In en, this message translates to:
  /// **'Set as user'**
  String get dog_detail_member_action_set_user;

  /// No description provided for @dog_detail_member_action_remove_access.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get dog_detail_member_action_remove_access;

  /// No description provided for @dog_detail_role_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Edit role'**
  String get dog_detail_role_dialog_title;

  /// No description provided for @dog_detail_role_dialog_label.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get dog_detail_role_dialog_label;

  /// No description provided for @dog_detail_role_confirm_admin_title.
  ///
  /// In en, this message translates to:
  /// **'Grant administrator role?'**
  String get dog_detail_role_confirm_admin_title;

  /// No description provided for @dog_detail_role_confirm_admin_message.
  ///
  /// In en, this message translates to:
  /// **'Administrators can manage access for this dog.'**
  String get dog_detail_role_confirm_admin_message;

  /// No description provided for @share_role_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get share_role_owner;

  /// No description provided for @share_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get share_role_admin;

  /// No description provided for @share_role_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get share_role_user;

  /// No description provided for @dog_detail_share_empty.
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get dog_detail_share_empty;

  /// No description provided for @dog_detail_share_empty_owner.
  ///
  /// In en, this message translates to:
  /// **'No sharing yet.'**
  String get dog_detail_share_empty_owner;

  /// No description provided for @dog_detail_my_role_label.
  ///
  /// In en, this message translates to:
  /// **'Your role: {role}'**
  String dog_detail_my_role_label(String role);

  /// No description provided for @dog_detail_share_disabled_explanation.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to share this dog.'**
  String get dog_detail_share_disabled_explanation;

  /// No description provided for @share_accept_title.
  ///
  /// In en, this message translates to:
  /// **'Accept share'**
  String get share_accept_title;

  /// No description provided for @share_accept_code_label.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get share_accept_code_label;

  /// No description provided for @share_accept_scan_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get share_accept_scan_qr;

  /// No description provided for @share_accept_button.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get share_accept_button;

  /// No description provided for @share_error_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Share failed'**
  String get share_error_dialog_title;

  /// No description provided for @share_error_not_owner.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or an administrator can share the dog.'**
  String get share_error_not_owner;

  /// No description provided for @share_error_invite_not_found.
  ///
  /// In en, this message translates to:
  /// **'Invite not found.'**
  String get share_error_invite_not_found;

  /// No description provided for @share_error_invite_expired.
  ///
  /// In en, this message translates to:
  /// **'The invite has expired.'**
  String get share_error_invite_expired;

  /// No description provided for @share_error_invite_revoked.
  ///
  /// In en, this message translates to:
  /// **'The invite has been revoked.'**
  String get share_error_invite_revoked;

  /// No description provided for @share_error_invite_inactive.
  ///
  /// In en, this message translates to:
  /// **'The invite is not active.'**
  String get share_error_invite_inactive;

  /// No description provided for @share_error_already_has_access.
  ///
  /// In en, this message translates to:
  /// **'You already have access.'**
  String get share_error_already_has_access;

  /// No description provided for @share_error_already_invited.
  ///
  /// In en, this message translates to:
  /// **'This email has already been invited.'**
  String get share_error_already_invited;

  /// No description provided for @share_error_invalid_role.
  ///
  /// In en, this message translates to:
  /// **'Invalid role.'**
  String get share_error_invalid_role;

  /// No description provided for @share_error_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get share_error_invalid_email;

  /// No description provided for @membership_role_error_not_authorized.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to change this role.'**
  String get membership_role_error_not_authorized;

  /// No description provided for @membership_role_error_membership_not_found.
  ///
  /// In en, this message translates to:
  /// **'Member not found.'**
  String get membership_role_error_membership_not_found;

  /// No description provided for @membership_role_error_cannot_edit_self.
  ///
  /// In en, this message translates to:
  /// **'You cannot change your own role.'**
  String get membership_role_error_cannot_edit_self;

  /// No description provided for @membership_role_error_owner_locked.
  ///
  /// In en, this message translates to:
  /// **'Owner role can only be changed through ownership transfer.'**
  String get membership_role_error_owner_locked;

  /// No description provided for @membership_role_error_cannot_promote_to_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrators cannot assign or change administrator roles.'**
  String get membership_role_error_cannot_promote_to_admin;

  /// No description provided for @share_error_dog_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'Dog not found'**
  String get share_error_dog_not_found_title;

  /// No description provided for @share_error_dog_not_found_detail.
  ///
  /// In en, this message translates to:
  /// **'No dog matches that code.'**
  String get share_error_dog_not_found_detail;

  /// No description provided for @transfer_error_not_owner.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can decline the transfer request.'**
  String get transfer_error_not_owner;

  /// No description provided for @transfer_error_not_recipient.
  ///
  /// In en, this message translates to:
  /// **'You are not the recipient of this request.'**
  String get transfer_error_not_recipient;

  /// No description provided for @transfer_error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Transfer request not found.'**
  String get transfer_error_not_found;

  /// No description provided for @transfer_error_expired.
  ///
  /// In en, this message translates to:
  /// **'Transfer request has expired.'**
  String get transfer_error_expired;

  /// No description provided for @transfer_error_not_pending.
  ///
  /// In en, this message translates to:
  /// **'Transfer request is not pending.'**
  String get transfer_error_not_pending;

  /// No description provided for @transfer_error_cannot_transfer_to_self.
  ///
  /// In en, this message translates to:
  /// **'Cannot transfer ownership to yourself.'**
  String get transfer_error_cannot_transfer_to_self;

  /// No description provided for @transfer_error_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Transfer request has already been declined.'**
  String get transfer_error_cancelled;

  /// No description provided for @role_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get role_owner;

  /// No description provided for @role_editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get role_editor;

  /// No description provided for @role_viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get role_viewer;

  /// No description provided for @role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get role_admin;

  /// No description provided for @dog_editor_owner_email_label.
  ///
  /// In en, this message translates to:
  /// **'Owner email'**
  String get dog_editor_owner_email_label;

  /// No description provided for @dog_editor_owner_email_hint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get dog_editor_owner_email_hint;

  /// No description provided for @dog_editor_owner_email_required_error.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email for the owner.'**
  String get dog_editor_owner_email_required_error;

  /// No description provided for @dog_detail_section_owner_request_title.
  ///
  /// In en, this message translates to:
  /// **'Ownership requested'**
  String get dog_detail_section_owner_request_title;

  /// No description provided for @dog_detail_label_from_user.
  ///
  /// In en, this message translates to:
  /// **'From: {userId}'**
  String dog_detail_label_from_user(String userId);

  /// No description provided for @dog_detail_label_to_user.
  ///
  /// In en, this message translates to:
  /// **'To: {userId}'**
  String dog_detail_label_to_user(String userId);

  /// No description provided for @dog_detail_button_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get dog_detail_button_accept;

  /// No description provided for @dog_detail_button_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get dog_detail_button_decline;

  /// No description provided for @dog_detail_button_cancel_request.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get dog_detail_button_cancel_request;

  /// No description provided for @dog_detail_button_edit_photo.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get dog_detail_button_edit_photo;

  /// No description provided for @dog_detail_button_mark_dead.
  ///
  /// In en, this message translates to:
  /// **'Mark as deceased'**
  String get dog_detail_button_mark_dead;

  /// No description provided for @dog_detail_watermark_section_title.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get dog_detail_watermark_section_title;

  /// No description provided for @dog_detail_watermark_info.
  ///
  /// In en, this message translates to:
  /// **'A watermark is required when sharing dog photos.'**
  String get dog_detail_watermark_info;

  /// No description provided for @dog_detail_watermark_toggle_title.
  ///
  /// In en, this message translates to:
  /// **'Show title'**
  String get dog_detail_watermark_toggle_title;

  /// No description provided for @dog_detail_watermark_toggle_name.
  ///
  /// In en, this message translates to:
  /// **'Show name'**
  String get dog_detail_watermark_toggle_name;

  /// No description provided for @dog_detail_watermark_share_button.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get dog_detail_watermark_share_button;

  /// No description provided for @dog_detail_watermark_share_subject.
  ///
  /// In en, this message translates to:
  /// **'Photo from GundogTracker'**
  String get dog_detail_watermark_share_subject;

  /// No description provided for @dog_detail_watermark_share_message.
  ///
  /// In en, this message translates to:
  /// **'Shared via GundogTracker'**
  String get dog_detail_watermark_share_message;

  /// No description provided for @session_image_viewer_watermark_toggle_title.
  ///
  /// In en, this message translates to:
  /// **'Show title'**
  String get session_image_viewer_watermark_toggle_title;

  /// No description provided for @session_image_viewer_watermark_toggle_official_name.
  ///
  /// In en, this message translates to:
  /// **'Show official name'**
  String get session_image_viewer_watermark_toggle_official_name;

  /// No description provided for @session_image_viewer_watermark_toggle_nickname.
  ///
  /// In en, this message translates to:
  /// **'Show nickname'**
  String get session_image_viewer_watermark_toggle_nickname;

  /// No description provided for @session_image_viewer_watermark_color_title.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get session_image_viewer_watermark_color_title;

  /// No description provided for @session_image_viewer_watermark_color_light.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get session_image_viewer_watermark_color_light;

  /// No description provided for @session_image_viewer_watermark_color_dark.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get session_image_viewer_watermark_color_dark;

  /// No description provided for @session_image_viewer_watermark_presets_title.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get session_image_viewer_watermark_presets_title;

  /// No description provided for @session_image_viewer_watermark_preset_discreet.
  ///
  /// In en, this message translates to:
  /// **'Discreet'**
  String get session_image_viewer_watermark_preset_discreet;

  /// No description provided for @session_image_viewer_watermark_preset_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get session_image_viewer_watermark_preset_clear;

  /// No description provided for @session_image_viewer_watermark_preset_contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get session_image_viewer_watermark_preset_contrast;

  /// No description provided for @dog_detail_watermark_share_missing_photo.
  ///
  /// In en, this message translates to:
  /// **'Could not find an image to share.'**
  String get dog_detail_watermark_share_missing_photo;

  /// No description provided for @dog_detail_watermark_share_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to share the image.'**
  String get dog_detail_watermark_share_error;

  /// No description provided for @dog_detail_label_death_date.
  ///
  /// In en, this message translates to:
  /// **'Date of death'**
  String get dog_detail_label_death_date;

  /// No description provided for @dog_detail_button_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dog_detail_button_edit;

  /// No description provided for @dog_detail_button_register_death.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get dog_detail_button_register_death;

  /// No description provided for @dog_detail_photo_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get dog_detail_photo_dialog_title;

  /// No description provided for @dog_detail_photo_pick_camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get dog_detail_photo_pick_camera;

  /// No description provided for @dog_detail_photo_pick_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get dog_detail_photo_pick_gallery;

  /// No description provided for @dog_detail_photo_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get dog_detail_photo_remove;

  /// No description provided for @dog_detail_snackbar_photo_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get dog_detail_snackbar_photo_updated;

  /// No description provided for @dog_detail_snackbar_photo_removed.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get dog_detail_snackbar_photo_removed;

  /// No description provided for @dog_detail_snackbar_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get dog_detail_snackbar_error_generic;

  /// No description provided for @dog_detail_info_label_sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get dog_detail_info_label_sex;

  /// No description provided for @dog_detail_info_label_born.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get dog_detail_info_label_born;

  /// No description provided for @dog_detail_summary_points_label.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get dog_detail_summary_points_label;

  /// No description provided for @dog_detail_summary_session_count_label.
  ///
  /// In en, this message translates to:
  /// **'Session count'**
  String get dog_detail_summary_session_count_label;

  /// No description provided for @dog_detail_summary_active_time_label.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get dog_detail_summary_active_time_label;

  /// No description provided for @dog_detail_summary_birds_down_label.
  ///
  /// In en, this message translates to:
  /// **'Birds down'**
  String get dog_detail_summary_birds_down_label;

  /// No description provided for @dog_detail_summary_first_session_label.
  ///
  /// In en, this message translates to:
  /// **'First session'**
  String get dog_detail_summary_first_session_label;

  /// No description provided for @dog_detail_summary_last_session_label.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get dog_detail_summary_last_session_label;

  /// No description provided for @dog_detail_tooltip_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit dog'**
  String get dog_detail_tooltip_edit_profile;

  /// No description provided for @dog_detail_farewell_prefix.
  ///
  /// In en, this message translates to:
  /// **'Farewell'**
  String get dog_detail_farewell_prefix;

  /// Sentence describing how old the dog was when passing.
  ///
  /// In en, this message translates to:
  /// **'{name} was {years} {months} {days} old'**
  String dog_detail_farewell_age_sentence(Object name, Object years, Object months, Object days);

  /// No description provided for @dog_detail_next_milestones_title.
  ///
  /// In en, this message translates to:
  /// **'Next milestones'**
  String get dog_detail_next_milestones_title;

  /// No description provided for @dog_detail_next_milestone_title.
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get dog_detail_next_milestone_title;

  /// No description provided for @dog_heat_cycle_section_title.
  ///
  /// In en, this message translates to:
  /// **'Heat cycle'**
  String get dog_heat_cycle_section_title;

  /// No description provided for @dog_heat_cycle_add_button.
  ///
  /// In en, this message translates to:
  /// **'Add heat cycle'**
  String get dog_heat_cycle_add_button;

  /// No description provided for @dog_heat_cycle_add_title.
  ///
  /// In en, this message translates to:
  /// **'New heat cycle'**
  String get dog_heat_cycle_add_title;

  /// No description provided for @dog_heat_cycle_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit heat cycle'**
  String get dog_heat_cycle_edit_title;

  /// No description provided for @dog_heat_cycle_start_date_label.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get dog_heat_cycle_start_date_label;

  /// No description provided for @dog_heat_cycle_end_date_label.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get dog_heat_cycle_end_date_label;

  /// No description provided for @dog_heat_cycle_end_not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dog_heat_cycle_end_not_set;

  /// No description provided for @dog_heat_cycle_note_label.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get dog_heat_cycle_note_label;

  /// No description provided for @dog_heat_cycle_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get dog_heat_cycle_note_hint;

  /// No description provided for @dog_heat_cycle_empty.
  ///
  /// In en, this message translates to:
  /// **'No heat cycle has been logged yet.'**
  String get dog_heat_cycle_empty;

  /// No description provided for @dog_heat_cycle_period_value.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String dog_heat_cycle_period_value(Object start, Object end);

  /// No description provided for @dog_heat_cycle_edit_button.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dog_heat_cycle_edit_button;

  /// No description provided for @dog_heat_cycle_delete_button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dog_heat_cycle_delete_button;

  /// No description provided for @dog_heat_cycle_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete heat cycle'**
  String get dog_heat_cycle_delete_title;

  /// No description provided for @dog_heat_cycle_delete_body.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this heat cycle entry?'**
  String get dog_heat_cycle_delete_body;

  /// No description provided for @dog_heat_cycle_info_title.
  ///
  /// In en, this message translates to:
  /// **'Heat cycle info'**
  String get dog_heat_cycle_info_title;

  /// No description provided for @dog_heat_cycle_info_line_1.
  ///
  /// In en, this message translates to:
  /// **'Heat cycles in female dogs often happen around 1-2 times per year, but this varies between individuals.'**
  String get dog_heat_cycle_info_line_1;

  /// No description provided for @dog_heat_cycle_info_line_2.
  ///
  /// In en, this message translates to:
  /// **'The duration is often around 2-3 weeks, but can vary.'**
  String get dog_heat_cycle_info_line_2;

  /// No description provided for @dog_heat_cycle_info_line_3.
  ///
  /// In en, this message translates to:
  /// **'During heat, the dog may be less focused, show behavior changes, or perform differently in training/hunting.'**
  String get dog_heat_cycle_info_line_3;

  /// No description provided for @dog_heat_cycle_info_line_4.
  ///
  /// In en, this message translates to:
  /// **'Be extra attentive around other dogs.'**
  String get dog_heat_cycle_info_line_4;

  /// No description provided for @dog_heat_cycle_info_line_5.
  ///
  /// In en, this message translates to:
  /// **'Adjust training based on the dog\'s condition and behavior.'**
  String get dog_heat_cycle_info_line_5;

  /// No description provided for @dog_heat_cycle_info_line_6.
  ///
  /// In en, this message translates to:
  /// **'Contact a veterinarian if there is unusual bleeding, pain, signs of illness, or concern.'**
  String get dog_heat_cycle_info_line_6;

  /// No description provided for @milestone_first_session_title.
  ///
  /// In en, this message translates to:
  /// **'First session completed'**
  String get milestone_first_session_title;

  /// No description provided for @milestone_first_session_subtitle.
  ///
  /// In en, this message translates to:
  /// **'First session with {dogName}'**
  String milestone_first_session_subtitle(Object dogName);

  /// No description provided for @milestone_first_bird_title.
  ///
  /// In en, this message translates to:
  /// **'First bird'**
  String get milestone_first_bird_title;

  /// Age measured in years with plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year} other{{count} years}}'**
  String age_years(int count);

  /// Short year label when showing age in the hero header.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} yr} other{{count} yrs}}'**
  String age_years_short(int count);

  /// Age measured in months with plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} month} other{{count} months}}'**
  String age_months(int count);

  /// Short month label when showing age in the hero header.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} mo} other{{count} mos}}'**
  String age_months_short(int count);

  /// Age measured in days with plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String age_days(int count);

  /// No description provided for @age_zero_days.
  ///
  /// In en, this message translates to:
  /// **'0 days'**
  String get age_zero_days;

  /// No description provided for @age_and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get age_and;

  /// No description provided for @home_startNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start new session'**
  String get home_startNewSession;

  /// No description provided for @chooseDog.
  ///
  /// In en, this message translates to:
  /// **'Choose dog'**
  String get chooseDog;

  /// No description provided for @noDogsAddDog.
  ///
  /// In en, this message translates to:
  /// **'No dogs – add a dog'**
  String get noDogsAddDog;

  /// No description provided for @home_addDogPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a dog to start a session'**
  String get home_addDogPrompt;

  /// Title for the empty home state when no dogs are registered.
  ///
  /// In en, this message translates to:
  /// **'Start your journey with your hunting dog'**
  String get home_empty_title;

  /// Body text that explains the empty home state.
  ///
  /// In en, this message translates to:
  /// **'Log sessions, track progress, and build a history for your dog – session by session.'**
  String get home_empty_body;

  /// First bullet in the empty home state.
  ///
  /// In en, this message translates to:
  /// **'See development over time – stand, flushes and activity.'**
  String get home_empty_bullet_progress;

  /// Second bullet in the empty home state.
  ///
  /// In en, this message translates to:
  /// **'Train better – see what actually pays off.'**
  String get home_empty_bullet_training;

  /// Third bullet in the empty home state.
  ///
  /// In en, this message translates to:
  /// **'Hunting history you actually use – season after season, area by area.'**
  String get home_empty_bullet_history;

  /// Label for the add dog action on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Add dog'**
  String get home_addDog_button;

  /// No description provided for @home_empty_next_step.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your dog. Then when you\'re ready, log your first session and build your history from day one.'**
  String get home_empty_next_step;

  /// No description provided for @home_first_session_title.
  ///
  /// In en, this message translates to:
  /// **'Ready for your first session?'**
  String get home_first_session_title;

  /// No description provided for @home_first_session_body.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got your dog registered. Next step is to log your first session – that\'s where your history and stats begin.'**
  String get home_first_session_body;

  /// Note that the app works offline shown in the empty home state.
  ///
  /// In en, this message translates to:
  /// **'You can use the app completely offline. All data is stored locally on your phone.'**
  String get home_empty_offline_note;

  /// No description provided for @home_dashboard_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Personal goal'**
  String get home_dashboard_goal_title;

  /// No description provided for @home_dashboard_goal_prompt.
  ///
  /// In en, this message translates to:
  /// **'Set a personal goal in Settings to track your stands progress.'**
  String get home_dashboard_goal_prompt;

  /// No description provided for @home_dashboard_latest_session_title.
  ///
  /// In en, this message translates to:
  /// **'Latest session'**
  String get home_dashboard_latest_session_title;

  /// No description provided for @home_dashboard_latest_session_empty.
  ///
  /// In en, this message translates to:
  /// **'No sessions registered yet.'**
  String get home_dashboard_latest_session_empty;

  /// No description provided for @home_dashboard_latest_session_unknown_dog.
  ///
  /// In en, this message translates to:
  /// **'Unknown dog'**
  String get home_dashboard_latest_session_unknown_dog;

  /// No description provided for @home_dashboard_quick_action_title.
  ///
  /// In en, this message translates to:
  /// **'Quick action'**
  String get home_dashboard_quick_action_title;

  /// No description provided for @home_dashboard_quick_action_body.
  ///
  /// In en, this message translates to:
  /// **'Ready for the next session? Start logging with one tap.'**
  String get home_dashboard_quick_action_body;

  /// Title shown when filtered dog list is empty.
  ///
  /// In en, this message translates to:
  /// **'No dogs available'**
  String get home_visible_empty_title;

  /// Explanation shown when the user has no active memberships for any dog.
  ///
  /// In en, this message translates to:
  /// **'This account has no dogs yet. Check invitations or ask someone to share a dog with you.'**
  String get home_visible_empty_body;

  /// Button label for opening the invitations page.
  ///
  /// In en, this message translates to:
  /// **'Open invitations'**
  String get home_visible_empty_button;

  /// Home banner text shown when the user has pending dog invitations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have a dog invitation} other{You have {count} dog invitations}}'**
  String home_pendingInvitationsTitle(int count);

  /// No description provided for @home_pendingInvitationsButton.
  ///
  /// In en, this message translates to:
  /// **'View invitation'**
  String get home_pendingInvitationsButton;

  /// No description provided for @home_noDogsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No dogs registered'**
  String get home_noDogsRegistered;

  /// No description provided for @home_primaryActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notes first. Use the + buttons in the fields.'**
  String get home_primaryActionSubtitle;

  /// No description provided for @home_top10_points_title.
  ///
  /// In en, this message translates to:
  /// **'Top 10 – Points'**
  String get home_top10_points_title;

  /// No description provided for @top10Title.
  ///
  /// In en, this message translates to:
  /// **'Top 10'**
  String get top10Title;

  /// No description provided for @home_top10_points_empty.
  ///
  /// In en, this message translates to:
  /// **'No points recorded yet.'**
  String get home_top10_points_empty;

  /// No description provided for @home_top10_points_pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points: {count}'**
  String home_top10_points_pointsLabel(int count);

  /// No description provided for @standsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get standsLabel;

  /// No description provided for @standsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 points} one{1 point} other{{count} points}}'**
  String standsCount(num count);

  /// Unit label for top10 points.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{point} other{points}}'**
  String top10_points_unit(int count);

  /// No description provided for @flushesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 flushes} one{1 flush} other{{count} flushes}}'**
  String flushesCount(num count);

  /// No description provided for @birdContactsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 bird contacts} one{1 bird contact} other{{count} bird contacts}}'**
  String birdContactsCount(num count);

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 sessions} one{1 session} other{{count} sessions}}'**
  String sessionsCount(num count);

  /// No description provided for @home_top10_birds_title.
  ///
  /// In en, this message translates to:
  /// **'Top 10 birds down'**
  String get home_top10_birds_title;

  /// No description provided for @home_top10_birds_empty.
  ///
  /// In en, this message translates to:
  /// **'No birds recorded yet.'**
  String get home_top10_birds_empty;

  /// No description provided for @home_top10_birds_fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get home_top10_birds_fieldLabel;

  /// No description provided for @session_log_title.
  ///
  /// In en, this message translates to:
  /// **'Session log – Gundog'**
  String get session_log_title;

  /// No description provided for @session_saved_list_title.
  ///
  /// In en, this message translates to:
  /// **'Saved sessions'**
  String get session_saved_list_title;

  /// No description provided for @session_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get session_save_button;

  /// No description provided for @session_unit_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get session_unit_min;

  /// No description provided for @session_unit_sec.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get session_unit_sec;

  /// No description provided for @session_label_points.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get session_label_points;

  /// No description provided for @session_label_flushes.
  ///
  /// In en, this message translates to:
  /// **'flushes'**
  String get session_label_flushes;

  /// No description provided for @session_label_birds.
  ///
  /// In en, this message translates to:
  /// **'birds'**
  String get session_label_birds;

  /// No description provided for @session_label_birds_down.
  ///
  /// In en, this message translates to:
  /// **'birds down'**
  String get session_label_birds_down;

  /// No description provided for @session_all_dogs_label.
  ///
  /// In en, this message translates to:
  /// **'All dogs'**
  String get session_all_dogs_label;

  /// No description provided for @session_map_label.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get session_map_label;

  /// No description provided for @session_map_error_no_tracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get session_map_error_no_tracks;

  /// No description provided for @session_map_error_map_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the map'**
  String get session_map_error_map_load_failed;

  /// No description provided for @map_page_snackbar_no_tracks_to_focus.
  ///
  /// In en, this message translates to:
  /// **'No tracks to focus on'**
  String get map_page_snackbar_no_tracks_to_focus;

  /// No description provided for @map_page_dialog_delete_downloaded_map_body.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this downloaded map?'**
  String get map_page_dialog_delete_downloaded_map_body;

  /// No description provided for @map_download_title.
  ///
  /// In en, this message translates to:
  /// **'Download map'**
  String get map_download_title;

  /// No description provided for @map_download_area_label.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get map_download_area_label;

  /// No description provided for @map_download_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get map_download_cancel;

  /// No description provided for @map_download_start.
  ///
  /// In en, this message translates to:
  /// **'Start download'**
  String get map_download_start;

  /// No description provided for @map_downloaded_maps_title.
  ///
  /// In en, this message translates to:
  /// **'Downloaded maps'**
  String get map_downloaded_maps_title;

  /// No description provided for @map_downloaded_maps_empty.
  ///
  /// In en, this message translates to:
  /// **'No downloaded maps yet.'**
  String get map_downloaded_maps_empty;

  /// No description provided for @map_delete_offline_title.
  ///
  /// In en, this message translates to:
  /// **'Delete offline map'**
  String get map_delete_offline_title;

  /// No description provided for @map_delete_offline_body.
  ///
  /// In en, this message translates to:
  /// **'This deletes downloaded map tiles for the selected style.'**
  String get map_delete_offline_body;

  /// No description provided for @map_delete_offline_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get map_delete_offline_cancel;

  /// No description provided for @map_delete_offline_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get map_delete_offline_confirm;

  /// No description provided for @map_downloading_title.
  ///
  /// In en, this message translates to:
  /// **'Downloading map'**
  String get map_downloading_title;

  /// No description provided for @map_downloading_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get map_downloading_cancel;

  /// No description provided for @map_go_to.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get map_go_to;

  /// No description provided for @map_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get map_delete;

  /// No description provided for @map_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete map'**
  String get map_delete_title;

  /// No description provided for @map_tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get map_tracks;

  /// No description provided for @map_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get map_me;

  /// No description provided for @hunt_session_snackbar_export_ready_opening_share.
  ///
  /// In en, this message translates to:
  /// **'Export ready, opening share…'**
  String get hunt_session_snackbar_export_ready_opening_share;

  /// No description provided for @hunt_session_snackbar_gpx_export_failed_see_log.
  ///
  /// In en, this message translates to:
  /// **'GPX export failed. See log.'**
  String get hunt_session_snackbar_gpx_export_failed_see_log;

  /// No description provided for @session_gpx_import_label.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get session_gpx_import_label;

  /// No description provided for @session_gpx_importing_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get session_gpx_importing_ellipsis;

  /// No description provided for @session_gpx_export_label.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get session_gpx_export_label;

  /// No description provided for @session_gpx_exporting_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get session_gpx_exporting_ellipsis;

  /// No description provided for @session_form_dog_section_title.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get session_form_dog_section_title;

  /// No description provided for @session_form_dog_prefix.
  ///
  /// In en, this message translates to:
  /// **'Dog:'**
  String get session_form_dog_prefix;

  /// No description provided for @session_form_no_dogs_registered.
  ///
  /// In en, this message translates to:
  /// **'No dogs registered.'**
  String get session_form_no_dogs_registered;

  /// No description provided for @session_form_no_dogs_help.
  ///
  /// In en, this message translates to:
  /// **'Add a dog first, then you can start your first session.'**
  String get session_form_no_dogs_help;

  /// No description provided for @session_summary_sessions_label.
  ///
  /// In en, this message translates to:
  /// **'Sessions:'**
  String get session_summary_sessions_label;

  /// No description provided for @session_summary_total_time_label.
  ///
  /// In en, this message translates to:
  /// **'Total time:'**
  String get session_summary_total_time_label;

  /// No description provided for @session_summary_total_bird_contacts_label.
  ///
  /// In en, this message translates to:
  /// **'Total bird contacts:'**
  String get session_summary_total_bird_contacts_label;

  /// No description provided for @session_summary_total_points_label.
  ///
  /// In en, this message translates to:
  /// **'Total points:'**
  String get session_summary_total_points_label;

  /// No description provided for @session_summary_total_secondary_points_label.
  ///
  /// In en, this message translates to:
  /// **'Total secondary points:'**
  String get session_summary_total_secondary_points_label;

  /// No description provided for @session_summary_total_tomstand_label.
  ///
  /// In en, this message translates to:
  /// **'Total tomstand:'**
  String get session_summary_total_tomstand_label;

  /// No description provided for @session_summary_total_flushes_label.
  ///
  /// In en, this message translates to:
  /// **'Total flushes:'**
  String get session_summary_total_flushes_label;

  /// No description provided for @session_action_add_new_session.
  ///
  /// In en, this message translates to:
  /// **'Add new session'**
  String get session_action_add_new_session;

  /// No description provided for @session_action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get session_action_cancel;

  /// No description provided for @session_type_title.
  ///
  /// In en, this message translates to:
  /// **'Session type'**
  String get session_type_title;

  /// No description provided for @session_type_training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get session_type_training;

  /// No description provided for @session_type_hunt.
  ///
  /// In en, this message translates to:
  /// **'Hunt'**
  String get session_type_hunt;

  /// No description provided for @session_field_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get session_field_location;

  /// No description provided for @session_field_active_time_minutes.
  ///
  /// In en, this message translates to:
  /// **'Active time (min)'**
  String get session_field_active_time_minutes;

  /// No description provided for @session_field_bird_contacts.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts'**
  String get session_field_bird_contacts;

  /// No description provided for @session_field_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get session_field_points;

  /// No description provided for @session_field_tomstand.
  ///
  /// In en, this message translates to:
  /// **'Tomstand'**
  String get session_field_tomstand;

  /// No description provided for @session_field_secondary_points.
  ///
  /// In en, this message translates to:
  /// **'Secondary points'**
  String get session_field_secondary_points;

  /// No description provided for @session_field_flushes.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get session_field_flushes;

  /// No description provided for @session_pick_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get session_pick_date;

  /// No description provided for @session_pick_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get session_pick_time;

  /// No description provided for @session_birds_section_title.
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get session_birds_section_title;

  /// No description provided for @session_birds_select_species.
  ///
  /// In en, this message translates to:
  /// **'Select bird species'**
  String get session_birds_select_species;

  /// No description provided for @session_birds_none_selected.
  ///
  /// In en, this message translates to:
  /// **'No species selected'**
  String get session_birds_none_selected;

  /// No description provided for @species_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Select bird species'**
  String get species_picker_title;

  /// No description provided for @species_picker_empty.
  ///
  /// In en, this message translates to:
  /// **'No species saved yet'**
  String get species_picker_empty;

  /// No description provided for @species_picker_add_button.
  ///
  /// In en, this message translates to:
  /// **'New bird'**
  String get species_picker_add_button;

  /// No description provided for @species_picker_done_button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get species_picker_done_button;

  /// No description provided for @species_picker_new_title.
  ///
  /// In en, this message translates to:
  /// **'New bird species'**
  String get species_picker_new_title;

  /// No description provided for @species_picker_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get species_picker_name_label;

  /// No description provided for @session_species_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Select species'**
  String get session_species_picker_title;

  /// No description provided for @session_species_picker_empty.
  ///
  /// In en, this message translates to:
  /// **'No species available'**
  String get session_species_picker_empty;

  /// No description provided for @session_species_picker_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get session_species_picker_add;

  /// No description provided for @session_species_picker_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get session_species_picker_done;

  /// No description provided for @session_error_no_dogs_registered.
  ///
  /// In en, this message translates to:
  /// **'No dogs registered'**
  String get session_error_no_dogs_registered;

  /// No description provided for @session_select_species_title.
  ///
  /// In en, this message translates to:
  /// **'Select species'**
  String get session_select_species_title;

  /// No description provided for @session_no_species_saved_yet.
  ///
  /// In en, this message translates to:
  /// **'No species saved yet'**
  String get session_no_species_saved_yet;

  /// No description provided for @session_new_bird_button.
  ///
  /// In en, this message translates to:
  /// **'New bird'**
  String get session_new_bird_button;

  /// No description provided for @session_new_species_title.
  ///
  /// In en, this message translates to:
  /// **'New species'**
  String get session_new_species_title;

  /// No description provided for @session_error_photo_add.
  ///
  /// In en, this message translates to:
  /// **'Could not add photo'**
  String get session_error_photo_add;

  /// No description provided for @session_error_video_add.
  ///
  /// In en, this message translates to:
  /// **'Could not add video'**
  String get session_error_video_add;

  /// No description provided for @session_error_media_save.
  ///
  /// In en, this message translates to:
  /// **'Could not save media file'**
  String get session_error_media_save;

  /// No description provided for @session_error_gpx_import.
  ///
  /// In en, this message translates to:
  /// **'GPX import failed. See log.'**
  String get session_error_gpx_import;

  /// No description provided for @session_error_location_services_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get session_error_location_services_disabled;

  /// No description provided for @session_error_no_gps.
  ///
  /// In en, this message translates to:
  /// **'No GPS access'**
  String get session_error_no_gps;

  /// GPS failure message.
  ///
  /// In en, this message translates to:
  /// **'GPS error: {error}'**
  String session_error_gps_failure(String error);

  /// No description provided for @session_error_stop_gps.
  ///
  /// In en, this message translates to:
  /// **'Could not stop GPS'**
  String get session_error_stop_gps;

  /// No description provided for @session_error_select_dog_first.
  ///
  /// In en, this message translates to:
  /// **'Select a dog first'**
  String get session_error_select_dog_first;

  /// No description provided for @session_error_no_track_export.
  ///
  /// In en, this message translates to:
  /// **'This session has no track to export'**
  String get session_error_no_track_export;

  /// No description provided for @session_error_track_empty.
  ///
  /// In en, this message translates to:
  /// **'Track is missing or empty'**
  String get session_error_track_empty;

  /// Snackbar message with dynamic text.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String session_snackbar_message(String message);

  /// No description provided for @session_media_add_image_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not add image'**
  String get session_media_add_image_failed;

  /// No description provided for @session_media_add_video_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not add video'**
  String get session_media_add_video_failed;

  /// No description provided for @session_media_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the media file'**
  String get session_media_save_failed;

  /// Shown when a session video file cannot be opened because it is gone or empty
  ///
  /// In en, this message translates to:
  /// **'Video missing or was not saved correctly'**
  String get session_media_video_missing;

  /// Displayed when the video player fails to initialize the selected media
  ///
  /// In en, this message translates to:
  /// **'Could not open video'**
  String get session_media_video_open_failed;

  /// No description provided for @session_media_section_title.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get session_media_section_title;

  /// No description provided for @session_media_add_photo_video.
  ///
  /// In en, this message translates to:
  /// **'Add photo/video'**
  String get session_media_add_photo_video;

  /// No description provided for @session_media_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing media ...'**
  String get session_media_importing;

  /// No description provided for @session_media_gallery_label.
  ///
  /// In en, this message translates to:
  /// **'Photo from gallery'**
  String get session_media_gallery_label;

  /// No description provided for @session_media_camera_label.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get session_media_camera_label;

  /// No description provided for @session_media_video_label.
  ///
  /// In en, this message translates to:
  /// **'Video from gallery'**
  String get session_media_video_label;

  /// No description provided for @gpx_import_failed_see_log.
  ///
  /// In en, this message translates to:
  /// **'GPX import failed. See log.'**
  String get gpx_import_failed_see_log;

  /// No description provided for @gps_services_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get gps_services_disabled;

  /// No description provided for @gps_no_permission.
  ///
  /// In en, this message translates to:
  /// **'No GPS permission'**
  String get gps_no_permission;

  /// GPS error placeholder.
  ///
  /// In en, this message translates to:
  /// **'GPS error: {error}'**
  String gps_error_message(String error);

  /// No description provided for @gps_stop_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not stop GPS'**
  String get gps_stop_failed;

  /// No description provided for @session_select_dog_first.
  ///
  /// In en, this message translates to:
  /// **'Select a dog first'**
  String get session_select_dog_first;

  /// No description provided for @session_export_no_track.
  ///
  /// In en, this message translates to:
  /// **'This session has no track to export'**
  String get session_export_no_track;

  /// No description provided for @session_track_missing_or_empty.
  ///
  /// In en, this message translates to:
  /// **'Track is missing or empty'**
  String get session_track_missing_or_empty;

  /// Snackbar after exporting GPX file.
  ///
  /// In en, this message translates to:
  /// **'GPX exported to Desktop: {filename} ✅'**
  String gpx_exported_to_desktop(String filename);

  /// No description provided for @session_detail_title_edit_session.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get session_detail_title_edit_session;

  /// No description provided for @session_detail_title_new_session.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get session_detail_title_new_session;

  /// No description provided for @session_detail_label_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get session_detail_label_points;

  /// No description provided for @session_detail_label_flushes.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get session_detail_label_flushes;

  /// No description provided for @session_detail_button_add_media.
  ///
  /// In en, this message translates to:
  /// **'Add photo/video'**
  String get session_detail_button_add_media;

  /// Label showing total points in session detail.
  ///
  /// In en, this message translates to:
  /// **'Points total: {value}'**
  String session_detail_total_points(String value);

  /// No description provided for @session_detail_title_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get session_detail_title_home;

  /// No description provided for @session_detail_title_main.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session_detail_title_main;

  /// No description provided for @session_detail_title_active_session.
  ///
  /// In en, this message translates to:
  /// **'Active session'**
  String get session_detail_title_active_session;

  /// No description provided for @active_session_hunt_events_title.
  ///
  /// In en, this message translates to:
  /// **'Hunting events +1'**
  String get active_session_hunt_events_title;

  /// No description provided for @active_session_action_stand_plus1.
  ///
  /// In en, this message translates to:
  /// **'Point +1'**
  String get active_session_action_stand_plus1;

  /// No description provided for @active_session_action_secondary_plus1.
  ///
  /// In en, this message translates to:
  /// **'Backing +1'**
  String get active_session_action_secondary_plus1;

  /// No description provided for @active_session_action_flush_plus1.
  ///
  /// In en, this message translates to:
  /// **'Flush +1'**
  String get active_session_action_flush_plus1;

  /// No description provided for @active_session_action_bird_plus1.
  ///
  /// In en, this message translates to:
  /// **'Bird +1'**
  String get active_session_action_bird_plus1;

  /// No description provided for @active_session_action_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get active_session_action_undo;

  /// No description provided for @session_detail_label_choose_dog.
  ///
  /// In en, this message translates to:
  /// **'Choose dog'**
  String get session_detail_label_choose_dog;

  /// No description provided for @session_detail_button_open_latest_session.
  ///
  /// In en, this message translates to:
  /// **'Open latest session'**
  String get session_detail_button_open_latest_session;

  /// No description provided for @session_detail_button_start_new_session.
  ///
  /// In en, this message translates to:
  /// **'Start new session'**
  String get session_detail_button_start_new_session;

  /// No description provided for @session_detail_button_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get session_detail_button_settings;

  /// No description provided for @session_detail_media_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get session_detail_media_sheet_title;

  /// No description provided for @session_detail_media_sheet_action_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get session_detail_media_sheet_action_gallery;

  /// No description provided for @session_detail_media_sheet_action_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get session_detail_media_sheet_action_camera;

  /// No description provided for @session_detail_media_sheet_action_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get session_detail_media_sheet_action_video;

  /// No description provided for @session_detail_media_section_title.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get session_detail_media_section_title;

  /// No description provided for @session_detail_media_empty_placeholder.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get session_detail_media_empty_placeholder;

  /// No description provided for @session_detail_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Notes from the session...'**
  String get session_detail_notes_hint;

  /// Label used in the active time chip on the session detail screen.
  ///
  /// In en, this message translates to:
  /// **'Active time: {minutes} min'**
  String session_detail_meta_time_minutes(Object minutes);

  /// Label used in the bird contacts chip on the session detail screen.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts: {value}'**
  String session_detail_meta_birds(Object value);

  /// Label used in the secondary points chip on the session detail screen.
  ///
  /// In en, this message translates to:
  /// **'Secondary points: {count}'**
  String session_detail_meta_secondary_points(Object count);

  /// Label used in the flushes chip on the session detail screen.
  ///
  /// In en, this message translates to:
  /// **'Flushes: {value}'**
  String session_detail_meta_flushes(Object value);

  /// No description provided for @session_detail_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get session_detail_screen_title;

  /// No description provided for @session_notes_hint_from_session.
  ///
  /// In en, this message translates to:
  /// **'Notes from the session...'**
  String get session_notes_hint_from_session;

  /// No description provided for @session_notes_section_title.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get session_notes_section_title;

  /// No description provided for @session_detail_section_dog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get session_detail_section_dog;

  /// No description provided for @session_detail_section_media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get session_detail_section_media;

  /// No description provided for @session_detail_section_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get session_detail_section_notes;

  /// No description provided for @session_detail_media_open_gallery.
  ///
  /// In en, this message translates to:
  /// **'Open gallery'**
  String get session_detail_media_open_gallery;

  /// No description provided for @session_detail_button_import_gpx.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get session_detail_button_import_gpx;

  /// No description provided for @session_detail_button_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get session_detail_button_importing;

  /// No description provided for @session_detail_empty_bird_species.
  ///
  /// In en, this message translates to:
  /// **'No bird species'**
  String get session_detail_empty_bird_species;

  /// No description provided for @session_detail_empty_location.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get session_detail_empty_location;

  /// No description provided for @session_detail_saved_sessions_title.
  ///
  /// In en, this message translates to:
  /// **'Saved sessions'**
  String get session_detail_saved_sessions_title;

  /// No description provided for @session_detail_empty_sessions_for_selected_dog.
  ///
  /// In en, this message translates to:
  /// **'No sessions for the selected dog'**
  String get session_detail_empty_sessions_for_selected_dog;

  /// No description provided for @session_detail_empty_dogs_registered.
  ///
  /// In en, this message translates to:
  /// **'No dogs registered.'**
  String get session_detail_empty_dogs_registered;

  /// No description provided for @session_detail_empty_sessions_yet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get session_detail_empty_sessions_yet;

  /// Summary label showing count of GPS points.
  ///
  /// In en, this message translates to:
  /// **'Track: {count} points'**
  String session_detail_track_summary_points(int count);

  /// Label showing track start time.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String session_detail_track_summary_start(String time);

  /// Label showing track end time.
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String session_detail_track_summary_end(String time);

  /// Label showing distance in meters.
  ///
  /// In en, this message translates to:
  /// **'Distance: {meters} m'**
  String session_detail_track_summary_distance_meters(String meters);

  /// Label showing distance in kilometers.
  ///
  /// In en, this message translates to:
  /// **'Distance: {kilometers} km'**
  String session_detail_track_summary_distance_km(String kilometers);

  /// Label showing formatted duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {value}'**
  String session_detail_track_summary_duration(String value);

  /// No description provided for @session_detail_action_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get session_detail_action_saving;

  /// No description provided for @session_detail_action_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get session_detail_action_save_changes;

  /// No description provided for @session_detail_action_save_session.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get session_detail_action_save_session;

  /// No description provided for @session_detail_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get session_detail_edit_title;

  /// No description provided for @session_detail_button_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get session_detail_button_save;

  /// No description provided for @session_detail_button_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get session_detail_button_cancel;

  /// No description provided for @session_detail_button_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get session_detail_button_delete;

  /// No description provided for @session_detail_field_location_label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get session_detail_field_location_label;

  /// No description provided for @session_detail_field_active_time_minutes_label.
  ///
  /// In en, this message translates to:
  /// **'Active time (min)'**
  String get session_detail_field_active_time_minutes_label;

  /// No description provided for @session_detail_field_bird_contacts_label.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts'**
  String get session_detail_field_bird_contacts_label;

  /// No description provided for @session_detail_field_points_label.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get session_detail_field_points_label;

  /// No description provided for @session_detail_field_secondary_points_label.
  ///
  /// In en, this message translates to:
  /// **'Secondary points'**
  String get session_detail_field_secondary_points_label;

  /// No description provided for @session_detail_field_tomstand_label.
  ///
  /// In en, this message translates to:
  /// **'Tomstand'**
  String get session_detail_field_tomstand_label;

  /// No description provided for @session_detail_field_flushes_label.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get session_detail_field_flushes_label;

  /// No description provided for @session_detail_field_notes_label.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get session_detail_field_notes_label;

  /// Suffix for the debug build number label.
  ///
  /// In en, this message translates to:
  /// **' (build {buildNumber})'**
  String session_detail_version_build(String buildNumber);

  /// No description provided for @settings_version_label.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settings_version_label(Object version);

  /// No description provided for @settings_version_build.
  ///
  /// In en, this message translates to:
  /// **' (build {buildNumber})'**
  String settings_version_build(Object buildNumber);

  /// No description provided for @session_detail_snackbar_changes_saved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get session_detail_snackbar_changes_saved;

  /// No description provided for @session_detail_snackbar_session_saved.
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get session_detail_snackbar_session_saved;

  /// No description provided for @session_detail_snackbar_saved_with_imported_gpx.
  ///
  /// In en, this message translates to:
  /// **'Session saved with imported GPX ({points} points)'**
  String session_detail_snackbar_saved_with_imported_gpx(int points);

  /// No description provided for @session_detail_snackbar_saved_with_gps_track.
  ///
  /// In en, this message translates to:
  /// **'Session saved with GPS track ({points} points)'**
  String session_detail_snackbar_saved_with_gps_track(int points);

  /// No description provided for @session_detail_help_notes_first.
  ///
  /// In en, this message translates to:
  /// **'Notes first. Counters with + in the field.'**
  String get session_detail_help_notes_first;

  /// No description provided for @session_detail_stats_sessions_count.
  ///
  /// In en, this message translates to:
  /// **'Sessions: {count}'**
  String session_detail_stats_sessions_count(int count);

  /// No description provided for @session_detail_stats_total_active_time.
  ///
  /// In en, this message translates to:
  /// **'Total active time: {minutes} min'**
  String session_detail_stats_total_active_time(int minutes);

  /// No description provided for @session_detail_stats_total_birds.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts total: {count}'**
  String session_detail_stats_total_birds(int count);

  /// No description provided for @session_detail_stats_total_points.
  ///
  /// In en, this message translates to:
  /// **'Points total: {count}'**
  String session_detail_stats_total_points(int count);

  /// No description provided for @session_detail_stats_total_secondary_points.
  ///
  /// In en, this message translates to:
  /// **'Secondary points total: {count}'**
  String session_detail_stats_total_secondary_points(int count);

  /// No description provided for @session_detail_stats_total_tomstand.
  ///
  /// In en, this message translates to:
  /// **'Tomstand total: {count}'**
  String session_detail_stats_total_tomstand(int count);

  /// No description provided for @session_detail_stats_total_flushes.
  ///
  /// In en, this message translates to:
  /// **'Flushes total: {count}'**
  String session_detail_stats_total_flushes(int count);

  /// No description provided for @session_detail_button_select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get session_detail_button_select_date;

  /// No description provided for @session_detail_button_select_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get session_detail_button_select_time;

  /// No description provided for @session_detail_label_duration_from_track.
  ///
  /// In en, this message translates to:
  /// **'Taken from GPS track'**
  String get session_detail_label_duration_from_track;

  /// No description provided for @session_detail_confirm_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get session_detail_confirm_delete_title;

  /// No description provided for @session_detail_confirm_delete_body.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get session_detail_confirm_delete_body;

  /// No description provided for @session_detail_media_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment?'**
  String get session_detail_media_delete_title;

  /// No description provided for @session_detail_media_delete_body.
  ///
  /// In en, this message translates to:
  /// **'The attachment will be permanently removed from the session.'**
  String get session_detail_media_delete_body;

  /// Summary line for saved session entries.
  ///
  /// In en, this message translates to:
  /// **'Time: {durationMinutes} min, Birds: {birds}, Points: {stand}, Secondary: {secondaryPoints}, Tomstand: {tomstandCount}, Flushes: {flushes}'**
  String session_detail_saved_session_summary(int durationMinutes, int birds, int stand, int secondaryPoints, int tomstandCount, int flushes);

  /// No description provided for @session_detail_button_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get session_detail_button_exporting;

  /// No description provided for @session_detail_button_export_gpx.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get session_detail_button_export_gpx;

  /// No description provided for @session_detail_error_gpx_too_few_points.
  ///
  /// In en, this message translates to:
  /// **'Too few GPX points in the file'**
  String get session_detail_error_gpx_too_few_points;

  /// Formatted duration when hours are present.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String session_detail_helper_duration_hours_minutes(int hours, int minutes);

  /// No description provided for @session_detail_bird_species_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Select bird species'**
  String get session_detail_bird_species_picker_title;

  /// No description provided for @session_detail_bird_section_title.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get session_detail_bird_section_title;

  /// No description provided for @session_detail_bird_species_button_label.
  ///
  /// In en, this message translates to:
  /// **'Select bird species'**
  String get session_detail_bird_species_button_label;

  /// No description provided for @session_detail_bird_species_empty_selection.
  ///
  /// In en, this message translates to:
  /// **'No species selected'**
  String get session_detail_bird_species_empty_selection;

  /// No description provided for @session_detail_bird_species_empty_saved.
  ///
  /// In en, this message translates to:
  /// **'No species saved yet'**
  String get session_detail_bird_species_empty_saved;

  /// No description provided for @session_detail_bird_species_new.
  ///
  /// In en, this message translates to:
  /// **'New bird'**
  String get session_detail_bird_species_new;

  /// No description provided for @session_notes_field_label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get session_notes_field_label;

  /// No description provided for @session_detail_action_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get session_detail_action_done;

  /// No description provided for @session_detail_bird_species_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'New bird species'**
  String get session_detail_bird_species_dialog_title;

  /// No description provided for @session_detail_bird_species_dialog_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get session_detail_bird_species_dialog_name_label;

  /// No description provided for @session_action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get session_action_save;

  /// No description provided for @session_detail_media_gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get session_detail_media_gallery_title;

  /// No description provided for @hunt_session_title_new.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get hunt_session_title_new;

  /// No description provided for @hunt_session_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get hunt_session_title_edit;

  /// No description provided for @hunt_session_field_location_label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get hunt_session_field_location_label;

  /// No description provided for @hunt_session_field_duration_minutes_label.
  ///
  /// In en, this message translates to:
  /// **'Active time (min)'**
  String get hunt_session_field_duration_minutes_label;

  /// No description provided for @hunt_session_field_birds_seen_label.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts'**
  String get hunt_session_field_birds_seen_label;

  /// No description provided for @hunt_session_field_points_label.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get hunt_session_field_points_label;

  /// No description provided for @hunt_session_field_secondary_points_label.
  ///
  /// In en, this message translates to:
  /// **'Secondary points'**
  String get hunt_session_field_secondary_points_label;

  /// No description provided for @hunt_session_field_tomstand_label.
  ///
  /// In en, this message translates to:
  /// **'Tomstand'**
  String get hunt_session_field_tomstand_label;

  /// No description provided for @hunt_session_field_flushes_label.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get hunt_session_field_flushes_label;

  /// No description provided for @hunt_session_field_notes_label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get hunt_session_field_notes_label;

  /// No description provided for @hunt_session_action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hunt_session_action_save;

  /// No description provided for @hunt_session_action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hunt_session_action_cancel;

  /// No description provided for @hunt_session_action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get hunt_session_action_delete;

  /// No description provided for @hunt_session_action_import_gpx.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get hunt_session_action_import_gpx;

  /// No description provided for @hunt_session_action_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get hunt_session_action_importing;

  /// No description provided for @hunt_session_snackbar_saved_with_gps_track.
  ///
  /// In en, this message translates to:
  /// **'Session saved with GPS track ({points} points)'**
  String hunt_session_snackbar_saved_with_gps_track(Object points);

  /// No description provided for @session_detail_filter_all_dogs.
  ///
  /// In en, this message translates to:
  /// **'All dogs'**
  String get session_detail_filter_all_dogs;

  /// No description provided for @session_detail_session_menu_export.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get session_detail_session_menu_export;

  /// No description provided for @session_detail_session_menu_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get session_detail_session_menu_exporting;

  /// No description provided for @session_detail_session_menu_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get session_detail_session_menu_edit;

  /// No description provided for @session_detail_session_menu_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get session_detail_session_menu_delete;

  /// No description provided for @session_detail_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get session_detail_detail_title;

  /// No description provided for @session_detail_detail_label_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get session_detail_detail_label_date;

  /// No description provided for @session_detail_detail_label_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get session_detail_detail_label_location;

  /// No description provided for @session_detail_detail_label_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get session_detail_detail_label_active_time;

  /// No description provided for @session_detail_detail_label_bird_contacts.
  ///
  /// In en, this message translates to:
  /// **'Bird contacts'**
  String get session_detail_detail_label_bird_contacts;

  /// No description provided for @session_detail_detail_label_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get session_detail_detail_label_points;

  /// No description provided for @session_detail_detail_label_secondary_points.
  ///
  /// In en, this message translates to:
  /// **'Secondary points'**
  String get session_detail_detail_label_secondary_points;

  /// No description provided for @session_detail_detail_label_tomstand.
  ///
  /// In en, this message translates to:
  /// **'Tomstand'**
  String get session_detail_detail_label_tomstand;

  /// No description provided for @session_detail_detail_label_flushes.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get session_detail_detail_label_flushes;

  /// No description provided for @session_detail_label_bird_species.
  ///
  /// In en, this message translates to:
  /// **'Bird species'**
  String get session_detail_label_bird_species;

  /// No description provided for @session_detail_label_gps_track.
  ///
  /// In en, this message translates to:
  /// **'GPS track'**
  String get session_detail_label_gps_track;

  /// No description provided for @session_detail_label_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get session_detail_label_yes;

  /// No description provided for @session_detail_label_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get session_detail_label_no;

  /// No description provided for @session_detail_label_dog_prefix.
  ///
  /// In en, this message translates to:
  /// **'Dog: '**
  String get session_detail_label_dog_prefix;

  /// No description provided for @session_detail_map_title.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get session_detail_map_title;

  /// No description provided for @session_detail_map_prefix.
  ///
  /// In en, this message translates to:
  /// **'Map – '**
  String get session_detail_map_prefix;

  /// No description provided for @map_title.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map_title;

  /// No description provided for @session_detail_gpx_replace_title.
  ///
  /// In en, this message translates to:
  /// **'Replace track?'**
  String get session_detail_gpx_replace_title;

  /// No description provided for @session_detail_gpx_replace_body.
  ///
  /// In en, this message translates to:
  /// **'This will replace the existing track. Continue?'**
  String get session_detail_gpx_replace_body;

  /// No description provided for @session_detail_gpx_replace_confirm.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get session_detail_gpx_replace_confirm;

  /// No description provided for @session_detail_gpx_replaced_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Track replaced: {points} points'**
  String session_detail_gpx_replaced_snackbar(int points);

  /// No description provided for @session_detail_gpx_imported_snackbar.
  ///
  /// In en, this message translates to:
  /// **'GPX imported: {points} points'**
  String session_detail_gpx_imported_snackbar(int points);

  /// No description provided for @session_detail_empty_notes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get session_detail_empty_notes;

  /// No description provided for @session_detail_empty_media.
  ///
  /// In en, this message translates to:
  /// **'No media added'**
  String get session_detail_empty_media;

  /// Formatted duration when only minutes and seconds exist.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String session_detail_helper_duration_minutes_seconds(int minutes, int seconds);

  /// Formatted duration when only seconds exist.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String session_detail_helper_duration_seconds(int seconds);

  /// Label showing total flushes in session detail.
  ///
  /// In en, this message translates to:
  /// **'Flushes total: {value}'**
  String session_detail_total_flushes(String value);

  /// No description provided for @gpx_import_label.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get gpx_import_label;

  /// No description provided for @session_menu_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get session_menu_edit;

  /// No description provided for @session_menu_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get session_menu_delete;

  /// No description provided for @stats_trend_label.
  ///
  /// In en, this message translates to:
  /// **'Trend: {symbol}'**
  String stats_trend_label(String symbol);

  /// No description provided for @stats_title_points_and_flushes.
  ///
  /// In en, this message translates to:
  /// **'Points and flushes'**
  String get stats_title_points_and_flushes;

  /// No description provided for @stats_title_sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get stats_title_sessions;

  /// No description provided for @stats_title_birds_down_per_year.
  ///
  /// In en, this message translates to:
  /// **'Birds down per year'**
  String get stats_title_birds_down_per_year;

  /// No description provided for @stats_subtitle_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get stats_subtitle_active_time;

  /// No description provided for @stats_subtitle_session_count.
  ///
  /// In en, this message translates to:
  /// **'Session count'**
  String get stats_subtitle_session_count;

  /// No description provided for @stats_legend_bars.
  ///
  /// In en, this message translates to:
  /// **'Bars:'**
  String get stats_legend_bars;

  /// No description provided for @stats_legend_line.
  ///
  /// In en, this message translates to:
  /// **'Line:'**
  String get stats_legend_line;

  /// No description provided for @stats_title_development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get stats_title_development;

  /// No description provided for @stats_period_30_days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get stats_period_30_days;

  /// No description provided for @stats_period_90_days.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get stats_period_90_days;

  /// No description provided for @stats_legend_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get stats_legend_active_time;

  /// No description provided for @stats_legend_sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get stats_legend_sessions;

  /// Tooltip text for weekly stats bars.
  ///
  /// In en, this message translates to:
  /// **'{weekLabel}: {sessions} sessions, {time}'**
  String stats_week_tooltip(String weekLabel, int sessions, String time);

  /// No description provided for @stats_info_active_time_title.
  ///
  /// In en, this message translates to:
  /// **'Active time'**
  String get stats_info_active_time_title;

  /// No description provided for @stats_info_active_time_body_1.
  ///
  /// In en, this message translates to:
  /// **'Total time the dog has been working.'**
  String get stats_info_active_time_body_1;

  /// No description provided for @stats_info_active_time_body_2.
  ///
  /// In en, this message translates to:
  /// **'Used to assess workload and consistency.'**
  String get stats_info_active_time_body_2;

  /// No description provided for @stats_info_session_count_title.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get stats_info_session_count_title;

  /// No description provided for @stats_info_session_count_body_1.
  ///
  /// In en, this message translates to:
  /// **'How often the dog has been active.'**
  String get stats_info_session_count_body_1;

  /// No description provided for @stats_info_session_count_body_2.
  ///
  /// In en, this message translates to:
  /// **'Shows training and hunting frequency.'**
  String get stats_info_session_count_body_2;

  /// No description provided for @stats_v1_overview_title.
  ///
  /// In en, this message translates to:
  /// **'V1 overview'**
  String get stats_v1_overview_title;

  /// No description provided for @stats_total_points_title.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get stats_total_points_title;

  /// No description provided for @stats_total_active_time_title.
  ///
  /// In en, this message translates to:
  /// **'Total active time'**
  String get stats_total_active_time_title;

  /// No description provided for @stats_avg_points_per_session_title.
  ///
  /// In en, this message translates to:
  /// **'Avg points per session'**
  String get stats_avg_points_per_session_title;

  /// No description provided for @stats_avg_time_per_session_title.
  ///
  /// In en, this message translates to:
  /// **'Avg time per session'**
  String get stats_avg_time_per_session_title;

  /// No description provided for @stats_last_30_days_sessions_title.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days: Sessions'**
  String get stats_last_30_days_sessions_title;

  /// No description provided for @stats_last_30_days_points_title.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days: Points'**
  String get stats_last_30_days_points_title;

  /// Total sessions value shown on the stats overview cards.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String stats_overview_sessions_value(int count);

  /// Total points value shown on the stats overview cards.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String stats_overview_points_value(int count);

  /// Session count for the last 30 days card.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String stats_last_30_days_sessions_value(int count);

  /// Point total for the last 30 days card.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String stats_last_30_days_points_value(int count);

  /// No description provided for @stats_points_label.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get stats_points_label;

  /// No description provided for @stats_flushes_label.
  ///
  /// In en, this message translates to:
  /// **'Flushes'**
  String get stats_flushes_label;

  /// Months suffix with year.
  ///
  /// In en, this message translates to:
  /// **'per month • {year}'**
  String stats_per_month_suffix(int year);

  /// Tooltip text for monthly session bars with data.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}: {count} sessions'**
  String stats_monthly_sessions_tooltip(String month, int year, int count);

  /// Tooltip for monthly session bars without data.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}: No sessions'**
  String stats_monthly_sessions_tooltip_empty(String month, int year);

  /// Summarizes monthly totals.
  ///
  /// In en, this message translates to:
  /// **'Total: {points} points, {flushes} flushes'**
  String stats_total_points_flushes_prefix(int points, int flushes);

  /// Tooltip for the stand and flush bar chart.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}: Points {stand}, Flushes {flush}'**
  String stats_stand_flush_tooltip(String month, int year, String stand, String flush);

  /// No description provided for @stats_info_points_flushes_title.
  ///
  /// In en, this message translates to:
  /// **'Points and flushes'**
  String get stats_info_points_flushes_title;

  /// No description provided for @stats_info_points_flushes_body_1.
  ///
  /// In en, this message translates to:
  /// **'Shows the number of points and flushes over time.'**
  String get stats_info_points_flushes_body_1;

  /// No description provided for @stats_info_points_flushes_body_2.
  ///
  /// In en, this message translates to:
  /// **'Gives insight into the dog’s field work and hunting pattern.'**
  String get stats_info_points_flushes_body_2;

  /// No description provided for @stats_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get stats_none;

  /// No description provided for @stats_unknown_species.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get stats_unknown_species;

  /// No description provided for @stats_info_explanation_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get stats_info_explanation_tooltip;

  /// Total sessions prefix.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} sessions'**
  String stats_total_sessions_prefix(int count);

  /// No description provided for @stats_info_sessions_title.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get stats_info_sessions_title;

  /// No description provided for @stats_info_sessions_body_1.
  ///
  /// In en, this message translates to:
  /// **'How often the dog has been active.'**
  String get stats_info_sessions_body_1;

  /// No description provided for @stats_info_sessions_body_2.
  ///
  /// In en, this message translates to:
  /// **'Shows training and hunting frequency.'**
  String get stats_info_sessions_body_2;

  /// No description provided for @stats_no_birds_down_yet.
  ///
  /// In en, this message translates to:
  /// **'No birds down registered yet'**
  String get stats_no_birds_down_yet;

  /// No description provided for @stats_birds_distribution_title.
  ///
  /// In en, this message translates to:
  /// **'Birds down distribution'**
  String get stats_birds_distribution_title;

  /// No description provided for @stats_birds_pie_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap a slice for details'**
  String get stats_birds_pie_hint;

  /// No description provided for @stats_info_birds_down_title.
  ///
  /// In en, this message translates to:
  /// **'Birds down'**
  String get stats_info_birds_down_title;

  /// No description provided for @stats_info_birds_down_body_1.
  ///
  /// In en, this message translates to:
  /// **'Number of birds down per calendar year.'**
  String get stats_info_birds_down_body_1;

  /// No description provided for @stats_info_birds_down_body_2.
  ///
  /// In en, this message translates to:
  /// **'Provides a basis for year-to-year comparison.'**
  String get stats_info_birds_down_body_2;

  /// No description provided for @stats_info_birds_distribution_title.
  ///
  /// In en, this message translates to:
  /// **'Birds down distribution'**
  String get stats_info_birds_distribution_title;

  /// No description provided for @stats_info_birds_distribution_body_1.
  ///
  /// In en, this message translates to:
  /// **'Shows which species were taken in the selected year.'**
  String get stats_info_birds_distribution_body_1;

  /// No description provided for @stats_info_birds_distribution_body_2.
  ///
  /// In en, this message translates to:
  /// **'Gives an overview of harvest and variation.'**
  String get stats_info_birds_distribution_body_2;

  /// No description provided for @stats_label_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get stats_label_year;

  /// No description provided for @stats_label_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get stats_label_total;

  /// No description provided for @stats_label_per_month.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get stats_label_per_month;

  /// No description provided for @gpx_importing_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get gpx_importing_ellipsis;

  /// No description provided for @gpx_export_label.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get gpx_export_label;

  /// No description provided for @gpx_exporting_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get gpx_exporting_ellipsis;

  /// No description provided for @home_open_settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get home_open_settings_tooltip;

  /// No description provided for @home_settings_button_label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get home_settings_button_label;

  /// No description provided for @home_sessions_empty.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get home_sessions_empty;

  /// No description provided for @home_openSession.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get home_openSession;

  /// No description provided for @home_select_dog.
  ///
  /// In en, this message translates to:
  /// **'Select dog'**
  String get home_select_dog;

  /// No description provided for @home_no_sessions_yet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get home_no_sessions_yet;

  /// No description provided for @home_no_dogs_title.
  ///
  /// In en, this message translates to:
  /// **'No dogs registered yet'**
  String get home_no_dogs_title;

  /// No description provided for @home_no_dogs_message.
  ///
  /// In en, this message translates to:
  /// **'Register your dogs to log training, hunting, and trials. You’ll get a clear history and a better view of progress over time.'**
  String get home_no_dogs_message;

  /// No description provided for @home_no_dogs_bullet_history.
  ///
  /// In en, this message translates to:
  /// **'History: keep sessions, notes, and locations in one place'**
  String get home_no_dogs_bullet_history;

  /// No description provided for @home_no_dogs_bullet_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress: track points, flushes, and active time over time'**
  String get home_no_dogs_bullet_progress;

  /// No description provided for @home_no_dogs_bullet_stats.
  ///
  /// In en, this message translates to:
  /// **'Stats: meaningful trends that support your hunting'**
  String get home_no_dogs_bullet_stats;

  /// No description provided for @home_wisdom_empty.
  ///
  /// In en, this message translates to:
  /// **'A calm beginning leads to better hunting than haste.'**
  String get home_wisdom_empty;

  /// No description provided for @wisdom_001.
  ///
  /// In en, this message translates to:
  /// **'A calm dog learns faster than a stressed one.'**
  String get wisdom_001;

  /// No description provided for @wisdom_002.
  ///
  /// In en, this message translates to:
  /// **'What you train today, you’ll get back in the autumn.'**
  String get wisdom_002;

  /// No description provided for @wisdom_003.
  ///
  /// In en, this message translates to:
  /// **'Repeat less. Wait more.'**
  String get wisdom_003;

  /// No description provided for @wisdom_004.
  ///
  /// In en, this message translates to:
  /// **'Silence is training too.'**
  String get wisdom_004;

  /// No description provided for @wisdom_005.
  ///
  /// In en, this message translates to:
  /// **'Progress often happens between sessions.'**
  String get wisdom_005;

  /// No description provided for @wisdom_006.
  ///
  /// In en, this message translates to:
  /// **'A timely break is better than one repetition too many.'**
  String get wisdom_006;

  /// No description provided for @wisdom_007.
  ///
  /// In en, this message translates to:
  /// **'Patience is the most underrated exercise.'**
  String get wisdom_007;

  /// No description provided for @wisdom_008.
  ///
  /// In en, this message translates to:
  /// **'Train what you want to see, not what you hope for.'**
  String get wisdom_008;

  /// No description provided for @wisdom_009.
  ///
  /// In en, this message translates to:
  /// **'A confident dog learns faster than an eager one.'**
  String get wisdom_009;

  /// No description provided for @wisdom_010.
  ///
  /// In en, this message translates to:
  /// **'It’s okay to end on a high note.'**
  String get wisdom_010;

  /// No description provided for @wisdom_011.
  ///
  /// In en, this message translates to:
  /// **'A point is built before the bird, not after.'**
  String get wisdom_011;

  /// No description provided for @wisdom_012.
  ///
  /// In en, this message translates to:
  /// **'Steadiness in the flush starts in the mind.'**
  String get wisdom_012;

  /// No description provided for @wisdom_013.
  ///
  /// In en, this message translates to:
  /// **'Steadiness is a choice the dog learns to make.'**
  String get wisdom_013;

  /// No description provided for @wisdom_014.
  ///
  /// In en, this message translates to:
  /// **'Pressure creates movement. Time creates steadiness.'**
  String get wisdom_014;

  /// No description provided for @wisdom_015.
  ///
  /// In en, this message translates to:
  /// **'A good point doesn’t need an audience.'**
  String get wisdom_015;

  /// No description provided for @wisdom_016.
  ///
  /// In en, this message translates to:
  /// **'When the dog points, let the world wait.'**
  String get wisdom_016;

  /// No description provided for @wisdom_017.
  ///
  /// In en, this message translates to:
  /// **'One calm point is better than three rushed ones.'**
  String get wisdom_017;

  /// No description provided for @wisdom_018.
  ///
  /// In en, this message translates to:
  /// **'The bird teaches the dog. You shape the reaction.'**
  String get wisdom_018;

  /// No description provided for @wisdom_019.
  ///
  /// In en, this message translates to:
  /// **'Pointing is a moment of balance.'**
  String get wisdom_019;

  /// No description provided for @wisdom_020.
  ///
  /// In en, this message translates to:
  /// **'Don’t rush through stillness.'**
  String get wisdom_020;

  /// No description provided for @wisdom_021.
  ///
  /// In en, this message translates to:
  /// **'Read the wind before you read the dog.'**
  String get wisdom_021;

  /// No description provided for @wisdom_022.
  ///
  /// In en, this message translates to:
  /// **'The terrain trains the dog as much as you do.'**
  String get wisdom_022;

  /// No description provided for @wisdom_023.
  ///
  /// In en, this message translates to:
  /// **'Every bird is a new lesson.'**
  String get wisdom_023;

  /// No description provided for @wisdom_024.
  ///
  /// In en, this message translates to:
  /// **'Bad conditions create good experience.'**
  String get wisdom_024;

  /// No description provided for @wisdom_025.
  ///
  /// In en, this message translates to:
  /// **'Hunting is cooperation, not competition.'**
  String get wisdom_025;

  /// No description provided for @wisdom_026.
  ///
  /// In en, this message translates to:
  /// **'Quality shows in a headwind.'**
  String get wisdom_026;

  /// No description provided for @wisdom_027.
  ///
  /// In en, this message translates to:
  /// **'An empty round can still be full of learning.'**
  String get wisdom_027;

  /// No description provided for @wisdom_028.
  ///
  /// In en, this message translates to:
  /// **'Let the dog find the solution.'**
  String get wisdom_028;

  /// No description provided for @wisdom_029.
  ///
  /// In en, this message translates to:
  /// **'A bird dog’s strength is independence with direction.'**
  String get wisdom_029;

  /// No description provided for @wisdom_030.
  ///
  /// In en, this message translates to:
  /// **'The field remembers everything.'**
  String get wisdom_030;

  /// No description provided for @wisdom_031.
  ///
  /// In en, this message translates to:
  /// **'Be consistent, not perfect.'**
  String get wisdom_031;

  /// No description provided for @wisdom_032.
  ///
  /// In en, this message translates to:
  /// **'The dog mirrors your pace.'**
  String get wisdom_032;

  /// No description provided for @wisdom_033.
  ///
  /// In en, this message translates to:
  /// **'What you don’t react to, you accept.'**
  String get wisdom_033;

  /// No description provided for @wisdom_034.
  ///
  /// In en, this message translates to:
  /// **'A clear mind makes a clear dog.'**
  String get wisdom_034;

  /// No description provided for @wisdom_035.
  ///
  /// In en, this message translates to:
  /// **'Fairness beats harshness.'**
  String get wisdom_035;

  /// No description provided for @wisdom_036.
  ///
  /// In en, this message translates to:
  /// **'Train with your head before your voice.'**
  String get wisdom_036;

  /// No description provided for @wisdom_037.
  ///
  /// In en, this message translates to:
  /// **'Don’t explain. Show.'**
  String get wisdom_037;

  /// No description provided for @wisdom_038.
  ///
  /// In en, this message translates to:
  /// **'A confident handler builds a confident dog.'**
  String get wisdom_038;

  /// No description provided for @wisdom_039.
  ///
  /// In en, this message translates to:
  /// **'Your calm is the dog’s framework.'**
  String get wisdom_039;

  /// No description provided for @wisdom_040.
  ///
  /// In en, this message translates to:
  /// **'Listen more than you correct.'**
  String get wisdom_040;

  /// No description provided for @wisdom_041.
  ///
  /// In en, this message translates to:
  /// **'The relationship is built even without birds.'**
  String get wisdom_041;

  /// No description provided for @wisdom_042.
  ///
  /// In en, this message translates to:
  /// **'A good walk is never wasted.'**
  String get wisdom_042;

  /// No description provided for @wisdom_043.
  ///
  /// In en, this message translates to:
  /// **'Trust takes time. Distrust takes seconds.'**
  String get wisdom_043;

  /// No description provided for @wisdom_044.
  ///
  /// In en, this message translates to:
  /// **'The dog works best for the one it trusts.'**
  String get wisdom_044;

  /// No description provided for @wisdom_045.
  ///
  /// In en, this message translates to:
  /// **'Small routines create big security.'**
  String get wisdom_045;

  /// No description provided for @wisdom_046.
  ///
  /// In en, this message translates to:
  /// **'It’s okay to just be a dog sometimes.'**
  String get wisdom_046;

  /// No description provided for @wisdom_047.
  ///
  /// In en, this message translates to:
  /// **'Playfulness isn’t lack of discipline.'**
  String get wisdom_047;

  /// No description provided for @wisdom_048.
  ///
  /// In en, this message translates to:
  /// **'A satisfied dog performs better.'**
  String get wisdom_048;

  /// No description provided for @wisdom_049.
  ///
  /// In en, this message translates to:
  /// **'Cooperation beats control.'**
  String get wisdom_049;

  /// No description provided for @wisdom_050.
  ///
  /// In en, this message translates to:
  /// **'Relationship before skills.'**
  String get wisdom_050;

  /// No description provided for @wisdom_051.
  ///
  /// In en, this message translates to:
  /// **'A trial is a snapshot, not a verdict.'**
  String get wisdom_051;

  /// No description provided for @wisdom_052.
  ///
  /// In en, this message translates to:
  /// **'The judge sees one day. You see the whole year.'**
  String get wisdom_052;

  /// No description provided for @wisdom_053.
  ///
  /// In en, this message translates to:
  /// **'Results are a bonus, not the goal.'**
  String get wisdom_053;

  /// No description provided for @wisdom_054.
  ///
  /// In en, this message translates to:
  /// **'A good experience beats a good placement.'**
  String get wisdom_054;

  /// No description provided for @wisdom_055.
  ///
  /// In en, this message translates to:
  /// **'Pressure at home creates calm at the trial.'**
  String get wisdom_055;

  /// No description provided for @wisdom_056.
  ///
  /// In en, this message translates to:
  /// **'Train situations, not points.'**
  String get wisdom_056;

  /// No description provided for @wisdom_057.
  ///
  /// In en, this message translates to:
  /// **'A steady dog is always competitive.'**
  String get wisdom_057;

  /// No description provided for @wisdom_058.
  ///
  /// In en, this message translates to:
  /// **'Learn from what didn’t work.'**
  String get wisdom_058;

  /// No description provided for @wisdom_059.
  ///
  /// In en, this message translates to:
  /// **'Trials are training with an audience.'**
  String get wisdom_059;

  /// No description provided for @wisdom_060.
  ///
  /// In en, this message translates to:
  /// **'Don’t chase prizes, build the dog.'**
  String get wisdom_060;

  /// No description provided for @wisdom_061.
  ///
  /// In en, this message translates to:
  /// **'A bird dog is never fully finished learning.'**
  String get wisdom_061;

  /// No description provided for @wisdom_062.
  ///
  /// In en, this message translates to:
  /// **'It’s the road to the point that matters.'**
  String get wisdom_062;

  /// No description provided for @wisdom_063.
  ///
  /// In en, this message translates to:
  /// **'Patience doesn’t smell like stress.'**
  String get wisdom_063;

  /// No description provided for @wisdom_064.
  ///
  /// In en, this message translates to:
  /// **'The best moments can’t be logged.'**
  String get wisdom_064;

  /// No description provided for @wisdom_065.
  ///
  /// In en, this message translates to:
  /// **'A bird dog is trust at speed.'**
  String get wisdom_065;

  /// No description provided for @wisdom_066.
  ///
  /// In en, this message translates to:
  /// **'Silence is often the answer.'**
  String get wisdom_066;

  /// No description provided for @wisdom_067.
  ///
  /// In en, this message translates to:
  /// **'Nature always sets the limits.'**
  String get wisdom_067;

  /// No description provided for @wisdom_068.
  ///
  /// In en, this message translates to:
  /// **'A good day in the field lasts a long time.'**
  String get wisdom_068;

  /// No description provided for @wisdom_069.
  ///
  /// In en, this message translates to:
  /// **'The dog remembers the mood.'**
  String get wisdom_069;

  /// No description provided for @wisdom_070.
  ///
  /// In en, this message translates to:
  /// **'Hunting is teamwork with the landscape.'**
  String get wisdom_070;

  /// No description provided for @wisdom_071.
  ///
  /// In en, this message translates to:
  /// **'A short lead today can create long calm tomorrow.'**
  String get wisdom_071;

  /// No description provided for @wisdom_072.
  ///
  /// In en, this message translates to:
  /// **'What gets rewarded, gets repeated.'**
  String get wisdom_072;

  /// No description provided for @wisdom_073.
  ///
  /// In en, this message translates to:
  /// **'Keep demands small, and build them big over time.'**
  String get wisdom_073;

  /// No description provided for @wisdom_074.
  ///
  /// In en, this message translates to:
  /// **'When you lose calm, you lose learning.'**
  String get wisdom_074;

  /// No description provided for @wisdom_075.
  ///
  /// In en, this message translates to:
  /// **'A clear start makes the finish easy.'**
  String get wisdom_075;

  /// No description provided for @wisdom_076.
  ///
  /// In en, this message translates to:
  /// **'Calm isn’t passive. Calm is control.'**
  String get wisdom_076;

  /// No description provided for @wisdom_077.
  ///
  /// In en, this message translates to:
  /// **'Train the boring stuff. It saves the day.'**
  String get wisdom_077;

  /// No description provided for @wisdom_078.
  ///
  /// In en, this message translates to:
  /// **'Good handling is often invisible.'**
  String get wisdom_078;

  /// No description provided for @wisdom_079.
  ///
  /// In en, this message translates to:
  /// **'When the dog succeeds, it’s because you were predictable.'**
  String get wisdom_079;

  /// No description provided for @wisdom_080.
  ///
  /// In en, this message translates to:
  /// **'Don’t chase speed. Chase quality.'**
  String get wisdom_080;

  /// No description provided for @wisdom_081.
  ///
  /// In en, this message translates to:
  /// **'Give the dog time to finish thinking.'**
  String get wisdom_081;

  /// No description provided for @wisdom_082.
  ///
  /// In en, this message translates to:
  /// **'A ‘no’ without anger is worth more than ten ‘yes’ with stress.'**
  String get wisdom_082;

  /// No description provided for @wisdom_083.
  ///
  /// In en, this message translates to:
  /// **'Stop before you have to stop.'**
  String get wisdom_083;

  /// No description provided for @wisdom_084.
  ///
  /// In en, this message translates to:
  /// **'You’re always training, even when you think you’re just walking.'**
  String get wisdom_084;

  /// No description provided for @wisdom_085.
  ///
  /// In en, this message translates to:
  /// **'The bird reveals the gaps. Train the gaps.'**
  String get wisdom_085;

  /// No description provided for @wisdom_086.
  ///
  /// In en, this message translates to:
  /// **'A good stop is the start of a good point.'**
  String get wisdom_086;

  /// No description provided for @wisdom_087.
  ///
  /// In en, this message translates to:
  /// **'A light hand builds heavy cooperation.'**
  String get wisdom_087;

  /// No description provided for @wisdom_088.
  ///
  /// In en, this message translates to:
  /// **'When things go sideways: slow down, increase clarity.'**
  String get wisdom_088;

  /// No description provided for @wisdom_089.
  ///
  /// In en, this message translates to:
  /// **'A reliable routine beats a perfect plan.'**
  String get wisdom_089;

  /// No description provided for @wisdom_090.
  ///
  /// In en, this message translates to:
  /// **'Your most important signal is your body language.'**
  String get wisdom_090;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_section_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settings_section_profile;

  /// No description provided for @settings_profile_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settings_profile_name_label;

  /// No description provided for @settings_profile_phone_label.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get settings_profile_phone_label;

  /// No description provided for @settings_profile_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get settings_profile_email_label;

  /// No description provided for @settings_profile_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get settings_profile_email_invalid;

  /// No description provided for @settings_profile_personal_goal_stands_label.
  ///
  /// In en, this message translates to:
  /// **'Personal stands goal'**
  String get settings_profile_personal_goal_stands_label;

  /// No description provided for @settings_profile_personal_goal_section_title.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get settings_profile_personal_goal_section_title;

  /// No description provided for @settings_profile_personal_goal_prompt.
  ///
  /// In en, this message translates to:
  /// **'{count} stands registered in total. Set a personal goal to track your progress.'**
  String settings_profile_personal_goal_prompt(Object count);

  /// No description provided for @settings_profile_personal_goal_progress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {goal} stands'**
  String settings_profile_personal_goal_progress(Object current, Object goal);

  /// No description provided for @settings_profile_personal_goal_percent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String settings_profile_personal_goal_percent(Object percent);

  /// No description provided for @settings_profile_personal_goal_celebration_generic.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached your goal 🎉'**
  String get settings_profile_personal_goal_celebration_generic;

  /// No description provided for @settings_profile_personal_goal_celebration_named.
  ///
  /// In en, this message translates to:
  /// **'Congratulations {name}! You reached your goal 🎉'**
  String settings_profile_personal_goal_celebration_named(Object name);

  /// No description provided for @settings_profile_birthday_greeting_and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get settings_profile_birthday_greeting_and;

  /// No description provided for @settings_profile_birthday_greeting_generic.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday 🎉'**
  String get settings_profile_birthday_greeting_generic;

  /// No description provided for @settings_profile_birthday_greeting_named.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {name}! 🎉'**
  String settings_profile_birthday_greeting_named(Object name);

  /// No description provided for @settings_profile_birthday_greeting_dogs_generic.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday! Greetings from {dogs} 🎉'**
  String settings_profile_birthday_greeting_dogs_generic(Object dogs);

  /// No description provided for @settings_profile_birthday_greeting_dogs_named.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, {name}! Greetings from {dogs} 🎉'**
  String settings_profile_birthday_greeting_dogs_named(Object name, Object dogs);

  /// No description provided for @settings_notification_birthday_title.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday!'**
  String get settings_notification_birthday_title;

  /// No description provided for @settings_notification_birthday_body.
  ///
  /// In en, this message translates to:
  /// **'Wishing you a wonderful day 🎉'**
  String get settings_notification_birthday_body;

  /// No description provided for @settings_notification_goal_title.
  ///
  /// In en, this message translates to:
  /// **'You reached your goal!'**
  String get settings_notification_goal_title;

  /// No description provided for @settings_notification_goal_body.
  ///
  /// In en, this message translates to:
  /// **'Great work - keep it up 🎯'**
  String get settings_notification_goal_body;

  /// No description provided for @settings_profile_birth_date_label.
  ///
  /// In en, this message translates to:
  /// **'Birth date / birthday'**
  String get settings_profile_birth_date_label;

  /// No description provided for @settings_profile_birth_date_empty.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settings_profile_birth_date_empty;

  /// No description provided for @settings_profile_birth_date_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get settings_profile_birth_date_clear;

  /// No description provided for @settings_profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get settings_profile_saved;

  /// No description provided for @settings_profile_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving profile…'**
  String get settings_profile_saving;

  /// No description provided for @settings_section_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_section_general;

  /// No description provided for @settings_section_milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get settings_section_milestones;

  /// No description provided for @invitations_title.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations_title;

  /// No description provided for @invitations_empty.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get invitations_empty;

  /// No description provided for @settings_section_feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settings_section_feedback;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'support@gundogtracker.app'**
  String get supportEmail;

  /// No description provided for @support_email.
  ///
  /// In en, this message translates to:
  /// **'support@gundogtracker.app'**
  String get support_email;

  /// No description provided for @settings_section_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settings_section_subscription;

  /// No description provided for @settings_section_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_section_language;

  /// No description provided for @settings_section_community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get settings_section_community;

  /// No description provided for @settings_section_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_section_security;

  /// No description provided for @settings_change_password_title.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settings_change_password_title;

  /// No description provided for @settings_change_password_current_password.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get settings_change_password_current_password;

  /// No description provided for @settings_change_password_new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get settings_change_password_new_password;

  /// No description provided for @settings_change_password_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get settings_change_password_confirm_password;

  /// No description provided for @settings_change_password_submit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get settings_change_password_submit;

  /// No description provided for @settings_change_password_success.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get settings_change_password_success;

  /// No description provided for @settings_reset_password_button.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get settings_reset_password_button;

  /// No description provided for @settings_reset_password_sent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a reset link'**
  String get settings_reset_password_sent;

  /// No description provided for @settings_reset_password_no_email.
  ///
  /// In en, this message translates to:
  /// **'No email on record to reset password'**
  String get settings_reset_password_no_email;

  /// No description provided for @settings_change_password_error_fields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get settings_change_password_error_fields;

  /// No description provided for @settings_change_password_error_mismatch.
  ///
  /// In en, this message translates to:
  /// **'New password and confirmation must match'**
  String get settings_change_password_error_mismatch;

  /// No description provided for @forgot_password_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgot_password_title;

  /// No description provided for @forgot_password_description.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get forgot_password_description;

  /// No description provided for @forgot_password_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgot_password_email_label;

  /// No description provided for @forgot_password_button.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgot_password_button;

  /// No description provided for @forgot_password_error_missing.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get forgot_password_error_missing;

  /// No description provided for @forgot_password_error_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get forgot_password_error_invalid;

  /// No description provided for @forgot_password_check_spam_hint.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox. If the email doesn\'t show up, check Spam/Junk.'**
  String get forgot_password_check_spam_hint;

  /// No description provided for @signup_title.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signup_title;

  /// No description provided for @signup_intro.
  ///
  /// In en, this message translates to:
  /// **'Create an account with email and password to get started.'**
  String get signup_intro;

  /// No description provided for @signup_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signup_email_label;

  /// No description provided for @signup_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signup_password_label;

  /// No description provided for @signup_password_repeat_label.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get signup_password_repeat_label;

  /// No description provided for @signup_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signup_create_button;

  /// No description provided for @signup_success.
  ///
  /// In en, this message translates to:
  /// **'Account created.'**
  String get signup_success;

  /// No description provided for @signup_error_email_in_use.
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use.'**
  String get signup_error_email_in_use;

  /// No description provided for @signup_error_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get signup_error_invalid_email;

  /// No description provided for @signup_error_weak_password.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get signup_error_weak_password;

  /// No description provided for @signup_error_operation_not_allowed.
  ///
  /// In en, this message translates to:
  /// **'Account creation is not available right now.'**
  String get signup_error_operation_not_allowed;

  /// No description provided for @signup_error_network.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get signup_error_network;

  /// No description provided for @signup_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Could not create account right now.'**
  String get signup_error_generic;

  /// No description provided for @signup_validation_email_missing.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get signup_validation_email_missing;

  /// No description provided for @signup_validation_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get signup_validation_email_invalid;

  /// No description provided for @signup_validation_password_missing.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get signup_validation_password_missing;

  /// No description provided for @signup_validation_password_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get signup_validation_password_short;

  /// No description provided for @signup_validation_password_repeat_missing.
  ///
  /// In en, this message translates to:
  /// **'Repeat the password.'**
  String get signup_validation_password_repeat_missing;

  /// No description provided for @signup_validation_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get signup_validation_password_mismatch;

  /// No description provided for @settings_backup_import_success.
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get settings_backup_import_success;

  /// No description provided for @settings_theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_theme_system;

  /// No description provided for @settings_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// No description provided for @settings_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// No description provided for @settings_language_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language_title;

  /// No description provided for @settings_language_followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settings_language_followSystem;

  /// No description provided for @settings_language_nb.
  ///
  /// In en, this message translates to:
  /// **'Norwegian (Bokmål)'**
  String get settings_language_nb;

  /// No description provided for @settings_language_sv.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get settings_language_sv;

  /// No description provided for @settings_language_da.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get settings_language_da;

  /// No description provided for @settings_language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_language_en;

  /// No description provided for @settings_milestones_enabled_title.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get settings_milestones_enabled_title;

  /// No description provided for @settings_milestones_enabled_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show small moments when your dog reaches important steps.'**
  String get settings_milestones_enabled_subtitle;

  /// No description provided for @settings_milestones_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Milestone goals'**
  String get settings_milestones_goal_title;

  /// No description provided for @settings_milestones_goal_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set seasonal and personal target stand points.'**
  String get settings_milestones_goal_subtitle;

  /// No description provided for @settings_milestones_season_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Season target (stand points)'**
  String get settings_milestones_season_goal_title;

  /// No description provided for @settings_milestones_personal_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Personal target (stand points)'**
  String get settings_milestones_personal_goal_title;

  /// No description provided for @milestone_goal_achieved.
  ///
  /// In en, this message translates to:
  /// **'{dogName} reached the {goalTitle}!'**
  String milestone_goal_achieved(String dogName, String goalTitle);

  /// No description provided for @settings_haptics_enabled_title.
  ///
  /// In en, this message translates to:
  /// **'Haptics for milestones'**
  String get settings_haptics_enabled_title;

  /// No description provided for @settings_haptics_enabled_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtle vibration when milestones are achieved.'**
  String get settings_haptics_enabled_subtitle;

  /// No description provided for @settings_restore_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Restore in progress… Please wait.'**
  String get settings_restore_in_progress;

  /// No description provided for @settings_section_backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settings_section_backup;

  /// No description provided for @settings_backup_export_action.
  ///
  /// In en, this message translates to:
  /// **'Export backup (ZIP)'**
  String get settings_backup_export_action;

  /// No description provided for @settings_backup_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get settings_backup_exporting;

  /// No description provided for @settings_backup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Export/import dogs, sessions, tracks, milestones, and media.'**
  String get settings_backup_subtitle;

  /// No description provided for @settings_backup_import_action.
  ///
  /// In en, this message translates to:
  /// **'Import backup (ZIP)'**
  String get settings_backup_import_action;

  /// No description provided for @settings_backup_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get settings_backup_importing;

  /// No description provided for @settings_backup_import_description.
  ///
  /// In en, this message translates to:
  /// **'Select a backup zip to restore data.'**
  String get settings_backup_import_description;

  /// No description provided for @settings_backup_where_title.
  ///
  /// In en, this message translates to:
  /// **'Where is backup stored?'**
  String get settings_backup_where_title;

  /// No description provided for @settings_backup_where_action.
  ///
  /// In en, this message translates to:
  /// **'Show storage folder'**
  String get settings_backup_where_action;

  /// No description provided for @settings_backup_status_collectingData.
  ///
  /// In en, this message translates to:
  /// **'Collecting data…'**
  String get settings_backup_status_collectingData;

  /// No description provided for @settings_backup_status_collectingMedia.
  ///
  /// In en, this message translates to:
  /// **'Collecting media…'**
  String get settings_backup_status_collectingMedia;

  /// No description provided for @settings_backup_status_creatingZip.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP…'**
  String get settings_backup_status_creatingZip;

  /// No description provided for @settings_backup_status_sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing…'**
  String get settings_backup_status_sharing;

  /// No description provided for @settings_backup_status_selectZip.
  ///
  /// In en, this message translates to:
  /// **'Select ZIP…'**
  String get settings_backup_status_selectZip;

  /// No description provided for @settings_backup_status_restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring data…'**
  String get settings_backup_status_restoring;

  /// No description provided for @settings_backup_share_subject.
  ///
  /// In en, this message translates to:
  /// **'Fuglehund backup'**
  String get settings_backup_share_subject;

  /// Shows the file name of the exported backup.
  ///
  /// In en, this message translates to:
  /// **'Backup ready: {fileName} ✅'**
  String settings_backup_ready(Object fileName);

  /// Displays the error message when a backup fails.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {message}'**
  String settings_backup_failed(Object message);

  /// No description provided for @auth_profile_pending_title.
  ///
  /// In en, this message translates to:
  /// **'Creating profile…'**
  String get auth_profile_pending_title;

  /// No description provided for @auth_profile_pending_body.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the backend document to exist. Tap \"Try again\" to re-check.'**
  String get auth_profile_pending_body;

  /// No description provided for @auth_loading_waiting.
  ///
  /// In en, this message translates to:
  /// **'Preparing sign-in…'**
  String get auth_loading_waiting;

  /// No description provided for @auth_profile_load_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile'**
  String get auth_profile_load_failed_title;

  /// No description provided for @auth_profile_load_failed_body.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment. If the problem continues, close and reopen the app.'**
  String get auth_profile_load_failed_body;

  /// No description provided for @auth_profile_timeout_error.
  ///
  /// In en, this message translates to:
  /// **'Could not find the user profile within a few seconds. Check your network or try again.'**
  String get auth_profile_timeout_error;

  /// No description provided for @settings_backup_failed_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error.'**
  String get settings_backup_failed_unknown;

  /// Displays the error message when an import fails.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {message}'**
  String settings_backup_import_failed(Object message);

  /// No description provided for @settings_backup_restore_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get settings_backup_restore_dialog_title;

  /// No description provided for @settings_backup_restore_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'This will restore data from a ZIP backup.\n\nTip: Restart the app once the import finishes.'**
  String get settings_backup_restore_dialog_content;

  /// No description provided for @settings_backup_restore_dialog_confirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settings_backup_restore_dialog_confirm;

  /// No description provided for @settings_backup_restore_prompt_title.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get settings_backup_restore_prompt_title;

  /// No description provided for @settings_backup_restore_prompt_message.
  ///
  /// In en, this message translates to:
  /// **'Restore finished. Restart the app now?'**
  String get settings_backup_restore_prompt_message;

  /// No description provided for @settings_backup_restore_saved.
  ///
  /// In en, this message translates to:
  /// **'Restore saved. Restart the app when convenient.'**
  String get settings_backup_restore_saved;

  /// No description provided for @settings_backup_restore_complete.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get settings_backup_restore_complete;

  /// No description provided for @settings_backup_storage_title.
  ///
  /// In en, this message translates to:
  /// **'Backup storage'**
  String get settings_backup_storage_title;

  /// Shows the folder where backups are stored.
  ///
  /// In en, this message translates to:
  /// **'Backup files are saved here:\n\n{path}'**
  String settings_backup_storage_description(String path);

  /// No description provided for @settings_backup_restore_pending.
  ///
  /// In en, this message translates to:
  /// **'Importing backup…'**
  String get settings_backup_restore_pending;

  /// No description provided for @settings_backup_restore_pending_message.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup… please wait.'**
  String get settings_backup_restore_pending_message;

  /// No description provided for @settings_section_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_section_appearance;

  /// No description provided for @settings_season_title.
  ///
  /// In en, this message translates to:
  /// **'Season theme'**
  String get settings_season_title;

  /// No description provided for @settings_season_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Colors for the top and bottom of the screen.'**
  String get settings_season_subtitle;

  /// No description provided for @settings_season_auto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settings_season_auto;

  /// No description provided for @settings_season_spring.
  ///
  /// In en, this message translates to:
  /// **'🌱 Spring'**
  String get settings_season_spring;

  /// No description provided for @settings_season_summer.
  ///
  /// In en, this message translates to:
  /// **'☀️ Summer'**
  String get settings_season_summer;

  /// No description provided for @settings_season_autumn.
  ///
  /// In en, this message translates to:
  /// **'🍁 Autumn'**
  String get settings_season_autumn;

  /// No description provided for @settings_season_winter.
  ///
  /// In en, this message translates to:
  /// **'❄️ Winter'**
  String get settings_season_winter;

  /// No description provided for @settings_feedback_send_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens email with app info.'**
  String get settings_feedback_send_subtitle;

  /// No description provided for @settings_feedback_bug_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens email with a bug report template.'**
  String get settings_feedback_bug_subtitle;

  /// No description provided for @settings_feedback_copy_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Copies app and device info.'**
  String get settings_feedback_copy_subtitle;

  /// No description provided for @settings_feedback_suggest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Send suggestions via email.'**
  String get settings_feedback_suggest_subtitle;

  /// No description provided for @settings_feedback_error_open_email.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open email.'**
  String get settings_feedback_error_open_email;

  /// No description provided for @settings_feedback_error_copy.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy.'**
  String get settings_feedback_error_copy;

  /// No description provided for @settings_diagnostics_section_title.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settings_diagnostics_section_title;

  /// No description provided for @settings_diagnostics_title.
  ///
  /// In en, this message translates to:
  /// **'Advanced diagnostics'**
  String get settings_diagnostics_title;

  /// No description provided for @settings_diagnostics_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tools for troubleshooting and support.'**
  String get settings_diagnostics_subtitle;

  /// No description provided for @settings_diagnostics_outbox_label.
  ///
  /// In en, this message translates to:
  /// **'Outbox'**
  String get settings_diagnostics_outbox_label;

  /// No description provided for @settings_diagnostics_count_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get settings_diagnostics_count_pending;

  /// No description provided for @settings_diagnostics_count_inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get settings_diagnostics_count_inProgress;

  /// No description provided for @settings_diagnostics_count_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get settings_diagnostics_count_failed;

  /// No description provided for @settings_diagnostics_count_sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get settings_diagnostics_count_sent;

  /// No description provided for @settings_diagnostics_action_dog_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Refresh dogs'**
  String get settings_diagnostics_action_dog_restore_title;

  /// No description provided for @settings_diagnostics_action_dog_restore_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetches available dogs from the cloud into local storage.'**
  String get settings_diagnostics_action_dog_restore_subtitle;

  /// No description provided for @settings_diagnostics_action_session_fetch_title.
  ///
  /// In en, this message translates to:
  /// **'Check cloud sessions'**
  String get settings_diagnostics_action_session_fetch_title;

  /// No description provided for @settings_diagnostics_action_session_fetch_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetches sessions for the first dog linked to the cloud.'**
  String get settings_diagnostics_action_session_fetch_subtitle;

  /// No description provided for @settings_diagnostics_action_session_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Restore sessions locally'**
  String get settings_diagnostics_action_session_restore_title;

  /// No description provided for @settings_diagnostics_action_session_restore_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores cloud sessions locally for the first linked dog.'**
  String get settings_diagnostics_action_session_restore_subtitle;

  /// No description provided for @settings_diagnostics_action_process_outbox_title.
  ///
  /// In en, this message translates to:
  /// **'Run sync queue now'**
  String get settings_diagnostics_action_process_outbox_title;

  /// No description provided for @settings_diagnostics_action_process_outbox_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Processes pending sync tasks once.'**
  String get settings_diagnostics_action_process_outbox_subtitle;

  /// No description provided for @settings_diagnostics_action_retry_outbox_title.
  ///
  /// In en, this message translates to:
  /// **'Reset failed sync tasks'**
  String get settings_diagnostics_action_retry_outbox_title;

  /// No description provided for @settings_diagnostics_action_retry_outbox_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Moves failed sync tasks back to the queue for another attempt.'**
  String get settings_diagnostics_action_retry_outbox_subtitle;

  /// No description provided for @settings_diagnostics_missing_cloud_dog.
  ///
  /// In en, this message translates to:
  /// **'No local dog linked to the cloud was found.'**
  String get settings_diagnostics_missing_cloud_dog;

  /// No description provided for @settings_diagnostics_dog_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Refreshed dog data: {count}'**
  String settings_diagnostics_dog_restore_success(Object count);

  /// No description provided for @settings_diagnostics_dog_restore_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh dog data: {error}'**
  String settings_diagnostics_dog_restore_failed(Object error);

  /// No description provided for @settings_diagnostics_session_fetch_success.
  ///
  /// In en, this message translates to:
  /// **'Found {count} sessions in the cloud.'**
  String settings_diagnostics_session_fetch_success(Object count);

  /// No description provided for @settings_diagnostics_session_fetch_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch sessions from the cloud: {error}'**
  String settings_diagnostics_session_fetch_failed(Object error);

  /// No description provided for @settings_diagnostics_session_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} sessions locally.'**
  String settings_diagnostics_session_restore_success(Object count);

  /// No description provided for @settings_diagnostics_session_restore_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore sessions locally: {error}'**
  String settings_diagnostics_session_restore_failed(Object error);

  /// No description provided for @settings_diagnostics_outbox_process_success.
  ///
  /// In en, this message translates to:
  /// **'The sync queue was processed.'**
  String get settings_diagnostics_outbox_process_success;

  /// No description provided for @settings_diagnostics_outbox_process_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not process the sync queue: {error}'**
  String settings_diagnostics_outbox_process_failed(Object error);

  /// No description provided for @settings_diagnostics_retry_success.
  ///
  /// In en, this message translates to:
  /// **'Reset {count} sync tasks.'**
  String settings_diagnostics_retry_success(Object count);

  /// No description provided for @settings_diagnostics_retry_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset sync tasks: {error}'**
  String settings_diagnostics_retry_failed(Object error);

  /// No description provided for @settings_sign_out_button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settings_sign_out_button;

  /// No description provided for @settings_sign_out_success.
  ///
  /// In en, this message translates to:
  /// **'You have signed out.'**
  String get settings_sign_out_success;

  /// No description provided for @settings_sign_out_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out right now.'**
  String get settings_sign_out_failed;

  /// No description provided for @settings_sound_on_app_start_title.
  ///
  /// In en, this message translates to:
  /// **'Sound on app start'**
  String get settings_sound_on_app_start_title;

  /// No description provided for @settings_sound_on_app_start_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Play grouse sound when the app starts'**
  String get settings_sound_on_app_start_subtitle;

  /// No description provided for @settings_sound_on_milestone_title.
  ///
  /// In en, this message translates to:
  /// **'Sound on milestones'**
  String get settings_sound_on_milestone_title;

  /// No description provided for @settings_sound_on_milestone_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound when you achieve a milestone'**
  String get settings_sound_on_milestone_subtitle;

  /// No description provided for @milestones_achieved_title.
  ///
  /// In en, this message translates to:
  /// **'Achieved milestones'**
  String get milestones_achieved_title;

  /// No description provided for @milestones_achieved_empty.
  ///
  /// In en, this message translates to:
  /// **'No milestones yet.'**
  String get milestones_achieved_empty;

  /// Label describing how long ago the milestone was achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved {duration}'**
  String milestones_achieved_duration(String duration);

  /// No description provided for @milestone_sheet_button_ok.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get milestone_sheet_button_ok;

  /// No description provided for @milestone_sheet_button_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View milestones'**
  String get milestone_sheet_button_viewAll;

  /// No description provided for @milestone_snackbar_new_title.
  ///
  /// In en, this message translates to:
  /// **'New milestone!'**
  String get milestone_snackbar_new_title;

  /// No description provided for @milestone_snackbar_open_error.
  ///
  /// In en, this message translates to:
  /// **'Could not open milestone'**
  String get milestone_snackbar_open_error;

  /// No description provided for @milestone_stands_count_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has recorded {countText}.'**
  String milestone_stands_count_subtitle(Object dogName, Object countText);

  /// No description provided for @milestone_sessions_count_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has logged {countText}.'**
  String milestone_sessions_count_subtitle(Object dogName, Object countText);

  /// No description provided for @milestone_birds_count_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has felled {countText}.'**
  String milestone_birds_count_subtitle(Object dogName, Object countText);

  /// No description provided for @milestone_first_point_title.
  ///
  /// In en, this message translates to:
  /// **'First point'**
  String get milestone_first_point_title;

  /// No description provided for @milestone_first_point_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} recorded its first point.'**
  String milestone_first_point_subtitle(String dogName);

  /// No description provided for @milestone_first_flush_title.
  ///
  /// In en, this message translates to:
  /// **'First flush'**
  String get milestone_first_flush_title;

  /// No description provided for @milestone_first_flush_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} recorded its first flush.'**
  String milestone_first_flush_subtitle(String dogName);

  /// No description provided for @milestone_sessions_10_title.
  ///
  /// In en, this message translates to:
  /// **'10 sessions'**
  String get milestone_sessions_10_title;

  /// No description provided for @milestone_sessions_10_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has logged 10 sessions.'**
  String milestone_sessions_10_subtitle(String dogName);

  /// No description provided for @milestone_active_hours_10_title.
  ///
  /// In en, this message translates to:
  /// **'10 active hours'**
  String get milestone_active_hours_10_title;

  /// No description provided for @milestone_active_hours_10_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has passed 10 hours of active time.'**
  String milestone_active_hours_10_subtitle(String dogName);

  /// No description provided for @milestone_section_birds_down_title.
  ///
  /// In en, this message translates to:
  /// **'Birds down'**
  String get milestone_section_birds_down_title;

  /// No description provided for @milestone_dog_fallback_name.
  ///
  /// In en, this message translates to:
  /// **'The dog'**
  String get milestone_dog_fallback_name;

  /// Sentence describing the milestone achievement for the dog with date and age.
  ///
  /// In en, this message translates to:
  /// **'{dog} achieved “{milestone}” on {date}{age}'**
  String milestone_achieved_sentence(Object dog, Object milestone, Object date, Object age);

  /// No description provided for @milestone_bird_threshold_label.
  ///
  /// In en, this message translates to:
  /// **'{threshold}th bird'**
  String milestone_bird_threshold_label(Object threshold);

  /// No description provided for @milestone_bird_label.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get milestone_bird_label;

  /// No description provided for @milestone_century_points_title.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String milestone_century_points_title(int count);

  /// No description provided for @milestone_century_points_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dogName} has passed {count} points.'**
  String milestone_century_points_subtitle(String dogName, int count);

  /// No description provided for @subscription_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription_title;

  /// No description provided for @subscription_status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subscription_status_label;

  /// No description provided for @subscription_status_active.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get subscription_status_active;

  /// No description provided for @subscription_active_compact_title.
  ///
  /// In en, this message translates to:
  /// **'GundogTracker Pro active'**
  String get subscription_active_compact_title;

  /// No description provided for @subscription_status_inactive.
  ///
  /// In en, this message translates to:
  /// **'Not active'**
  String get subscription_status_inactive;

  /// No description provided for @subscription_status_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get subscription_status_unknown;

  /// No description provided for @subscription_product_title.
  ///
  /// In en, this message translates to:
  /// **'Fuglehund Pro'**
  String get subscription_product_title;

  /// No description provided for @subscription_description.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited dogs and unlimited sessions.'**
  String get subscription_description;

  /// No description provided for @subscription_benefit_unlimited_dogs.
  ///
  /// In en, this message translates to:
  /// **'Unlimited dogs'**
  String get subscription_benefit_unlimited_dogs;

  /// No description provided for @subscription_benefit_unlimited_sessions.
  ///
  /// In en, this message translates to:
  /// **'Unlimited sessions'**
  String get subscription_benefit_unlimited_sessions;

  /// No description provided for @subscription_price_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Price unavailable'**
  String get subscription_price_unavailable;

  /// No description provided for @subscription_subscribe_button.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get subscription_subscribe_button;

  /// No description provided for @subscription_restore_button.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscription_restore_button;

  /// No description provided for @subscription_manage_button.
  ///
  /// In en, this message translates to:
  /// **'Manage / Cancel'**
  String get subscription_manage_button;

  /// No description provided for @subscription_purchase_success.
  ///
  /// In en, this message translates to:
  /// **'Pro is now active.'**
  String get subscription_purchase_success;

  /// No description provided for @subscription_purchase_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase was cancelled.'**
  String get subscription_purchase_cancelled;

  /// No description provided for @subscription_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Restore has started.'**
  String get subscription_restore_success;

  /// No description provided for @subscription_limit_dogs_reached.
  ///
  /// In en, this message translates to:
  /// **'The free plan is full for dogs. Upgrade to Pro to add more.'**
  String get subscription_limit_dogs_reached;

  /// No description provided for @subscription_limit_sessions_reached.
  ///
  /// In en, this message translates to:
  /// **'The free plan is full for sessions. Upgrade to Pro to save more.'**
  String get subscription_limit_sessions_reached;

  /// No description provided for @subscription_error_load_status.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription status right now.'**
  String get subscription_error_load_status;

  /// No description provided for @subscription_error_purchase_start.
  ///
  /// In en, this message translates to:
  /// **'Could not start the purchase right now.'**
  String get subscription_error_purchase_start;

  /// No description provided for @subscription_error_product_unavailable.
  ///
  /// In en, this message translates to:
  /// **'The product is not available in the store right now.'**
  String get subscription_error_product_unavailable;

  /// No description provided for @subscription_error_restore_purchase.
  ///
  /// In en, this message translates to:
  /// **'Could not restore purchases right now.'**
  String get subscription_error_restore_purchase;

  /// No description provided for @subscription_error_manage_open.
  ///
  /// In en, this message translates to:
  /// **'Could not open the subscription page.'**
  String get subscription_error_manage_open;

  /// No description provided for @feedback_send_title.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedback_send_title;

  /// No description provided for @feedback_bug_title.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get feedback_bug_title;

  /// No description provided for @feedback_copy_diagnostics_title.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get feedback_copy_diagnostics_title;

  /// No description provided for @feedback_suggest_milestone_title.
  ///
  /// In en, this message translates to:
  /// **'Suggest a milestone'**
  String get feedback_suggest_milestone_title;

  /// No description provided for @feedback_email_body_intro.
  ///
  /// In en, this message translates to:
  /// **'Describe your feedback here.'**
  String get feedback_email_body_intro;

  /// No description provided for @feedback_bug_prompt.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get feedback_bug_prompt;

  /// No description provided for @feedback_bug_reproduce.
  ///
  /// In en, this message translates to:
  /// **'How can we reproduce the issue?'**
  String get feedback_bug_reproduce;

  /// No description provided for @feedback_suggest_title.
  ///
  /// In en, this message translates to:
  /// **'Idea for a new milestone:'**
  String get feedback_suggest_title;

  /// No description provided for @feedback_suggest_question_what_to_celebrate.
  ///
  /// In en, this message translates to:
  /// **'What should be celebrated?'**
  String get feedback_suggest_question_what_to_celebrate;

  /// No description provided for @feedback_suggest_question_why_important.
  ///
  /// In en, this message translates to:
  /// **'Why is this important in practice?'**
  String get feedback_suggest_question_why_important;

  /// No description provided for @feedback_suggest_question_when_should_trigger.
  ///
  /// In en, this message translates to:
  /// **'When should it trigger?'**
  String get feedback_suggest_question_when_should_trigger;

  /// No description provided for @feedback_suggest_trigger_hint.
  ///
  /// In en, this message translates to:
  /// **'(first time, every 10th, every 100th, other)'**
  String get feedback_suggest_trigger_hint;

  /// No description provided for @feedback_suggest_comments.
  ///
  /// In en, this message translates to:
  /// **'Any comments:'**
  String get feedback_suggest_comments;

  /// No description provided for @feedback_error_email_not_available.
  ///
  /// In en, this message translates to:
  /// **'No email app is available.'**
  String get feedback_error_email_not_available;

  /// No description provided for @community_open_discord.
  ///
  /// In en, this message translates to:
  /// **'Open Discord group'**
  String get community_open_discord;

  /// No description provided for @community_open_facebook.
  ///
  /// In en, this message translates to:
  /// **'Open Facebook group'**
  String get community_open_facebook;

  /// No description provided for @home_continueActiveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue active session'**
  String get home_continueActiveSessionTitle;

  /// No description provided for @home_continueActiveSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished session for {dogName}.'**
  String home_continueActiveSessionSubtitle(String dogName);

  /// No description provided for @home_continueActiveSessionMissingDogTitle.
  ///
  /// In en, this message translates to:
  /// **'Active session cannot be restored'**
  String get home_continueActiveSessionMissingDogTitle;

  /// No description provided for @home_continueActiveSessionMissingDogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The dog is no longer available. You can discard the draft.'**
  String get home_continueActiveSessionMissingDogSubtitle;

  /// No description provided for @home_continueActiveSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Continue active session'**
  String get home_continueActiveSessionButton;

  /// No description provided for @home_discardActiveSessionButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get home_discardActiveSessionButton;

  /// No description provided for @home_discardActiveSessionSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Discarded active session'**
  String get home_discardActiveSessionSnackbar;

  /// No description provided for @home_endActiveSessionButton.
  ///
  /// In en, this message translates to:
  /// **'End active session'**
  String get home_endActiveSessionButton;

  /// No description provided for @home_endActiveSessionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End active session?'**
  String get home_endActiveSessionConfirmTitle;

  /// No description provided for @home_endActiveSessionConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard the active session?'**
  String get home_endActiveSessionConfirmSubtitle;

  /// No description provided for @milestones_category_firsts.
  ///
  /// In en, this message translates to:
  /// **'Firsts'**
  String get milestones_category_firsts;

  /// No description provided for @milestones_category_sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get milestones_category_sessions;

  /// No description provided for @milestones_category_points.
  ///
  /// In en, this message translates to:
  /// **'Stand'**
  String get milestones_category_points;

  /// No description provided for @milestones_category_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get milestones_category_time;

  /// No description provided for @milestones_category_contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get milestones_category_contacts;

  /// No description provided for @birdsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 birds} one{1 bird} other{{count} birds}}'**
  String birdsCount(num count);

  /// No description provided for @birdsDownCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 birds down} one{1 bird down} other{{count} birds down}}'**
  String birdsDownCount(num count);

  /// Button label for starting a field session (auto-start).
  ///
  /// In en, this message translates to:
  /// **'Start field session'**
  String get session_field_session_button;

  /// Help text explaining field session is for logging while out with the dog.
  ///
  /// In en, this message translates to:
  /// **'For logging while you are out with your dog'**
  String get session_field_session_help;

  /// Button label for manual session registration.
  ///
  /// In en, this message translates to:
  /// **'Register session manually'**
  String get session_manual_registration_button;

  /// Tooltip for the info button that explains session start options.
  ///
  /// In en, this message translates to:
  /// **'What do the options mean?'**
  String get session_options_info_tooltip;

  /// Title in the info dialog that explains session start options.
  ///
  /// In en, this message translates to:
  /// **'What do the options mean?'**
  String get session_options_info_title;

  /// Explanation text for starting a field session immediately.
  ///
  /// In en, this message translates to:
  /// **'Use this when you are out with your dog and want to start logging right away.'**
  String get session_options_info_field_body;

  /// Explanation text for manual session registration.
  ///
  /// In en, this message translates to:
  /// **'Use this when you want to add a previous training session, hunt, or trial.'**
  String get session_options_info_manual_body;

  /// Section title for account information.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_section_account;

  /// Label for showing which account is currently signed in.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get settings_signed_in_as;

  /// Message shown when no user is currently signed in.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settings_not_signed_in;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['da', 'en', 'nb', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da': return AppLocalizationsDa();
    case 'en': return AppLocalizationsEn();
    case 'nb': return AppLocalizationsNb();
    case 'sv': return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
