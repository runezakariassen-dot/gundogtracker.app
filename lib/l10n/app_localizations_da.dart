// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appName => 'Fuglehund';

  @override
  String get app_store_identity_subtitle => 'Offline jagtlog for stående fuglehunde';

  @override
  String get app_store_identity_short_description => 'Log sessioner, følg fremgang og byg historik for din hund – også offline.';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Luk';

  @override
  String get common_done => 'Færdig';

  @override
  String get common_cancel => 'Annuller';

  @override
  String get common_save => 'Gem';

  @override
  String get common_copy => 'Kopiér';

  @override
  String get common_copied => 'Kopieret ✅';

  @override
  String get common_comingSoon => 'Kommer snart.';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nej';

  @override
  String get common_invalid_link => 'Ugyldig link';

  @override
  String get common_could_not_open_link => 'Kunne ikke åbne linket';

  @override
  String get common_unknown => 'Ukendt';

  @override
  String get common_unknown_email => 'Ukendt e-mail';

  @override
  String get common_unknown_member => 'Ukendt medlem';

  @override
  String get common_no_permission => 'Du har ikke adgang til denne handling.';

  @override
  String get common_retry => 'Prøv igen';

  @override
  String get age_unknown => 'Alder ukendt';

  @override
  String get boot_error_title => 'Start mislykkedes';

  @override
  String boot_error_body(Object message) {
    return 'Se terminalen for detaljer.\n$message';
  }

  @override
  String get boot_error_unknown => 'Ukendt fejl';

  @override
  String get boot_restore_title => 'Gendanner backup…';

  @override
  String get boot_restore_body => 'Luk ikke appen.\n\nVi blokerer adgangen til data, mens gendannelsen kører for at undgå Hive-fejl.';

  @override
  String get boot_restart_title => 'Backup gendannet ✅';

  @override
  String get boot_restart_body => 'Appen lukkes nu, så ændringerne kan indlæses.\n\nÅbn appen igen bagefter.';

  @override
  String get qr_scan_title => 'Scan QR';

  @override
  String get home_title => 'Hjem';

  @override
  String get home => 'Hjem';

  @override
  String get sessions => 'Sessioner';

  @override
  String get statistics => 'Statistik';

  @override
  String get advanced_statistics => 'Advanced statistics';

  @override
  String get advanced_statistics_overview => 'Overview';

  @override
  String get advanced_statistics_progress => 'Progress';

  @override
  String get advanced_statistics_season => 'Season';

  @override
  String get advanced_statistics_comparison => 'Comparison';

  @override
  String get advanced_statistics_export => 'Export';

  @override
  String get advanced_statistics_no_progress_data => 'No progress data available';

  @override
  String get advanced_statistics_no_season_data => 'No seasonal data available';

  @override
  String get advanced_statistics_need_two_dogs => 'Need at least 2 dogs to compare';

  @override
  String get advanced_statistics_exporting => 'Exporting...';

  @override
  String get advanced_statistics_export_stats => 'Export statistics';

  @override
  String get advanced_statistics_export_sessions => 'Export sessions';

  @override
  String get advanced_statistics_generate_text_report => 'Generate text report';

  @override
  String advanced_statistics_key_metrics_for(Object dogName) {
    return 'Key metrics for $dogName';
  }

  @override
  String get advanced_statistics_stand_rate_per_hour => 'Stand-rate per hour';

  @override
  String get advanced_statistics_bird_contacts_per_session => 'Bird contacts per session';

  @override
  String get advanced_statistics_average_flushes_per_session => 'Average flushes per session';

  @override
  String get advanced_statistics_success_rate => 'Success rate';

  @override
  String get advanced_statistics_totals => 'Totals';

  @override
  String get advanced_statistics_sessions_total => 'Sessions total';

  @override
  String get advanced_statistics_active_time => 'Active time';

  @override
  String get advanced_statistics_total_points => 'Total points';

  @override
  String get advanced_statistics_total_flushes => 'Total flushes';

  @override
  String get advanced_statistics_bird_contacts => 'Bird contacts';

  @override
  String get advanced_statistics_birds_shot => 'Birds shot';

  @override
  String advanced_statistics_progress_over_time(Object dogName) {
    return 'Progress over time - $dogName';
  }

  @override
  String get advanced_statistics_average_points_per_session_over_time => 'Average points per session over time';

  @override
  String get advanced_statistics_trend_analysis => 'Trend analysis';

  @override
  String get advanced_statistics_improvement => 'Improvement!';

  @override
  String get advanced_statistics_declining => 'Declining';

  @override
  String get advanced_statistics_stable => 'Stable';

  @override
  String advanced_statistics_seasonal_analysis(Object dogName) {
    return 'Seasonal analysis - $dogName';
  }

  @override
  String get advanced_statistics_sessions => 'Sessions';

  @override
  String get advanced_statistics_points => 'Points';

  @override
  String get advanced_statistics_points_per_hour => 'Points per hour';

  @override
  String get advanced_statistics_dog_comparison => 'Dog comparison';

  @override
  String get advanced_statistics_success_rate_percent => 'Success rate (%)';

  @override
  String get advanced_statistics_export_reports => 'Export reports';

  @override
  String get advanced_statistics_export_statistics_csv => 'Export statistics as CSV';

  @override
  String get advanced_statistics_contains_comparison_all_dogs => 'Contains comparison of all dogs with key figures.';

  @override
  String get advanced_statistics_export_sessions_csv => 'Export all session data as CSV';

  @override
  String get advanced_statistics_sessions_csv_description => 'Detailed overview of all hunt sessions with all fields.';

  @override
  String get advanced_statistics_generate_text_report_description => 'Generate a text summary of all statistics.';

  @override
  String get advanced_statistics_export_session_data => 'Export session data';

  @override
  String advanced_statistics_text_report_for(Object dogName) {
    return 'Text report for $dogName';
  }

  @override
  String get advanced_statistics_generate_readable_text_report => 'Generate a readable text report with all statistics.';

  @override
  String stats_week_label(int week) {
    return 'Uge $week';
  }

  @override
  String get common_conjunction_and => 'og';

  @override
  String stats_stands_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stande',
      one: '$count stand',
    );
    return '$_temp0';
  }

  @override
  String stats_sessions_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioner',
      one: '$count session',
    );
    return '$_temp0';
  }

  @override
  String stats_birds_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fugle',
      one: '$count fugl',
    );
    return '$_temp0';
  }

  @override
  String stats_flushes_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rejsninger',
      one: '$count rejsning',
    );
    return '$_temp0';
  }

  @override
  String common_years(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count år',
      one: '$count år',
    );
    return '$_temp0';
  }

  @override
  String common_months(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count måneder',
      one: '$count måned',
    );
    return '$_temp0';
  }

  @override
  String common_days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dage',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get common_months_short => 'mdr';

  @override
  String get stats_screen_title => 'Statistik';

  @override
  String get stats_period_daily => 'Dagligt';

  @override
  String get stats_period_weekly => 'Ugentligt';

  @override
  String get stats_period_monthly => 'Månedligt';

  @override
  String get stats_no_sessions_registered => 'Ingen sessioner registreret endnu';

  @override
  String get stats_filter_all_dogs => 'Alle hunde';

  @override
  String get stats_filter_dynamic_period => 'Dynamisk periode';

  @override
  String get stats_trendline_title => 'Trendlinje';

  @override
  String stats_period_range(Object from, Object to) {
    return '$from–$to';
  }

  @override
  String stats_bucket_title(Object title) {
    return '$title';
  }

  @override
  String stats_buckets_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buckets',
      one: '$count bucket',
    );
    return '$_temp0';
  }

  @override
  String stats_total_label(Object count) {
    return 'Total: $count';
  }

  @override
  String stats_more_points(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points mere',
      one: '$count point mere',
    );
    return '$_temp0';
  }

  @override
  String stats_trend_point_label(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get dogs => 'Hunde';

  @override
  String get dog_sex_male => 'Hanhund';

  @override
  String get dog_sex_female => 'Tæve';

  @override
  String get dog_unnamed => 'Uden navn';

  @override
  String dog_subtitle_born_prefix(String date) {
    return 'Født: $date';
  }

  @override
  String get dog_editor_error_name_missing => 'Navn mangler';

  @override
  String get dog_editor_save => 'Gem';

  @override
  String get dog_editor_saving => 'Gemmer…';

  @override
  String get dog_editor_delete_dog => 'Slet hund';

  @override
  String get dog_editor_deleting => 'Sletter…';

  @override
  String get dog_editor_delete_dog_title => 'Slet hund';

  @override
  String get dog_editor_delete_dog_body => 'Vil du slette hunden? Det kan ikke fortrydes.';

  @override
  String get dog_editor_discard_changes_title => 'Forkast ændringer?';

  @override
  String get dog_editor_discard_changes_body => 'Dine ændringer er ikke gemt endnu.';

  @override
  String get dog_editor_discard_changes_confirm => 'Forkast';

  @override
  String get dog_editor_intro_title => 'Tilføj din hund';

  @override
  String get dog_editor_intro_body => 'Du kan begynde enkelt nu. Et navn er nok for at komme i gang, og flere detaljer kan tilføjes senere.';

  @override
  String get dog_editor_button_cancel => 'Annuller';

  @override
  String get dog_editor_button_delete => 'Slet';

  @override
  String get dog_editor_new_breed_title => 'Ny race';

  @override
  String get dog_editor_new_breed_hint => 'F.eks. Gordon setter';

  @override
  String get dog_editor_button_add => 'Tilføj';

  @override
  String get dog_editor_select_breed_label => 'Vælg race';

  @override
  String get dog_editor_select_breed_placeholder => 'Vælg race';

  @override
  String get dog_editor_new_breed_option => 'Ny race…';

  @override
  String get dog_editor_name_label => 'Navn';

  @override
  String get dog_editor_nickname_label => 'Kaldenavn';

  @override
  String get dog_editor_nickname_hint => 'Valgfrit (f.eks. Zoë, Bowie)';

  @override
  String get dog_editor_birthdate_label => 'Fødselsdato';

  @override
  String get dog_editor_birthdate_not_set => 'Ikke sat';

  @override
  String get dog_editor_regnr_label => 'Reg.nr';

  @override
  String get dog_editor_pedigree_url_label => 'Stamtavle-URL';

  @override
  String get dog_editor_memory_words_label => 'Mindeord';

  @override
  String get dog_editor_image_text_anchor_label => 'Tekstplacering på billede';

  @override
  String get dog_editor_death_registered_title => 'Registreret død';

  @override
  String get dog_editor_section_breed_title => 'Race';

  @override
  String get dog_editor_section_sex => 'Køn';

  @override
  String get dog_editor_role_section_title => 'Vælg rolle';

  @override
  String get dog_editor_role_owner => 'Ejer';

  @override
  String get dog_editor_role_admin => 'Administrator';

  @override
  String get dog_editor_role_user => 'Bruger';

  @override
  String get dog_editor_section_hero_title => 'Hero-tekst';

  @override
  String get dog_editor_anchor_bottom_left => 'Nederst til venstre';

  @override
  String get dog_editor_anchor_bottom_center => 'Nederst centreret';

  @override
  String get dog_editor_anchor_top_left => 'Øverst til venstre';

  @override
  String get dog_editor_text_size_label => 'Tekststørrelse';

  @override
  String get dog_editor_text_size_small => 'Lille';

  @override
  String get dog_editor_text_size_normal => 'Normal';

  @override
  String get dog_editor_text_size_large => 'Stor';

  @override
  String get dog_editor_section_lifecycle_title => 'Livsløb';

  @override
  String get dog_editor_death_date_label => 'Dødsdato';

  @override
  String get dog_editor_death_date_picker_hint => 'Vælg dato';

  @override
  String get dog_detail_snackbar_invite_accepted => 'Invitation accepteret';

  @override
  String get dog_detail_snackbar_invite_declined => 'Invitation afvist';

  @override
  String get dog_detail_snackbar_invite_sent => 'Invitation sendt';

  @override
  String get dog_detail_snackbar_ownership_accepted => 'Ejerskab accepteret';

  @override
  String get dog_detail_snackbar_request_declined => 'Forespørgsel afvist';

  @override
  String get dog_detail_snackbar_request_cancelled => 'Forespørgsel annulleret';

  @override
  String get dog_detail_snackbar_image_save_failed => 'Kunne ikke gemme billedet.';

  @override
  String get dog_detail_snackbar_pedigree_invalid => 'Stamtavle-linket er ugyldigt eller kan ikke åbnes.';

  @override
  String get dog_detail_photo_source_gallery => 'Vælg fra billeder';

  @override
  String get dog_detail_photo_source_camera => 'Tag billede';

  @override
  String get dog_detail_button_cancel => 'Annuller';

  @override
  String get dog_detail_pedigree_section_title => 'Stamtavle';

  @override
  String get dog_detail_button_open_pedigree => 'Åbn stamtavle';

  @override
  String get dog_pedigree_no_link => 'Ingen link registreret';

  @override
  String get dog_detail_appbar_title => 'Hundeprofil';

  @override
  String get dog_detail_error_dog_not_found => 'Hunden blev ikke fundet';

  @override
  String get dog_detail_title_add_dog => 'Tilføj hund';

  @override
  String get dog_editor_title_add_dog => 'Tilføj hund';

  @override
  String get dog_editor_title_edit_dog => 'Rediger hund';

  @override
  String get dog_profile_title => 'Hund';

  @override
  String get dog_profile_subtitle_breed_age => 'Race · Alder';

  @override
  String get dog_generic_name => 'Hund';

  @override
  String get dog_detail_section_access => 'Adgange';

  @override
  String get dog_detail_button_send_invite => 'Send invitation';

  @override
  String get dog_detail_section_invites => 'Invitationer';

  @override
  String get invite_send_email_label => 'Modtagers e-mail';

  @override
  String get invite_send_button => 'Send invitation';

  @override
  String invite_sent_to(Object email) {
    return 'Invitation sendt til $email';
  }

  @override
  String get invite_revoke_button => 'Tilbagekald';

  @override
  String get invite_status_invited => 'Inviteret';

  @override
  String invite_status_invited_as_user(Object role) {
    return 'Inviteret som $role';
  }

  @override
  String get invite_accept => 'Accepter';

  @override
  String get invite_decline => 'Afslå';

  @override
  String get dog_share_section_title => 'Delt med';

  @override
  String get dog_detail_access_section_title => 'Adgang til denne hund';

  @override
  String get dog_detail_member_action_set_reader => 'Sæt som læser';

  @override
  String get dog_detail_member_action_set_user => 'Sæt som bruger';

  @override
  String get dog_detail_member_action_remove_access => 'Fjern adgang';

  @override
  String get share_role_owner => 'Ejer';

  @override
  String get share_role_admin => 'Administrator';

  @override
  String get share_role_user => 'Bruger';

  @override
  String get dog_detail_share_empty => 'Ingen invitationer';

  @override
  String get dog_detail_share_empty_owner => 'Ingen deling endnu.';

  @override
  String dog_detail_my_role_label(String role) {
    return 'Din rolle: $role';
  }

  @override
  String get dog_detail_share_disabled_explanation => 'Du har ikke rettigheder til at dele denne hund.';

  @override
  String get share_accept_title => 'Accepter deling';

  @override
  String get share_accept_code_label => 'Delingskode';

  @override
  String get share_accept_scan_qr => 'Scan QR';

  @override
  String get share_accept_button => 'Accepter';

  @override
  String get share_error_dialog_title => 'Deling mislykkedes';

  @override
  String get share_error_not_owner => 'Kun ejeren eller en administrator kan dele hunden.';

  @override
  String get share_error_invite_not_found => 'Inviteringen blev ikke fundet.';

  @override
  String get share_error_invite_expired => 'Inviteringen er udløbet.';

  @override
  String get share_error_invite_revoked => 'Inviteringen er trukket tilbage.';

  @override
  String get share_error_invite_inactive => 'Inviteringen er ikke aktiv.';

  @override
  String get share_error_already_has_access => 'Du har allerede adgang.';

  @override
  String get share_error_already_invited => 'Denne e-mail er allerede blevet inviteret.';

  @override
  String get share_error_invalid_role => 'Ugyldig rolle.';

  @override
  String get share_error_invalid_email => 'Ugyldig e-mailadresse.';

  @override
  String get share_error_dog_not_found_title => 'Hund ikke fundet';

  @override
  String get share_error_dog_not_found_detail => 'Ingen hund matcher den kode.';

  @override
  String get transfer_error_not_owner => 'Kun ejeren kan afvise anmodningen.';

  @override
  String get transfer_error_not_recipient => 'Du er ikke modtager af denne anmodning.';

  @override
  String get transfer_error_not_found => 'Anmodningen blev ikke fundet.';

  @override
  String get transfer_error_expired => 'Anmodningen er udløbet.';

  @override
  String get transfer_error_not_pending => 'Anmodningen er ikke aktiv.';

  @override
  String get transfer_error_cannot_transfer_to_self => 'Kan ikke overføre til sig selv.';

  @override
  String get transfer_error_cancelled => 'Anmodningen er allerede afvist.';

  @override
  String get role_owner => 'Ejer';

  @override
  String get role_editor => 'Redaktør';

  @override
  String get role_viewer => 'Læser';

  @override
  String get role_admin => 'Administrator';

  @override
  String get dog_editor_owner_email_label => 'Ejers e-mail';

  @override
  String get dog_editor_owner_email_hint => 'navn@eksempel.dk';

  @override
  String get dog_editor_owner_email_required_error => 'Indtast en gyldig e-mail for ejeren.';

  @override
  String get dog_detail_section_owner_request_title => 'Ejerskab anmodet';

  @override
  String dog_detail_label_from_user(String userId) {
    return 'Fra: $userId';
  }

  @override
  String dog_detail_label_to_user(String userId) {
    return 'Til: $userId';
  }

  @override
  String get dog_detail_button_accept => 'Accepter';

  @override
  String get dog_detail_button_decline => 'Afslå';

  @override
  String get dog_detail_button_cancel_request => 'Annuller forespørgsel';

  @override
  String get dog_detail_button_edit_photo => 'Rediger profilbillede';

  @override
  String get dog_detail_button_mark_dead => 'Marker som død';

  @override
  String get dog_detail_watermark_section_title => 'Vandmærke';

  @override
  String get dog_detail_watermark_info => 'Vandmærke er obligatorisk ved deling af hundebilleder.';

  @override
  String get dog_detail_watermark_toggle_title => 'Vis titel';

  @override
  String get dog_detail_watermark_toggle_name => 'Vis navn';

  @override
  String get dog_detail_watermark_share_button => 'Del billede';

  @override
  String get dog_detail_watermark_share_subject => 'Billede fra GundogTracker';

  @override
  String get dog_detail_watermark_share_message => 'Delt via GundogTracker';

  @override
  String get session_image_viewer_watermark_toggle_title => 'Vis titel';

  @override
  String get session_image_viewer_watermark_toggle_official_name => 'Vis officielt navn';

  @override
  String get session_image_viewer_watermark_toggle_nickname => 'Vis kælenavn';

  @override
  String get session_image_viewer_watermark_color_title => 'Tekstfarve';

  @override
  String get session_image_viewer_watermark_color_light => 'Hvid';

  @override
  String get session_image_viewer_watermark_color_dark => 'Sort';

  @override
  String get session_image_viewer_watermark_presets_title => 'Forvalg';

  @override
  String get session_image_viewer_watermark_preset_discreet => 'Diskret';

  @override
  String get session_image_viewer_watermark_preset_clear => 'Klar';

  @override
  String get session_image_viewer_watermark_preset_contrast => 'Kontrast';

  @override
  String get dog_detail_watermark_share_missing_photo => 'Kunne ikke finde et billede at dele.';

  @override
  String get dog_detail_watermark_share_error => 'Kunne ikke dele billedet.';

  @override
  String get dog_detail_label_death_date => 'Dødsdato';

  @override
  String get dog_detail_button_edit => 'Rediger';

  @override
  String get dog_detail_button_register_death => 'Registrer';

  @override
  String get dog_detail_photo_dialog_title => 'Profilbillede';

  @override
  String get dog_detail_photo_pick_camera => 'Tag billede';

  @override
  String get dog_detail_photo_pick_gallery => 'Vælg fra billeder';

  @override
  String get dog_detail_photo_remove => 'Fjern billede';

  @override
  String get dog_detail_snackbar_photo_updated => 'Profilbillede opdateret';

  @override
  String get dog_detail_snackbar_photo_removed => 'Profilbillede fjernet';

  @override
  String get dog_detail_snackbar_error_generic => 'Noget gik galt';

  @override
  String get dog_detail_info_label_sex => 'Køn';

  @override
  String get dog_detail_info_label_born => 'Født';

  @override
  String get dog_detail_summary_points_label => 'Point';

  @override
  String get dog_detail_summary_session_count_label => 'Antal sessioner';

  @override
  String get dog_detail_summary_active_time_label => 'Aktiv tid';

  @override
  String get dog_detail_summary_birds_down_label => 'Nedlagt fugl';

  @override
  String get dog_detail_summary_first_session_label => 'Første session';

  @override
  String get dog_detail_summary_last_session_label => 'Seneste session';

  @override
  String get dog_detail_tooltip_edit_profile => 'Rediger hund';

  @override
  String get dog_detail_farewell_prefix => 'Farvel';

  @override
  String dog_detail_farewell_age_sentence(Object name, Object years, Object months, Object days) {
    return '$name blev $years $months $days gammel';
  }

  @override
  String get dog_detail_next_milestones_title => 'Næste milepæle';

  @override
  String get dog_detail_next_milestone_title => 'Næste milepæl';

  @override
  String get milestone_first_session_title => 'Første session gennemført';

  @override
  String milestone_first_session_subtitle(Object dogName) {
    return 'Første session med $dogName';
  }

  @override
  String get milestone_first_bird_title => 'Første fugl';

  @override
  String age_years(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count år',
      one: '$count år',
    );
    return '$_temp0';
  }

  @override
  String age_years_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count år',
      one: '$count år',
    );
    return '$_temp0';
  }

  @override
  String age_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mdr.',
      one: '$count md.',
    );
    return '$_temp0';
  }

  @override
  String age_months_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mdr',
      one: '$count mdr',
    );
    return '$_temp0';
  }

  @override
  String age_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dage',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get age_zero_days => '0 dage';

  @override
  String get age_and => 'og';

  @override
  String get home_startNewSession => 'Start ny tur';

  @override
  String get chooseDog => 'Vælg hund';

  @override
  String get noDogsAddDog => 'Ingen hunde – tilføj hund';

  @override
  String get home_addDogPrompt => 'Tilføj hund for at starte en tur';

  @override
  String get home_empty_title => 'Start rejsen med din jagthund';

  @override
  String get home_empty_body => 'Log sessioner, følg udviklingen og opbyg en historik på din hund – session for session.';

  @override
  String get home_empty_bullet_progress => 'Se udviklingen over tid – stand, støt og aktivitet.';

  @override
  String get home_empty_bullet_training => 'Bedre træning og jagt – se hvad der faktisk giver afkast.';

  @override
  String get home_empty_bullet_history => 'Jagt-historik du rent faktisk bruger – sæson for sæson, område for område.';

  @override
  String get home_addDog_button => 'Tilføj hund';

  @override
  String get home_empty_next_step => 'Begynd med at tilføje din hund. Derefter kan du logge den første session, når I er klar.';

  @override
  String get home_first_session_title => 'Klar til dit første pas?';

  @override
  String get home_first_session_body => 'Du har registreret din hund. Næste trin er at logge et pas – så begynder din historik og statistik at vokse.';

  @override
  String get home_empty_offline_note => 'Du kan bruge appen helt offline. Alle data gemmes lokalt på din telefon.';

  @override
  String get home_visible_empty_title => 'Ingen hunde tilgængelige';

  @override
  String get home_visible_empty_body => 'Denne konto har ingen hunde endnu. Tjek invitationer eller bed nogen om at dele en hund med dig.';

  @override
  String get home_visible_empty_button => 'Åbn invitationer';

  @override
  String get home_noDogsRegistered => 'Ingen hunde registreret';

  @override
  String get home_primaryActionSubtitle => 'Noter først. Brug + i felterne.';

  @override
  String get home_top10_points_title => 'Top 10 – Stand';

  @override
  String get top10Title => 'Top 10';

  @override
  String get home_top10_points_empty => 'Ingen stand registreret endnu.';

  @override
  String home_top10_points_pointsLabel(int count) {
    return 'Stand: $count';
  }

  @override
  String get standsLabel => 'Stand';

  @override
  String standsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stand',
      one: '1 stand',
      zero: '0 stand',
    );
    return '$_temp0';
  }

  @override
  String top10_points_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stande',
      one: 'stand',
    );
    return '$_temp0';
  }

  @override
  String get home_top10_birds_title => 'Top 10 fugle';

  @override
  String get home_top10_birds_empty => 'Ingen fugle registreret endnu.';

  @override
  String get home_top10_birds_fieldLabel => 'Fugl';

  @override
  String get session_log_title => 'Sessionlog – jagthund';

  @override
  String get session_saved_list_title => 'Gemte sessioner';

  @override
  String get session_save_button => 'Gem session';

  @override
  String get session_unit_min => 'min';

  @override
  String get session_unit_sec => 'sek';

  @override
  String get session_label_points => 'stand';

  @override
  String get session_label_flushes => 'stød';

  @override
  String get session_label_birds => 'fugl';

  @override
  String get session_label_birds_down => 'nedlagt fugl';

  @override
  String get session_all_dogs_label => 'Alle hunde';

  @override
  String get session_map_label => 'Kort';

  @override
  String get session_map_error_no_tracks => 'Fandt ingen spor';

  @override
  String get session_map_error_map_load_failed => 'Kunne ikke indlæse kortet';

  @override
  String get map_page_snackbar_no_tracks_to_focus => 'Ingen spor at fokusere på';

  @override
  String get map_page_dialog_delete_downloaded_map_body => 'Vil du slette dette downloadede kort?';

  @override
  String get map_download_title => 'Download kort';

  @override
  String get map_download_area_label => 'Område';

  @override
  String get map_download_cancel => 'Annuller';

  @override
  String get map_download_start => 'Start download';

  @override
  String get map_downloaded_maps_title => 'Downloadede kort';

  @override
  String get map_downloaded_maps_empty => 'Ingen downloadede kort endnu.';

  @override
  String get map_delete_offline_title => 'Slet offline kort';

  @override
  String get map_delete_offline_body => 'Dette sletter downloadede kortfliser for den valgte stil.';

  @override
  String get map_delete_offline_cancel => 'Annuller';

  @override
  String get map_delete_offline_confirm => 'Slet';

  @override
  String get map_downloading_title => 'Downloader kort';

  @override
  String get map_downloading_cancel => 'Annuller';

  @override
  String get map_go_to => 'Gå til';

  @override
  String get map_delete => 'Slet';

  @override
  String get map_delete_title => 'Slet kort';

  @override
  String get map_tracks => 'Spor';

  @override
  String get map_me => 'Mig';

  @override
  String get hunt_session_snackbar_export_ready_opening_share => 'Eksport klar, åbner deling …';

  @override
  String get hunt_session_snackbar_gpx_export_failed_see_log => 'GPX-eksport fejlede. Se log.';

  @override
  String get session_gpx_import_label => 'Importer GPX';

  @override
  String get session_gpx_importing_ellipsis => 'Importerer…';

  @override
  String get session_gpx_export_label => 'Eksporter GPX';

  @override
  String get session_gpx_exporting_ellipsis => 'Eksporterer…';

  @override
  String get session_form_dog_section_title => 'Hund';

  @override
  String get session_form_dog_prefix => 'Hund:';

  @override
  String get session_form_no_dogs_registered => 'Ingen hunde registreret.';

  @override
  String get session_form_no_dogs_help => 'Tilføj en hund først, så kan du starte din første session.';

  @override
  String get session_summary_sessions_label => 'Sessioner:';

  @override
  String get session_summary_total_time_label => 'Samlet tid:';

  @override
  String get session_summary_total_bird_contacts_label => 'Fuglekontakter i alt:';

  @override
  String get session_summary_total_points_label => 'Stand i alt:';

  @override
  String get session_summary_total_secondary_points_label => 'Sekundering i alt:';

  @override
  String get session_summary_total_tomstand_label => 'Tomstand i alt:';

  @override
  String get session_summary_total_flushes_label => 'Stød i alt:';

  @override
  String get session_action_add_new_session => 'Tilføj ny session';

  @override
  String get session_action_cancel => 'Annuller';

  @override
  String get session_type_title => 'Sessiontype';

  @override
  String get session_type_training => 'Træning';

  @override
  String get session_type_hunt => 'Jag';

  @override
  String get session_field_location => 'Sted';

  @override
  String get session_field_active_time_minutes => 'Aktiv tid (min)';

  @override
  String get session_field_bird_contacts => 'Fuglekontakter';

  @override
  String get session_field_points => 'Stand';

  @override
  String get session_field_secondary_points => 'Sekundering';

  @override
  String get session_field_tomstand => 'Tomstand';

  @override
  String get session_field_flushes => 'Stød';

  @override
  String get session_pick_date => 'Vælg dato';

  @override
  String get session_pick_time => 'Tidspunkt';

  @override
  String get session_birds_section_title => 'Fugl';

  @override
  String get session_birds_select_species => 'Vælg fuglearter';

  @override
  String get session_birds_none_selected => 'Ingen arter valgt';

  @override
  String get session_species_picker_title => 'Vælg arter';

  @override
  String get session_species_picker_empty => 'Ingen arter tilgængelige';

  @override
  String get session_species_picker_add => 'Tilføj';

  @override
  String get session_species_picker_done => 'Færdig';

  @override
  String get session_error_no_dogs_registered => 'Ingen hunde registreret';

  @override
  String get session_select_species_title => 'Vælg art';

  @override
  String get session_no_species_saved_yet => 'Ingen arter gemt endnu';

  @override
  String get session_new_bird_button => 'Ny fugl';

  @override
  String get session_new_species_title => 'Ny art';

  @override
  String get session_error_photo_add => 'Kunne ikke tilføje billede';

  @override
  String get session_error_video_add => 'Kunne ikke tilføje video';

  @override
  String get session_error_media_save => 'Kunne ikke gemme mediefilen';

  @override
  String get session_error_gpx_import => 'GPX-import mislykkedes. Se log.';

  @override
  String get session_error_location_services_disabled => 'Placeringstjenester er deaktiveret';

  @override
  String get session_error_no_gps => 'Ingen GPS-tilladelse';

  @override
  String session_error_gps_failure(String error) {
    return 'GPS-fejl: $error';
  }

  @override
  String get session_error_stop_gps => 'Kunne ikke stoppe GPS';

  @override
  String get session_error_select_dog_first => 'Vælg en hund først';

  @override
  String get session_error_no_track_export => 'Denne session har ikke et spor at eksportere';

  @override
  String get session_error_track_empty => 'Spor mangler/er tomt';

  @override
  String session_snackbar_message(String message) {
    return '$message';
  }

  @override
  String get session_media_add_image_failed => 'Kunne ikke tilføje billede';

  @override
  String get session_media_add_video_failed => 'Kunne ikke tilføje video';

  @override
  String get session_media_save_failed => 'Kunne ikke gemme mediefilen';

  @override
  String get session_media_video_missing => 'Video mangler eller blev ikke gemt korrekt';

  @override
  String get session_media_video_open_failed => 'Kunne ikke åbne video';

  @override
  String get session_media_section_title => 'Media';

  @override
  String get session_media_add_photo_video => 'Tilføj billede/video';

  @override
  String get session_media_gallery_label => 'Billede fra galleri';

  @override
  String get session_media_camera_label => 'Tag billede';

  @override
  String get session_media_video_label => 'Video fra galleri';

  @override
  String get gpx_import_failed_see_log => 'GPX-import mislykkedes. Se log.';

  @override
  String get gps_services_disabled => 'Placeringstjenester er deaktiveret';

  @override
  String get gps_no_permission => 'Ingen GPS-tilladelse';

  @override
  String gps_error_message(String error) {
    return 'GPS-fejl: $error';
  }

  @override
  String get gps_stop_failed => 'Kunne ikke stoppe GPS';

  @override
  String get session_select_dog_first => 'Vælg en hund først';

  @override
  String get session_export_no_track => 'Denne session har ikke et spor at eksportere';

  @override
  String get session_track_missing_or_empty => 'Spor mangler/er tomt';

  @override
  String gpx_exported_to_desktop(String filename) {
    return 'GPX eksporteret til Skrivebordet: $filename ✅';
  }

  @override
  String get session_detail_title_edit_session => 'Rediger session';

  @override
  String get session_detail_title_new_session => 'Ny session';

  @override
  String get session_detail_label_points => 'Point';

  @override
  String get session_detail_label_flushes => 'Stød';

  @override
  String get session_detail_button_add_media => 'Tilføj billede/video';

  @override
  String session_detail_total_points(String value) {
    return 'Point total: $value';
  }

  @override
  String get session_detail_title_home => 'Hjem';

  @override
  String get session_detail_title_main => 'Session';

  @override
  String get session_detail_title_active_session => 'Aktiv session';

  @override
  String get active_session_hunt_events_title => 'Jagthændelser +1';

  @override
  String get active_session_action_stand_plus1 => 'Stand +1';

  @override
  String get active_session_action_secondary_plus1 => 'Sekundering +1';

  @override
  String get active_session_action_flush_plus1 => 'Stød +1';

  @override
  String get active_session_action_bird_plus1 => 'Fugl +1';

  @override
  String get active_session_action_undo => 'Fortryd';

  @override
  String get session_detail_label_choose_dog => 'Vælg hund';

  @override
  String get session_detail_button_open_latest_session => 'Åbn seneste session';

  @override
  String get session_detail_button_start_new_session => 'Start ny session';

  @override
  String get session_detail_button_settings => 'Indstillinger';

  @override
  String get session_detail_media_sheet_title => 'Tilføj medier';

  @override
  String get session_detail_media_sheet_action_gallery => 'Galleri';

  @override
  String get session_detail_media_sheet_action_camera => 'Kamera';

  @override
  String get session_detail_media_sheet_action_video => 'Video';

  @override
  String get session_detail_media_section_title => 'Medier';

  @override
  String get session_detail_media_empty_placeholder => 'Ingen medier endnu';

  @override
  String get session_detail_notes_hint => 'Notater fra sessionen...';

  @override
  String session_detail_meta_time_minutes(Object minutes) {
    return 'Aktiv tid: $minutes min';
  }

  @override
  String session_detail_meta_birds(Object value) {
    return 'Fuglekontakter: $value';
  }

  @override
  String session_detail_meta_secondary_points(Object count) {
    return 'Sekundering: $count';
  }

  @override
  String session_detail_meta_flushes(Object value) {
    return 'Stød: $value';
  }

  @override
  String get session_detail_screen_title => 'Sessionsdetaljer';

  @override
  String get session_notes_hint_from_session => 'Noter fra sessionen...';

  @override
  String get session_notes_section_title => 'Noter';

  @override
  String get session_detail_section_dog => 'Hund';

  @override
  String get session_detail_section_media => 'Medier';

  @override
  String get session_detail_section_notes => 'Notater';

  @override
  String get session_detail_media_open_gallery => 'Åbn galleri';

  @override
  String get session_detail_button_import_gpx => 'Importer GPX';

  @override
  String get session_detail_button_importing => 'Importerer…';

  @override
  String get session_detail_empty_bird_species => 'Ingen fuglearter';

  @override
  String get session_detail_empty_location => 'Ukendt sted';

  @override
  String get session_detail_saved_sessions_title => 'Gemte sessioner';

  @override
  String get session_detail_empty_sessions_for_selected_dog => 'Ingen sessioner for valgt hund';

  @override
  String get session_detail_empty_dogs_registered => 'Ingen hunde registreret.';

  @override
  String get session_detail_empty_sessions_yet => 'Ingen sessioner endnu';

  @override
  String session_detail_track_summary_points(int count) {
    return 'Spor: $count punkter';
  }

  @override
  String session_detail_track_summary_start(String time) {
    return 'Start: $time';
  }

  @override
  String session_detail_track_summary_end(String time) {
    return 'Slut: $time';
  }

  @override
  String session_detail_track_summary_distance_meters(String meters) {
    return 'Distance: $meters m';
  }

  @override
  String session_detail_track_summary_distance_km(String kilometers) {
    return 'Distance: $kilometers km';
  }

  @override
  String session_detail_track_summary_duration(String value) {
    return 'Varighed: $value';
  }

  @override
  String get session_detail_action_saving => 'Gemmer…';

  @override
  String get session_detail_action_save_changes => 'Gem ændringer';

  @override
  String get session_detail_action_save_session => 'Gem session';

  @override
  String get session_detail_edit_title => 'Rediger session';

  @override
  String get session_detail_button_save => 'Gem';

  @override
  String get session_detail_button_cancel => 'Annuller';

  @override
  String get session_detail_button_delete => 'Slet';

  @override
  String get session_detail_field_location_label => 'Sted';

  @override
  String get session_detail_field_active_time_minutes_label => 'Aktiv tid (min)';

  @override
  String get session_detail_field_bird_contacts_label => 'Fuglekontakter';

  @override
  String get session_detail_field_points_label => 'Point';

  @override
  String get session_detail_field_secondary_points_label => 'Sekundering';

  @override
  String get session_detail_field_tomstand_label => 'Tomstand';

  @override
  String get session_detail_field_flushes_label => 'Stød';

  @override
  String get session_detail_field_notes_label => 'Note';

  @override
  String session_detail_version_build(String buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String settings_version_label(Object version) {
    return 'Version $version';
  }

  @override
  String settings_version_build(Object buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String get session_detail_snackbar_changes_saved => 'Ændringer gemt';

  @override
  String get session_detail_snackbar_session_saved => 'Session gemt';

  @override
  String session_detail_snackbar_saved_with_imported_gpx(int points) {
    return 'Session gemt med importeret GPX ($points punkter)';
  }

  @override
  String session_detail_snackbar_saved_with_gps_track(int points) {
    return 'Session gemt med GPS-spor ($points punkter)';
  }

  @override
  String get session_detail_help_notes_first => 'Noter først. Tellere med + i felten.';

  @override
  String session_detail_stats_sessions_count(int count) {
    return 'Antal sessioner: $count';
  }

  @override
  String session_detail_stats_total_active_time(int minutes) {
    return 'Total aktiv tid: $minutes min';
  }

  @override
  String session_detail_stats_total_birds(int count) {
    return 'Fuglekontakter i alt: $count';
  }

  @override
  String session_detail_stats_total_points(int count) {
    return 'Stande i alt: $count';
  }

  @override
  String session_detail_stats_total_secondary_points(int count) {
    return 'Sekundering i alt: $count';
  }

  @override
  String session_detail_stats_total_tomstand(int count) {
    return 'Tomstand i alt: $count';
  }

  @override
  String session_detail_stats_total_flushes(int count) {
    return 'Stød i alt: $count';
  }

  @override
  String get session_detail_button_select_date => 'Vælg dato';

  @override
  String get session_detail_button_select_time => 'Tidspunkt';

  @override
  String get session_detail_label_duration_from_track => 'Hentet fra GPS-spor';

  @override
  String get session_detail_confirm_delete_title => 'Slet session?';

  @override
  String get session_detail_confirm_delete_body => 'Dette fjerner sessionen fra hunden.';

  @override
  String get session_detail_media_delete_title => 'Slet medie?';

  @override
  String get session_detail_media_delete_body => 'Dette fjerner det valgte medie fra sessionen.';

  @override
  String session_detail_saved_session_summary(int durationMinutes, int birds, int stand, int secondaryPoints, int tomstandCount, int flushes) {
    return 'Tid: $durationMinutes min, Fugle: $birds, stande: $stand, sekundering: $secondaryPoints, tomstand: $tomstandCount, stød: $flushes';
  }

  @override
  String get session_detail_button_exporting => 'Eksporterer…';

  @override
  String get session_detail_button_export_gpx => 'Eksportér GPX';

  @override
  String get session_detail_error_gpx_too_few_points => 'Fundet for få GPX-punkter i filen';

  @override
  String session_detail_helper_duration_hours_minutes(int hours, int minutes) {
    return '${hours}t ${minutes}m';
  }

  @override
  String get session_detail_bird_species_picker_title => 'Vælg fuglearter';

  @override
  String get session_detail_bird_section_title => 'Fuglearter';

  @override
  String get session_detail_bird_species_button_label => 'Vælg fuglearter';

  @override
  String get session_detail_bird_species_empty_selection => 'Ingen arter valgt';

  @override
  String get session_detail_bird_species_empty_saved => 'Ingen arter gemt endnu';

  @override
  String get session_detail_bird_species_new => 'Ny fugl';

  @override
  String get session_detail_action_done => 'Færdig';

  @override
  String get session_detail_bird_species_dialog_title => 'Ny fugleart';

  @override
  String get session_detail_bird_species_dialog_name_label => 'Navn';

  @override
  String get session_action_save => 'Gem';

  @override
  String get session_detail_media_gallery_title => 'Medier';

  @override
  String get hunt_session_title_new => 'Ny session';

  @override
  String get hunt_session_title_edit => 'Rediger session';

  @override
  String get hunt_session_field_location_label => 'Sted';

  @override
  String get hunt_session_field_duration_minutes_label => 'Aktiv tid (min)';

  @override
  String get hunt_session_field_birds_seen_label => 'Fuglekontakter';

  @override
  String get hunt_session_field_points_label => 'Point';

  @override
  String get hunt_session_field_secondary_points_label => 'Sekundering';

  @override
  String get hunt_session_field_tomstand_label => 'Tomstand';

  @override
  String get hunt_session_field_flushes_label => 'Stød';

  @override
  String get hunt_session_field_notes_label => 'Note';

  @override
  String get hunt_session_action_save => 'Gem';

  @override
  String get hunt_session_action_cancel => 'Annuller';

  @override
  String get hunt_session_action_delete => 'Slet';

  @override
  String get hunt_session_action_import_gpx => 'Importer GPX';

  @override
  String get hunt_session_action_importing => 'Importerer…';

  @override
  String hunt_session_snackbar_saved_with_gps_track(Object points) {
    return 'Session gemt med GPS-spor ($points punkter)';
  }

  @override
  String get session_detail_filter_all_dogs => 'Alle hunde';

  @override
  String get session_detail_session_menu_export => 'Eksportér GPX';

  @override
  String get session_detail_session_menu_exporting => 'Eksporterer…';

  @override
  String get session_detail_session_menu_edit => 'Rediger session';

  @override
  String get session_detail_session_menu_delete => 'Slet session';

  @override
  String get session_detail_detail_title => 'Detaljer';

  @override
  String get session_detail_detail_label_date => 'Dato';

  @override
  String get session_detail_detail_label_location => 'Sted';

  @override
  String get session_detail_detail_label_active_time => 'Aktiv tid';

  @override
  String get session_detail_detail_label_bird_contacts => 'Fuglekontakter';

  @override
  String get session_detail_detail_label_points => 'Point';

  @override
  String get session_detail_detail_label_secondary_points => 'Sekundering';

  @override
  String get session_detail_detail_label_tomstand => 'Tomstand';

  @override
  String get session_detail_detail_label_flushes => 'Stød';

  @override
  String get session_detail_label_bird_species => 'Fuglearter';

  @override
  String get session_detail_label_gps_track => 'GPS-spor';

  @override
  String get session_detail_label_yes => 'Ja';

  @override
  String get session_detail_label_no => 'Nej';

  @override
  String get session_detail_label_dog_prefix => 'Hund: ';

  @override
  String get session_detail_map_title => 'Kort';

  @override
  String get session_detail_map_prefix => 'Kort – ';

  @override
  String get map_title => 'Kort';

  @override
  String get session_detail_gpx_replace_title => 'Erstat spor?';

  @override
  String get session_detail_gpx_replace_body => 'Dette vil erstatte eksisterende spor. Fortsæt?';

  @override
  String get session_detail_gpx_replace_confirm => 'Erstat';

  @override
  String session_detail_gpx_replaced_snackbar(int points) {
    return 'Spor erstattet: $points punkter';
  }

  @override
  String session_detail_gpx_imported_snackbar(int points) {
    return 'GPX importeret: $points punkter';
  }

  @override
  String get session_detail_empty_notes => 'Ingen notat';

  @override
  String get session_detail_empty_media => 'Ingen medier tilføjet';

  @override
  String session_detail_helper_duration_minutes_seconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String session_detail_helper_duration_seconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String session_detail_total_flushes(String value) {
    return 'Stød total: $value';
  }

  @override
  String get gpx_import_label => 'Importer GPX';

  @override
  String get session_menu_edit => 'Redigér session';

  @override
  String get session_menu_delete => 'Slet session';

  @override
  String stats_trend_label(String symbol) {
    return 'Trend: $symbol';
  }

  @override
  String get stats_title_points_and_flushes => 'Stand og flush';

  @override
  String get stats_title_sessions => 'Sessioner';

  @override
  String get stats_title_birds_down_per_year => 'Fældet fugl pr. år';

  @override
  String get stats_subtitle_active_time => 'Aktiv tid';

  @override
  String get stats_subtitle_session_count => 'Antal sessioner';

  @override
  String get stats_legend_bars => 'Søjler:';

  @override
  String get stats_legend_line => 'Linje:';

  @override
  String get stats_title_development => 'Udvikling';

  @override
  String get stats_period_30_days => '30 dage';

  @override
  String get stats_period_90_days => '90 dage';

  @override
  String get stats_legend_active_time => 'Aktiv tid';

  @override
  String get stats_legend_sessions => 'Sessioner';

  @override
  String stats_week_tooltip(String weekLabel, int sessions, String time) {
    return '$weekLabel: $sessions sessioner, $time';
  }

  @override
  String get stats_info_active_time_title => 'Aktiv tid';

  @override
  String get stats_info_active_time_body_1 => 'Samlet tid hunden har været i arbejde.';

  @override
  String get stats_info_active_time_body_2 => 'Bruges til at vurdere belastning og kontinuitet.';

  @override
  String get stats_info_session_count_title => 'Sessioner';

  @override
  String get stats_info_session_count_body_1 => 'Hvor ofte hunden har været aktiv.';

  @override
  String get stats_info_session_count_body_2 => 'Viser trænings- og jagtfrekvens.';

  @override
  String get stats_v1_overview_title => 'V1-oversigt';

  @override
  String get stats_total_points_title => 'Samlede stande';

  @override
  String get stats_total_active_time_title => 'Samlet aktiv tid';

  @override
  String get stats_avg_points_per_session_title => 'Gns.: stande pr. session';

  @override
  String get stats_avg_time_per_session_title => 'Gns.: tid pr. session';

  @override
  String get stats_last_30_days_sessions_title => 'Seneste 30 dage: Sessioner';

  @override
  String get stats_last_30_days_points_title => 'Seneste 30 dage: Stand(e)';

  @override
  String stats_overview_sessions_value(int count) {
    return '$count sessioner';
  }

  @override
  String stats_overview_points_value(int count) {
    return '$count stand';
  }

  @override
  String stats_last_30_days_sessions_value(int count) {
    return '$count sessioner';
  }

  @override
  String stats_last_30_days_points_value(int count) {
    return '$count stand';
  }

  @override
  String get stats_points_label => 'Stand';

  @override
  String get stats_flushes_label => 'Flush';

  @override
  String stats_per_month_suffix(int year) {
    return 'pr. måned • $year';
  }

  @override
  String stats_monthly_sessions_tooltip(String month, int year, int count) {
    return '$month $year: $count sessioner';
  }

  @override
  String stats_monthly_sessions_tooltip_empty(String month, int year) {
    return '$month $year: Ingen sessioner';
  }

  @override
  String stats_total_points_flushes_prefix(int points, int flushes) {
    return 'I alt: $points stand, $flushes flush';
  }

  @override
  String stats_stand_flush_tooltip(String month, int year, String stand, String flush) {
    return '$month $year: Stand $stand, Støkk $flush';
  }

  @override
  String get stats_info_points_flushes_title => 'Stand og flush';

  @override
  String get stats_info_points_flushes_body_1 => 'Viser antal stand og flush over tid.';

  @override
  String get stats_info_points_flushes_body_2 => 'Giver indblik i hundens arbejde i marken og jagtmønster.';

  @override
  String get stats_none => 'Ingen';

  @override
  String get stats_unknown_species => 'Ukendt';

  @override
  String get stats_info_explanation_tooltip => 'Forklaring';

  @override
  String stats_total_sessions_prefix(int count) {
    return 'I alt: $count sessioner';
  }

  @override
  String get stats_info_sessions_title => 'Sessioner';

  @override
  String get stats_info_sessions_body_1 => 'Hvor ofte hunden har været aktiv.';

  @override
  String get stats_info_sessions_body_2 => 'Viser trænings- og jagtfrekvens.';

  @override
  String get stats_no_birds_down_yet => 'Ingen fældede fugle registreret endnu';

  @override
  String get stats_birds_distribution_title => 'Fordeling felt fugl';

  @override
  String get stats_birds_pie_hint => 'Tryk på et kakestykke for detaljer';

  @override
  String get stats_info_birds_down_title => 'Felt fugl';

  @override
  String get stats_info_birds_down_body_1 => 'Antal fældede fugle pr. kalenderår.';

  @override
  String get stats_info_birds_down_body_2 => 'Giver grundlag for år-til-år sammenligning.';

  @override
  String get stats_info_birds_distribution_title => 'Fordeling af fældet fugl';

  @override
  String get stats_info_birds_distribution_body_1 => 'Viser hvilke arter der er fældet i det valgte år.';

  @override
  String get stats_info_birds_distribution_body_2 => 'Giver overblik over jagtudtag og variation.';

  @override
  String get stats_label_year => 'År';

  @override
  String get stats_label_total => 'I alt';

  @override
  String get stats_label_per_month => 'pr. måned';

  @override
  String get gpx_importing_ellipsis => 'Importerer…';

  @override
  String get gpx_export_label => 'Eksporter GPX';

  @override
  String get gpx_exporting_ellipsis => 'Eksporterer…';

  @override
  String get home_open_settings_tooltip => 'Indstillinger';

  @override
  String get home_settings_button_label => 'Indstillinger';

  @override
  String get home_sessions_empty => 'Ingen sessioner endnu';

  @override
  String get home_openSession => 'Åbn';

  @override
  String get home_select_dog => 'Vælg hund';

  @override
  String get home_no_sessions_yet => 'Ingen sessioner endnu';

  @override
  String get home_no_dogs_title => 'Ingen hunde registreret endnu';

  @override
  String get home_no_dogs_message => 'Registrer dine hunde for at logge træning, jagt og prøver. Så får du en overskuelig historik og bedre overblik over udviklingen.';

  @override
  String get home_no_dogs_bullet_history => 'Historik: se sessioner, noter og steder samlet';

  @override
  String get home_no_dogs_bullet_progress => 'Progres: følg stand, støt og aktiv tid over tid';

  @override
  String get home_no_dogs_bullet_stats => 'Statistik: meningsfulde trends der støtter jagten';

  @override
  String get home_wisdom_empty => 'En rolig start giver bedre jagt end hastværk.';

  @override
  String get wisdom_001 => 'En rolig hund lærer hurtigere end en stresset.';

  @override
  String get wisdom_002 => 'Det du træner i dag, får du igen til efteråret.';

  @override
  String get wisdom_003 => 'Gentag mindre. Vent mere.';

  @override
  String get wisdom_004 => 'Stilhed er også træning.';

  @override
  String get wisdom_005 => 'Fremskridt sker ofte mellem sessionerne.';

  @override
  String get wisdom_006 => 'En pause på rette tidspunkt er bedre end én gentagelse for meget.';

  @override
  String get wisdom_007 => 'Tålmodighed er den mest undervurderede øvelse.';

  @override
  String get wisdom_008 => 'Træn det du vil se, ikke det du håber på.';

  @override
  String get wisdom_009 => 'En tryg hund lærer hurtigere end en ivrig.';

  @override
  String get wisdom_010 => 'Det er lov at stoppe mens det går godt.';

  @override
  String get wisdom_011 => 'En stand bygges før fugl, ikke efter.';

  @override
  String get wisdom_012 => 'Ro i opflugt starter i hovedet.';

  @override
  String get wisdom_013 => 'Stabilitet er et valg hunden lærer at tage.';

  @override
  String get wisdom_014 => 'Pres skaber bevægelse. Tid skaber ro.';

  @override
  String get wisdom_015 => 'En god stand behøver ikke publikum.';

  @override
  String get wisdom_016 => 'Når hunden står, må verden vente.';

  @override
  String get wisdom_017 => 'Én rolig stand slår tre hurtige.';

  @override
  String get wisdom_018 => 'Fuglen lærer hunden. Du former reaktionen.';

  @override
  String get wisdom_019 => 'Stand er et øjeblik af balance.';

  @override
  String get wisdom_020 => 'Skynd dig ikke gennem stilheden.';

  @override
  String get wisdom_021 => 'Læs vinden før du læser hunden.';

  @override
  String get wisdom_022 => 'Terrænet træner hunden lige så meget.';

  @override
  String get wisdom_023 => 'Hver fugl er en ny lektion.';

  @override
  String get wisdom_024 => 'Dårlige forhold giver værdifuld erfaring.';

  @override
  String get wisdom_025 => 'Jagt er samarbejde, ikke konkurrence.';

  @override
  String get wisdom_026 => 'Modvind afslører kvalitet.';

  @override
  String get wisdom_027 => 'En tom runde kan indeholde masser af læring.';

  @override
  String get wisdom_028 => 'Lad hunden finde løsningen.';

  @override
  String get wisdom_029 => 'Fuglehundens styrke er selvstændighed med retning.';

  @override
  String get wisdom_030 => 'Marken husker alt.';

  @override
  String get wisdom_031 => 'Vær konsekvent, ikke perfekt.';

  @override
  String get wisdom_032 => 'Hunden spejler dit tempo.';

  @override
  String get wisdom_033 => 'Det du ikke reagerer på, accepterer du.';

  @override
  String get wisdom_034 => 'Klar tanke giver klar hund.';

  @override
  String get wisdom_035 => 'Retfærdighed slår strenghed.';

  @override
  String get wisdom_036 => 'Træn med hovedet før stemmen.';

  @override
  String get wisdom_037 => 'Forklar ikke. Vis.';

  @override
  String get wisdom_038 => 'En tryg fører giver en tryg hund.';

  @override
  String get wisdom_039 => 'Din ro er hundens ramme.';

  @override
  String get wisdom_040 => 'Lyt mere end du retter.';

  @override
  String get wisdom_041 => 'Relation bygges også uden fugl.';

  @override
  String get wisdom_042 => 'En god tur er aldrig spildt.';

  @override
  String get wisdom_043 => 'Tillid tager tid. Mistillid tager sekunder.';

  @override
  String get wisdom_044 => 'Hunden arbejder bedst for den, den stoler på.';

  @override
  String get wisdom_045 => 'Små rutiner giver stor tryghed.';

  @override
  String get wisdom_046 => 'Det må være ok at være bare hund indimellem.';

  @override
  String get wisdom_047 => 'Lekenhed er ikke udisciplin.';

  @override
  String get wisdom_048 => 'En tilfreds hund leverer bedre.';

  @override
  String get wisdom_049 => 'Samarbejde slår kontrol.';

  @override
  String get wisdom_050 => 'Fællesskab før færdigheder.';

  @override
  String get wisdom_051 => 'Prøve er øjebliksbillede, ikke facit.';

  @override
  String get wisdom_052 => 'Dommeren ser én dag. Du ser hele året.';

  @override
  String get wisdom_053 => 'Resultat er bonus, ikke mål.';

  @override
  String get wisdom_054 => 'En god oplevelse slår en god placering.';

  @override
  String get wisdom_055 => 'Press hjemme giver ro på prøve.';

  @override
  String get wisdom_056 => 'Træn situationer, ikke point.';

  @override
  String get wisdom_057 => 'En stabil hund er altid konkurrencedygtig.';

  @override
  String get wisdom_058 => 'Lær af det som ikke gik.';

  @override
  String get wisdom_059 => 'Prøver er træning med publikum.';

  @override
  String get wisdom_060 => 'Jag ikke på præmier, byg hund.';

  @override
  String get wisdom_061 => 'En fuglehund er aldrig færdiguddannet.';

  @override
  String get wisdom_062 => 'Vejen til standen er det, der tæller.';

  @override
  String get wisdom_063 => 'Tålmodighed lugter ikke af stress.';

  @override
  String get wisdom_064 => 'De bedste øjeblikke kan ikke logges.';

  @override
  String get wisdom_065 => 'Fuglehund handler om tillid i fart.';

  @override
  String get wisdom_066 => 'Stilhed er ofte svaret.';

  @override
  String get wisdom_067 => 'Naturen sætter altid rammerne.';

  @override
  String get wisdom_068 => 'En god dag i marken varer længe.';

  @override
  String get wisdom_069 => 'Hunden husker stemningen.';

  @override
  String get wisdom_070 => 'Jagt er samspil med landskabet.';

  @override
  String get wisdom_071 => 'En kort line i dag kan give lang ro i morgen.';

  @override
  String get wisdom_072 => 'Det, der belønnes, gentages.';

  @override
  String get wisdom_073 => 'Hold kravene små og byg dem store over tid.';

  @override
  String get wisdom_074 => 'Når du mister roen, mister du også læring.';

  @override
  String get wisdom_075 => 'En tydelig start gør slutningen nem.';

  @override
  String get wisdom_076 => 'Ro er ikke passivitet. Ro er kontrol.';

  @override
  String get wisdom_077 => 'Træn det kedelige. Det redder dagen.';

  @override
  String get wisdom_078 => 'En god føring er ofte usynlig.';

  @override
  String get wisdom_079 => 'Når hunden lykkes, har du været forudsigelig.';

  @override
  String get wisdom_080 => 'Jag ikke tempo. Jag kvalitet.';

  @override
  String get wisdom_081 => 'Giv hunden tid til at tænke færdigt.';

  @override
  String get wisdom_082 => 'Et nej uden vrede er mere værd end ti ja med stress.';

  @override
  String get wisdom_083 => 'Stop før du må stoppe.';

  @override
  String get wisdom_084 => 'Du træner altid, også når du bare går tur.';

  @override
  String get wisdom_085 => 'Fuglen afslører hullerne. Træn hullerne.';

  @override
  String get wisdom_086 => 'En god stop er starten på en god stand.';

  @override
  String get wisdom_087 => 'Let hånd giver tungt samarbejde.';

  @override
  String get wisdom_088 => 'Når noget går galt: sænk tempoet, øg tydeligheden.';

  @override
  String get wisdom_089 => 'En tryg rutine slår en perfekt plan.';

  @override
  String get wisdom_090 => 'Det vigtigste signal er det, du giver med kroppen.';

  @override
  String get settings_title => 'Indstillinger';

  @override
  String get settings_section_general => 'Generelt';

  @override
  String get settings_section_milestones => 'Milepæle';

  @override
  String get invitations_title => 'Invitationer';

  @override
  String get invitations_empty => 'Ingen ventende invitationer';

  @override
  String get settings_section_feedback => 'Feedback';

  @override
  String get supportEmail => 'support@gundogtracker.app';

  @override
  String get support_email => 'support@gundogtracker.app';

  @override
  String get settings_section_subscription => 'Abonnement';

  @override
  String get settings_section_language => 'Sprog';

  @override
  String get settings_section_community => 'Community';

  @override
  String get settings_section_security => 'Sikkerhed';

  @override
  String get settings_change_password_title => 'Skift adgangskode';

  @override
  String get settings_change_password_current_password => 'Nuværende adgangskode';

  @override
  String get settings_change_password_new_password => 'Ny adgangskode';

  @override
  String get settings_change_password_confirm_password => 'Bekræft ny adgangskode';

  @override
  String get settings_change_password_submit => 'Opdater adgangskode';

  @override
  String get settings_change_password_success => 'Adgangskoden er opdateret';

  @override
  String get settings_reset_password_button => 'Glemt adgangskode';

  @override
  String get settings_reset_password_sent => 'Tjek din e-mail for et link';

  @override
  String get settings_reset_password_no_email => 'Ingen e-mail tilgængelig til nulstilling';

  @override
  String get settings_change_password_error_fields => 'Udfyld alle felterne';

  @override
  String get settings_change_password_error_mismatch => 'Nyt kodeord og bekræftelse skal være ens';

  @override
  String get forgot_password_title => 'Glemt adgangskode';

  @override
  String get forgot_password_description => 'Indtast din e-mail, så sender vi et link, så du kan nulstille adgangskoden.';

  @override
  String get forgot_password_email_label => 'E-mail';

  @override
  String get forgot_password_button => 'Send nulstillingslink';

  @override
  String get forgot_password_error_missing => 'Indtast e-mail.';

  @override
  String get forgot_password_error_invalid => 'Indtast en gyldig e-mail.';

  @override
  String get forgot_password_check_spam_hint => 'Tjek din indbakke. Hvis du ikke finder e-mailen, tjek spam/søppelpost.';

  @override
  String get signup_title => 'Opret konto';

  @override
  String get signup_intro => 'Opret konto med e-mail og adgangskode for at komme i gang.';

  @override
  String get signup_email_label => 'E-mail';

  @override
  String get signup_password_label => 'Adgangskode';

  @override
  String get signup_password_repeat_label => 'Gentag adgangskode';

  @override
  String get signup_create_button => 'Opret konto';

  @override
  String get signup_success => 'Kontoen er oprettet.';

  @override
  String get signup_error_email_in_use => 'Denne e-mailadresse er allerede i brug.';

  @override
  String get signup_error_invalid_email => 'Indtast en gyldig e-mailadresse.';

  @override
  String get signup_error_weak_password => 'Adgangskoden skal være mindst 6 tegn.';

  @override
  String get signup_error_operation_not_allowed => 'Det er ikke muligt at oprette konto lige nu.';

  @override
  String get signup_error_network => 'Tjek internettet og prøv igen.';

  @override
  String get signup_error_generic => 'Kunne ikke oprette konto lige nu.';

  @override
  String get signup_validation_email_missing => 'Indtast e-mail.';

  @override
  String get signup_validation_email_invalid => 'Indtast en gyldig e-mail.';

  @override
  String get signup_validation_password_missing => 'Indtast adgangskode.';

  @override
  String get signup_validation_password_short => 'Adgangskoden skal være mindst 6 tegn.';

  @override
  String get signup_validation_password_repeat_missing => 'Gentag adgangskoden.';

  @override
  String get signup_validation_password_mismatch => 'Adgangskoderne matcher ikke.';

  @override
  String get settings_backup_import_success => 'Backup importeret';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Lys';

  @override
  String get settings_theme_dark => 'Mørk';

  @override
  String get settings_language_title => 'Sprog';

  @override
  String get settings_language_followSystem => 'Følg systemet';

  @override
  String get settings_language_nb => 'Norsk (bokmål)';

  @override
  String get settings_language_sv => 'Svensk';

  @override
  String get settings_language_da => 'Dansk';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_milestones_enabled_title => 'Milepæle';

  @override
  String get settings_milestones_enabled_subtitle => 'Vis små øjeblikke når hunden når vigtige skridt.';

  @override
  String get settings_milestones_goal_title => 'Milepælsmål';

  @override
  String get settings_milestones_goal_subtitle => 'Indstil sæson- og personlige mål for standpoint.';

  @override
  String get settings_milestones_season_goal_title => 'Sæsonmål (standpoint)';

  @override
  String get settings_milestones_personal_goal_title => 'Personligt mål (standpoint)';

  @override
  String milestone_goal_achieved(String dogName, String goalTitle) {
    return '$dogName nåede $goalTitle!';
  }

  @override
  String get settings_haptics_enabled_title => 'Vibration ved milepæle';

  @override
  String get settings_haptics_enabled_subtitle => 'Diskret vibration når milepæle opnås.';

  @override
  String get settings_restore_in_progress => 'Gendannelse pågår… vent venligst.';

  @override
  String get settings_section_backup => 'Sikkerhedskopi';

  @override
  String get settings_backup_export_action => 'Eksporter backup (ZIP)';

  @override
  String get settings_backup_exporting => 'Eksporterer…';

  @override
  String get settings_backup_subtitle => 'Eksporter/importer hunde, sessioner, spor, milepæle og medier.';

  @override
  String get settings_backup_import_action => 'Importer backup (ZIP)';

  @override
  String get settings_backup_importing => 'Importer…';

  @override
  String get settings_backup_import_description => 'Vælg en backup-ZIP og genskab data.';

  @override
  String get settings_backup_where_title => 'Hvor gemmes backup?';

  @override
  String get settings_backup_where_action => 'Vis lagringsmappe';

  @override
  String get settings_backup_status_collectingData => 'Indsamler data…';

  @override
  String get settings_backup_status_collectingMedia => 'Indsamler medier…';

  @override
  String get settings_backup_status_creatingZip => 'Opretter ZIP…';

  @override
  String get settings_backup_status_sharing => 'Deler…';

  @override
  String get settings_backup_status_selectZip => 'Vælg ZIP…';

  @override
  String get settings_backup_status_restoring => 'Gendanner data…';

  @override
  String get settings_backup_share_subject => 'Fuglehund backup';

  @override
  String settings_backup_ready(Object fileName) {
    return 'Backup klar: $fileName ✅';
  }

  @override
  String settings_backup_failed(Object message) {
    return 'Backup mislykkedes: $message';
  }

  @override
  String get auth_profile_pending_title => 'Opretter profil…';

  @override
  String get auth_profile_pending_body => 'Vi venter på, at backend-dokumentet er klart. Tryk på \"Prøv igen\" for at tjekke igen.';

  @override
  String get auth_loading_waiting => 'Gør log ind klar…';

  @override
  String get auth_profile_load_failed_title => 'Kunne ikke indlæse din profil';

  @override
  String get auth_profile_load_failed_body => 'Prøv igen om et øjeblik. Hvis problemet fortsætter, kan du lukke og åbne appen igen.';

  @override
  String get auth_profile_timeout_error => 'Kan ikke finde brugerprofilen inden for kort tid. Tjek netværket eller prøv igen.';

  @override
  String get settings_backup_failed_unknown => 'Ukendt fejl.';

  @override
  String settings_backup_import_failed(Object message) {
    return 'Import mislykkedes: $message';
  }

  @override
  String get settings_backup_restore_dialog_title => 'Importer backup';

  @override
  String get settings_backup_restore_dialog_content => 'Dette gendanner data fra en ZIP-backup.\n\nTip: Efter import kan det være en god idé at genstarte appen.';

  @override
  String get settings_backup_restore_dialog_confirm => 'Importer';

  @override
  String get settings_backup_restore_prompt_title => 'Gendannelse færdig';

  @override
  String get settings_backup_restore_prompt_message => 'Gendannelsen er fuldført. Genstart appen nu?';

  @override
  String get settings_backup_restore_saved => 'Gendannelsen er gemt. Genstart appen når det passer.';

  @override
  String get settings_backup_restore_complete => 'Import færdig';

  @override
  String get settings_backup_storage_title => 'Backup-lagring';

  @override
  String settings_backup_storage_description(String path) {
    return 'Backup-filer gemmes her:\n\n$path';
  }

  @override
  String get settings_backup_restore_pending => 'Importer backup…';

  @override
  String get settings_backup_restore_pending_message => 'Gendanner backup… vent venligst.';

  @override
  String get settings_section_appearance => 'Udseende';

  @override
  String get settings_season_title => 'Sæsontema';

  @override
  String get settings_season_subtitle => 'Farver for top og bund.';

  @override
  String get settings_season_auto => 'Automatisk';

  @override
  String get settings_season_spring => '🌱 Forår';

  @override
  String get settings_season_summer => '☀️ Sommer';

  @override
  String get settings_season_autumn => '🍁 Efterår';

  @override
  String get settings_season_winter => '❄️ Vinter';

  @override
  String get settings_feedback_send_subtitle => 'Åbner e-mail med appinfo.';

  @override
  String get settings_feedback_bug_subtitle => 'Åbner e-mail med fejlskabelon.';

  @override
  String get settings_feedback_copy_subtitle => 'Kopierer app- og enhedsinfo.';

  @override
  String get settings_feedback_suggest_subtitle => 'Send forslag via e-mail.';

  @override
  String get settings_feedback_error_open_email => 'Kunne ikke åbne e-mail.';

  @override
  String get settings_feedback_error_copy => 'Kunne ikke kopiere.';

  @override
  String get settings_diagnostics_section_title => 'Diagnostik';

  @override
  String get settings_diagnostics_title => 'Avanceret diagnostik';

  @override
  String get settings_diagnostics_subtitle => 'Værktøjer til fejlsøgning og support.';

  @override
  String get settings_diagnostics_outbox_label => 'Outbox';

  @override
  String get settings_diagnostics_count_pending => 'Venter';

  @override
  String get settings_diagnostics_count_inProgress => 'I gang';

  @override
  String get settings_diagnostics_count_failed => 'Mislykket';

  @override
  String get settings_diagnostics_count_sent => 'Sendt';

  @override
  String get settings_diagnostics_action_dog_restore_title => 'Hent hunde igen';

  @override
  String get settings_diagnostics_action_dog_restore_subtitle => 'Henter tilgængelige hunde fra skyen til lokal lagring.';

  @override
  String get settings_diagnostics_action_session_fetch_title => 'Tjek sessioner i skyen';

  @override
  String get settings_diagnostics_action_session_fetch_subtitle => 'Henter sessioner for den første hund, der er koblet til skyen.';

  @override
  String get settings_diagnostics_action_session_restore_title => 'Læg sessioner tilbage lokalt';

  @override
  String get settings_diagnostics_action_session_restore_subtitle => 'Lagrer sessioner fra skyen lokalt for den første tilkoblede hund.';

  @override
  String get settings_diagnostics_action_process_outbox_title => 'Kør synkkø nu';

  @override
  String get settings_diagnostics_action_process_outbox_subtitle => 'Behandler ventende synkopgaver én gang.';

  @override
  String get settings_diagnostics_action_retry_outbox_title => 'Nulstil mislykkede synkopgaver';

  @override
  String get settings_diagnostics_action_retry_outbox_subtitle => 'Sætter mislykkede synkopgaver tilbage i kø til et nyt forsøg.';

  @override
  String get settings_diagnostics_missing_cloud_dog => 'Fandt ingen lokal hund, der er koblet til skyen.';

  @override
  String settings_diagnostics_dog_restore_success(Object count) {
    return 'Hundedata hentet igen: $count';
  }

  @override
  String settings_diagnostics_dog_restore_failed(Object error) {
    return 'Kunne ikke hente hundedata igen: $error';
  }

  @override
  String settings_diagnostics_session_fetch_success(Object count) {
    return 'Fandt $count sessioner i skyen.';
  }

  @override
  String settings_diagnostics_session_fetch_failed(Object error) {
    return 'Kunne ikke hente sessioner fra skyen: $error';
  }

  @override
  String settings_diagnostics_session_restore_success(Object count) {
    return 'Lagde $count sessioner tilbage lokalt.';
  }

  @override
  String settings_diagnostics_session_restore_failed(Object error) {
    return 'Kunne ikke lægge sessioner tilbage lokalt: $error';
  }

  @override
  String get settings_diagnostics_outbox_process_success => 'Synkkøen blev behandlet.';

  @override
  String settings_diagnostics_outbox_process_failed(Object error) {
    return 'Kunne ikke behandle synkkøen: $error';
  }

  @override
  String settings_diagnostics_retry_success(Object count) {
    return 'Nulstillede $count synkopgaver.';
  }

  @override
  String settings_diagnostics_retry_failed(Object error) {
    return 'Kunne ikke nulstille synkopgaver: $error';
  }

  @override
  String get settings_sign_out_button => 'Log ud';

  @override
  String get settings_sign_out_success => 'Du er logget ud.';

  @override
  String get settings_sign_out_failed => 'Kunne ikke logge ud lige nu.';

  @override
  String get settings_sound_on_app_start_title => 'Lyd ved opstart';

  @override
  String get settings_sound_on_app_start_subtitle => 'Afspil rype-lyd når appen starter';

  @override
  String get settings_sound_on_milestone_title => 'Lyd ved milepæle';

  @override
  String get settings_sound_on_milestone_subtitle => 'Afspil lyd når du opnår en milepæl';

  @override
  String get milestones_achieved_title => 'Opnåede milepæle';

  @override
  String get milestones_achieved_empty => 'Ingen milepæle endnu.';

  @override
  String milestones_achieved_duration(String duration) {
    return 'Opnået $duration';
  }

  @override
  String get milestone_sheet_button_ok => 'Fint!';

  @override
  String get milestone_sheet_button_viewAll => 'Se milepæle';

  @override
  String get milestone_snackbar_new_title => 'Ny milepæl!';

  @override
  String get milestone_snackbar_open_error => 'Kunne ikke åbne milepæl';

  @override
  String milestone_stands_count_subtitle(Object dogName, Object countText) {
    return '$dogName har registreret $countText.';
  }

  @override
  String milestone_sessions_count_subtitle(Object dogName, Object countText) {
    return '$dogName har logget $countText.';
  }

  @override
  String milestone_birds_count_subtitle(Object dogName, Object countText) {
    return '$dogName har nedlagt $countText.';
  }

  @override
  String get milestone_first_point_title => 'Første stand';

  @override
  String milestone_first_point_subtitle(String dogName) {
    return '$dogName har registreret sin første stand.';
  }

  @override
  String get milestone_first_flush_title => 'Første støk';

  @override
  String milestone_first_flush_subtitle(String dogName) {
    return '$dogName har registreret sit første støk.';
  }

  @override
  String get milestone_sessions_10_title => '10 ture';

  @override
  String milestone_sessions_10_subtitle(String dogName) {
    return '$dogName har logget 10 ture.';
  }

  @override
  String get milestone_active_hours_10_title => '10 timer aktiv';

  @override
  String milestone_active_hours_10_subtitle(String dogName) {
    return '$dogName har passeret 10 timer aktiv tid.';
  }

  @override
  String get milestone_section_birds_down_title => 'Fældet fugl';

  @override
  String get milestone_dog_fallback_name => 'Hunden';

  @override
  String milestone_achieved_sentence(Object dog, Object milestone, Object date, Object age) {
    return '$dog opnåede “$milestone” $date$age';
  }

  @override
  String milestone_bird_threshold_label(Object threshold) {
    return '$threshold. fugl';
  }

  @override
  String get milestone_bird_label => 'Fugl';

  @override
  String milestone_century_points_title(int count) {
    return '$count stand';
  }

  @override
  String milestone_century_points_subtitle(String dogName, int count) {
    return '$dogName har passeret $count stand.';
  }

  @override
  String get subscription_title => 'Abonnement';

  @override
  String get subscription_status_label => 'Status';

  @override
  String get subscription_status_active => 'Aktivt';

  @override
  String get subscription_status_inactive => 'Ikke aktivt';

  @override
  String get subscription_status_unknown => 'Ukendt';

  @override
  String get subscription_product_title => 'Fuglehund Pro';

  @override
  String get subscription_description => 'Lås op for ubegrænset antal hunde og ubegrænset antal sessioner.';

  @override
  String get subscription_benefit_unlimited_dogs => 'Ubegrænset antal hunde';

  @override
  String get subscription_benefit_unlimited_sessions => 'Ubegrænset antal sessioner';

  @override
  String get subscription_price_unavailable => 'Pris utilgængelig';

  @override
  String get subscription_subscribe_button => 'Opgrader til Pro';

  @override
  String get subscription_restore_button => 'Gendan køb';

  @override
  String get subscription_manage_button => 'Administrer / Opsig';

  @override
  String get subscription_purchase_success => 'Pro er nu aktivt.';

  @override
  String get subscription_purchase_cancelled => 'Købet blev annulleret.';

  @override
  String get subscription_restore_success => 'Gendannelse er startet.';

  @override
  String get subscription_limit_dogs_reached => 'Gratisversionen er fuld for hunde. Opgrader til Pro for at tilføje flere.';

  @override
  String get subscription_limit_sessions_reached => 'Gratisversionen er fuld for sessioner. Opgrader til Pro for at gemme flere.';

  @override
  String get subscription_error_load_status => 'Kunne ikke hente abonnementsstatus lige nu.';

  @override
  String get subscription_error_purchase_start => 'Kunne ikke starte købet lige nu.';

  @override
  String get subscription_error_product_unavailable => 'Produktet er ikke tilgængeligt i butikken lige nu.';

  @override
  String get subscription_error_restore_purchase => 'Kunne ikke gendanne køb lige nu.';

  @override
  String get subscription_error_manage_open => 'Kunne ikke åbne abonnementssiden.';

  @override
  String get feedback_send_title => 'Send feedback';

  @override
  String get feedback_bug_title => 'Rapportér en fejl';

  @override
  String get feedback_copy_diagnostics_title => 'Kopiér diagnostik';

  @override
  String get feedback_suggest_milestone_title => 'Foreslå milepæl';

  @override
  String get feedback_email_body_intro => 'Beskriv din feedback her.';

  @override
  String get feedback_bug_prompt => 'Hvad skete der?';

  @override
  String get feedback_bug_reproduce => 'Hvordan kan vi genskabe problemet?';

  @override
  String get feedback_suggest_title => 'Forslag til ny milepæl:';

  @override
  String get feedback_suggest_question_what_to_celebrate => 'Hvad bør fejres?';

  @override
  String get feedback_suggest_question_why_important => 'Hvorfor er dette vigtigt i praksis?';

  @override
  String get feedback_suggest_question_when_should_trigger => 'Hvornår bør den udløses?';

  @override
  String get feedback_suggest_trigger_hint => '(første gang, hver 10., hver 100., andet)';

  @override
  String get feedback_suggest_comments => 'Eventuelle kommentarer:';

  @override
  String get feedback_error_email_not_available => 'Ingen e-mail-app er tilgængelig.';

  @override
  String get community_open_discord => 'Åbn Discord-gruppe';

  @override
  String get community_open_facebook => 'Åbn Facebook-gruppe';

  @override
  String get home_continueActiveSessionTitle => 'Fortsæt aktiv session';

  @override
  String home_continueActiveSessionSubtitle(String dogName) {
    return 'Ufuldført session for $dogName.';
  }

  @override
  String get home_continueActiveSessionMissingDogTitle => 'Aktiv session kan ikke gendannes';

  @override
  String get home_continueActiveSessionMissingDogSubtitle => 'Hunden er ikke længere tilgængelig. Du kan forkaste udkastet.';

  @override
  String get home_continueActiveSessionButton => 'Fortsæt aktiv session';

  @override
  String get home_discardActiveSessionButton => 'Forkast';

  @override
  String get home_discardActiveSessionSnackbar => 'Forkastet aktiv session';

  @override
  String get home_endActiveSessionButton => 'Afslut aktiv session';

  @override
  String get home_endActiveSessionConfirmTitle => 'Afslut aktiv session?';

  @override
  String get home_endActiveSessionConfirmSubtitle => 'Alt mistes, hvis du afslutter. Er du sikker?';

  @override
  String get milestones_category_firsts => 'Første gang';

  @override
  String get milestones_category_sessions => 'Økter';

  @override
  String get milestones_category_points => 'Stand';

  @override
  String get milestones_category_time => 'Tid';

  @override
  String get milestones_category_contacts => 'Kontakter';

  @override
  String birdsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fugle',
      one: '1 fugl',
      zero: '0 fugle',
    );
    return '$_temp0';
  }

  @override
  String birdsDownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedlagte fugle',
      one: '1 nedlagt fugl',
      zero: '0 nedlagte fugle',
    );
    return '$_temp0';
  }
}
