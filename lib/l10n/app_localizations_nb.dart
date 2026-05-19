// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appName => 'Fuglehund';

  @override
  String get app_store_identity_subtitle => 'Offline jaktlogg for fuglehunder';

  @override
  String get app_store_identity_short_description => 'Loggfør økter, spor fremgang og bygg historikk for hunden din – også offline.';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Lukk';

  @override
  String get common_done => 'Ferdig';

  @override
  String get common_cancel => 'Avbryt';

  @override
  String get common_save => 'Lagre';

  @override
  String get common_copy => 'Kopier';

  @override
  String get common_copied => 'Kopiert ✅';

  @override
  String get common_comingSoon => 'Kommer snart.';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nei';

  @override
  String get common_invalid_link => 'Ugyldig lenke';

  @override
  String get common_could_not_open_link => 'Kunne ikke åpne lenken';

  @override
  String get common_unknown => 'Ukjent';

  @override
  String get common_unknown_email => 'Ukjent e-post';

  @override
  String get common_unknown_member => 'Ukjent medlem';

  @override
  String get common_no_permission => 'Du har ikke tilgang til denne handlingen.';

  @override
  String get common_retry => 'Prøv igjen';

  @override
  String get age_unknown => 'Alder ukjent';

  @override
  String get boot_error_title => 'Oppstart feilet';

  @override
  String boot_error_body(Object message) {
    return 'Se terminalen for detaljer.\n$message';
  }

  @override
  String get boot_error_unknown => 'Ukjent feil';

  @override
  String get boot_restore_title => 'Gjenoppretter backup…';

  @override
  String get boot_restore_body => 'Ikke lukk appen.\n\nVi blokkerer tilgang til data mens restore pågår for å unngå Hive-feil.';

  @override
  String get boot_restart_title => 'Backup gjenopprettet ✅';

  @override
  String get boot_restart_body => 'Appen lukkes nå slik at endringene kan lastes inn.\n\nÅpne appen igjen etterpå.';

  @override
  String get qr_scan_title => 'Skann QR';

  @override
  String get home_title => 'Hjem';

  @override
  String get home => 'Hjem';

  @override
  String get sessions => 'Økter';

  @override
  String get statistics => 'Statistikk';

  @override
  String get advanced_statistics => 'Avansert statistikk';

  @override
  String get advanced_statistics_overview => 'Oversikt';

  @override
  String get advanced_statistics_progress => 'Progresjon';

  @override
  String get advanced_statistics_season => 'Sesong';

  @override
  String get advanced_statistics_comparison => 'Sammenligning';

  @override
  String get advanced_statistics_export => 'Eksport';

  @override
  String get advanced_statistics_no_progress_data => 'Ingen progresjonsdata tilgjengelig';

  @override
  String get advanced_statistics_no_season_data => 'Ingen sesongdata tilgjengelig';

  @override
  String get advanced_statistics_need_two_dogs => 'Trenger minst 2 hunder for sammenligning';

  @override
  String get advanced_statistics_exporting => 'Eksporterer...';

  @override
  String get advanced_statistics_export_stats => 'Eksporter statistikker';

  @override
  String get advanced_statistics_export_sessions => 'Eksporter økter';

  @override
  String get advanced_statistics_generate_text_report => 'Generer tekst-rapport';

  @override
  String advanced_statistics_key_metrics_for(Object dogName) {
    return 'Nøkkeltall for $dogName';
  }

  @override
  String get advanced_statistics_stand_rate_per_hour => 'Stand-rate per time';

  @override
  String get advanced_statistics_bird_contacts_per_session => 'Fuglkontakter per økt';

  @override
  String get advanced_statistics_average_flushes_per_session => 'Gjennomsnittlige støkk per økt';

  @override
  String get advanced_statistics_success_rate => 'Suksessrate';

  @override
  String get advanced_statistics_totals => 'Totaler';

  @override
  String get advanced_statistics_sessions_total => 'Økter totalt';

  @override
  String get advanced_statistics_active_time => 'Aktiv tid';

  @override
  String get advanced_statistics_total_points => 'Totale poeng';

  @override
  String get advanced_statistics_total_flushes => 'Totale støkk';

  @override
  String get advanced_statistics_bird_contacts => 'Fuglkontakter';

  @override
  String get advanced_statistics_birds_shot => 'Fugl skutt';

  @override
  String advanced_statistics_progress_over_time(Object dogName) {
    return 'Progresjon over tid - $dogName';
  }

  @override
  String get advanced_statistics_average_points_per_session_over_time => 'Gjennomsnittlige poeng per økt over tid';

  @override
  String get advanced_statistics_trend_analysis => 'Trendanalyse';

  @override
  String get advanced_statistics_improvement => 'Forbedring!';

  @override
  String get advanced_statistics_declining => 'Nedgang';

  @override
  String get advanced_statistics_stable => 'Stabil';

  @override
  String advanced_statistics_seasonal_analysis(Object dogName) {
    return 'Sesonganalyse - $dogName';
  }

  @override
  String get advanced_statistics_sessions => 'Økter';

  @override
  String get advanced_statistics_points => 'Poeng';

  @override
  String get advanced_statistics_points_per_hour => 'Poeng per time';

  @override
  String get advanced_statistics_dog_comparison => 'Hundsammenligning';

  @override
  String get advanced_statistics_success_rate_percent => 'Suksessrate (%)';

  @override
  String get advanced_statistics_export_reports => 'Eksport av rapporter';

  @override
  String get advanced_statistics_export_statistics_csv => 'Eksporter statistikker som CSV';

  @override
  String get advanced_statistics_contains_comparison_all_dogs => 'Inneholder sammenligning av alle hunder med nøkkeltall.';

  @override
  String get advanced_statistics_export_sessions_csv => 'Eksporter alle økt-data som CSV';

  @override
  String get advanced_statistics_sessions_csv_description => 'Detaljert oversikt over alle jaktsesjoner med alle felter.';

  @override
  String get advanced_statistics_generate_text_report_description => 'Generer en tekst-sammendrag av alle statistikker.';

  @override
  String get advanced_statistics_export_session_data => 'Eksporter økt-data';

  @override
  String advanced_statistics_text_report_for(Object dogName) {
    return 'Tekstrapport for $dogName';
  }

  @override
  String get advanced_statistics_generate_readable_text_report => 'Generer en lesbar tekst-rapport med alle statistikker.';

  @override
  String stats_week_label(int week) {
    return 'Uke $week';
  }

  @override
  String get common_conjunction_and => 'og';

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
      other: '$count økter',
      one: '$count økt',
    );
    return '$_temp0';
  }

  @override
  String stats_birds_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fugler',
      one: '$count fugl',
    );
    return '$_temp0';
  }

  @override
  String stats_flushes_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count støkk',
      one: '$count støkk',
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
      other: '$count dager',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get common_months_short => 'mnd';

  @override
  String get stats_screen_title => 'Statistikk';

  @override
  String get stats_period_daily => 'Daglig';

  @override
  String get stats_period_weekly => 'Ukentlig';

  @override
  String get stats_period_monthly => 'Månedlig';

  @override
  String get stats_no_sessions_registered => 'Ingen økter registrert enda';

  @override
  String get stats_filter_all_dogs => 'Alle hunder';

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
      other: '$count bøtter',
      one: '$count bøtte',
    );
    return '$_temp0';
  }

  @override
  String stats_total_label(Object count) {
    return 'Totalt: $count';
  }

  @override
  String stats_more_points(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flere poeng',
      one: '$count flere poeng',
    );
    return '$_temp0';
  }

  @override
  String stats_trend_point_label(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get dogs => 'Hund';

  @override
  String get dog_sex_male => 'Hannhund';

  @override
  String get dog_sex_female => 'Tispe';

  @override
  String get dog_unnamed => 'Uten navn';

  @override
  String dog_subtitle_born_prefix(String date) {
    return 'Født: $date';
  }

  @override
  String get dog_editor_error_name_missing => 'Navn mangler';

  @override
  String get dog_editor_save => 'Lagre';

  @override
  String get dog_editor_saving => 'Lagrer…';

  @override
  String get dog_editor_delete_dog => 'Slett hund';

  @override
  String get dog_editor_deleting => 'Sletter…';

  @override
  String get dog_editor_delete_dog_title => 'Slett hund';

  @override
  String get dog_editor_delete_dog_body => 'Vil du slette hunden? Dette kan ikke angres.';

  @override
  String get dog_editor_discard_changes_title => 'Forkast endringer?';

  @override
  String get dog_editor_discard_changes_body => 'Endringene er ikke lagret ennå.';

  @override
  String get dog_editor_discard_changes_confirm => 'Forkast';

  @override
  String get dog_editor_intro_title => 'Legg til hunden din';

  @override
  String get dog_editor_intro_body => 'Du kan begynne enkelt nå. Navn er nok for å komme i gang, og flere detaljer kan legges inn senere.';

  @override
  String get dog_editor_button_cancel => 'Avbryt';

  @override
  String get dog_editor_button_delete => 'Slett';

  @override
  String get dog_editor_new_breed_title => 'Ny rase';

  @override
  String get dog_editor_new_breed_hint => 'F.eks. Gordon setter';

  @override
  String get dog_editor_button_add => 'Legg til';

  @override
  String get dog_editor_select_breed_label => 'Velg rase';

  @override
  String get dog_editor_select_breed_placeholder => 'Velg rase';

  @override
  String get dog_editor_new_breed_option => 'Ny rase…';

  @override
  String get dog_editor_name_label => 'Navn';

  @override
  String get dog_editor_nickname_label => 'Kallenavn';

  @override
  String get dog_editor_nickname_hint => 'Valgfritt (f.eks Zoë, Bowie)';

  @override
  String get dog_editor_birthdate_label => 'Fødselsdato';

  @override
  String get dog_editor_birthdate_not_set => 'Ikke satt';

  @override
  String get dog_editor_regnr_label => 'Reg.nr';

  @override
  String get dog_editor_pedigree_url_label => 'Stamtavle URL';

  @override
  String get dog_editor_memory_words_label => 'Minneord';

  @override
  String get dog_editor_image_text_anchor_label => 'Tekstplassering på bilde';

  @override
  String get dog_editor_death_registered_title => 'Registrert død';

  @override
  String get dog_editor_section_breed_title => 'Rase';

  @override
  String get dog_editor_section_sex => 'Kjønn';

  @override
  String get dog_editor_role_section_title => 'Velg rolle';

  @override
  String get dog_editor_role_owner => 'Eier';

  @override
  String get dog_editor_role_admin => 'Administrator';

  @override
  String get dog_editor_role_user => 'Bruker';

  @override
  String get dog_editor_section_hero_title => 'Hero-tekst';

  @override
  String get dog_editor_anchor_bottom_left => 'Nederst til venstre';

  @override
  String get dog_editor_anchor_bottom_center => 'Nederst midtstilt';

  @override
  String get dog_editor_anchor_top_left => 'Øverst til venstre';

  @override
  String get dog_editor_text_size_label => 'Tekststørrelse';

  @override
  String get dog_editor_text_size_small => 'Lite';

  @override
  String get dog_editor_text_size_normal => 'Normal';

  @override
  String get dog_editor_text_size_large => 'Stor';

  @override
  String get dog_editor_section_lifecycle_title => 'Livsløp';

  @override
  String get dog_editor_death_date_label => 'Dødsdato';

  @override
  String get dog_editor_death_date_picker_hint => 'Velg dato';

  @override
  String get dog_detail_snackbar_invite_accepted => 'Invitasjon akseptert';

  @override
  String get dog_detail_snackbar_invite_declined => 'Invitasjon avvist';

  @override
  String get dog_detail_snackbar_invite_sent => 'Invitasjon sendt';

  @override
  String get dog_detail_snackbar_ownership_accepted => 'Eierskap godtatt';

  @override
  String get dog_detail_snackbar_request_declined => 'Forespørsel avslått';

  @override
  String get dog_detail_snackbar_request_cancelled => 'Forespørsel avbrutt';

  @override
  String get dog_detail_snackbar_image_save_failed => 'Kunne ikke lagre bildet.';

  @override
  String get dog_detail_snackbar_pedigree_invalid => 'Stamtavle-linken er ugyldig eller kan ikke åpnes.';

  @override
  String get dog_detail_photo_source_gallery => 'Velg fra bilder';

  @override
  String get dog_detail_photo_source_camera => 'Ta bilde';

  @override
  String get dog_detail_button_cancel => 'Avbryt';

  @override
  String get dog_detail_pedigree_section_title => 'Stamtavle';

  @override
  String get dog_detail_button_open_pedigree => 'Åpne stamtavle';

  @override
  String get dog_pedigree_no_link => 'Ingen lenke registrert';

  @override
  String get dog_detail_appbar_title => 'Hundeprofil';

  @override
  String get dog_detail_error_dog_not_found => 'Hund ikke funnet';

  @override
  String get dog_detail_title_add_dog => 'Legg til hund';

  @override
  String get dog_editor_title_add_dog => 'Legg til hund';

  @override
  String get dog_editor_title_edit_dog => 'Rediger hund';

  @override
  String get dog_profile_title => 'Hund';

  @override
  String get dog_profile_subtitle_breed_age => 'Rase · Alder';

  @override
  String get dog_generic_name => 'Hund';

  @override
  String get dog_detail_section_access => 'Tilganger';

  @override
  String get dog_detail_button_send_invite => 'Send invitasjon';

  @override
  String get dog_detail_section_invites => 'Invitasjoner';

  @override
  String get invite_send_email_label => 'Mottakers e-post';

  @override
  String get invite_send_button => 'Send invitasjon';

  @override
  String invite_sent_to(Object email) {
    return 'Invitasjon sendt til $email';
  }

  @override
  String get invite_revoke_button => 'Trekk tilbake';

  @override
  String get invite_status_invited => 'Invitert';

  @override
  String invite_status_invited_as_user(Object role) {
    return 'Invitert som $role';
  }

  @override
  String get invite_accept => 'Aksepter';

  @override
  String get invite_decline => 'Avslå';

  @override
  String get dog_share_section_title => 'Delt med';

  @override
  String get dog_detail_access_section_title => 'Tilgang til denne hunden';

  @override
  String get dog_detail_member_action_set_reader => 'Sett som leser';

  @override
  String get dog_detail_member_action_set_user => 'Sett som bruker';

  @override
  String get dog_detail_member_action_remove_access => 'Fjern tilgang';

  @override
  String get share_role_owner => 'Eier';

  @override
  String get share_role_admin => 'Administrator';

  @override
  String get share_role_user => 'Bruker';

  @override
  String get dog_detail_share_empty => 'Ingen invitasjoner';

  @override
  String get dog_detail_share_empty_owner => 'Ingen deling enda.';

  @override
  String dog_detail_my_role_label(String role) {
    return 'Din rolle: $role';
  }

  @override
  String get dog_detail_share_disabled_explanation => 'Du har ikke rettigheter til å dele denne hunden.';

  @override
  String get share_accept_title => 'Aksepter deling';

  @override
  String get share_accept_code_label => 'Delingskode';

  @override
  String get share_accept_scan_qr => 'Skann QR';

  @override
  String get share_accept_button => 'Aksepter';

  @override
  String get share_error_dialog_title => 'Deling feilet';

  @override
  String get share_error_not_owner => 'Kun eier eller administrator kan dele hunden.';

  @override
  String get share_error_invite_not_found => 'Invitasjonen ble ikke funnet.';

  @override
  String get share_error_invite_expired => 'Invitasjonen er utløpt.';

  @override
  String get share_error_invite_revoked => 'Invitasjonen er trukket tilbake.';

  @override
  String get share_error_invite_inactive => 'Invitasjonen er ikke aktiv.';

  @override
  String get share_error_already_has_access => 'Du har allerede tilgang.';

  @override
  String get share_error_already_invited => 'Denne e-postadressen er allerede invitert.';

  @override
  String get share_error_invalid_role => 'Ugyldig rolle.';

  @override
  String get share_error_invalid_email => 'Ugyldig e-postadresse.';

  @override
  String get share_error_dog_not_found_title => 'Hund ikke funnet';

  @override
  String get share_error_dog_not_found_detail => 'Fant ingen hund for denne koden.';

  @override
  String get transfer_error_not_owner => 'Kun eier kan avslå forespørselen.';

  @override
  String get transfer_error_not_recipient => 'Du er ikke mottaker av denne forespørselen.';

  @override
  String get transfer_error_not_found => 'Forespørselen ble ikke funnet.';

  @override
  String get transfer_error_expired => 'Forespørselen er utløpt.';

  @override
  String get transfer_error_not_pending => 'Forespørselen er ikke aktiv.';

  @override
  String get transfer_error_cannot_transfer_to_self => 'Kan ikke overføre til seg selv.';

  @override
  String get transfer_error_cancelled => 'Forespørselen er allerede avslått.';

  @override
  String get role_owner => 'Eier';

  @override
  String get role_editor => 'Redaktør';

  @override
  String get role_viewer => 'Leser';

  @override
  String get role_admin => 'Administrator';

  @override
  String get dog_editor_owner_email_label => 'Eierens e-post';

  @override
  String get dog_editor_owner_email_hint => 'navn@eksempel.no';

  @override
  String get dog_editor_owner_email_required_error => 'Skriv inn en gyldig e-post for eieren.';

  @override
  String get dog_detail_section_owner_request_title => 'Eierskap forespurt';

  @override
  String dog_detail_label_from_user(String userId) {
    return 'Fra: $userId';
  }

  @override
  String dog_detail_label_to_user(String userId) {
    return 'Til: $userId';
  }

  @override
  String get dog_detail_button_accept => 'Aksepter';

  @override
  String get dog_detail_button_decline => 'Avslå';

  @override
  String get dog_detail_button_cancel_request => 'Avbryt forespørsel';

  @override
  String get dog_detail_button_edit_photo => 'Endre profilbilde';

  @override
  String get dog_detail_button_mark_dead => 'Marker som død';

  @override
  String get dog_detail_watermark_section_title => 'Vannmerke';

  @override
  String get dog_detail_watermark_info => 'Vannmerke er obligatorisk ved deling av hundebilder.';

  @override
  String get dog_detail_watermark_toggle_title => 'Vis tittel';

  @override
  String get dog_detail_watermark_toggle_name => 'Vis navn';

  @override
  String get dog_detail_watermark_share_button => 'Del bilde';

  @override
  String get dog_detail_watermark_share_subject => 'Bilde fra GundogTracker';

  @override
  String get dog_detail_watermark_share_message => 'Delt fra GundogTracker';

  @override
  String get session_image_viewer_watermark_toggle_title => 'Vis tittel';

  @override
  String get session_image_viewer_watermark_toggle_official_name => 'Vis offisielt navn';

  @override
  String get session_image_viewer_watermark_toggle_nickname => 'Vis kallenavn';

  @override
  String get session_image_viewer_watermark_color_title => 'Tekstfarge';

  @override
  String get session_image_viewer_watermark_color_light => 'Hvit';

  @override
  String get session_image_viewer_watermark_color_dark => 'Svart';

  @override
  String get session_image_viewer_watermark_presets_title => 'Presets';

  @override
  String get session_image_viewer_watermark_preset_discreet => 'Diskré';

  @override
  String get session_image_viewer_watermark_preset_clear => 'Klar';

  @override
  String get session_image_viewer_watermark_preset_contrast => 'Kontrast';

  @override
  String get dog_detail_watermark_share_missing_photo => 'Fant ikke et bilde å dele.';

  @override
  String get dog_detail_watermark_share_error => 'Kunne ikke dele bildet.';

  @override
  String get dog_detail_label_death_date => 'Dødsdato';

  @override
  String get dog_detail_button_edit => 'Endre';

  @override
  String get dog_detail_button_register_death => 'Registrer';

  @override
  String get dog_detail_photo_dialog_title => 'Profilbilde';

  @override
  String get dog_detail_photo_pick_camera => 'Ta bilde';

  @override
  String get dog_detail_photo_pick_gallery => 'Velg fra bilder';

  @override
  String get dog_detail_photo_remove => 'Fjern bilde';

  @override
  String get dog_detail_snackbar_photo_updated => 'Profilbilde oppdatert';

  @override
  String get dog_detail_snackbar_photo_removed => 'Profilbilde fjernet';

  @override
  String get dog_detail_snackbar_error_generic => 'Noe gikk galt';

  @override
  String get dog_detail_info_label_sex => 'Kjønn';

  @override
  String get dog_detail_info_label_born => 'Født';

  @override
  String get dog_detail_summary_points_label => 'Stander';

  @override
  String get dog_detail_summary_session_count_label => 'Antall økter';

  @override
  String get dog_detail_summary_active_time_label => 'Tid aktiv';

  @override
  String get dog_detail_summary_birds_down_label => 'Fugl felt';

  @override
  String get dog_detail_summary_first_session_label => 'Første økt';

  @override
  String get dog_detail_summary_last_session_label => 'Siste økt';

  @override
  String get dog_detail_tooltip_edit_profile => 'Rediger hund';

  @override
  String get dog_detail_farewell_prefix => 'Avskjed';

  @override
  String dog_detail_farewell_age_sentence(Object name, Object years, Object months, Object days) {
    return '$name ble $years $months $days gammel';
  }

  @override
  String get dog_detail_next_milestones_title => 'Neste milepæler';

  @override
  String get dog_detail_next_milestone_title => 'Neste milepæl';

  @override
  String get milestone_first_session_title => 'Første økt gjennomført';

  @override
  String milestone_first_session_subtitle(Object dogName) {
    return 'Første økt med $dogName';
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
      other: '$count mnd',
      one: '$count mnd',
    );
    return '$_temp0';
  }

  @override
  String age_months_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mnd',
      one: '$count mnd',
    );
    return '$_temp0';
  }

  @override
  String age_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager',
      one: '$count dag',
    );
    return '$_temp0';
  }

  @override
  String get age_zero_days => '0 dager';

  @override
  String get age_and => 'og';

  @override
  String get home_startNewSession => 'Start ny økt';

  @override
  String get chooseDog => 'Velg hund';

  @override
  String get noDogsAddDog => 'Ingen hunder – legg til hund';

  @override
  String get home_addDogPrompt => 'Legg til hund for å starte økt';

  @override
  String get home_empty_title => 'Start reisen med jakthunden din';

  @override
  String get home_empty_body => 'Logg økter, følg utviklingen og bygg en historikk på hunden din – økt for økt.';

  @override
  String get home_empty_bullet_progress => 'Se utvikling over tid – stand, støkk og aktivitet.';

  @override
  String get home_empty_bullet_training => 'Bedre trening og jakt – se hva som faktisk gir uttelling.';

  @override
  String get home_empty_bullet_history => 'Jakt-historikk du faktisk bruker – sesong for sesong, område for område.';

  @override
  String get home_addDog_button => 'Legg til hund';

  @override
  String get home_empty_next_step => 'Begynn med å legge til hunden din. Deretter kan du logge første økt når dere er klare.';

  @override
  String get home_first_session_title => 'Klar for første økt?';

  @override
  String get home_first_session_body => 'Du har hunden på plass. Neste steg er å logge en økt, så bygger du historikk og statistikk fra start.';

  @override
  String get home_empty_offline_note => 'Du kan bruke appen helt offline. All data lagres lokalt på telefonen din.';

  @override
  String get home_visible_empty_title => 'Ingen hunder tilgjengelig';

  @override
  String get home_visible_empty_body => 'Du har ingen hunder knyttet til denne kontoen. Sjekk invitasjoner eller be noen dele en hund med deg.';

  @override
  String get home_visible_empty_button => 'Åpne invitasjoner';

  @override
  String get home_noDogsRegistered => 'Ingen hunder registrert';

  @override
  String get home_primaryActionSubtitle => 'Notater først. Tellere med + i felt.';

  @override
  String get home_top10_points_title => 'Topp 10 stander';

  @override
  String get top10Title => 'Topp 10';

  @override
  String get home_top10_points_empty => 'Ingen stand registrert ennå.';

  @override
  String home_top10_points_pointsLabel(int count) {
    return 'Stander: $count';
  }

  @override
  String get standsLabel => 'Stand';

  @override
  String standsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stander',
      one: '1 stand',
      zero: '0 stander',
    );
    return '$_temp0';
  }

  @override
  String top10_points_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stander',
      one: 'stand',
    );
    return '$_temp0';
  }

  @override
  String get home_top10_birds_title => 'Topp 10 felt fugl';

  @override
  String get home_top10_birds_empty => 'Ingen fugl registrert ennå.';

  @override
  String get home_top10_birds_fieldLabel => 'Fugl';

  @override
  String get session_log_title => 'Øktlogging – Fuglehund';

  @override
  String get session_saved_list_title => 'Lagrede økter';

  @override
  String get session_save_button => 'Lagre økt';

  @override
  String get session_unit_min => 'min';

  @override
  String get session_unit_sec => 'sek';

  @override
  String get session_label_points => 'stand';

  @override
  String get session_label_flushes => 'støkk';

  @override
  String get session_label_birds => 'fugl';

  @override
  String get session_label_birds_down => 'felt fugl';

  @override
  String get session_all_dogs_label => 'Alle hunder';

  @override
  String get session_map_label => 'Kart';

  @override
  String get session_map_error_no_tracks => 'Fant ingen spor';

  @override
  String get session_map_error_map_load_failed => 'Kunne ikke laste kartet';

  @override
  String get map_page_snackbar_no_tracks_to_focus => 'Ingen spor å fokusere på';

  @override
  String get map_page_dialog_delete_downloaded_map_body => 'Vil du slette dette nedlastede kartet?';

  @override
  String get map_download_title => 'Last ned kart';

  @override
  String get map_download_area_label => 'Område';

  @override
  String get map_download_cancel => 'Avbryt';

  @override
  String get map_download_start => 'Start nedlasting';

  @override
  String get map_downloaded_maps_title => 'Nedlastede kart';

  @override
  String get map_downloaded_maps_empty => 'Ingen nedlastede kart ennå.';

  @override
  String get map_delete_offline_title => 'Slett offline kart';

  @override
  String get map_delete_offline_body => 'Dette sletter nedlastede karttiles for valgt stil.';

  @override
  String get map_delete_offline_cancel => 'Avbryt';

  @override
  String get map_delete_offline_confirm => 'Slett';

  @override
  String get map_downloading_title => 'Laster ned kart';

  @override
  String get map_downloading_cancel => 'Avbryt';

  @override
  String get map_go_to => 'Gå til';

  @override
  String get map_delete => 'Slett';

  @override
  String get map_delete_title => 'Slett kart';

  @override
  String get map_tracks => 'Spor';

  @override
  String get map_me => 'Meg';

  @override
  String get hunt_session_snackbar_export_ready_opening_share => 'Eksport klar, åpner deling …';

  @override
  String get hunt_session_snackbar_gpx_export_failed_see_log => 'GPX-eksport feilet. Se logg.';

  @override
  String get session_gpx_import_label => 'Importer GPX';

  @override
  String get session_gpx_importing_ellipsis => 'Importer…';

  @override
  String get session_gpx_export_label => 'Eksporter GPX';

  @override
  String get session_gpx_exporting_ellipsis => 'Eksporterer…';

  @override
  String get session_form_dog_section_title => 'Hund';

  @override
  String get session_form_dog_prefix => 'Hund:';

  @override
  String get session_form_no_dogs_registered => 'Ingen hunder registrert.';

  @override
  String get session_form_no_dogs_help => 'Legg til en hund først, så kan du starte den første økten.';

  @override
  String get session_summary_sessions_label => 'Antall økter:';

  @override
  String get session_summary_total_time_label => 'Total tid:';

  @override
  String get session_summary_total_bird_contacts_label => 'Fuglkontakter total:';

  @override
  String get session_summary_total_points_label => 'Stand total:';

  @override
  String get session_summary_total_secondary_points_label => 'Sekundering total:';

  @override
  String get session_summary_total_tomstand_label => 'Tomstand total:';

  @override
  String get session_summary_total_flushes_label => 'Støkk total:';

  @override
  String get session_action_add_new_session => 'Legg inn ny økt';

  @override
  String get session_action_cancel => 'Avbryt';

  @override
  String get session_type_title => 'Økt-type';

  @override
  String get session_type_training => 'Trening';

  @override
  String get session_type_hunt => 'Jakt';

  @override
  String get session_field_location => 'Sted';

  @override
  String get session_field_active_time_minutes => 'Tid aktiv (min)';

  @override
  String get session_field_bird_contacts => 'Fuglkontakter';

  @override
  String get session_field_points => 'Stand';

  @override
  String get session_field_secondary_points => 'Sekundering';

  @override
  String get session_field_tomstand => 'Tomstand';

  @override
  String get session_field_flushes => 'Støkk';

  @override
  String get session_pick_date => 'Velg dato';

  @override
  String get session_pick_time => 'Klokkeslett';

  @override
  String get session_birds_section_title => 'Fugl';

  @override
  String get session_birds_select_species => 'Velg fuglearter';

  @override
  String get session_birds_none_selected => 'Ingen arter valgt';

  @override
  String get session_species_picker_title => 'Velg fuglearter';

  @override
  String get session_species_picker_empty => 'Ingen arter tilgjengelig';

  @override
  String get session_species_picker_add => 'Legg til';

  @override
  String get session_species_picker_done => 'Ferdig';

  @override
  String get session_error_no_dogs_registered => 'Ingen hunder registrert';

  @override
  String get session_select_species_title => 'Velg art';

  @override
  String get session_no_species_saved_yet => 'Ingen arter lagret ennå';

  @override
  String get session_new_bird_button => 'Ny fugl';

  @override
  String get session_new_species_title => 'Ny art';

  @override
  String get session_error_photo_add => 'Kunne ikke legge til bilde';

  @override
  String get session_error_video_add => 'Kunne ikke legge til video';

  @override
  String get session_error_media_save => 'Kunne ikke lagre mediafilen';

  @override
  String get session_error_gpx_import => 'GPX-import feilet. Se logg.';

  @override
  String get session_error_location_services_disabled => 'Stedstjenester er deaktivert';

  @override
  String get session_error_no_gps => 'Ingen GPS-tilgang';

  @override
  String session_error_gps_failure(String error) {
    return 'Feil fra GPS: $error';
  }

  @override
  String get session_error_stop_gps => 'Klarte ikke stoppe GPS';

  @override
  String get session_error_select_dog_first => 'Velg en hund først';

  @override
  String get session_error_no_track_export => 'Denne økten har ikke noe spor å eksportere';

  @override
  String get session_error_track_empty => 'Spor mangler/er tomt';

  @override
  String session_snackbar_message(String message) {
    return '$message';
  }

  @override
  String get session_media_add_image_failed => 'Kunne ikke legge til bilde';

  @override
  String get session_media_add_video_failed => 'Kunne ikke legge til video';

  @override
  String get session_media_save_failed => 'Kunne ikke lagre mediafilen';

  @override
  String get session_media_video_missing => 'Video mangler eller ble ikke lagret riktig';

  @override
  String get session_media_video_open_failed => 'Kunne ikke åpne video';

  @override
  String get session_media_section_title => 'Media';

  @override
  String get session_media_add_photo_video => 'Legg til bilde/video';

  @override
  String get session_media_gallery_label => 'Bilde fra galleri';

  @override
  String get session_media_camera_label => 'Ta bilde';

  @override
  String get session_media_video_label => 'Video fra galleri';

  @override
  String get gpx_import_failed_see_log => 'GPX-import feilet. Se logg.';

  @override
  String get gps_services_disabled => 'Stedstjenester er deaktivert';

  @override
  String get gps_no_permission => 'Ingen GPS-tilgang';

  @override
  String gps_error_message(String error) {
    return 'Feil fra GPS: $error';
  }

  @override
  String get gps_stop_failed => 'Klarte ikke stoppe GPS';

  @override
  String get session_select_dog_first => 'Velg en hund først';

  @override
  String get session_export_no_track => 'Denne økten har ikke noe spor å eksportere';

  @override
  String get session_track_missing_or_empty => 'Spor mangler/er tomt';

  @override
  String gpx_exported_to_desktop(String filename) {
    return 'GPX eksportert til Skrivebordet: $filename ✅';
  }

  @override
  String get session_detail_title_edit_session => 'Rediger økt';

  @override
  String get session_detail_title_new_session => 'Ny økt';

  @override
  String get session_detail_label_points => 'Stand';

  @override
  String get session_detail_label_flushes => 'Støkk';

  @override
  String get session_detail_button_add_media => 'Legg til bilde/video';

  @override
  String session_detail_total_points(String value) {
    return 'Stand totalt: $value';
  }

  @override
  String get session_detail_title_home => 'Hjem';

  @override
  String get session_detail_title_main => 'Økt';

  @override
  String get session_detail_title_active_session => 'Aktiv økt';

  @override
  String get active_session_hunt_events_title => 'Jakthendelser +1';

  @override
  String get active_session_action_stand_plus1 => 'Stand +1';

  @override
  String get active_session_action_secondary_plus1 => 'Sekundering +1';

  @override
  String get active_session_action_flush_plus1 => 'Støkk +1';

  @override
  String get active_session_action_bird_plus1 => 'Fugl +1';

  @override
  String get active_session_action_undo => 'Angre';

  @override
  String get session_detail_label_choose_dog => 'Velg hund';

  @override
  String get session_detail_button_open_latest_session => 'Åpne siste økt';

  @override
  String get session_detail_button_start_new_session => 'Start ny økt';

  @override
  String get session_detail_button_settings => 'Innstillinger';

  @override
  String get session_detail_media_sheet_title => 'Legg til media';

  @override
  String get session_detail_media_sheet_action_gallery => 'Galleri';

  @override
  String get session_detail_media_sheet_action_camera => 'Kamera';

  @override
  String get session_detail_media_sheet_action_video => 'Video';

  @override
  String get session_detail_media_section_title => 'Media';

  @override
  String get session_detail_media_empty_placeholder => 'Ingen media lagt til';

  @override
  String get session_detail_notes_hint => 'Notater fra økta...';

  @override
  String session_detail_meta_time_minutes(Object minutes) {
    return 'Tid aktiv: $minutes min';
  }

  @override
  String session_detail_meta_birds(Object value) {
    return 'Fuglkontakter: $value';
  }

  @override
  String session_detail_meta_secondary_points(Object count) {
    return 'Sekundering: $count';
  }

  @override
  String session_detail_meta_flushes(Object value) {
    return 'Støkk: $value';
  }

  @override
  String get session_detail_screen_title => 'Øktdetalj';

  @override
  String get session_notes_hint_from_session => 'Notater fra økta...';

  @override
  String get session_notes_section_title => 'Notater';

  @override
  String get session_detail_section_dog => 'Hund';

  @override
  String get session_detail_section_media => 'Media';

  @override
  String get session_detail_section_notes => 'Notater';

  @override
  String get session_detail_media_open_gallery => 'Åpne galleri';

  @override
  String get session_detail_button_import_gpx => 'Importer GPX';

  @override
  String get session_detail_button_importing => 'Importerer…';

  @override
  String get session_detail_empty_bird_species => 'Ingen fuglearter';

  @override
  String get session_detail_empty_location => 'Ukjent sted';

  @override
  String get session_detail_saved_sessions_title => 'Lagrede økter';

  @override
  String get session_detail_empty_sessions_for_selected_dog => 'Ingen økter for valgt hund';

  @override
  String get session_detail_empty_dogs_registered => 'Ingen hunder registrert.';

  @override
  String get session_detail_empty_sessions_yet => 'Ingen økter ennå';

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
    return 'Slutt: $time';
  }

  @override
  String session_detail_track_summary_distance_meters(String meters) {
    return 'Distanse: $meters m';
  }

  @override
  String session_detail_track_summary_distance_km(String kilometers) {
    return 'Distanse: $kilometers km';
  }

  @override
  String session_detail_track_summary_duration(String value) {
    return 'Varighet: $value';
  }

  @override
  String get session_detail_action_saving => 'Lagrer…';

  @override
  String get session_detail_action_save_changes => 'Lagre endringer';

  @override
  String get session_detail_action_save_session => 'Lagre økt';

  @override
  String get session_detail_edit_title => 'Rediger økt';

  @override
  String get session_detail_button_save => 'Lagre';

  @override
  String get session_detail_button_cancel => 'Avbryt';

  @override
  String get session_detail_button_delete => 'Slett';

  @override
  String get session_detail_field_location_label => 'Sted';

  @override
  String get session_detail_field_active_time_minutes_label => 'Tid aktiv (min)';

  @override
  String get session_detail_field_bird_contacts_label => 'Fuglkontakter';

  @override
  String get session_detail_field_points_label => 'Stand';

  @override
  String get session_detail_field_secondary_points_label => 'Sekundering';

  @override
  String get session_detail_field_tomstand_label => 'Tomstand';

  @override
  String get session_detail_field_flushes_label => 'Støkk';

  @override
  String get session_detail_field_notes_label => 'Notat';

  @override
  String session_detail_version_build(String buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String settings_version_label(Object version) {
    return 'Versjon $version';
  }

  @override
  String settings_version_build(Object buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String get session_detail_snackbar_changes_saved => 'Endringer lagret';

  @override
  String get session_detail_snackbar_session_saved => 'Økt lagret';

  @override
  String session_detail_snackbar_saved_with_imported_gpx(int points) {
    return 'Økt lagret med importert GPX ($points punkter)';
  }

  @override
  String session_detail_snackbar_saved_with_gps_track(int points) {
    return 'Økt lagret med GPS-spor ($points punkter)';
  }

  @override
  String get session_detail_help_notes_first => 'Notater først. Tellere med + i felt.';

  @override
  String session_detail_stats_sessions_count(int count) {
    return 'Antall økter: $count';
  }

  @override
  String session_detail_stats_total_active_time(int minutes) {
    return 'Total tid aktiv: $minutes min';
  }

  @override
  String session_detail_stats_total_birds(int count) {
    return 'Fuglkontakter totalt: $count';
  }

  @override
  String session_detail_stats_total_points(int count) {
    return 'Stand totalt: $count';
  }

  @override
  String session_detail_stats_total_secondary_points(int count) {
    return 'Sekundering totalt: $count';
  }

  @override
  String session_detail_stats_total_tomstand(int count) {
    return 'Tomstand totalt: $count';
  }

  @override
  String session_detail_stats_total_flushes(int count) {
    return 'Støkk totalt: $count';
  }

  @override
  String get session_detail_button_select_date => 'Velg dato';

  @override
  String get session_detail_button_select_time => 'Klokkeslett';

  @override
  String get session_detail_label_duration_from_track => 'Hentet fra GPS-spor';

  @override
  String get session_detail_confirm_delete_title => 'Slette økt?';

  @override
  String get session_detail_confirm_delete_body => 'Dette fjerner økten fra hunden.';

  @override
  String get session_detail_media_delete_title => 'Slette media?';

  @override
  String get session_detail_media_delete_body => 'Dette fjerner valgt media fra økten.';

  @override
  String session_detail_saved_session_summary(int durationMinutes, int birds, int stand, int secondaryPoints, int tomstandCount, int flushes) {
    return 'Tid: $durationMinutes min, Fugl: $birds, stand: $stand, sekundering: $secondaryPoints, tomstand: $tomstandCount, støkk: $flushes';
  }

  @override
  String get session_detail_button_exporting => 'Eksporterer…';

  @override
  String get session_detail_button_export_gpx => 'Eksporter GPX';

  @override
  String get session_detail_error_gpx_too_few_points => 'Fant for få GPX-punkter i filen';

  @override
  String session_detail_helper_duration_hours_minutes(int hours, int minutes) {
    return '${hours}t ${minutes}m';
  }

  @override
  String get session_detail_bird_species_picker_title => 'Velg fuglearter';

  @override
  String get session_detail_bird_section_title => 'Fugl';

  @override
  String get session_detail_bird_species_button_label => 'Velg fuglearter';

  @override
  String get session_detail_bird_species_empty_selection => 'Ingen arter valgt';

  @override
  String get session_detail_bird_species_empty_saved => 'Ingen arter lagret ennå';

  @override
  String get session_detail_bird_species_new => 'Ny fugl';

  @override
  String get session_detail_action_done => 'Ferdig';

  @override
  String get session_detail_bird_species_dialog_title => 'Ny fugleart';

  @override
  String get session_detail_bird_species_dialog_name_label => 'Navn';

  @override
  String get session_action_save => 'Lagre';

  @override
  String get session_detail_media_gallery_title => 'Media';

  @override
  String get hunt_session_title_new => 'Ny økt';

  @override
  String get hunt_session_title_edit => 'Rediger økt';

  @override
  String get hunt_session_field_location_label => 'Sted';

  @override
  String get hunt_session_field_duration_minutes_label => 'Tid aktiv (min)';

  @override
  String get hunt_session_field_birds_seen_label => 'Fuglkontakter';

  @override
  String get hunt_session_field_points_label => 'Stand';

  @override
  String get hunt_session_field_secondary_points_label => 'Sekundering';

  @override
  String get hunt_session_field_tomstand_label => 'Tomstand';

  @override
  String get hunt_session_field_flushes_label => 'Støkk';

  @override
  String get hunt_session_field_notes_label => 'Notat';

  @override
  String get hunt_session_action_save => 'Lagre';

  @override
  String get hunt_session_action_cancel => 'Avbryt';

  @override
  String get hunt_session_action_delete => 'Slett';

  @override
  String get hunt_session_action_import_gpx => 'Importer GPX';

  @override
  String get hunt_session_action_importing => 'Importer…';

  @override
  String hunt_session_snackbar_saved_with_gps_track(Object points) {
    return 'Økt lagret med GPS-spor ($points punkter)';
  }

  @override
  String get session_detail_filter_all_dogs => 'Alle hunder';

  @override
  String get session_detail_session_menu_export => 'Eksporter GPX';

  @override
  String get session_detail_session_menu_exporting => 'Eksporterer…';

  @override
  String get session_detail_session_menu_edit => 'Rediger økt';

  @override
  String get session_detail_session_menu_delete => 'Slett økt';

  @override
  String get session_detail_detail_title => 'Detaljer';

  @override
  String get session_detail_detail_label_date => 'Dato';

  @override
  String get session_detail_detail_label_location => 'Sted';

  @override
  String get session_detail_detail_label_active_time => 'Tid aktiv';

  @override
  String get session_detail_detail_label_bird_contacts => 'Fuglkontakter';

  @override
  String get session_detail_detail_label_points => 'Stand';

  @override
  String get session_detail_detail_label_secondary_points => 'Sekundering';

  @override
  String get session_detail_detail_label_tomstand => 'Tomstand';

  @override
  String get session_detail_detail_label_flushes => 'Støkk';

  @override
  String get session_detail_label_bird_species => 'Fuglearter';

  @override
  String get session_detail_label_gps_track => 'GPS-spor';

  @override
  String get session_detail_label_yes => 'Ja';

  @override
  String get session_detail_label_no => 'Nei';

  @override
  String get session_detail_label_dog_prefix => 'Hund: ';

  @override
  String get session_detail_map_title => 'Kart';

  @override
  String get session_detail_map_prefix => 'Kart – ';

  @override
  String get map_title => 'Kart';

  @override
  String get session_detail_gpx_replace_title => 'Erstatt spor?';

  @override
  String get session_detail_gpx_replace_body => 'Dette vil erstatte eksisterende spor. Fortsette?';

  @override
  String get session_detail_gpx_replace_confirm => 'Erstatt';

  @override
  String session_detail_gpx_replaced_snackbar(int points) {
    return 'Spor erstattet: $points punkter';
  }

  @override
  String session_detail_gpx_imported_snackbar(int points) {
    return 'GPX importert: $points punkter';
  }

  @override
  String get session_detail_empty_notes => 'Ingen notat';

  @override
  String get session_detail_empty_media => 'Ingen media lagt til';

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
    return 'Støkk totalt: $value';
  }

  @override
  String get gpx_import_label => 'Importer GPX';

  @override
  String get session_menu_edit => 'Rediger økt';

  @override
  String get session_menu_delete => 'Slett økt';

  @override
  String stats_trend_label(String symbol) {
    return 'Trend: $symbol';
  }

  @override
  String get stats_title_points_and_flushes => 'Stand og støkk';

  @override
  String get stats_title_sessions => 'Økter';

  @override
  String get stats_title_birds_down_per_year => 'Felt fugl per år';

  @override
  String get stats_subtitle_active_time => 'Aktiv tid';

  @override
  String get stats_subtitle_session_count => 'Antall økter';

  @override
  String get stats_legend_bars => 'Stolper:';

  @override
  String get stats_legend_line => 'Linje:';

  @override
  String get stats_title_development => 'Utvikling';

  @override
  String get stats_period_30_days => '30 dager';

  @override
  String get stats_period_90_days => '90 dager';

  @override
  String get stats_legend_active_time => 'Aktiv tid';

  @override
  String get stats_legend_sessions => 'Økter';

  @override
  String stats_week_tooltip(String weekLabel, int sessions, String time) {
    return '$weekLabel: $sessions økter, $time';
  }

  @override
  String get stats_info_active_time_title => 'Aktiv tid';

  @override
  String get stats_info_active_time_body_1 => 'Total tid hunden har vært i arbeid.';

  @override
  String get stats_info_active_time_body_2 => 'Brukes til å vurdere belastning og kontinuitet.';

  @override
  String get stats_info_session_count_title => 'Økter';

  @override
  String get stats_info_session_count_body_1 => 'Hvor ofte hunden har vært i aktivitet.';

  @override
  String get stats_info_session_count_body_2 => 'Viser trenings- og jaktfrekvens.';

  @override
  String get stats_v1_overview_title => 'V1-oversikt';

  @override
  String get stats_total_points_title => 'Totale stander';

  @override
  String get stats_total_active_time_title => 'Total aktiv tid';

  @override
  String get stats_avg_points_per_session_title => 'Snitt: stander per økt';

  @override
  String get stats_avg_time_per_session_title => 'Snitt: tid per økt';

  @override
  String get stats_last_30_days_sessions_title => 'Siste 30 dager: Økter';

  @override
  String get stats_last_30_days_points_title => 'Siste 30 dager: Stander';

  @override
  String stats_overview_sessions_value(int count) {
    return '$count økter';
  }

  @override
  String stats_overview_points_value(int count) {
    return '$count stand';
  }

  @override
  String stats_last_30_days_sessions_value(int count) {
    return '$count økter';
  }

  @override
  String stats_last_30_days_points_value(int count) {
    return '$count stand';
  }

  @override
  String get stats_points_label => 'Stand';

  @override
  String get stats_flushes_label => 'Støkk';

  @override
  String stats_per_month_suffix(int year) {
    return 'per måned • $year';
  }

  @override
  String stats_monthly_sessions_tooltip(String month, int year, int count) {
    return '$month $year: $count økter';
  }

  @override
  String stats_monthly_sessions_tooltip_empty(String month, int year) {
    return '$month $year: Ingen økter';
  }

  @override
  String stats_total_points_flushes_prefix(int points, int flushes) {
    return 'Totalt: $points stand, $flushes støkk';
  }

  @override
  String stats_stand_flush_tooltip(String month, int year, String stand, String flush) {
    return '$month $year: Stand $stand, Støkk $flush';
  }

  @override
  String get stats_info_points_flushes_title => 'Stand og støkk';

  @override
  String get stats_info_points_flushes_body_1 => 'Viser antall stander og støkk over tid.';

  @override
  String get stats_info_points_flushes_body_2 => 'Gir innsikt i hundens arbeid i felt og jaktmønster.';

  @override
  String get stats_none => 'Ingen';

  @override
  String get stats_unknown_species => 'Ukjent';

  @override
  String get stats_info_explanation_tooltip => 'Forklaring';

  @override
  String stats_total_sessions_prefix(int count) {
    return 'Totalt: $count økter';
  }

  @override
  String get stats_info_sessions_title => 'Økter';

  @override
  String get stats_info_sessions_body_1 => 'Hvor ofte hunden har vært i aktivitet.';

  @override
  String get stats_info_sessions_body_2 => 'Viser trenings- og jaktfrekvens.';

  @override
  String get stats_no_birds_down_yet => 'Ingen felte fugler registrert enda';

  @override
  String get stats_birds_distribution_title => 'Fordeling felt fugl';

  @override
  String get stats_birds_pie_hint => 'Trykk på et kakestykke for detaljer';

  @override
  String get stats_info_birds_down_title => 'Felt fugl';

  @override
  String get stats_info_birds_down_body_1 => 'Antall felte fugler per kalenderår.';

  @override
  String get stats_info_birds_down_body_2 => 'Gir grunnlag for sammenligning år for år.';

  @override
  String get stats_info_birds_distribution_title => 'Fordeling felt fugl';

  @override
  String get stats_info_birds_distribution_body_1 => 'Viser hvilke arter som er felt i valgt år.';

  @override
  String get stats_info_birds_distribution_body_2 => 'Gir oversikt over jaktuttak og variasjon.';

  @override
  String get stats_label_year => 'År';

  @override
  String get stats_label_total => 'Totalt';

  @override
  String get stats_label_per_month => 'per måned';

  @override
  String get gpx_importing_ellipsis => 'Importer…';

  @override
  String get gpx_export_label => 'Eksporter GPX';

  @override
  String get gpx_exporting_ellipsis => 'Eksporterer…';

  @override
  String get home_open_settings_tooltip => 'Innstillinger';

  @override
  String get home_settings_button_label => 'Innstillinger';

  @override
  String get home_sessions_empty => 'Ingen økter ennå';

  @override
  String get home_openSession => 'Åpne';

  @override
  String get home_select_dog => 'Velg hund';

  @override
  String get home_no_sessions_yet => 'Ingen økter ennå';

  @override
  String get home_no_dogs_title => 'Ingen hunder registrert ennå';

  @override
  String get home_no_dogs_message => 'Registrer hundene dine for å logge trening, jakt og prøver. Da får du en ryddig historikk og bedre oversikt over utviklingen.';

  @override
  String get home_no_dogs_bullet_history => 'Historikk: se økter, notater og steder samlet';

  @override
  String get home_no_dogs_bullet_progress => 'Progresjon: følg stand, støkk og aktiv tid over tid';

  @override
  String get home_no_dogs_bullet_stats => 'Statistikk: meningsfulle trender som støtter jakta';

  @override
  String get home_wisdom_empty => 'En rolig start gir bedre jakt enn hastverk.';

  @override
  String get wisdom_001 => 'En rolig hund lærer raskere enn en stresset.';

  @override
  String get wisdom_002 => 'Det du trener på i dag, får du igjen i høst.';

  @override
  String get wisdom_003 => 'Gjenta mindre. Vent mer.';

  @override
  String get wisdom_004 => 'Stillhet er også trening.';

  @override
  String get wisdom_005 => 'Fremgang skjer ofte mellom øktene.';

  @override
  String get wisdom_006 => 'En pause i tide er bedre enn én repetisjon for mye.';

  @override
  String get wisdom_007 => 'Tålmodighet er den mest undervurderte øvelsen.';

  @override
  String get wisdom_008 => 'Tren det du vil se, ikke det du håper på.';

  @override
  String get wisdom_009 => 'En trygg hund lærer fortere enn en ivrig.';

  @override
  String get wisdom_010 => 'Det er lov å avslutte på topp.';

  @override
  String get wisdom_011 => 'En stand bygges før fugl, ikke etter.';

  @override
  String get wisdom_012 => 'Ro i oppflukt starter i hodet.';

  @override
  String get wisdom_013 => 'Stødighet er et valg hunden lærer å ta.';

  @override
  String get wisdom_014 => 'Press skaper bevegelse. Tid skaper ro.';

  @override
  String get wisdom_015 => 'En god stand trenger ikke publikum.';

  @override
  String get wisdom_016 => 'Når hunden står, la verden vente.';

  @override
  String get wisdom_017 => 'Det er bedre med én rolig stand enn tre raske.';

  @override
  String get wisdom_018 => 'Fuglen lærer hunden. Du former reaksjonen.';

  @override
  String get wisdom_019 => 'Stand er et øyeblikk av balanse.';

  @override
  String get wisdom_020 => 'Ikke hast gjennom stillhet.';

  @override
  String get wisdom_021 => 'Les vinden før du leser hunden.';

  @override
  String get wisdom_022 => 'Terrenget trener hunden like mye som du gjør.';

  @override
  String get wisdom_023 => 'Hver fugl er en ny leksjon.';

  @override
  String get wisdom_024 => 'Dårlige forhold gir gode erfaringer.';

  @override
  String get wisdom_025 => 'Jakt er samarbeid, ikke konkurranse.';

  @override
  String get wisdom_026 => 'Det er i motvind du ser kvalitet.';

  @override
  String get wisdom_027 => 'En tom runde kan være full av læring.';

  @override
  String get wisdom_028 => 'La hunden finne løsningen.';

  @override
  String get wisdom_029 => 'Fuglehundens styrke er selvstendighet med retning.';

  @override
  String get wisdom_030 => 'Feltet husker alt.';

  @override
  String get wisdom_031 => 'Vær konsekvent, ikke perfekt.';

  @override
  String get wisdom_032 => 'Hunden speiler tempoet ditt.';

  @override
  String get wisdom_033 => 'Det du ikke reagerer på, godtar du.';

  @override
  String get wisdom_034 => 'Klar tanke gir klar hund.';

  @override
  String get wisdom_035 => 'Rettferdighet slår strenghet.';

  @override
  String get wisdom_036 => 'Tren med hodet før stemmen.';

  @override
  String get wisdom_037 => 'Ikke forklar. Vis.';

  @override
  String get wisdom_038 => 'En trygg fører gir trygg hund.';

  @override
  String get wisdom_039 => 'Din ro er hundens ramme.';

  @override
  String get wisdom_040 => 'Lytt mer enn du korrigerer.';

  @override
  String get wisdom_041 => 'Relasjon bygges også uten fugl.';

  @override
  String get wisdom_042 => 'En god tur er aldri bortkastet.';

  @override
  String get wisdom_043 => 'Tillit tar tid. Mistillit tar sekunder.';

  @override
  String get wisdom_044 => 'Hunden jobber best for den den stoler på.';

  @override
  String get wisdom_045 => 'Små rutiner gir stor trygghet.';

  @override
  String get wisdom_046 => 'Det er lov å være bare hund iblant.';

  @override
  String get wisdom_047 => 'Lekenhet er ikke udisiplin.';

  @override
  String get wisdom_048 => 'En fornøyd hund presterer bedre.';

  @override
  String get wisdom_049 => 'Samarbeid slår kontroll.';

  @override
  String get wisdom_050 => 'Fellesskap før ferdigheter.';

  @override
  String get wisdom_051 => 'Prøve er øyeblikksbilde, ikke fasit.';

  @override
  String get wisdom_052 => 'Dommeren ser én dag. Du ser hele året.';

  @override
  String get wisdom_053 => 'Resultat er bonus, ikke mål.';

  @override
  String get wisdom_054 => 'En god opplevelse slår en god plassering.';

  @override
  String get wisdom_055 => 'Press hjemme gir ro på prøve.';

  @override
  String get wisdom_056 => 'Tren på situasjoner, ikke poeng.';

  @override
  String get wisdom_057 => 'En stødig hund er alltid konkurransedyktig.';

  @override
  String get wisdom_058 => 'Lær av det som ikke gikk.';

  @override
  String get wisdom_059 => 'Prøver er trening med publikum.';

  @override
  String get wisdom_060 => 'Ikke jag premier, bygg hund.';

  @override
  String get wisdom_061 => 'En fuglehund er aldri ferdig lært.';

  @override
  String get wisdom_062 => 'Det er veien til standen som teller.';

  @override
  String get wisdom_063 => 'Tålmodighet lukter ikke stress.';

  @override
  String get wisdom_064 => 'De beste øyeblikkene kan ikke logges.';

  @override
  String get wisdom_065 => 'Fuglehund handler om tillit i fart.';

  @override
  String get wisdom_066 => 'Stillhet er ofte svaret.';

  @override
  String get wisdom_067 => 'Naturen setter alltid rammene.';

  @override
  String get wisdom_068 => 'En god dag i feltet varer lenge.';

  @override
  String get wisdom_069 => 'Hunden husker stemningen.';

  @override
  String get wisdom_070 => 'Jakt er samspill med landskapet.';

  @override
  String get wisdom_071 => 'En kort line i dag kan gi en lang ro i morgen.';

  @override
  String get wisdom_072 => 'Det som belønnes, blir gjentatt.';

  @override
  String get wisdom_073 => 'Hold kravene små, og bygg dem store over tid.';

  @override
  String get wisdom_074 => 'Når du mister roen, mister du også læring.';

  @override
  String get wisdom_075 => 'En tydelig start gjør slutten enkel.';

  @override
  String get wisdom_076 => 'Ro er ikke passivitet. Ro er kontroll.';

  @override
  String get wisdom_077 => 'Tren på det kjedelige. Det er det som redder dagen.';

  @override
  String get wisdom_078 => 'En god føring er ofte usynlig.';

  @override
  String get wisdom_079 => 'Når hunden lykkes, er det du som har vært forutsigbar.';

  @override
  String get wisdom_080 => 'Ikke jag tempo. Jag kvalitet.';

  @override
  String get wisdom_081 => 'Gi hunden tid til å tenke ferdig.';

  @override
  String get wisdom_082 => 'Et nei uten sinne er mer verdt enn ti ja med stress.';

  @override
  String get wisdom_083 => 'Stopp før du må stoppe.';

  @override
  String get wisdom_084 => 'Du trener alltid, også når du tror du bare går tur.';

  @override
  String get wisdom_085 => 'Fuglen avslører hullene. Tren hullene.';

  @override
  String get wisdom_086 => 'En god stopp er starten på en god stand.';

  @override
  String get wisdom_087 => 'Lett hånd gir tungt samarbeid.';

  @override
  String get wisdom_088 => 'Når ting går skeis: senk tempoet, øk tydeligheten.';

  @override
  String get wisdom_089 => 'En trygg rutine slår en perfekt plan.';

  @override
  String get wisdom_090 => 'Det viktigste signalet er det du gir med kroppen.';

  @override
  String get settings_title => 'Innstillinger';

  @override
  String get settings_section_general => 'Generelt';

  @override
  String get settings_section_milestones => 'Milepæler';

  @override
  String get invitations_title => 'Invitasjoner';

  @override
  String get invitations_empty => 'Ingen ventende invitasjoner';

  @override
  String get settings_section_feedback => 'Tilbakemelding';

  @override
  String get supportEmail => 'support@gundogtracker.app';

  @override
  String get support_email => 'support@gundogtracker.app';

  @override
  String get settings_section_subscription => 'Abonnement';

  @override
  String get settings_section_language => 'Språk';

  @override
  String get settings_section_community => 'Community';

  @override
  String get settings_section_security => 'Sikkerhet';

  @override
  String get settings_change_password_title => 'Endre passord';

  @override
  String get settings_change_password_current_password => 'Gjeldende passord';

  @override
  String get settings_change_password_new_password => 'Nytt passord';

  @override
  String get settings_change_password_confirm_password => 'Bekreft nytt passord';

  @override
  String get settings_change_password_submit => 'Oppdater passord';

  @override
  String get settings_change_password_success => 'Passordet er oppdatert';

  @override
  String get settings_reset_password_button => 'Glemt passord';

  @override
  String get settings_reset_password_sent => 'Sjekk e-posten din for en lenke';

  @override
  String get settings_reset_password_no_email => 'Ingen e-post tilgjengelig for tilbakestilling';

  @override
  String get settings_change_password_error_fields => 'Fyll ut alle feltene';

  @override
  String get settings_change_password_error_mismatch => 'Nytt passord og bekreftelse må være like';

  @override
  String get forgot_password_title => 'Glemt passord';

  @override
  String get forgot_password_description => 'Skriv inn e-postadressen din, så sender vi en lenke for å nullstille passordet.';

  @override
  String get forgot_password_email_label => 'E-post';

  @override
  String get forgot_password_button => 'Send reset-link';

  @override
  String get forgot_password_error_missing => 'Skriv inn e-post.';

  @override
  String get forgot_password_error_invalid => 'Ugyldig e-post.';

  @override
  String get forgot_password_check_spam_hint => 'Sjekk innboksen din. Hvis du ikke finner e-posten, sjekk søppelpost/spam.';

  @override
  String get signup_title => 'Opprett konto';

  @override
  String get signup_intro => 'Opprett konto med e-post og passord for å komme i gang.';

  @override
  String get signup_email_label => 'E-post';

  @override
  String get signup_password_label => 'Passord';

  @override
  String get signup_password_repeat_label => 'Gjenta passord';

  @override
  String get signup_create_button => 'Opprett konto';

  @override
  String get signup_success => 'Kontoen er opprettet.';

  @override
  String get signup_error_email_in_use => 'Denne e-postadressen er allerede i bruk.';

  @override
  String get signup_error_invalid_email => 'Skriv inn en gyldig e-postadresse.';

  @override
  String get signup_error_weak_password => 'Passordet må være minst 6 tegn.';

  @override
  String get signup_error_operation_not_allowed => 'Det er ikke mulig å opprette konto akkurat nå.';

  @override
  String get signup_error_network => 'Sjekk internett og prøv igjen.';

  @override
  String get signup_error_generic => 'Kunne ikke opprette konto akkurat nå.';

  @override
  String get signup_validation_email_missing => 'Skriv inn e-post.';

  @override
  String get signup_validation_email_invalid => 'Skriv inn en gyldig e-post.';

  @override
  String get signup_validation_password_missing => 'Skriv inn passord.';

  @override
  String get signup_validation_password_short => 'Passordet må være minst 6 tegn.';

  @override
  String get signup_validation_password_repeat_missing => 'Gjenta passordet.';

  @override
  String get signup_validation_password_mismatch => 'Passordene er ikke like.';

  @override
  String get settings_backup_import_success => 'Backup importert';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Lys';

  @override
  String get settings_theme_dark => 'Mørk';

  @override
  String get settings_language_title => 'Språk';

  @override
  String get settings_language_followSystem => 'Følg systemet';

  @override
  String get settings_language_nb => 'Norsk (bokmål)';

  @override
  String get settings_language_sv => 'Svenska';

  @override
  String get settings_language_da => 'Dansk';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_milestones_enabled_title => 'Milepæler';

  @override
  String get settings_milestones_enabled_subtitle => 'Vis små øyeblikk når hunden når viktige steg.';

  @override
  String get settings_milestones_goal_title => 'Milepælsmål';

  @override
  String get settings_milestones_goal_subtitle => 'Sett sesong- og personlig mål for standpoeng.';

  @override
  String get settings_milestones_season_goal_title => 'Sesongmål (stander)';

  @override
  String get settings_milestones_personal_goal_title => 'Personlig mål (stander)';

  @override
  String milestone_goal_achieved(String dogName, String goalTitle) {
    return '$dogName nådde $goalTitle!';
  }

  @override
  String get settings_haptics_enabled_title => 'Vibrering ved milepæler';

  @override
  String get settings_haptics_enabled_subtitle => 'Diskret vibrering når milepæler oppnås.';

  @override
  String get settings_restore_in_progress => 'Gjenoppretting pågår… vennligst vent.';

  @override
  String get settings_section_backup => 'Sikkerhetskopi';

  @override
  String get settings_backup_export_action => 'Eksporter backup (ZIP)';

  @override
  String get settings_backup_exporting => 'Eksporterer…';

  @override
  String get settings_backup_subtitle => 'Eksporter/importer hunder, økter, spor, milepæler og media.';

  @override
  String get settings_backup_import_action => 'Importer backup (ZIP)';

  @override
  String get settings_backup_importing => 'Importerer…';

  @override
  String get settings_backup_import_description => 'Velg en backup-zip og legg tilbake data.';

  @override
  String get settings_backup_where_title => 'Hvor lagres backup?';

  @override
  String get settings_backup_where_action => 'Vis lagringsmappe';

  @override
  String get settings_backup_status_collectingData => 'Samler data…';

  @override
  String get settings_backup_status_collectingMedia => 'Samler media…';

  @override
  String get settings_backup_status_creatingZip => 'Lager ZIP…';

  @override
  String get settings_backup_status_sharing => 'Deler…';

  @override
  String get settings_backup_status_selectZip => 'Velg ZIP…';

  @override
  String get settings_backup_status_restoring => 'Gjenoppretter data…';

  @override
  String get settings_backup_share_subject => 'Fuglehund backup';

  @override
  String settings_backup_ready(Object fileName) {
    return 'Backup klar: $fileName ✅';
  }

  @override
  String settings_backup_failed(Object message) {
    return 'Backup feilet: $message';
  }

  @override
  String get auth_profile_pending_title => 'Profil opprettes…';

  @override
  String get auth_profile_pending_body => 'Vi venter på at backend-dokumentet er klart. Trykk på \"Prøv igjen\" når du vil sjekke på nytt.';

  @override
  String get auth_loading_waiting => 'Klargjør innlogging…';

  @override
  String get auth_profile_load_failed_title => 'Kunne ikke laste profilen din';

  @override
  String get auth_profile_load_failed_body => 'Prøv igjen om et øyeblikk. Hvis problemet fortsetter, kan du lukke og åpne appen på nytt.';

  @override
  String get auth_profile_timeout_error => 'Finner ikke brukerprofilen på kort tid. Sjekk nettverk eller prøv igjen.';

  @override
  String get settings_backup_failed_unknown => 'Ukjent feil.';

  @override
  String settings_backup_import_failed(Object message) {
    return 'Import feilet: $message';
  }

  @override
  String get settings_backup_restore_dialog_title => 'Importer backup';

  @override
  String get settings_backup_restore_dialog_content => 'Dette vil legge tilbake data fra en ZIP-backup.\\n\\nTips: Etter import kan det være lurt å starte appen på nytt.';

  @override
  String get settings_backup_restore_dialog_confirm => 'Importer';

  @override
  String get settings_backup_restore_prompt_title => 'Gjenoppretting ferdig';

  @override
  String get settings_backup_restore_prompt_message => 'Gjenoppretting fullført. Start appen på nytt nå?';

  @override
  String get settings_backup_restore_saved => 'Gjenoppretting lagret. Start appen på nytt når det passer.';

  @override
  String get settings_backup_restore_complete => 'Import fullført';

  @override
  String get settings_backup_storage_title => 'Backup-lagring';

  @override
  String settings_backup_storage_description(String path) {
    return 'Backupfiler lagres her:\\n\\n$path';
  }

  @override
  String get settings_backup_restore_pending => 'Importerer backup…';

  @override
  String get settings_backup_restore_pending_message => 'Gjenoppretter backup… vennligst vent.';

  @override
  String get settings_section_appearance => 'Utseende';

  @override
  String get settings_season_title => 'Årstidstema';

  @override
  String get settings_season_subtitle => 'Farger for topp og bunn.';

  @override
  String get settings_season_auto => 'Automatisk';

  @override
  String get settings_season_spring => '🌱 Vår';

  @override
  String get settings_season_summer => '☀️ Sommer';

  @override
  String get settings_season_autumn => '🍁 Høst';

  @override
  String get settings_season_winter => '❄️ Vinter';

  @override
  String get settings_feedback_send_subtitle => 'Åpner e-post med appinfo.';

  @override
  String get settings_feedback_bug_subtitle => 'Åpner e-post med feilmal.';

  @override
  String get settings_feedback_copy_subtitle => 'Kopierer app- og enhetsinfo.';

  @override
  String get settings_feedback_suggest_subtitle => 'Send forslag via e-post.';

  @override
  String get settings_feedback_error_open_email => 'Kunne ikke åpne e-post.';

  @override
  String get settings_feedback_error_copy => 'Kunne ikke kopiere.';

  @override
  String get settings_diagnostics_section_title => 'Diagnostikk';

  @override
  String get settings_diagnostics_title => 'Avansert diagnostikk';

  @override
  String get settings_diagnostics_subtitle => 'Verktøy for feilsøking og support.';

  @override
  String get settings_diagnostics_outbox_label => 'Outbox';

  @override
  String get settings_diagnostics_count_pending => 'Venter';

  @override
  String get settings_diagnostics_count_inProgress => 'Pågår';

  @override
  String get settings_diagnostics_count_failed => 'Feilet';

  @override
  String get settings_diagnostics_count_sent => 'Sendt';

  @override
  String get settings_diagnostics_action_dog_restore_title => 'Hent hunder på nytt';

  @override
  String get settings_diagnostics_action_dog_restore_subtitle => 'Henter tilgjengelige hunder fra skyen til lokal lagring.';

  @override
  String get settings_diagnostics_action_session_fetch_title => 'Sjekk økter i skyen';

  @override
  String get settings_diagnostics_action_session_fetch_subtitle => 'Henter økter for den første hunden som er koblet til skyen.';

  @override
  String get settings_diagnostics_action_session_restore_title => 'Legg tilbake økter lokalt';

  @override
  String get settings_diagnostics_action_session_restore_subtitle => 'Lagrer økter fra skyen lokalt for den første tilkoblede hunden.';

  @override
  String get settings_diagnostics_action_process_outbox_title => 'Kjør synkkø nå';

  @override
  String get settings_diagnostics_action_process_outbox_subtitle => 'Behandler ventende synkoppgaver én gang.';

  @override
  String get settings_diagnostics_action_retry_outbox_title => 'Nullstill feilede synkoppgaver';

  @override
  String get settings_diagnostics_action_retry_outbox_subtitle => 'Setter feilede synkoppgaver tilbake i kø for ny behandling.';

  @override
  String get settings_diagnostics_missing_cloud_dog => 'Fant ingen lokal hund som er koblet til skyen.';

  @override
  String settings_diagnostics_dog_restore_success(Object count) {
    return 'Hentet hundedata på nytt: $count';
  }

  @override
  String settings_diagnostics_dog_restore_failed(Object error) {
    return 'Kunne ikke hente hundedata på nytt: $error';
  }

  @override
  String settings_diagnostics_session_fetch_success(Object count) {
    return 'Fant $count økter i skyen.';
  }

  @override
  String settings_diagnostics_session_fetch_failed(Object error) {
    return 'Kunne ikke hente økter fra skyen: $error';
  }

  @override
  String settings_diagnostics_session_restore_success(Object count) {
    return 'La tilbake $count økter lokalt.';
  }

  @override
  String settings_diagnostics_session_restore_failed(Object error) {
    return 'Kunne ikke legge tilbake økter lokalt: $error';
  }

  @override
  String get settings_diagnostics_outbox_process_success => 'Synkkøen ble behandlet.';

  @override
  String settings_diagnostics_outbox_process_failed(Object error) {
    return 'Kunne ikke behandle synkkøen: $error';
  }

  @override
  String settings_diagnostics_retry_success(Object count) {
    return 'Nullstilte $count synkoppgaver.';
  }

  @override
  String settings_diagnostics_retry_failed(Object error) {
    return 'Kunne ikke nullstille synkoppgaver: $error';
  }

  @override
  String get settings_sign_out_button => 'Logg ut';

  @override
  String get settings_sign_out_success => 'Du er logget ut.';

  @override
  String get settings_sign_out_failed => 'Kunne ikke logge ut akkurat nå.';

  @override
  String get settings_sound_on_app_start_title => 'Lyd ved oppstart';

  @override
  String get settings_sound_on_app_start_subtitle => 'Spill av rype-lyd når appen starter';

  @override
  String get settings_sound_on_milestone_title => 'Lyd ved milepæler';

  @override
  String get settings_sound_on_milestone_subtitle => 'Spill av lyd når du oppnår en milepæl';

  @override
  String get milestones_achieved_title => 'Oppnådde milepæler';

  @override
  String get milestones_achieved_empty => 'Ingen milepæler ennå.';

  @override
  String milestones_achieved_duration(String duration) {
    return 'Oppnådd $duration';
  }

  @override
  String get milestone_sheet_button_ok => 'Fint!';

  @override
  String get milestone_sheet_button_viewAll => 'Se milepæler';

  @override
  String get milestone_snackbar_new_title => 'Ny milepæl!';

  @override
  String get milestone_snackbar_open_error => 'Kunne ikke åpne milepæl';

  @override
  String milestone_stands_count_subtitle(Object dogName, Object countText) {
    return '$dogName har registrert $countText.';
  }

  @override
  String milestone_sessions_count_subtitle(Object dogName, Object countText) {
    return '$dogName har logget $countText.';
  }

  @override
  String milestone_birds_count_subtitle(Object dogName, Object countText) {
    return '$dogName har felt $countText.';
  }

  @override
  String get milestone_first_point_title => 'Første stand';

  @override
  String milestone_first_point_subtitle(String dogName) {
    return '$dogName har registrert sin første stand.';
  }

  @override
  String get milestone_first_flush_title => 'Første støkk';

  @override
  String milestone_first_flush_subtitle(String dogName) {
    return '$dogName har registrert sitt første støkk.';
  }

  @override
  String get milestone_sessions_10_title => '10 økter';

  @override
  String milestone_sessions_10_subtitle(String dogName) {
    return '$dogName har logget 10 økter.';
  }

  @override
  String get milestone_active_hours_10_title => '10 timer aktiv';

  @override
  String milestone_active_hours_10_subtitle(String dogName) {
    return '$dogName har passert 10 timer aktiv tid.';
  }

  @override
  String get milestone_section_birds_down_title => 'Felt fugl';

  @override
  String get milestone_dog_fallback_name => 'Hunden';

  @override
  String milestone_achieved_sentence(Object dog, Object milestone, Object date, Object age) {
    return '$dog oppnådde «$milestone» $date$age';
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
    return '$dogName har passert $count stand.';
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
  String get subscription_status_unknown => 'Ukjent';

  @override
  String get subscription_product_title => 'Fuglehund Pro';

  @override
  String get subscription_description => 'Få ubegrenset antall hunder og ubegrenset antall økter.';

  @override
  String get subscription_benefit_unlimited_dogs => 'Ubegrenset antall hunder';

  @override
  String get subscription_benefit_unlimited_sessions => 'Ubegrenset antall økter';

  @override
  String get subscription_price_unavailable => 'Pris utilgjengelig';

  @override
  String get subscription_subscribe_button => 'Oppgrader til Pro';

  @override
  String get subscription_restore_button => 'Gjenopprett kjøp';

  @override
  String get subscription_manage_button => 'Administrer / Si opp';

  @override
  String get subscription_purchase_success => 'Pro er aktivert.';

  @override
  String get subscription_purchase_cancelled => 'Kjøpet ble avbrutt.';

  @override
  String get subscription_restore_success => 'Gjenoppretting er startet.';

  @override
  String get subscription_limit_dogs_reached => 'Gratisversjonen er full for hunder. Oppgrader til Pro for å legge til flere.';

  @override
  String get subscription_limit_sessions_reached => 'Gratisversjonen er full for økter. Oppgrader til Pro for å lagre flere.';

  @override
  String get subscription_error_load_status => 'Kunne ikke hente abonnementsstatus akkurat nå.';

  @override
  String get subscription_error_purchase_start => 'Kunne ikke starte kjøpet akkurat nå.';

  @override
  String get subscription_error_product_unavailable => 'Produktet er ikke tilgjengelig i butikken akkurat nå.';

  @override
  String get subscription_error_restore_purchase => 'Kunne ikke gjenopprette kjøp akkurat nå.';

  @override
  String get subscription_error_manage_open => 'Kunne ikke åpne abonnementssiden.';

  @override
  String get feedback_send_title => 'Send tilbakemelding';

  @override
  String get feedback_bug_title => 'Rapporter en feil';

  @override
  String get feedback_copy_diagnostics_title => 'Kopier diagnoseinfo';

  @override
  String get feedback_suggest_milestone_title => 'Foreslå milepæl';

  @override
  String get feedback_email_body_intro => 'Beskriv tilbakemeldingen din her.';

  @override
  String get feedback_bug_prompt => 'Hva skjedde?';

  @override
  String get feedback_bug_reproduce => 'Hvordan kan vi reprodusere problemet?';

  @override
  String get feedback_suggest_title => 'Forslag til ny milepæl:';

  @override
  String get feedback_suggest_question_what_to_celebrate => 'Hva bør feires?';

  @override
  String get feedback_suggest_question_why_important => 'Hvorfor er dette viktig i praksis?';

  @override
  String get feedback_suggest_question_when_should_trigger => 'Når bør den trigges?';

  @override
  String get feedback_suggest_trigger_hint => '(første gang, hver 10., hver 100., annet)';

  @override
  String get feedback_suggest_comments => 'Eventuelle kommentarer:';

  @override
  String get feedback_error_email_not_available => 'Ingen e-post-app er tilgjengelig.';

  @override
  String get community_open_discord => 'Åpne Discord-gruppe';

  @override
  String get community_open_facebook => 'Åpne Facebook-gruppe';

  @override
  String get home_continueActiveSessionTitle => 'Fortsett aktiv økt';

  @override
  String home_continueActiveSessionSubtitle(String dogName) {
    return 'Ufullført økt for $dogName.';
  }

  @override
  String get home_continueActiveSessionMissingDogTitle => 'Aktiv økt kan ikke gjenopprettes';

  @override
  String get home_continueActiveSessionMissingDogSubtitle => 'Hunden finnes ikke lenger. Du kan forkaste utkastet.';

  @override
  String get home_continueActiveSessionButton => 'Fortsett aktiv økt';

  @override
  String get home_discardActiveSessionButton => 'Forkast';

  @override
  String get home_discardActiveSessionSnackbar => 'Forkastet aktiv økt';

  @override
  String get home_endActiveSessionButton => 'Avslutt aktiv økt';

  @override
  String get home_endActiveSessionConfirmTitle => 'Avslutt aktiv økt?';

  @override
  String get home_endActiveSessionConfirmSubtitle => 'Alt går tapt dersom du avslutter. Er du sikker?';

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
      other: '$count fugler',
      one: '1 fugl',
      zero: '0 fugler',
    );
    return '$_temp0';
  }

  @override
  String birdsDownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count felt fugl',
      one: '1 felt fugl',
      zero: '0 felt fugl',
    );
    return '$_temp0';
  }
}
