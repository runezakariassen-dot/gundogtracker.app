// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'Fuglehund';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Stäng';

  @override
  String get common_done => 'Klart';

  @override
  String get common_cancel => 'Avbryt';

  @override
  String get common_save => 'Spara';

  @override
  String get common_copy => 'Kopiera';

  @override
  String get common_copied => 'Kopierat ✅';

  @override
  String get common_comingSoon => 'Kommer snart.';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nej';

  @override
  String get common_invalid_link => 'Ogiltig länk';

  @override
  String get common_could_not_open_link => 'Kunde inte öppna länken';

  @override
  String get common_unknown => 'Okänd';

  @override
  String get common_unknown_email => 'Okänd e-post';

  @override
  String get common_unknown_member => 'Okänt medlem';

  @override
  String get common_no_permission => 'Du har inte behörighet till det här.';

  @override
  String get common_retry => 'Försök igen';

  @override
  String get age_unknown => 'Ålder okänd';

  @override
  String get boot_error_title => 'Starten misslyckades';

  @override
  String boot_error_body(Object message) {
    return 'Se terminalen för detaljer.\n$message';
  }

  @override
  String get boot_error_unknown => 'Okänt fel';

  @override
  String get boot_restore_title => 'Återställer backup…';

  @override
  String get boot_restore_body => 'Stäng inte appen.\n\nVi blockerar åtkomst till data medan återställningen pågår för att undvika Hive-fel.';

  @override
  String get boot_restart_title => 'Backup återställd ✅';

  @override
  String get boot_restart_body => 'Appen stängs nu så ändringarna kan laddas.\n\nÖppna appen igen efteråt.';

  @override
  String get qr_scan_title => 'Skanna QR';

  @override
  String get home_title => 'Hem';

  @override
  String get home => 'Hem';

  @override
  String get sessions => 'Pass';

  @override
  String get statistics => 'Statistik';

  @override
  String stats_week_label(int week) {
    return 'Vecka $week';
  }

  @override
  String get common_conjunction_and => 'och';

  @override
  String stats_stands_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stander',
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
      other: '$count fåglar',
      one: '$count fågel',
    );
    return '$_temp0';
  }

  @override
  String stats_flushes_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stöt',
      one: '$count stöt',
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
      other: '$count månader',
      one: '$count månad',
    );
    return '$_temp0';
  }

  @override
  String common_days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get common_months_short => 'mån';

  @override
  String get stats_screen_title => 'Statistik';

  @override
  String get stats_period_daily => 'Dagligen';

  @override
  String get stats_period_weekly => 'Veckovis';

  @override
  String get stats_period_monthly => 'Månatligen';

  @override
  String get stats_no_sessions_registered => 'Inga sessioner registrerade ännu';

  @override
  String get stats_filter_all_dogs => 'Alla hundar';

  @override
  String get stats_filter_dynamic_period => 'Dynamisk period';

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
      other: '$count poäng mer',
      one: '$count poäng mer',
    );
    return '$_temp0';
  }

  @override
  String stats_trend_point_label(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get dogs => 'Hundar';

  @override
  String get dog_sex_male => 'Hanhund';

  @override
  String get dog_sex_female => 'Tik';

  @override
  String get dog_unnamed => 'Namnlös';

  @override
  String dog_subtitle_born_prefix(String date) {
    return 'Född: $date';
  }

  @override
  String get dog_editor_error_name_missing => 'Namn saknas';

  @override
  String get dog_editor_save => 'Spara';

  @override
  String get dog_editor_saving => 'Sparar…';

  @override
  String get dog_editor_delete_dog => 'Radera hund';

  @override
  String get dog_editor_deleting => 'Raderar…';

  @override
  String get dog_editor_delete_dog_title => 'Radera hund';

  @override
  String get dog_editor_delete_dog_body => 'Vill du radera hunden? Det går inte att ångra.';

  @override
  String get dog_editor_button_cancel => 'Avbryt';

  @override
  String get dog_editor_button_delete => 'Radera';

  @override
  String get dog_editor_new_breed_title => 'Ny ras';

  @override
  String get dog_editor_new_breed_hint => 'T.ex. Gordon setter';

  @override
  String get dog_editor_button_add => 'Lägg till';

  @override
  String get dog_editor_select_breed_label => 'Välj ras';

  @override
  String get dog_editor_select_breed_placeholder => 'Välj ras';

  @override
  String get dog_editor_new_breed_option => 'Ny ras…';

  @override
  String get dog_editor_name_label => 'Namn';

  @override
  String get dog_editor_nickname_label => 'Smeknamn';

  @override
  String get dog_editor_nickname_hint => 'Valfritt (t.ex. Zoë, Bowie)';

  @override
  String get dog_editor_birthdate_label => 'Födelsedatum';

  @override
  String get dog_editor_birthdate_not_set => 'Inte valt';

  @override
  String get dog_editor_regnr_label => 'Reg.nr';

  @override
  String get dog_editor_pedigree_url_label => 'Stamtavle-URL';

  @override
  String get dog_editor_memory_words_label => 'Minnesord';

  @override
  String get dog_editor_image_text_anchor_label => 'Textplacering på bild';

  @override
  String get dog_editor_death_registered_title => 'Registrerad död';

  @override
  String get dog_editor_section_breed_title => 'Ras';

  @override
  String get dog_editor_section_sex => 'Kön';

  @override
  String get dog_editor_role_section_title => 'Välj roll';

  @override
  String get dog_editor_role_owner => 'Ägare';

  @override
  String get dog_editor_role_admin => 'Administratör';

  @override
  String get dog_editor_role_user => 'Användare';

  @override
  String get dog_editor_section_hero_title => 'Hero-text';

  @override
  String get dog_editor_anchor_bottom_left => 'Nederst till vänster';

  @override
  String get dog_editor_anchor_bottom_center => 'Nederst centrerad';

  @override
  String get dog_editor_anchor_top_left => 'Överst till vänster';

  @override
  String get dog_editor_text_size_label => 'Textstorlek';

  @override
  String get dog_editor_text_size_small => 'Liten';

  @override
  String get dog_editor_text_size_normal => 'Normal';

  @override
  String get dog_editor_text_size_large => 'Stor';

  @override
  String get dog_editor_section_lifecycle_title => 'Livscykel';

  @override
  String get dog_editor_death_date_label => 'Dödsdatum';

  @override
  String get dog_editor_death_date_picker_hint => 'Välj datum';

  @override
  String get dog_detail_snackbar_invite_accepted => 'Inbjudan accepterad';

  @override
  String get dog_detail_snackbar_invite_declined => 'Inbjudan avvisad';

  @override
  String get dog_detail_snackbar_invite_sent => 'Inbjudan skickad';

  @override
  String get dog_detail_snackbar_ownership_accepted => 'Ägarskap accepterat';

  @override
  String get dog_detail_snackbar_request_declined => 'Förfrågan avvisad';

  @override
  String get dog_detail_snackbar_request_cancelled => 'Förfrågan avbruten';

  @override
  String get dog_detail_snackbar_image_save_failed => 'Kunde inte spara bilden.';

  @override
  String get dog_detail_snackbar_pedigree_invalid => 'Stamtavle-länken är ogiltig eller kan inte öppnas.';

  @override
  String get dog_detail_photo_source_gallery => 'Välj från bilder';

  @override
  String get dog_detail_photo_source_camera => 'Ta bild';

  @override
  String get dog_detail_button_cancel => 'Avbryt';

  @override
  String get dog_detail_pedigree_section_title => 'Stamtavle';

  @override
  String get dog_detail_button_open_pedigree => 'Öppna stamtavle';

  @override
  String get dog_pedigree_no_link => 'Ingen länk registrerad';

  @override
  String get dog_detail_appbar_title => 'Hundprofil';

  @override
  String get dog_detail_error_dog_not_found => 'Hunden hittades inte';

  @override
  String get dog_detail_title_add_dog => 'Lägg till hund';

  @override
  String get dog_editor_title_add_dog => 'Lägg till hund';

  @override
  String get dog_editor_title_edit_dog => 'Redigera hund';

  @override
  String get dog_profile_title => 'Hund';

  @override
  String get dog_profile_subtitle_breed_age => 'Ras · Ålder';

  @override
  String get dog_generic_name => 'Hund';

  @override
  String get dog_detail_section_access => 'Åtkomster';

  @override
  String get dog_detail_button_send_invite => 'Skicka inbjudan';

  @override
  String get dog_detail_section_invites => 'Inbjudningar';

  @override
  String get invite_send_email_label => 'Mottagarens e-post';

  @override
  String get invite_send_button => 'Skicka inbjudan';

  @override
  String invite_sent_to(Object email) {
    return 'Inbjudan skickad till $email';
  }

  @override
  String get invite_revoke_button => 'Återkalla';

  @override
  String get invite_status_invited => 'Inbjuden';

  @override
  String invite_status_invited_as_user(Object role) {
    return 'Inbjuden som $role';
  }

  @override
  String get invite_accept => 'Acceptera';

  @override
  String get invite_decline => 'Avslå';

  @override
  String get dog_share_section_title => 'Delat med';

  @override
  String get dog_detail_access_section_title => 'Åtkomst till den här hunden';

  @override
  String get dog_detail_member_action_set_reader => 'Sätt som läsare';

  @override
  String get dog_detail_member_action_set_user => 'Sätt som användare';

  @override
  String get dog_detail_member_action_remove_access => 'Ta bort åtkomst';

  @override
  String get share_role_owner => 'Ägare';

  @override
  String get share_role_admin => 'Administratör';

  @override
  String get share_role_user => 'Användare';

  @override
  String get dog_detail_share_empty => 'Inga inbjudningar';

  @override
  String get dog_detail_share_empty_owner => 'Ingen delning ännu.';

  @override
  String dog_detail_my_role_label(String role) {
    return 'Din roll: $role';
  }

  @override
  String get dog_detail_share_disabled_explanation => 'Du har inte rätt att dela den här hunden.';

  @override
  String get share_accept_title => 'Acceptera delning';

  @override
  String get share_accept_code_label => 'Delningskod';

  @override
  String get share_accept_scan_qr => 'Skanna QR';

  @override
  String get share_accept_button => 'Acceptera';

  @override
  String get share_error_dialog_title => 'Delning misslyckades';

  @override
  String get share_error_not_owner => 'Endast ägaren eller en administratör kan dela hunden.';

  @override
  String get share_error_invite_not_found => 'Inbjudan hittades inte.';

  @override
  String get share_error_invite_expired => 'Inbjudan har gått ut.';

  @override
  String get share_error_invite_revoked => 'Inbjudan har återkallats.';

  @override
  String get share_error_invite_inactive => 'Inbjudan är inte aktiv.';

  @override
  String get share_error_already_has_access => 'Du har redan åtkomst.';

  @override
  String get share_error_invalid_role => 'Ogiltig roll.';

  @override
  String get share_error_invalid_email => 'Ogiltig e-postadress.';

  @override
  String get share_error_dog_not_found_title => 'Hund hittades inte';

  @override
  String get share_error_dog_not_found_detail => 'Ingen hund matchar den här koden.';

  @override
  String get transfer_error_not_owner => 'Endast ägaren kan avslå förfrågan.';

  @override
  String get transfer_error_not_recipient => 'Du är inte mottagare av denna förfrågan.';

  @override
  String get transfer_error_not_found => 'Förfrågan hittades inte.';

  @override
  String get transfer_error_expired => 'Förfrågan har gått ut.';

  @override
  String get transfer_error_not_pending => 'Förfrågan är inte aktiv.';

  @override
  String get transfer_error_cannot_transfer_to_self => 'Kan inte överföra till sig själv.';

  @override
  String get transfer_error_cancelled => 'Förfrågan har redan avslagits.';

  @override
  String get role_owner => 'Ägare';

  @override
  String get role_editor => 'Redigerare';

  @override
  String get role_viewer => 'Läsare';

  @override
  String get role_admin => 'Administratör';

  @override
  String get dog_editor_owner_email_label => 'Ägarens e-post';

  @override
  String get dog_editor_owner_email_hint => 'namn@exempel.se';

  @override
  String get dog_editor_owner_email_required_error => 'Ange en giltig e-post för ägaren.';

  @override
  String get dog_detail_section_owner_request_title => 'Ägarskap begärt';

  @override
  String dog_detail_label_from_user(String userId) {
    return 'Från: $userId';
  }

  @override
  String dog_detail_label_to_user(String userId) {
    return 'Till: $userId';
  }

  @override
  String get dog_detail_button_accept => 'Acceptera';

  @override
  String get dog_detail_button_decline => 'Avslå';

  @override
  String get dog_detail_button_cancel_request => 'Avbryt förfrågan';

  @override
  String get dog_detail_button_edit_photo => 'Ändra profilbild';

  @override
  String get dog_detail_button_mark_dead => 'Markera som död';

  @override
  String get dog_detail_label_death_date => 'Dödsdatum';

  @override
  String get dog_detail_button_edit => 'Ändra';

  @override
  String get dog_detail_button_register_death => 'Registrera';

  @override
  String get dog_detail_photo_dialog_title => 'Profilbild';

  @override
  String get dog_detail_photo_pick_camera => 'Ta bild';

  @override
  String get dog_detail_photo_pick_gallery => 'Välj från bilder';

  @override
  String get dog_detail_photo_remove => 'Ta bort bild';

  @override
  String get dog_detail_snackbar_photo_updated => 'Profilbild uppdaterat';

  @override
  String get dog_detail_snackbar_photo_removed => 'Profilbild borttaget';

  @override
  String get dog_detail_snackbar_error_generic => 'Något gick fel';

  @override
  String get dog_detail_info_label_sex => 'Kön';

  @override
  String get dog_detail_info_label_born => 'Född';

  @override
  String get dog_detail_summary_points_label => 'Poäng';

  @override
  String get dog_detail_summary_session_count_label => 'Antal pass';

  @override
  String get dog_detail_summary_active_time_label => 'Aktiv tid';

  @override
  String get dog_detail_summary_birds_down_label => 'Fälld fågel';

  @override
  String get dog_detail_summary_first_session_label => 'Första passet';

  @override
  String get dog_detail_summary_last_session_label => 'Senaste passet';

  @override
  String get dog_detail_tooltip_edit_profile => 'Redigera hund';

  @override
  String get dog_detail_farewell_prefix => 'Avsked';

  @override
  String dog_detail_farewell_age_sentence(Object name, Object years, Object months, Object days) {
    return '$name blev $years $months $days gammal';
  }

  @override
  String get dog_detail_next_milestones_title => 'Nästa milstolpar';

  @override
  String get dog_detail_next_milestone_title => 'Nästa milstolpe';

  @override
  String get milestone_first_session_title => 'Första passet genomfört';

  @override
  String milestone_first_session_subtitle(Object dogName) {
    return 'Första passet med $dogName';
  }

  @override
  String get milestone_first_bird_title => 'Första fågel';

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
      other: '$count mån',
      one: '$count mån',
    );
    return '$_temp0';
  }

  @override
  String age_months_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mån',
      one: '$count mån',
    );
    return '$_temp0';
  }

  @override
  String age_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get age_zero_days => '0 dagar';

  @override
  String get age_and => 'och';

  @override
  String get home_startNewSession => 'Starta nytt pass';

  @override
  String get chooseDog => 'Välj hund';

  @override
  String get noDogsAddDog => 'Inga hundar – lägg till hund';

  @override
  String get home_addDogPrompt => 'Lägg till hund för att starta ett pass';

  @override
  String get home_empty_title => 'Starta resan med din jakthund';

  @override
  String get home_empty_body => 'Logga sessioner, följ utvecklingen och bygg en historik för din hund – session för session.';

  @override
  String get home_empty_bullet_progress => 'Se utvecklingen över tid – stånd, flykt och aktivitet.';

  @override
  String get home_empty_bullet_training => 'Bättre träning och jakt – se vad som faktiskt ger utdelning.';

  @override
  String get home_empty_bullet_history => 'Jakthistorik du faktiskt använder – säsong för säsong, område för område.';

  @override
  String get home_visible_empty_title => 'Inga hundar tillgängliga';

  @override
  String get home_visible_empty_body => 'Det här kontot har inga hundar ännu. Kolla inbjudningar eller be någon dela en hund med dig.';

  @override
  String get home_visible_empty_button => 'Öppna inbjudningar';

  @override
  String get home_addDog_button => 'Lägg till hund';

  @override
  String get home_empty_offline_note => 'Du kan använda appen helt offline. All data sparas lokalt på din telefon.';

  @override
  String get home_noDogsRegistered => 'Inga hundar registrerade';

  @override
  String get home_primaryActionSubtitle => 'Anteckningar först. Använd + i fälten.';

  @override
  String get home_top10_points_title => 'Topp 10 – Stand';

  @override
  String get top10Title => 'Topp 10';

  @override
  String get home_top10_points_empty => 'Inga stånd registrerade ännu.';

  @override
  String home_top10_points_pointsLabel(int count) {
    return 'Stand: $count';
  }

  @override
  String top10_points_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stånd',
      one: 'stånd',
    );
    return '$_temp0';
  }

  @override
  String get home_top10_birds_title => 'Topp 10 fågel';

  @override
  String get home_top10_birds_empty => 'Inga fåglar registrerade ännu.';

  @override
  String get home_top10_birds_fieldLabel => 'Fågel';

  @override
  String get session_log_title => 'Passlogg – Jakthund';

  @override
  String get session_saved_list_title => 'Sparade pass';

  @override
  String get session_save_button => 'Spara session';

  @override
  String get session_unit_min => 'min';

  @override
  String get session_unit_sec => 'sek';

  @override
  String get session_label_points => 'stånd';

  @override
  String get session_label_flushes => 'stöt';

  @override
  String get session_label_birds => 'fågel';

  @override
  String get session_label_birds_down => 'fältfågel';

  @override
  String get session_all_dogs_label => 'Alla hundar';

  @override
  String get session_map_label => 'Karta';

  @override
  String get session_map_error_no_tracks => 'Hittade inga spår';

  @override
  String get session_map_error_map_load_failed => 'Kunde inte ladda kartan';

  @override
  String get map_page_snackbar_no_tracks_to_focus => 'Inga spår att fokusera på';

  @override
  String get map_page_dialog_delete_downloaded_map_body => 'Vill du ta bort den här nedladdade kartan?';

  @override
  String get hunt_session_snackbar_export_ready_opening_share => 'Export klar, öppnar delning …';

  @override
  String get hunt_session_snackbar_gpx_export_failed_see_log => 'GPX-export misslyckades. Se logg.';

  @override
  String get session_gpx_import_label => 'Importera GPX';

  @override
  String get session_gpx_importing_ellipsis => 'Importerar…';

  @override
  String get session_gpx_export_label => 'Exportera GPX';

  @override
  String get session_gpx_exporting_ellipsis => 'Exporterar…';

  @override
  String get session_form_dog_section_title => 'Hund';

  @override
  String get session_form_dog_prefix => 'Hund:';

  @override
  String get session_form_no_dogs_registered => 'Inga hundar registrerade.';

  @override
  String get session_summary_sessions_label => 'Antal pass:';

  @override
  String get session_summary_total_time_label => 'Total tid:';

  @override
  String get session_summary_total_bird_contacts_label => 'Fågelkontakter totalt:';

  @override
  String get session_summary_total_points_label => 'Stånd totalt:';

  @override
  String get session_summary_total_secondary_points_label => 'Sekundering totalt:';

  @override
  String get session_summary_total_flushes_label => 'Stötar totalt:';

  @override
  String get session_action_add_new_session => 'Lägg till nytt pass';

  @override
  String get session_action_cancel => 'Avbryt';

  @override
  String get session_type_title => 'Pass-typ';

  @override
  String get session_type_training => 'Träning';

  @override
  String get session_type_hunt => 'Jakt';

  @override
  String get session_field_location => 'Plats';

  @override
  String get session_field_active_time_minutes => 'Aktiv tid (min)';

  @override
  String get session_field_bird_contacts => 'Fågelkontakter';

  @override
  String get session_field_points => 'Stånd';

  @override
  String get session_field_secondary_points => 'Sekundering';

  @override
  String get session_field_flushes => 'Stötar';

  @override
  String get session_pick_date => 'Välj datum';

  @override
  String get session_pick_time => 'Tid';

  @override
  String get session_birds_section_title => 'Fåglar';

  @override
  String get session_birds_select_species => 'Välj fågelarter';

  @override
  String get session_birds_none_selected => 'Inga arter valda';

  @override
  String get session_species_picker_title => 'Välj fågelarter';

  @override
  String get session_species_picker_empty => 'Inga arter tillgängliga';

  @override
  String get session_species_picker_add => 'Lägg till';

  @override
  String get session_species_picker_done => 'Klar';

  @override
  String get session_error_no_dogs_registered => 'Inga hundar registrerade';

  @override
  String get session_select_species_title => 'Välj art';

  @override
  String get session_no_species_saved_yet => 'Inga arter sparade än';

  @override
  String get session_new_bird_button => 'Ny fågel';

  @override
  String get session_new_species_title => 'Ny art';

  @override
  String get session_error_photo_add => 'Kunde inte lägga till bild';

  @override
  String get session_error_video_add => 'Kunde inte lägga till video';

  @override
  String get session_error_media_save => 'Kunde inte spara mediafilen';

  @override
  String get session_error_gpx_import => 'GPX-import misslyckades. Se logg.';

  @override
  String get session_error_location_services_disabled => 'Platstjänster är inaktiverade';

  @override
  String get session_error_no_gps => 'Ingen GPS-åtkomst';

  @override
  String session_error_gps_failure(String error) {
    return 'GPS-fel: $error';
  }

  @override
  String get session_error_stop_gps => 'Kunde inte stoppa GPS';

  @override
  String get session_error_select_dog_first => 'Välj en hund först';

  @override
  String get session_error_no_track_export => 'Den här sessionen har inget spår att exportera';

  @override
  String get session_error_track_empty => 'Spår saknas/är tomt';

  @override
  String session_snackbar_message(String message) {
    return '$message';
  }

  @override
  String get session_media_add_image_failed => 'Kunde inte lägga till bild';

  @override
  String get session_media_add_video_failed => 'Kunde inte lägga till video';

  @override
  String get session_media_save_failed => 'Kunde inte spara mediafilen';

  @override
  String get session_media_video_missing => 'Videon saknas eller sparades inte korrekt';

  @override
  String get session_media_video_open_failed => 'Kunde inte öppna videon';

  @override
  String get session_media_section_title => 'Media';

  @override
  String get session_media_add_photo_video => 'Lägg till foto/video';

  @override
  String get session_media_gallery_label => 'Foto från biblioteket';

  @override
  String get session_media_camera_label => 'Ta foto';

  @override
  String get session_media_video_label => 'Video från biblioteket';

  @override
  String get gpx_import_failed_see_log => 'GPX-import misslyckades. Se logg.';

  @override
  String get gps_services_disabled => 'Platstjänster är inaktiverade';

  @override
  String get gps_no_permission => 'Ingen GPS-åtkomst';

  @override
  String gps_error_message(String error) {
    return 'GPS-fel: $error';
  }

  @override
  String get gps_stop_failed => 'Kunde inte stoppa GPS';

  @override
  String get session_select_dog_first => 'Välj en hund först';

  @override
  String get session_export_no_track => 'Den här sessionen har inget spår att exportera';

  @override
  String get session_track_missing_or_empty => 'Spår saknas/är tomt';

  @override
  String gpx_exported_to_desktop(String filename) {
    return 'GPX exporterad till Skrivbordet: $filename ✅';
  }

  @override
  String get session_detail_title_edit_session => 'Redigera pass';

  @override
  String get session_detail_title_new_session => 'Nytt pass';

  @override
  String get session_detail_label_points => 'Poäng';

  @override
  String get session_detail_label_flushes => 'Flushes';

  @override
  String get session_detail_button_add_media => 'Lägg till foto/video';

  @override
  String session_detail_total_points(String value) {
    return 'Poäng totalt: $value';
  }

  @override
  String get session_detail_title_home => 'Hem';

  @override
  String get session_detail_title_main => 'Pass';

  @override
  String get session_detail_title_active_session => 'Aktivt pass';

  @override
  String get active_session_hunt_events_title => 'Jakthändelser +1';

  @override
  String get active_session_action_stand_plus1 => 'Stånd +1';

  @override
  String get active_session_action_secondary_plus1 => 'Sekundering +1';

  @override
  String get active_session_action_flush_plus1 => 'Stöt +1';

  @override
  String get active_session_action_bird_plus1 => 'Fågel +1';

  @override
  String get active_session_action_undo => 'Ångra';

  @override
  String get session_detail_label_choose_dog => 'Välj hund';

  @override
  String get session_detail_button_open_latest_session => 'Öppna senaste passet';

  @override
  String get session_detail_button_start_new_session => 'Starta nytt pass';

  @override
  String get session_detail_button_settings => 'Inställningar';

  @override
  String get session_detail_media_sheet_title => 'Lägg till media';

  @override
  String get session_detail_media_sheet_action_gallery => 'Galleri';

  @override
  String get session_detail_media_sheet_action_camera => 'Kamera';

  @override
  String get session_detail_media_sheet_action_video => 'Video';

  @override
  String get session_detail_media_section_title => 'Media';

  @override
  String get session_detail_media_empty_placeholder => 'Inga media än';

  @override
  String get session_detail_notes_hint => 'Anteckningar från passet...';

  @override
  String session_detail_meta_time_minutes(Object minutes) {
    return 'Aktiv tid: $minutes min';
  }

  @override
  String session_detail_meta_birds(Object value) {
    return 'Fågelkontakter: $value';
  }

  @override
  String session_detail_meta_secondary_points(Object count) {
    return 'Sekundering: $count';
  }

  @override
  String session_detail_meta_flushes(Object value) {
    return 'Stötar: $value';
  }

  @override
  String get session_detail_screen_title => 'Passdetaljer';

  @override
  String get session_notes_hint_from_session => 'Anteckningar från passet...';

  @override
  String get session_notes_section_title => 'Anteckningar';

  @override
  String get session_detail_section_dog => 'Hund';

  @override
  String get session_detail_section_media => 'Media';

  @override
  String get session_detail_section_notes => 'Anteckningar';

  @override
  String get session_detail_media_open_gallery => 'Öppna galleri';

  @override
  String get session_detail_button_import_gpx => 'Importera GPX';

  @override
  String get session_detail_button_importing => 'Importerar…';

  @override
  String get session_detail_empty_bird_species => 'Inga fågelarter';

  @override
  String get session_detail_empty_location => 'Okänd plats';

  @override
  String get session_detail_saved_sessions_title => 'Sparade pass';

  @override
  String get session_detail_empty_sessions_for_selected_dog => 'Inga pass för vald hund';

  @override
  String get session_detail_empty_dogs_registered => 'Inga hundar registrerade.';

  @override
  String get session_detail_empty_sessions_yet => 'Inga pass än';

  @override
  String session_detail_track_summary_points(int count) {
    return 'Spår: $count punkter';
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
    return 'Distans: $meters m';
  }

  @override
  String session_detail_track_summary_distance_km(String kilometers) {
    return 'Distans: $kilometers km';
  }

  @override
  String session_detail_track_summary_duration(String value) {
    return 'Varaktighet: $value';
  }

  @override
  String get session_detail_action_saving => 'Sparar…';

  @override
  String get session_detail_action_save_changes => 'Spara ändringar';

  @override
  String get session_detail_action_save_session => 'Spara pass';

  @override
  String get session_detail_edit_title => 'Redigera pass';

  @override
  String get session_detail_button_save => 'Spara';

  @override
  String get session_detail_button_cancel => 'Avbryt';

  @override
  String get session_detail_button_delete => 'Ta bort';

  @override
  String get session_detail_field_location_label => 'Plats';

  @override
  String get session_detail_field_active_time_minutes_label => 'Aktiv tid (min)';

  @override
  String get session_detail_field_bird_contacts_label => 'Fågelkontakter';

  @override
  String get session_detail_field_points_label => 'Poäng';

  @override
  String get session_detail_field_secondary_points_label => 'Sekundering';

  @override
  String get session_detail_field_flushes_label => 'Stötar';

  @override
  String get session_detail_field_notes_label => 'Anteckning';

  @override
  String session_detail_version_build(String buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String get session_detail_snackbar_changes_saved => 'Ändringar sparade';

  @override
  String get session_detail_snackbar_session_saved => 'Pass sparat';

  @override
  String session_detail_snackbar_saved_with_imported_gpx(int points) {
    return 'Pass sparat med importerad GPX ($points punkter)';
  }

  @override
  String session_detail_snackbar_saved_with_gps_track(int points) {
    return 'Pass sparat med GPS-spår ($points punkter)';
  }

  @override
  String get session_detail_help_notes_first => 'Anteckningar först. Räkneverk med + i fältet.';

  @override
  String session_detail_stats_sessions_count(int count) {
    return 'Antal pass: $count';
  }

  @override
  String session_detail_stats_total_active_time(int minutes) {
    return 'Total aktiv tid: $minutes min';
  }

  @override
  String session_detail_stats_total_birds(int count) {
    return 'Fågelkontakter totalt: $count';
  }

  @override
  String session_detail_stats_total_points(int count) {
    return 'Stånd totalt: $count';
  }

  @override
  String session_detail_stats_total_secondary_points(int count) {
    return 'Sekundering totalt: $count';
  }

  @override
  String session_detail_stats_total_flushes(int count) {
    return 'Stöt totalt: $count';
  }

  @override
  String get session_detail_button_select_date => 'Välj datum';

  @override
  String get session_detail_button_select_time => 'Tid';

  @override
  String get session_detail_label_duration_from_track => 'Hämtat från GPS-spår';

  @override
  String session_detail_saved_session_summary(int durationMinutes, int birds, int stand, int secondaryPoints, int flushes) {
    return 'Tid: $durationMinutes min, Fågel: $birds, stånd: $stand, sekundering: $secondaryPoints, stöt: $flushes';
  }

  @override
  String get session_detail_button_exporting => 'Exporterar…';

  @override
  String get session_detail_button_export_gpx => 'Exportera GPX';

  @override
  String get session_detail_error_gpx_too_few_points => 'Hittade för få GPX-punkter i filen';

  @override
  String session_detail_helper_duration_hours_minutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get session_detail_bird_species_picker_title => 'Välj fågelarter';

  @override
  String get session_detail_bird_section_title => 'Fåglar';

  @override
  String get session_detail_bird_species_button_label => 'Välj fågelarter';

  @override
  String get session_detail_bird_species_empty_selection => 'Inga arter valda';

  @override
  String get session_detail_bird_species_empty_saved => 'Inga arter sparade ännu';

  @override
  String get session_detail_bird_species_new => 'Ny fågel';

  @override
  String get session_detail_action_done => 'Klar';

  @override
  String get session_detail_bird_species_dialog_title => 'Ny fågelart';

  @override
  String get session_detail_bird_species_dialog_name_label => 'Namn';

  @override
  String get session_action_save => 'Spara';

  @override
  String get session_detail_media_gallery_title => 'Media';

  @override
  String get hunt_session_title_new => 'Nytt pass';

  @override
  String get hunt_session_title_edit => 'Redigera pass';

  @override
  String get hunt_session_field_location_label => 'Plats';

  @override
  String get hunt_session_field_duration_minutes_label => 'Aktiv tid (min)';

  @override
  String get hunt_session_field_birds_seen_label => 'Fågelkontakter';

  @override
  String get hunt_session_field_points_label => 'Poäng';

  @override
  String get hunt_session_field_secondary_points_label => 'Sekundering';

  @override
  String get hunt_session_field_flushes_label => 'Stötar';

  @override
  String get hunt_session_field_notes_label => 'Anteckningar';

  @override
  String get hunt_session_action_save => 'Spara';

  @override
  String get hunt_session_action_cancel => 'Avbryt';

  @override
  String get hunt_session_action_delete => 'Ta bort';

  @override
  String get hunt_session_action_import_gpx => 'Importera GPX';

  @override
  String get hunt_session_action_importing => 'Importerar…';

  @override
  String hunt_session_snackbar_saved_with_gps_track(Object points) {
    return 'Pass sparat med GPS-spår ($points punkter)';
  }

  @override
  String get session_detail_filter_all_dogs => 'Alla hundar';

  @override
  String get session_detail_session_menu_export => 'Exportera GPX';

  @override
  String get session_detail_session_menu_exporting => 'Exporterar…';

  @override
  String get session_detail_session_menu_edit => 'Redigera pass';

  @override
  String get session_detail_session_menu_delete => 'Ta bort pass';

  @override
  String get session_detail_detail_title => 'Detaljer';

  @override
  String get session_detail_detail_label_date => 'Datum';

  @override
  String get session_detail_detail_label_location => 'Plats';

  @override
  String get session_detail_detail_label_active_time => 'Aktiv tid';

  @override
  String get session_detail_detail_label_bird_contacts => 'Fågelkontakter';

  @override
  String get session_detail_detail_label_points => 'Poäng';

  @override
  String get session_detail_detail_label_secondary_points => 'Sekundering';

  @override
  String get session_detail_detail_label_flushes => 'Stötar';

  @override
  String get session_detail_label_bird_species => 'Fågelarter';

  @override
  String get session_detail_label_gps_track => 'GPS-spår';

  @override
  String get session_detail_label_yes => 'Ja';

  @override
  String get session_detail_label_no => 'Nej';

  @override
  String get session_detail_label_dog_prefix => 'Hund: ';

  @override
  String get session_detail_map_title => 'Karta';

  @override
  String get session_detail_map_prefix => 'Karta – ';

  @override
  String get map_title => 'Karta';

  @override
  String get session_detail_gpx_replace_title => 'Ersätt spår?';

  @override
  String get session_detail_gpx_replace_body => 'Detta ersätter det befintliga spåret. Fortsätt?';

  @override
  String get session_detail_gpx_replace_confirm => 'Ersätt';

  @override
  String session_detail_gpx_replaced_snackbar(int points) {
    return 'Spår ersatt: $points punkter';
  }

  @override
  String session_detail_gpx_imported_snackbar(int points) {
    return 'GPX importerat: $points punkter';
  }

  @override
  String get session_detail_empty_notes => 'Inga anteckningar';

  @override
  String get session_detail_empty_media => 'Inga medier tillagda';

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
    return 'Flushes totalt: $value';
  }

  @override
  String get gpx_import_label => 'Importera GPX';

  @override
  String get session_menu_edit => 'Redigera session';

  @override
  String get session_menu_delete => 'Ta bort session';

  @override
  String stats_trend_label(String symbol) {
    return 'Trend: $symbol';
  }

  @override
  String get stats_title_points_and_flushes => 'Stånd och flush';

  @override
  String get stats_title_sessions => 'Sessioner';

  @override
  String get stats_title_birds_down_per_year => 'Fällda fåglar per år';

  @override
  String get stats_subtitle_active_time => 'Aktiv tid';

  @override
  String get stats_subtitle_session_count => 'Antal sessioner';

  @override
  String get stats_legend_bars => 'Staplar:';

  @override
  String get stats_legend_line => 'Linje:';

  @override
  String get stats_title_development => 'Utveckling';

  @override
  String get stats_period_30_days => '30 dagar';

  @override
  String get stats_period_90_days => '90 dagar';

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
  String get stats_info_active_time_body_1 => 'Total tid hunden har arbetat.';

  @override
  String get stats_info_active_time_body_2 => 'Används för att bedöma belastning och kontinuitet.';

  @override
  String get stats_info_session_count_title => 'Sessioner';

  @override
  String get stats_info_session_count_body_1 => 'Hur ofta hunden har varit aktiv.';

  @override
  String get stats_info_session_count_body_2 => 'Visar tränings- och jaktfrekvens.';

  @override
  String get stats_v1_overview_title => 'V1-översikt';

  @override
  String get stats_total_points_title => 'Totala stånd';

  @override
  String get stats_total_active_time_title => 'Total aktiv tid';

  @override
  String get stats_avg_points_per_session_title => 'Snitt: stånd per session';

  @override
  String get stats_avg_time_per_session_title => 'Snitt: tid per session';

  @override
  String get stats_last_30_days_sessions_title => 'Senaste 30 dagarna: Sessioner';

  @override
  String get stats_last_30_days_points_title => 'Senaste 30 dagarna: Stånd';

  @override
  String stats_overview_sessions_value(int count) {
    return '$count sessioner';
  }

  @override
  String stats_overview_points_value(int count) {
    return '$count stånd';
  }

  @override
  String stats_last_30_days_sessions_value(int count) {
    return '$count sessioner';
  }

  @override
  String stats_last_30_days_points_value(int count) {
    return '$count stånd';
  }

  @override
  String get stats_points_label => 'Stånd';

  @override
  String get stats_flushes_label => 'Flush';

  @override
  String stats_per_month_suffix(int year) {
    return 'per månad • $year';
  }

  @override
  String stats_monthly_sessions_tooltip(String month, int year, int count) {
    return '$month $year: $count sessioner';
  }

  @override
  String stats_monthly_sessions_tooltip_empty(String month, int year) {
    return '$month $year: Inga sessioner';
  }

  @override
  String stats_total_points_flushes_prefix(int points, int flushes) {
    return 'Totalt: $points stånd, $flushes flush';
  }

  @override
  String stats_stand_flush_tooltip(String month, int year, String stand, String flush) {
    return '$month $year: Stånd $stand, Flush $flush';
  }

  @override
  String get stats_info_points_flushes_title => 'Stånd och flush';

  @override
  String get stats_info_points_flushes_body_1 => 'Visar antal stånd och flush över tid.';

  @override
  String get stats_info_points_flushes_body_2 => 'Ger insikt i hundens arbete i fält och jaktmönster.';

  @override
  String get stats_none => 'Ingen';

  @override
  String get stats_unknown_species => 'Okänd';

  @override
  String get stats_info_explanation_tooltip => 'Förklaring';

  @override
  String stats_total_sessions_prefix(int count) {
    return 'Totalt: $count sessioner';
  }

  @override
  String get stats_info_sessions_title => 'Sessioner';

  @override
  String get stats_info_sessions_body_1 => 'Hur ofta hunden har varit aktiv.';

  @override
  String get stats_info_sessions_body_2 => 'Visar tränings- och jaktfrekvens.';

  @override
  String get stats_no_birds_down_yet => 'Inga fällda fåglar registrerade ännu';

  @override
  String get stats_birds_distribution_title => 'Förd eldning';

  @override
  String get stats_birds_pie_hint => 'Tryck på en bit för detaljer';

  @override
  String get stats_info_birds_down_title => 'Fällda fåglar';

  @override
  String get stats_info_birds_down_body_1 => 'Antal fällda fåglar per kalenderår.';

  @override
  String get stats_info_birds_down_body_2 => 'Ger underlag för jämförelser mellan år.';

  @override
  String get stats_info_birds_distribution_title => 'Fördelning fälld fågel';

  @override
  String get stats_info_birds_distribution_body_1 => 'Visar vilka arter som fällts under valt år.';

  @override
  String get stats_info_birds_distribution_body_2 => 'Ger en översikt över jaktuttag och variation.';

  @override
  String get stats_label_year => 'År';

  @override
  String get stats_label_total => 'Totalt';

  @override
  String get stats_label_per_month => 'per månad';

  @override
  String get gpx_importing_ellipsis => 'Importerar…';

  @override
  String get gpx_export_label => 'Exportera GPX';

  @override
  String get gpx_exporting_ellipsis => 'Exporterar…';

  @override
  String get home_open_settings_tooltip => 'Inställningar';

  @override
  String get home_settings_button_label => 'Inställningar';

  @override
  String get home_no_dogs_title => 'Inga hundar registrerade än';

  @override
  String get home_no_dogs_message => 'Registrera dina hundar för att logga träning, jakt och prov. Då får du en tydlig historik och bättre koll på utvecklingen.';

  @override
  String get home_no_dogs_bullet_history => 'Historik: se sessioner, anteckningar och platser samlat';

  @override
  String get home_no_dogs_bullet_progress => 'Framsteg: följ stånd, stöt och aktiv tid över tid';

  @override
  String get home_no_dogs_bullet_stats => 'Statistik: meningsfulla trender som stöder jakten';

  @override
  String get home_wisdom_empty => 'En lugn start ger bättre jakt än stress.';

  @override
  String get wisdom_001 => 'En lugn hund lär sig snabbare än en stressad.';

  @override
  String get wisdom_002 => 'Det du tränar idag får du tillbaka i höst.';

  @override
  String get wisdom_003 => 'Repetera mindre. Vänta mer.';

  @override
  String get wisdom_004 => 'Tystnad är också träning.';

  @override
  String get wisdom_005 => 'Framgång sker ofta mellan passen.';

  @override
  String get wisdom_006 => 'En paus i rätt ögonblick är bättre än en repetition för mycket.';

  @override
  String get wisdom_007 => 'Tålamod är den mest underskattade övningen.';

  @override
  String get wisdom_008 => 'Träna det du vill se, inte det du hoppas på.';

  @override
  String get wisdom_009 => 'En trygg hund lär sig fortare än en ivrig.';

  @override
  String get wisdom_010 => 'Det är okej att avsluta på topp.';

  @override
  String get wisdom_011 => 'Ett stånd byggs innan fågel, inte efter.';

  @override
  String get wisdom_012 => 'Lugn i upptag börjar i huvudet.';

  @override
  String get wisdom_013 => 'Stabilitet är ett val hunden lär sig ta.';

  @override
  String get wisdom_014 => 'Press skapar rörelse. Tid skapar ro.';

  @override
  String get wisdom_015 => 'En bra ståndpunkt behöver inget publik.';

  @override
  String get wisdom_016 => 'När hunden står, låt världen vänta.';

  @override
  String get wisdom_017 => 'En lugn stånd slår tre snabba.';

  @override
  String get wisdom_018 => 'Fågeln lär hunden. Du formar reaktionen.';

  @override
  String get wisdom_019 => 'Stånd är ett ögonblick av balans.';

  @override
  String get wisdom_020 => 'Skynda inte genom tystnad.';

  @override
  String get wisdom_021 => 'Läs vinden innan du läser hunden.';

  @override
  String get wisdom_022 => 'Terrängen tränar hunden lika mycket.';

  @override
  String get wisdom_023 => 'Varje fågel är en ny lektion.';

  @override
  String get wisdom_024 => 'Dåliga förhållanden ger värdefulla erfarenheter.';

  @override
  String get wisdom_025 => 'Jakt är samarbete, inte tävling.';

  @override
  String get wisdom_026 => 'Det är i motvind du ser kvalitet.';

  @override
  String get wisdom_027 => 'En tom omgång kan vara full av lärdom.';

  @override
  String get wisdom_028 => 'Låt hunden hitta lösningen.';

  @override
  String get wisdom_029 => 'Fågelhundens styrka är självständighet med riktning.';

  @override
  String get wisdom_030 => 'Fältet minns allt.';

  @override
  String get wisdom_031 => 'Var konsekvent, inte perfekt.';

  @override
  String get wisdom_032 => 'Hunden speglar ditt tempo.';

  @override
  String get wisdom_033 => 'Det du inte reagerar på, accepterar du.';

  @override
  String get wisdom_034 => 'Klar tanke ger klar hund.';

  @override
  String get wisdom_035 => 'Rättvisa slår stränghet.';

  @override
  String get wisdom_036 => 'Träna med hjärnan innan du höjer rösten.';

  @override
  String get wisdom_037 => 'Förklara inte. Visa.';

  @override
  String get wisdom_038 => 'En trygg förare ger en trygg hund.';

  @override
  String get wisdom_039 => 'Din ro är hundens ram.';

  @override
  String get wisdom_040 => 'Lyssna mer än du korrigerar.';

  @override
  String get wisdom_041 => 'Relation byggs också utan fågel.';

  @override
  String get wisdom_042 => 'En bra tur är aldrig bortkastad.';

  @override
  String get wisdom_043 => 'Förtroende tar tid. Misstro tar sekunder.';

  @override
  String get wisdom_044 => 'Hunden jobbar bäst för den den litar på.';

  @override
  String get wisdom_045 => 'Små rutiner ger stor trygghet.';

  @override
  String get wisdom_046 => 'Det är okej att ibland bara vara hund.';

  @override
  String get wisdom_047 => 'Lekfullhet är inte odisciplin.';

  @override
  String get wisdom_048 => 'En nöjd hund presterar bättre.';

  @override
  String get wisdom_049 => 'Samarbete slår kontroll.';

  @override
  String get wisdom_050 => 'Gemenskap före färdigheter.';

  @override
  String get wisdom_051 => 'Prov är ögonblicksbilder, inte facit.';

  @override
  String get wisdom_052 => 'Domaren ser en dag. Du ser hela året.';

  @override
  String get wisdom_053 => 'Resultat är bonus, inte mål.';

  @override
  String get wisdom_054 => 'En bra upplevelse slår en bra placering.';

  @override
  String get wisdom_055 => 'Press hemma ger lugn på prov.';

  @override
  String get wisdom_056 => 'Träna situationer, inte poäng.';

  @override
  String get wisdom_057 => 'En stabil hund är alltid konkurrenskraftig.';

  @override
  String get wisdom_058 => 'Lär av det som inte gick.';

  @override
  String get wisdom_059 => 'Prov är träning med publik.';

  @override
  String get wisdom_060 => 'Jaga inte premier, bygg hund.';

  @override
  String get wisdom_061 => 'En fågelhund är aldrig fullärd.';

  @override
  String get wisdom_062 => 'Vägen till ståndet är det som räknas.';

  @override
  String get wisdom_063 => 'Tålamod luktar inte stress.';

  @override
  String get wisdom_064 => 'De bästa ögonblicken kan inte loggas.';

  @override
  String get wisdom_065 => 'Fågelhund handlar om tillit i fart.';

  @override
  String get wisdom_066 => 'Tystnad är ofta svaret.';

  @override
  String get wisdom_067 => 'Naturen sätter alltid ramarna.';

  @override
  String get wisdom_068 => 'En bra dag i fältet känns länge.';

  @override
  String get wisdom_069 => 'Hunden minns stämningen.';

  @override
  String get wisdom_070 => 'Jakt är samspel med landskapet.';

  @override
  String get wisdom_071 => 'En kort lina idag kan ge lång lugn imorgon.';

  @override
  String get wisdom_072 => 'Det som belönas upprepas.';

  @override
  String get wisdom_073 => 'Håll kraven små och bygg dem stora över tid.';

  @override
  String get wisdom_074 => 'När du tappar lugnet tappar du också lärandet.';

  @override
  String get wisdom_075 => 'En tydlig start gör slutet enkelt.';

  @override
  String get wisdom_076 => 'Lugn är inte passivitet. Lugn är kontroll.';

  @override
  String get wisdom_077 => 'Träna det tråkiga. Det räddar dagen.';

  @override
  String get wisdom_078 => 'En bra förare syns sällan.';

  @override
  String get wisdom_079 => 'När hunden lyckas har du varit förutsägbar.';

  @override
  String get wisdom_080 => 'Jaga inte tempo. Jaga kvalitet.';

  @override
  String get wisdom_081 => 'Ge hunden tid att tänka klart.';

  @override
  String get wisdom_082 => 'Ett nej utan ilska värderas högre än tio ja med stress.';

  @override
  String get wisdom_083 => 'Stoppa innan du måste stoppa.';

  @override
  String get wisdom_084 => 'Du tränar alltid, även när du bara går tur.';

  @override
  String get wisdom_085 => 'Fågeln avslöjar hålen. Träna hålen.';

  @override
  String get wisdom_086 => 'En bra stopp är starten på ett bra stånd.';

  @override
  String get wisdom_087 => 'Lätt hand ger tungt samarbete.';

  @override
  String get wisdom_088 => 'När det går snett: sänk tempot, öka tydligheten.';

  @override
  String get wisdom_089 => 'En trygg rutin slår en perfekt plan.';

  @override
  String get wisdom_090 => 'Det viktigaste signalet är det du ger med kroppen.';

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
  String get settings_title => 'Inställningar';

  @override
  String get settings_section_general => 'Allmänt';

  @override
  String get settings_section_milestones => 'Milstolpar';

  @override
  String get invitations_title => 'Inbjudningar';

  @override
  String get invitations_empty => 'Inga väntande inbjudningar';

  @override
  String get settings_section_feedback => 'Feedback';

  @override
  String get supportEmail => 'support@gundogtracker.app';

  @override
  String get support_email => 'support@gundogtracker.app';

  @override
  String get settings_section_subscription => 'Prenumeration';

  @override
  String get settings_section_language => 'Språk';

  @override
  String get settings_section_community => 'Community';

  @override
  String get settings_section_security => 'Säkerhet';

  @override
  String get settings_change_password_title => 'Ändra lösenord';

  @override
  String get settings_change_password_current_password => 'Nuvarande lösenord';

  @override
  String get settings_change_password_new_password => 'Nytt lösenord';

  @override
  String get settings_change_password_confirm_password => 'Bekräfta nytt lösenord';

  @override
  String get settings_change_password_submit => 'Uppdatera lösenord';

  @override
  String get settings_change_password_success => 'Lösenordet är uppdaterat';

  @override
  String get settings_reset_password_button => 'Glömt lösenord';

  @override
  String get settings_reset_password_sent => 'Kolla din e-post för en länk';

  @override
  String get settings_reset_password_no_email => 'Ingen e-post tillgänglig för återställning';

  @override
  String get settings_change_password_error_fields => 'Fyll i alla fält';

  @override
  String get settings_change_password_error_mismatch => 'Nytt lösenord och bekräftelse måste matcha';

  @override
  String get forgot_password_title => 'Glömt lösenord';

  @override
  String get forgot_password_description => 'Fyll i din e-postadress så skickar vi en länk för att återställa lösenordet.';

  @override
  String get forgot_password_email_label => 'E-post';

  @override
  String get forgot_password_button => 'Skicka återställningslänk';

  @override
  String get forgot_password_error_missing => 'Ange e-post.';

  @override
  String get forgot_password_error_invalid => 'Ange en giltig e-post.';

  @override
  String get forgot_password_check_spam_hint => 'Kolla inkorgen. Om mejlet inte dyker upp, kolla skräppost/Spam.';

  @override
  String get settings_backup_import_success => 'Backup importerad';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Ljust';

  @override
  String get settings_theme_dark => 'Mörkt';

  @override
  String get settings_language_title => 'Språk';

  @override
  String get settings_language_followSystem => 'Följ systemet';

  @override
  String get settings_language_nb => 'Norska (bokmål)';

  @override
  String get settings_language_sv => 'Svenska';

  @override
  String get settings_language_da => 'Danska';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_milestones_enabled_title => 'Milstolpar';

  @override
  String get settings_milestones_enabled_subtitle => 'Visa små ögonblick när hunden når viktiga steg.';

  @override
  String get settings_haptics_enabled_title => 'Vibration vid milstolpar';

  @override
  String get settings_haptics_enabled_subtitle => 'Diskret vibration när milstolpar uppnås.';

  @override
  String get settings_restore_in_progress => 'Återställning pågår… vänligen vänta.';

  @override
  String get settings_section_backup => 'Säkerhetskopiering';

  @override
  String get settings_backup_export_action => 'Exportera säkerhetskopia (ZIP)';

  @override
  String get settings_backup_exporting => 'Exporterar…';

  @override
  String get settings_backup_subtitle => 'Exportera/importera hundar, pass, spår, milstolpar och media.';

  @override
  String get settings_backup_import_action => 'Importera säkerhetskopia (ZIP)';

  @override
  String get settings_backup_importing => 'Importerar…';

  @override
  String get settings_backup_import_description => 'Välj en backup-ZIP och återställ data.';

  @override
  String get settings_backup_where_title => 'Var lagras säkerhetskopian?';

  @override
  String get settings_backup_where_action => 'Visa lagringsmapp';

  @override
  String get settings_backup_status_collectingData => 'Samlar data…';

  @override
  String get settings_backup_status_collectingMedia => 'Samlar media…';

  @override
  String get settings_backup_status_creatingZip => 'Skapar ZIP…';

  @override
  String get settings_backup_status_sharing => 'Dela…';

  @override
  String get settings_backup_status_selectZip => 'Välj ZIP…';

  @override
  String get settings_backup_status_restoring => 'Återställer data…';

  @override
  String get settings_backup_share_subject => 'Jakthund backup';

  @override
  String settings_backup_ready(Object fileName) {
    return 'Backup klar: $fileName ✅';
  }

  @override
  String settings_backup_failed(Object message) {
    return 'Backup misslyckades: $message';
  }

  @override
  String get auth_profile_pending_title => 'Skapar profil…';

  @override
  String get auth_profile_pending_body => 'Vi väntar på att backend-dokumentet ska bli klart. Tryck på \"Försök igen\" för att kontrollera igen.';

  @override
  String get auth_profile_timeout_error => 'Kunde inte hitta användarprofilen inom några sekunder. Kontrollera nätverket eller försök igen.';

  @override
  String get settings_backup_failed_unknown => 'Okänt fel.';

  @override
  String settings_backup_import_failed(Object message) {
    return 'Import misslyckades: $message';
  }

  @override
  String get settings_backup_restore_dialog_title => 'Importera säkerhetskopia';

  @override
  String get settings_backup_restore_dialog_content => 'Detta återställer data från en ZIP-säkerhetskopia.\n\nTips: Efter importen kan det vara bra att starta om appen.';

  @override
  String get settings_backup_restore_dialog_confirm => 'Importera';

  @override
  String get settings_backup_restore_prompt_title => 'Återställning klar';

  @override
  String get settings_backup_restore_prompt_message => 'Återställningen är klar. Starta om appen nu?';

  @override
  String get settings_backup_restore_saved => 'Återställningen är sparad. Starta om när det passar.';

  @override
  String get settings_backup_restore_complete => 'Import klar';

  @override
  String get settings_backup_storage_title => 'Backup-lagring';

  @override
  String settings_backup_storage_description(String path) {
    return 'Backupfiler lagras här:\n\n$path';
  }

  @override
  String get settings_backup_restore_pending => 'Importerar backup…';

  @override
  String get settings_backup_restore_pending_message => 'Återställer backup… vänta gärna.';

  @override
  String get settings_section_appearance => 'Utseende';

  @override
  String get settings_season_title => 'Årstidstema';

  @override
  String get settings_season_subtitle => 'Färger för topp och botten.';

  @override
  String get settings_season_auto => 'Automatiskt';

  @override
  String get settings_season_spring => '🌱 Vår';

  @override
  String get settings_season_summer => '☀️ Sommar';

  @override
  String get settings_season_autumn => '🍁 Höst';

  @override
  String get settings_season_winter => '❄️ Vinter';

  @override
  String get settings_feedback_send_subtitle => 'Öppnar e-post med appinfo.';

  @override
  String get settings_feedback_bug_subtitle => 'Öppnar e-post med felmall.';

  @override
  String get settings_feedback_copy_subtitle => 'Kopierar app- och enhetsinfo.';

  @override
  String get settings_feedback_suggest_subtitle => 'Skicka förslag via e-post.';

  @override
  String get settings_feedback_error_open_email => 'Kunde inte öppna e-post.';

  @override
  String get settings_feedback_error_copy => 'Kunde inte kopiera.';

  @override
  String get milestones_achieved_title => 'Uppnådda milstolpar';

  @override
  String get milestones_achieved_empty => 'Inga milstolpar ännu.';

  @override
  String milestones_achieved_duration(String duration) {
    return 'Uppnått $duration';
  }

  @override
  String get milestone_sheet_button_ok => 'Bra!';

  @override
  String get milestone_sheet_button_viewAll => 'Se milstolpar';

  @override
  String get milestone_snackbar_new_title => 'Ny milstolpe!';

  @override
  String get milestone_snackbar_open_error => 'Kunde inte öppna milstolpen';

  @override
  String milestone_stands_count_subtitle(Object dogName, Object countText) {
    return '$dogName har registrerat $countText.';
  }

  @override
  String milestone_sessions_count_subtitle(Object dogName, Object countText) {
    return '$dogName har loggat $countText.';
  }

  @override
  String milestone_birds_count_subtitle(Object dogName, Object countText) {
    return '$dogName har fällt $countText.';
  }

  @override
  String get milestone_first_point_title => 'Första stånd';

  @override
  String milestone_first_point_subtitle(String dogName) {
    return '$dogName har registrerat sitt första stånd.';
  }

  @override
  String get milestone_first_flush_title => 'Första stöt';

  @override
  String milestone_first_flush_subtitle(String dogName) {
    return '$dogName har registrerat sin första stöt.';
  }

  @override
  String get milestone_sessions_10_title => '10 pass';

  @override
  String milestone_sessions_10_subtitle(String dogName) {
    return '$dogName har loggat 10 pass.';
  }

  @override
  String get milestone_active_hours_10_title => '10 timmar aktiv';

  @override
  String milestone_active_hours_10_subtitle(String dogName) {
    return '$dogName har passerat 10 timmar aktiv tid.';
  }

  @override
  String get milestone_section_birds_down_title => 'Fälld fågel';

  @override
  String get milestone_dog_fallback_name => 'Hunden';

  @override
  String milestone_achieved_sentence(Object dog, Object milestone, Object date, Object age) {
    return '$dog uppnådde “$milestone” $date$age';
  }

  @override
  String milestone_bird_threshold_label(Object threshold) {
    return '$threshold. fågel';
  }

  @override
  String get milestone_bird_label => 'Fågel';

  @override
  String milestone_century_points_title(int count) {
    return '$count stånd';
  }

  @override
  String milestone_century_points_subtitle(String dogName, int count) {
    return '$dogName har passerat $count stånd.';
  }

  @override
  String get subscription_title => 'Prenumeration';

  @override
  String get subscription_status_label => 'Status';

  @override
  String get subscription_status_active => 'Aktiv';

  @override
  String get subscription_status_inactive => 'Inte aktiv';

  @override
  String get subscription_status_unknown => 'Okänd';

  @override
  String get subscription_subscribe_button => 'Teckna prenumeration';

  @override
  String get subscription_restore_button => 'Återställ köp';

  @override
  String get subscription_manage_button => 'Hantera / Avsluta';

  @override
  String get feedback_send_title => 'Skicka feedback';

  @override
  String get feedback_bug_title => 'Rapportera ett fel';

  @override
  String get feedback_copy_diagnostics_title => 'Kopiera diagnostik';

  @override
  String get feedback_suggest_milestone_title => 'Föreslå milstolpe';

  @override
  String get feedback_email_body_intro => 'Beskriv din feedback här.';

  @override
  String get feedback_bug_prompt => 'Vad hände?';

  @override
  String get feedback_bug_reproduce => 'Hur kan vi återupprepa problemet?';

  @override
  String get feedback_suggest_title => 'Förslag till ny milstolpe:';

  @override
  String get feedback_suggest_question_what_to_celebrate => 'Vad bör firas?';

  @override
  String get feedback_suggest_question_why_important => 'Varför är detta viktigt i praktiken?';

  @override
  String get feedback_suggest_question_when_should_trigger => 'När bör den utlösas?';

  @override
  String get feedback_suggest_trigger_hint => '(första gången, var 10:e, var 100:e, annat)';

  @override
  String get feedback_suggest_comments => 'Eventuella kommentarer:';

  @override
  String get feedback_error_email_not_available => 'Ingen e-postapp tillgänglig.';

  @override
  String get community_open_discord => 'Öppna Discord-grupp';

  @override
  String get community_open_facebook => 'Öppna Facebook-grupp';

  @override
  String get home_continueActiveSessionTitle => 'Fortsätt aktivt pass';

  @override
  String home_continueActiveSessionSubtitle(String dogName) {
    return 'Ofullständigt pass för $dogName.';
  }

  @override
  String get home_continueActiveSessionMissingDogTitle => 'Aktivt pass kan inte återställas';

  @override
  String get home_continueActiveSessionMissingDogSubtitle => 'Hunden finns inte längre tillgänglig. Du kan kasta utkastet.';

  @override
  String get home_continueActiveSessionButton => 'Fortsätt aktivt pass';

  @override
  String get home_discardActiveSessionButton => 'Kasta';

  @override
  String get home_discardActiveSessionSnackbar => 'Aktivt pass kastat';

  @override
  String get home_endActiveSessionButton => 'Avsluta aktiv session';

  @override
  String get home_endActiveSessionConfirmTitle => 'Avsluta aktiv session?';

  @override
  String get home_endActiveSessionConfirmSubtitle => 'Allt går förlorat om du avslutar. Är du säker?';

  @override
  String get milestones_category_firsts => 'Första gången';

  @override
  String get milestones_category_sessions => 'Pass';

  @override
  String get milestones_category_points => 'Stånd';

  @override
  String get milestones_category_time => 'Tid';

  @override
  String get milestones_category_contacts => 'Kontakter';

  @override
  String birdsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fåglar',
      one: '1 fågel',
      zero: '0 fåglar',
    );
    return '$_temp0';
  }

  @override
  String birdsDownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fällda fåglar',
      one: '1 fälld fågel',
      zero: '0 fällda fåglar',
    );
    return '$_temp0';
  }
}
