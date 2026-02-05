// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pointing dog';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Close';

  @override
  String get common_done => 'Done';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_copied => 'Copied ✅';

  @override
  String get common_comingSoon => 'Coming soon.';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_invalid_link => 'Invalid link';

  @override
  String get common_could_not_open_link => 'Couldn\'t open the link';

  @override
  String get common_unknown => 'Unknown';

  @override
  String get common_unknown_email => 'Unknown email';

  @override
  String get common_unknown_member => 'Unknown member';

  @override
  String get common_no_permission => 'You don\'t have permission to do that.';

  @override
  String get common_retry => 'Try again';

  @override
  String get age_unknown => 'Age unknown';

  @override
  String get boot_error_title => 'Startup failed';

  @override
  String boot_error_body(Object message) {
    return 'Check the terminal for details.\n$message';
  }

  @override
  String get boot_error_unknown => 'Unknown error';

  @override
  String get boot_restore_title => 'Restoring backup…';

  @override
  String get boot_restore_body => 'Do not close the app.\n\nWe block data access while the restore runs to avoid Hive issues.';

  @override
  String get boot_restart_title => 'Backup restored ✅';

  @override
  String get boot_restart_body => 'The app will close now so changes can load.\n\nReopen the app afterwards.';

  @override
  String get qr_scan_title => 'Scan QR';

  @override
  String get home_title => 'Home';

  @override
  String get home => 'Home';

  @override
  String get sessions => 'Sessions';

  @override
  String get statistics => 'Statistics';

  @override
  String stats_week_label(int week) {
    return 'Week $week';
  }

  @override
  String get common_conjunction_and => 'and';

  @override
  String stats_stands_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '$count point',
    );
    return '$_temp0';
  }

  @override
  String stats_sessions_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '$count session',
    );
    return '$_temp0';
  }

  @override
  String stats_birds_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count birds',
      one: '$count bird',
    );
    return '$_temp0';
  }

  @override
  String stats_flushes_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flushes',
      one: '$count flush',
    );
    return '$_temp0';
  }

  @override
  String common_years(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String common_months(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String common_days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get common_months_short => 'mo';

  @override
  String get stats_screen_title => 'Statistics';

  @override
  String get stats_period_daily => 'Daily';

  @override
  String get stats_period_weekly => 'Weekly';

  @override
  String get stats_period_monthly => 'Monthly';

  @override
  String get stats_no_sessions_registered => 'No sessions registered yet';

  @override
  String get stats_filter_all_dogs => 'All dogs';

  @override
  String get stats_filter_dynamic_period => 'Dynamic period';

  @override
  String get stats_trendline_title => 'Trendline';

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
      other: '$count more points',
      one: '$count more point',
    );
    return '$_temp0';
  }

  @override
  String stats_trend_point_label(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String get dogs => 'Dogs';

  @override
  String get dog_sex_male => 'Male';

  @override
  String get dog_sex_female => 'Female';

  @override
  String get dog_unnamed => 'Unnamed dog';

  @override
  String dog_subtitle_born_prefix(String date) {
    return 'Born: $date';
  }

  @override
  String get dog_editor_error_name_missing => 'Name is missing';

  @override
  String get dog_editor_save => 'Save';

  @override
  String get dog_editor_saving => 'Saving…';

  @override
  String get dog_editor_delete_dog => 'Delete dog';

  @override
  String get dog_editor_deleting => 'Deleting…';

  @override
  String get dog_editor_delete_dog_title => 'Delete dog';

  @override
  String get dog_editor_delete_dog_body => 'Do you want to delete the dog? This can\'t be undone.';

  @override
  String get dog_editor_button_cancel => 'Cancel';

  @override
  String get dog_editor_button_delete => 'Delete';

  @override
  String get dog_editor_new_breed_title => 'New breed';

  @override
  String get dog_editor_new_breed_hint => 'E.g. Gordon Setter';

  @override
  String get dog_editor_button_add => 'Add';

  @override
  String get dog_editor_select_breed_label => 'Select breed';

  @override
  String get dog_editor_select_breed_placeholder => 'Select breed';

  @override
  String get dog_editor_new_breed_option => 'New breed…';

  @override
  String get dog_editor_name_label => 'Name';

  @override
  String get dog_editor_nickname_label => 'Nickname';

  @override
  String get dog_editor_nickname_hint => 'Optional (e.g. Zoë, Bowie)';

  @override
  String get dog_editor_birthdate_label => 'Birth date';

  @override
  String get dog_editor_birthdate_not_set => 'Not set';

  @override
  String get dog_editor_regnr_label => 'Reg. no.';

  @override
  String get dog_editor_pedigree_url_label => 'Pedigree URL';

  @override
  String get dog_editor_memory_words_label => 'Memorial note';

  @override
  String get dog_editor_image_text_anchor_label => 'Text placement on photo';

  @override
  String get dog_editor_death_registered_title => 'Registered deceased';

  @override
  String get dog_editor_section_breed_title => 'Breed';

  @override
  String get dog_editor_section_sex => 'Sex';

  @override
  String get dog_editor_role_section_title => 'Choose role';

  @override
  String get dog_editor_role_owner => 'Owner';

  @override
  String get dog_editor_role_admin => 'Administrator';

  @override
  String get dog_editor_role_user => 'User';

  @override
  String get dog_editor_section_hero_title => 'Hero text';

  @override
  String get dog_editor_anchor_bottom_left => 'Bottom left';

  @override
  String get dog_editor_anchor_bottom_center => 'Bottom center';

  @override
  String get dog_editor_anchor_top_left => 'Top left';

  @override
  String get dog_editor_text_size_label => 'Text size';

  @override
  String get dog_editor_text_size_small => 'Small';

  @override
  String get dog_editor_text_size_normal => 'Normal';

  @override
  String get dog_editor_text_size_large => 'Large';

  @override
  String get dog_editor_section_lifecycle_title => 'Lifecycle';

  @override
  String get dog_editor_death_date_label => 'Death date';

  @override
  String get dog_editor_death_date_picker_hint => 'Select date';

  @override
  String get dog_detail_snackbar_invite_accepted => 'Invitation accepted';

  @override
  String get dog_detail_snackbar_invite_declined => 'Invitation declined';

  @override
  String get dog_detail_snackbar_invite_sent => 'Invitation sent';

  @override
  String get dog_detail_snackbar_ownership_accepted => 'Ownership accepted';

  @override
  String get dog_detail_snackbar_request_declined => 'Request declined';

  @override
  String get dog_detail_snackbar_request_cancelled => 'Request cancelled';

  @override
  String get dog_detail_snackbar_image_save_failed => 'Could not save the photo.';

  @override
  String get dog_detail_snackbar_pedigree_invalid => 'The pedigree link is invalid or can’t be opened.';

  @override
  String get dog_detail_photo_source_gallery => 'Choose from photos';

  @override
  String get dog_detail_photo_source_camera => 'Take photo';

  @override
  String get dog_detail_button_cancel => 'Cancel';

  @override
  String get dog_detail_pedigree_section_title => 'Pedigree';

  @override
  String get dog_detail_button_open_pedigree => 'Open pedigree';

  @override
  String get dog_pedigree_no_link => 'No link registered';

  @override
  String get dog_detail_appbar_title => 'Dog profile';

  @override
  String get dog_detail_error_dog_not_found => 'Dog not found';

  @override
  String get dog_detail_title_add_dog => 'Add dog';

  @override
  String get dog_editor_title_add_dog => 'Add dog';

  @override
  String get dog_editor_title_edit_dog => 'Edit dog';

  @override
  String get dog_profile_title => 'Dog';

  @override
  String get dog_profile_subtitle_breed_age => 'Breed · Age';

  @override
  String get dog_generic_name => 'Dog';

  @override
  String get dog_detail_section_access => 'Access';

  @override
  String get dog_detail_button_send_invite => 'Send invitation';

  @override
  String get dog_detail_section_invites => 'Invitations';

  @override
  String get invite_send_email_label => 'Recipient email';

  @override
  String get invite_send_button => 'Send invitation';

  @override
  String invite_sent_to(Object email) {
    return 'Invitation sent to $email';
  }

  @override
  String get invite_revoke_button => 'Revoke';

  @override
  String get invite_status_invited => 'Invited';

  @override
  String invite_status_invited_as_user(Object role) {
    return 'Invited as $role';
  }

  @override
  String get invite_accept => 'Accept';

  @override
  String get invite_decline => 'Decline';

  @override
  String get dog_share_section_title => 'Shared with';

  @override
  String get dog_detail_access_section_title => 'Access to this dog';

  @override
  String get dog_detail_member_action_set_reader => 'Set as reader';

  @override
  String get dog_detail_member_action_set_user => 'Set as user';

  @override
  String get dog_detail_member_action_remove_access => 'Remove access';

  @override
  String get share_role_owner => 'Owner';

  @override
  String get share_role_admin => 'Administrator';

  @override
  String get share_role_user => 'User';

  @override
  String get dog_detail_share_empty => 'No invitations';

  @override
  String get dog_detail_share_empty_owner => 'No sharing yet.';

  @override
  String dog_detail_my_role_label(String role) {
    return 'Your role: $role';
  }

  @override
  String get dog_detail_share_disabled_explanation => 'You don\'t have permission to share this dog.';

  @override
  String get share_accept_title => 'Accept share';

  @override
  String get share_accept_code_label => 'Share code';

  @override
  String get share_accept_scan_qr => 'Scan QR';

  @override
  String get share_accept_button => 'Accept';

  @override
  String get share_error_dialog_title => 'Share failed';

  @override
  String get share_error_not_owner => 'Only the owner or an administrator can share the dog.';

  @override
  String get share_error_invite_not_found => 'Invite not found.';

  @override
  String get share_error_invite_expired => 'The invite has expired.';

  @override
  String get share_error_invite_revoked => 'The invite has been revoked.';

  @override
  String get share_error_invite_inactive => 'The invite is not active.';

  @override
  String get share_error_already_has_access => 'You already have access.';

  @override
  String get share_error_invalid_role => 'Invalid role.';

  @override
  String get share_error_invalid_email => 'Invalid email address.';

  @override
  String get share_error_dog_not_found_title => 'Dog not found';

  @override
  String get share_error_dog_not_found_detail => 'No dog matches that code.';

  @override
  String get transfer_error_not_owner => 'Only the owner can decline the transfer request.';

  @override
  String get transfer_error_not_recipient => 'You are not the recipient of this request.';

  @override
  String get transfer_error_not_found => 'Transfer request not found.';

  @override
  String get transfer_error_expired => 'Transfer request has expired.';

  @override
  String get transfer_error_not_pending => 'Transfer request is not pending.';

  @override
  String get transfer_error_cannot_transfer_to_self => 'Cannot transfer ownership to yourself.';

  @override
  String get transfer_error_cancelled => 'Transfer request has already been declined.';

  @override
  String get role_owner => 'Owner';

  @override
  String get role_editor => 'Editor';

  @override
  String get role_viewer => 'Viewer';

  @override
  String get role_admin => 'Administrator';

  @override
  String get dog_editor_owner_email_label => 'Owner email';

  @override
  String get dog_editor_owner_email_hint => 'name@example.com';

  @override
  String get dog_editor_owner_email_required_error => 'Enter a valid email for the owner.';

  @override
  String get dog_detail_section_owner_request_title => 'Ownership requested';

  @override
  String dog_detail_label_from_user(String userId) {
    return 'From: $userId';
  }

  @override
  String dog_detail_label_to_user(String userId) {
    return 'To: $userId';
  }

  @override
  String get dog_detail_button_accept => 'Accept';

  @override
  String get dog_detail_button_decline => 'Decline';

  @override
  String get dog_detail_button_cancel_request => 'Cancel request';

  @override
  String get dog_detail_button_edit_photo => 'Change profile photo';

  @override
  String get dog_detail_button_mark_dead => 'Mark as deceased';

  @override
  String get dog_detail_watermark_section_title => 'Watermark';

  @override
  String get dog_detail_watermark_info => 'A watermark is required when sharing dog photos.';

  @override
  String get dog_detail_watermark_toggle_title => 'Show title';

  @override
  String get dog_detail_watermark_toggle_name => 'Show name';

  @override
  String get dog_detail_watermark_toggle_min_one => 'At least one of name/title must be on.';

  @override
  String get dog_detail_watermark_share_button => 'Share profile photo';

  @override
  String get dog_detail_watermark_share_subject => 'Photo from GundogTracker';

  @override
  String get dog_detail_watermark_share_message => 'Shared via GundogTracker';

  @override
  String get dog_detail_label_death_date => 'Date of death';

  @override
  String get dog_detail_button_edit => 'Edit';

  @override
  String get dog_detail_button_register_death => 'Register';

  @override
  String get dog_detail_photo_dialog_title => 'Profile photo';

  @override
  String get dog_detail_photo_pick_camera => 'Take photo';

  @override
  String get dog_detail_photo_pick_gallery => 'Choose from photos';

  @override
  String get dog_detail_photo_remove => 'Remove photo';

  @override
  String get dog_detail_snackbar_photo_updated => 'Profile photo updated';

  @override
  String get dog_detail_snackbar_photo_removed => 'Profile photo removed';

  @override
  String get dog_detail_snackbar_error_generic => 'Something went wrong';

  @override
  String get dog_detail_info_label_sex => 'Sex';

  @override
  String get dog_detail_info_label_born => 'Born';

  @override
  String get dog_detail_summary_points_label => 'Points';

  @override
  String get dog_detail_summary_session_count_label => 'Session count';

  @override
  String get dog_detail_summary_active_time_label => 'Active time';

  @override
  String get dog_detail_summary_birds_down_label => 'Birds down';

  @override
  String get dog_detail_summary_first_session_label => 'First session';

  @override
  String get dog_detail_summary_last_session_label => 'Last session';

  @override
  String get dog_detail_tooltip_edit_profile => 'Edit dog';

  @override
  String get dog_detail_farewell_prefix => 'Farewell';

  @override
  String dog_detail_farewell_age_sentence(Object name, Object years, Object months, Object days) {
    return '$name was $years $months $days old';
  }

  @override
  String get dog_detail_next_milestones_title => 'Next milestones';

  @override
  String get dog_detail_next_milestone_title => 'Next milestone';

  @override
  String get milestone_first_session_title => 'First session completed';

  @override
  String milestone_first_session_subtitle(Object dogName) {
    return 'First session with $dogName';
  }

  @override
  String get milestone_first_bird_title => 'First bird';

  @override
  String age_years(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String age_years_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yrs',
      one: '$count yr',
    );
    return '$_temp0';
  }

  @override
  String age_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String age_months_short(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mos',
      one: '$count mo',
    );
    return '$_temp0';
  }

  @override
  String age_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get age_zero_days => '0 days';

  @override
  String get age_and => 'and';

  @override
  String get home_startNewSession => 'Start new session';

  @override
  String get chooseDog => 'Choose dog';

  @override
  String get noDogsAddDog => 'No dogs – add a dog';

  @override
  String get home_addDogPrompt => 'Add a dog to start a session';

  @override
  String get home_empty_title => 'Start your journey with your hunting dog';

  @override
  String get home_empty_body => 'Log sessions, track progress, and build a history for your dog – session by session.';

  @override
  String get home_empty_bullet_progress => 'See development over time – stand, flushes and activity.';

  @override
  String get home_empty_bullet_training => 'Train better – see what actually pays off.';

  @override
  String get home_empty_bullet_history => 'Hunting history you actually use – season after season, area by area.';

  @override
  String get home_visible_empty_title => 'No dogs available';

  @override
  String get home_visible_empty_body => 'This account has no dogs yet. Check invitations or ask someone to share a dog with you.';

  @override
  String get home_visible_empty_button => 'Open invitations';

  @override
  String get home_addDog_button => 'Add dog';

  @override
  String get home_empty_offline_note => 'You can use the app completely offline. All data is stored locally on your phone.';

  @override
  String get home_noDogsRegistered => 'No dogs registered';

  @override
  String get home_primaryActionSubtitle => 'Notes first. Use the + buttons in the fields.';

  @override
  String get home_top10_points_title => 'Top 10 – Points';

  @override
  String get top10Title => 'Top 10';

  @override
  String get home_top10_points_empty => 'No points recorded yet.';

  @override
  String home_top10_points_pointsLabel(int count) {
    return 'Points: $count';
  }

  @override
  String top10_points_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'points',
      one: 'point',
    );
    return '$_temp0';
  }

  @override
  String get home_top10_birds_title => 'Top 10 birds down';

  @override
  String get home_top10_birds_empty => 'No birds recorded yet.';

  @override
  String get home_top10_birds_fieldLabel => 'Birds';

  @override
  String get session_log_title => 'Session log – Gundog';

  @override
  String get session_saved_list_title => 'Saved sessions';

  @override
  String get session_save_button => 'Save session';

  @override
  String get session_unit_min => 'min';

  @override
  String get session_unit_sec => 'sec';

  @override
  String get session_label_points => 'points';

  @override
  String get session_label_flushes => 'flushes';

  @override
  String get session_label_birds => 'birds';

  @override
  String get session_label_birds_down => 'birds down';

  @override
  String get session_all_dogs_label => 'All dogs';

  @override
  String get session_map_label => 'Map';

  @override
  String get session_map_error_no_tracks => 'No tracks found';

  @override
  String get session_map_error_map_load_failed => 'Could not load the map';

  @override
  String get map_page_snackbar_no_tracks_to_focus => 'No tracks to focus on';

  @override
  String get map_page_dialog_delete_downloaded_map_body => 'Do you want to delete this downloaded map?';

  @override
  String get hunt_session_snackbar_export_ready_opening_share => 'Export ready, opening share…';

  @override
  String get hunt_session_snackbar_gpx_export_failed_see_log => 'GPX export failed. See log.';

  @override
  String get session_gpx_import_label => 'Import GPX';

  @override
  String get session_gpx_importing_ellipsis => 'Importing…';

  @override
  String get session_gpx_export_label => 'Export GPX';

  @override
  String get session_gpx_exporting_ellipsis => 'Exporting…';

  @override
  String get session_form_dog_section_title => 'Dog';

  @override
  String get session_form_dog_prefix => 'Dog:';

  @override
  String get session_form_no_dogs_registered => 'No dogs registered.';

  @override
  String get session_summary_sessions_label => 'Sessions:';

  @override
  String get session_summary_total_time_label => 'Total time:';

  @override
  String get session_summary_total_bird_contacts_label => 'Total bird contacts:';

  @override
  String get session_summary_total_points_label => 'Total points:';

  @override
  String get session_summary_total_secondary_points_label => 'Total secondary points:';

  @override
  String get session_summary_total_flushes_label => 'Total flushes:';

  @override
  String get session_action_add_new_session => 'Add new session';

  @override
  String get session_action_cancel => 'Cancel';

  @override
  String get session_type_title => 'Session type';

  @override
  String get session_type_training => 'Training';

  @override
  String get session_type_hunt => 'Hunt';

  @override
  String get session_field_location => 'Location';

  @override
  String get session_field_active_time_minutes => 'Active time (min)';

  @override
  String get session_field_bird_contacts => 'Bird contacts';

  @override
  String get session_field_points => 'Points';

  @override
  String get session_field_secondary_points => 'Secondary points';

  @override
  String get session_field_flushes => 'Flushes';

  @override
  String get session_pick_date => 'Select date';

  @override
  String get session_pick_time => 'Time';

  @override
  String get session_birds_section_title => 'Birds';

  @override
  String get session_birds_select_species => 'Select bird species';

  @override
  String get session_birds_none_selected => 'No species selected';

  @override
  String get session_species_picker_title => 'Select species';

  @override
  String get session_species_picker_empty => 'No species available';

  @override
  String get session_species_picker_add => 'Add';

  @override
  String get session_species_picker_done => 'Done';

  @override
  String get session_error_no_dogs_registered => 'No dogs registered';

  @override
  String get session_select_species_title => 'Select species';

  @override
  String get session_no_species_saved_yet => 'No species saved yet';

  @override
  String get session_new_bird_button => 'New bird';

  @override
  String get session_new_species_title => 'New species';

  @override
  String get session_error_photo_add => 'Could not add photo';

  @override
  String get session_error_video_add => 'Could not add video';

  @override
  String get session_error_media_save => 'Could not save media file';

  @override
  String get session_error_gpx_import => 'GPX import failed. See log.';

  @override
  String get session_error_location_services_disabled => 'Location services are disabled';

  @override
  String get session_error_no_gps => 'No GPS access';

  @override
  String session_error_gps_failure(String error) {
    return 'GPS error: $error';
  }

  @override
  String get session_error_stop_gps => 'Could not stop GPS';

  @override
  String get session_error_select_dog_first => 'Select a dog first';

  @override
  String get session_error_no_track_export => 'This session has no track to export';

  @override
  String get session_error_track_empty => 'Track is missing or empty';

  @override
  String session_snackbar_message(String message) {
    return '$message';
  }

  @override
  String get session_media_add_image_failed => 'Could not add image';

  @override
  String get session_media_add_video_failed => 'Could not add video';

  @override
  String get session_media_save_failed => 'Could not save the media file';

  @override
  String get session_media_video_missing => 'Video missing or was not saved correctly';

  @override
  String get session_media_video_open_failed => 'Could not open video';

  @override
  String get session_media_section_title => 'Media';

  @override
  String get session_media_add_photo_video => 'Add photo/video';

  @override
  String get session_media_gallery_label => 'Photo from gallery';

  @override
  String get session_media_camera_label => 'Take photo';

  @override
  String get session_media_video_label => 'Video from gallery';

  @override
  String get gpx_import_failed_see_log => 'GPX import failed. See log.';

  @override
  String get gps_services_disabled => 'Location services are disabled';

  @override
  String get gps_no_permission => 'No GPS permission';

  @override
  String gps_error_message(String error) {
    return 'GPS error: $error';
  }

  @override
  String get gps_stop_failed => 'Could not stop GPS';

  @override
  String get session_select_dog_first => 'Select a dog first';

  @override
  String get session_export_no_track => 'This session has no track to export';

  @override
  String get session_track_missing_or_empty => 'Track is missing or empty';

  @override
  String gpx_exported_to_desktop(String filename) {
    return 'GPX exported to Desktop: $filename ✅';
  }

  @override
  String get session_detail_title_edit_session => 'Edit session';

  @override
  String get session_detail_title_new_session => 'New session';

  @override
  String get session_detail_label_points => 'Points';

  @override
  String get session_detail_label_flushes => 'Flushes';

  @override
  String get session_detail_button_add_media => 'Add photo/video';

  @override
  String session_detail_total_points(String value) {
    return 'Points total: $value';
  }

  @override
  String get session_detail_title_home => 'Home';

  @override
  String get session_detail_title_main => 'Session';

  @override
  String get session_detail_title_active_session => 'Active session';

  @override
  String get active_session_hunt_events_title => 'Hunting events +1';

  @override
  String get active_session_action_stand_plus1 => 'Point +1';

  @override
  String get active_session_action_secondary_plus1 => 'Backing +1';

  @override
  String get active_session_action_flush_plus1 => 'Flush +1';

  @override
  String get active_session_action_bird_plus1 => 'Bird +1';

  @override
  String get active_session_action_undo => 'Undo';

  @override
  String get session_detail_label_choose_dog => 'Choose dog';

  @override
  String get session_detail_button_open_latest_session => 'Open latest session';

  @override
  String get session_detail_button_start_new_session => 'Start new session';

  @override
  String get session_detail_button_settings => 'Settings';

  @override
  String get session_detail_media_sheet_title => 'Add media';

  @override
  String get session_detail_media_sheet_action_gallery => 'Gallery';

  @override
  String get session_detail_media_sheet_action_camera => 'Camera';

  @override
  String get session_detail_media_sheet_action_video => 'Video';

  @override
  String get session_detail_media_section_title => 'Media';

  @override
  String get session_detail_media_empty_placeholder => 'No media yet';

  @override
  String get session_detail_notes_hint => 'Notes from the session...';

  @override
  String session_detail_meta_time_minutes(Object minutes) {
    return 'Active time: $minutes min';
  }

  @override
  String session_detail_meta_birds(Object value) {
    return 'Bird contacts: $value';
  }

  @override
  String session_detail_meta_secondary_points(Object count) {
    return 'Secondary points: $count';
  }

  @override
  String session_detail_meta_flushes(Object value) {
    return 'Flushes: $value';
  }

  @override
  String get session_detail_screen_title => 'Session details';

  @override
  String get session_notes_hint_from_session => 'Notes from the session...';

  @override
  String get session_notes_section_title => 'Notes';

  @override
  String get session_detail_section_dog => 'Dog';

  @override
  String get session_detail_section_media => 'Media';

  @override
  String get session_detail_section_notes => 'Notes';

  @override
  String get session_detail_media_open_gallery => 'Open gallery';

  @override
  String get session_detail_button_import_gpx => 'Import GPX';

  @override
  String get session_detail_button_importing => 'Importing…';

  @override
  String get session_detail_empty_bird_species => 'No bird species';

  @override
  String get session_detail_empty_location => 'Unknown location';

  @override
  String get session_detail_saved_sessions_title => 'Saved sessions';

  @override
  String get session_detail_empty_sessions_for_selected_dog => 'No sessions for the selected dog';

  @override
  String get session_detail_empty_dogs_registered => 'No dogs registered.';

  @override
  String get session_detail_empty_sessions_yet => 'No sessions yet';

  @override
  String session_detail_track_summary_points(int count) {
    return 'Track: $count points';
  }

  @override
  String session_detail_track_summary_start(String time) {
    return 'Start: $time';
  }

  @override
  String session_detail_track_summary_end(String time) {
    return 'End: $time';
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
    return 'Duration: $value';
  }

  @override
  String get session_detail_action_saving => 'Saving…';

  @override
  String get session_detail_action_save_changes => 'Save changes';

  @override
  String get session_detail_action_save_session => 'Save session';

  @override
  String get session_detail_edit_title => 'Edit session';

  @override
  String get session_detail_button_save => 'Save';

  @override
  String get session_detail_button_cancel => 'Cancel';

  @override
  String get session_detail_button_delete => 'Delete';

  @override
  String get session_detail_field_location_label => 'Location';

  @override
  String get session_detail_field_active_time_minutes_label => 'Active time (min)';

  @override
  String get session_detail_field_bird_contacts_label => 'Bird contacts';

  @override
  String get session_detail_field_points_label => 'Points';

  @override
  String get session_detail_field_secondary_points_label => 'Secondary points';

  @override
  String get session_detail_field_flushes_label => 'Flushes';

  @override
  String get session_detail_field_notes_label => 'Note';

  @override
  String session_detail_version_build(String buildNumber) {
    return ' (build $buildNumber)';
  }

  @override
  String get session_detail_snackbar_changes_saved => 'Changes saved';

  @override
  String get session_detail_snackbar_session_saved => 'Session saved';

  @override
  String session_detail_snackbar_saved_with_imported_gpx(int points) {
    return 'Session saved with imported GPX ($points points)';
  }

  @override
  String session_detail_snackbar_saved_with_gps_track(int points) {
    return 'Session saved with GPS track ($points points)';
  }

  @override
  String get session_detail_help_notes_first => 'Notes first. Counters with + in the field.';

  @override
  String session_detail_stats_sessions_count(int count) {
    return 'Sessions: $count';
  }

  @override
  String session_detail_stats_total_active_time(int minutes) {
    return 'Total active time: $minutes min';
  }

  @override
  String session_detail_stats_total_birds(int count) {
    return 'Bird contacts total: $count';
  }

  @override
  String session_detail_stats_total_points(int count) {
    return 'Points total: $count';
  }

  @override
  String session_detail_stats_total_secondary_points(int count) {
    return 'Secondary points total: $count';
  }

  @override
  String session_detail_stats_total_flushes(int count) {
    return 'Flushes total: $count';
  }

  @override
  String get session_detail_button_select_date => 'Select date';

  @override
  String get session_detail_button_select_time => 'Time';

  @override
  String get session_detail_label_duration_from_track => 'Taken from GPS track';

  @override
  String session_detail_saved_session_summary(int durationMinutes, int birds, int stand, int secondaryPoints, int flushes) {
    return 'Time: $durationMinutes min, Birds: $birds, Points: $stand, Secondary: $secondaryPoints, Flushes: $flushes';
  }

  @override
  String get session_detail_button_exporting => 'Exporting…';

  @override
  String get session_detail_button_export_gpx => 'Export GPX';

  @override
  String get session_detail_error_gpx_too_few_points => 'Too few GPX points in the file';

  @override
  String session_detail_helper_duration_hours_minutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get session_detail_bird_species_picker_title => 'Select bird species';

  @override
  String get session_detail_bird_section_title => 'Bird';

  @override
  String get session_detail_bird_species_button_label => 'Select bird species';

  @override
  String get session_detail_bird_species_empty_selection => 'No species selected';

  @override
  String get session_detail_bird_species_empty_saved => 'No species saved yet';

  @override
  String get session_detail_bird_species_new => 'New bird';

  @override
  String get session_detail_action_done => 'Done';

  @override
  String get session_detail_bird_species_dialog_title => 'New bird species';

  @override
  String get session_detail_bird_species_dialog_name_label => 'Name';

  @override
  String get session_action_save => 'Save';

  @override
  String get session_detail_media_gallery_title => 'Media';

  @override
  String get hunt_session_title_new => 'New session';

  @override
  String get hunt_session_title_edit => 'Edit session';

  @override
  String get hunt_session_field_location_label => 'Location';

  @override
  String get hunt_session_field_duration_minutes_label => 'Active time (min)';

  @override
  String get hunt_session_field_birds_seen_label => 'Bird contacts';

  @override
  String get hunt_session_field_points_label => 'Points';

  @override
  String get hunt_session_field_secondary_points_label => 'Secondary points';

  @override
  String get hunt_session_field_flushes_label => 'Flushes';

  @override
  String get hunt_session_field_notes_label => 'Notes';

  @override
  String get hunt_session_action_save => 'Save';

  @override
  String get hunt_session_action_cancel => 'Cancel';

  @override
  String get hunt_session_action_delete => 'Delete';

  @override
  String get hunt_session_action_import_gpx => 'Import GPX';

  @override
  String get hunt_session_action_importing => 'Importing…';

  @override
  String hunt_session_snackbar_saved_with_gps_track(Object points) {
    return 'Session saved with GPS track ($points points)';
  }

  @override
  String get session_detail_filter_all_dogs => 'All dogs';

  @override
  String get session_detail_session_menu_export => 'Export GPX';

  @override
  String get session_detail_session_menu_exporting => 'Exporting…';

  @override
  String get session_detail_session_menu_edit => 'Edit session';

  @override
  String get session_detail_session_menu_delete => 'Delete session';

  @override
  String get session_detail_detail_title => 'Details';

  @override
  String get session_detail_detail_label_date => 'Date';

  @override
  String get session_detail_detail_label_location => 'Location';

  @override
  String get session_detail_detail_label_active_time => 'Active time';

  @override
  String get session_detail_detail_label_bird_contacts => 'Bird contacts';

  @override
  String get session_detail_detail_label_points => 'Points';

  @override
  String get session_detail_detail_label_secondary_points => 'Secondary points';

  @override
  String get session_detail_detail_label_flushes => 'Flushes';

  @override
  String get session_detail_label_bird_species => 'Bird species';

  @override
  String get session_detail_label_gps_track => 'GPS track';

  @override
  String get session_detail_label_yes => 'Yes';

  @override
  String get session_detail_label_no => 'No';

  @override
  String get session_detail_label_dog_prefix => 'Dog: ';

  @override
  String get session_detail_map_title => 'Map';

  @override
  String get session_detail_map_prefix => 'Map – ';

  @override
  String get map_title => 'Map';

  @override
  String get session_detail_gpx_replace_title => 'Replace track?';

  @override
  String get session_detail_gpx_replace_body => 'This will replace the existing track. Continue?';

  @override
  String get session_detail_gpx_replace_confirm => 'Replace';

  @override
  String session_detail_gpx_replaced_snackbar(int points) {
    return 'Track replaced: $points points';
  }

  @override
  String session_detail_gpx_imported_snackbar(int points) {
    return 'GPX imported: $points points';
  }

  @override
  String get session_detail_empty_notes => 'No notes';

  @override
  String get session_detail_empty_media => 'No media added';

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
    return 'Flushes total: $value';
  }

  @override
  String get gpx_import_label => 'Import GPX';

  @override
  String get session_menu_edit => 'Edit session';

  @override
  String get session_menu_delete => 'Delete session';

  @override
  String stats_trend_label(String symbol) {
    return 'Trend: $symbol';
  }

  @override
  String get stats_title_points_and_flushes => 'Points and flushes';

  @override
  String get stats_title_sessions => 'Sessions';

  @override
  String get stats_title_birds_down_per_year => 'Birds down per year';

  @override
  String get stats_subtitle_active_time => 'Active time';

  @override
  String get stats_subtitle_session_count => 'Session count';

  @override
  String get stats_legend_bars => 'Bars:';

  @override
  String get stats_legend_line => 'Line:';

  @override
  String get stats_title_development => 'Development';

  @override
  String get stats_period_30_days => '30 days';

  @override
  String get stats_period_90_days => '90 days';

  @override
  String get stats_legend_active_time => 'Active time';

  @override
  String get stats_legend_sessions => 'Sessions';

  @override
  String stats_week_tooltip(String weekLabel, int sessions, String time) {
    return '$weekLabel: $sessions sessions, $time';
  }

  @override
  String get stats_info_active_time_title => 'Active time';

  @override
  String get stats_info_active_time_body_1 => 'Total time the dog has been working.';

  @override
  String get stats_info_active_time_body_2 => 'Used to assess workload and consistency.';

  @override
  String get stats_info_session_count_title => 'Sessions';

  @override
  String get stats_info_session_count_body_1 => 'How often the dog has been active.';

  @override
  String get stats_info_session_count_body_2 => 'Shows training and hunting frequency.';

  @override
  String get stats_v1_overview_title => 'V1 overview';

  @override
  String get stats_total_points_title => 'Total points';

  @override
  String get stats_total_active_time_title => 'Total active time';

  @override
  String get stats_avg_points_per_session_title => 'Avg points per session';

  @override
  String get stats_avg_time_per_session_title => 'Avg time per session';

  @override
  String get stats_last_30_days_sessions_title => 'Last 30 days: Sessions';

  @override
  String get stats_last_30_days_points_title => 'Last 30 days: Points';

  @override
  String stats_overview_sessions_value(int count) {
    return '$count sessions';
  }

  @override
  String stats_overview_points_value(int count) {
    return '$count points';
  }

  @override
  String stats_last_30_days_sessions_value(int count) {
    return '$count sessions';
  }

  @override
  String stats_last_30_days_points_value(int count) {
    return '$count points';
  }

  @override
  String get stats_points_label => 'Points';

  @override
  String get stats_flushes_label => 'Flushes';

  @override
  String stats_per_month_suffix(int year) {
    return 'per month • $year';
  }

  @override
  String stats_monthly_sessions_tooltip(String month, int year, int count) {
    return '$month $year: $count sessions';
  }

  @override
  String stats_monthly_sessions_tooltip_empty(String month, int year) {
    return '$month $year: No sessions';
  }

  @override
  String stats_total_points_flushes_prefix(int points, int flushes) {
    return 'Total: $points points, $flushes flushes';
  }

  @override
  String stats_stand_flush_tooltip(String month, int year, String stand, String flush) {
    return '$month $year: Points $stand, Flushes $flush';
  }

  @override
  String get stats_info_points_flushes_title => 'Points and flushes';

  @override
  String get stats_info_points_flushes_body_1 => 'Shows the number of points and flushes over time.';

  @override
  String get stats_info_points_flushes_body_2 => 'Gives insight into the dog’s field work and hunting pattern.';

  @override
  String get stats_none => 'None';

  @override
  String get stats_unknown_species => 'Unknown';

  @override
  String get stats_info_explanation_tooltip => 'Explanation';

  @override
  String stats_total_sessions_prefix(int count) {
    return 'Total: $count sessions';
  }

  @override
  String get stats_info_sessions_title => 'Sessions';

  @override
  String get stats_info_sessions_body_1 => 'How often the dog has been active.';

  @override
  String get stats_info_sessions_body_2 => 'Shows training and hunting frequency.';

  @override
  String get stats_no_birds_down_yet => 'No birds down registered yet';

  @override
  String get stats_birds_distribution_title => 'Birds down distribution';

  @override
  String get stats_birds_pie_hint => 'Tap a slice for details';

  @override
  String get stats_info_birds_down_title => 'Birds down';

  @override
  String get stats_info_birds_down_body_1 => 'Number of birds down per calendar year.';

  @override
  String get stats_info_birds_down_body_2 => 'Provides a basis for year-to-year comparison.';

  @override
  String get stats_info_birds_distribution_title => 'Birds down distribution';

  @override
  String get stats_info_birds_distribution_body_1 => 'Shows which species were taken in the selected year.';

  @override
  String get stats_info_birds_distribution_body_2 => 'Gives an overview of harvest and variation.';

  @override
  String get stats_label_year => 'Year';

  @override
  String get stats_label_total => 'Total';

  @override
  String get stats_label_per_month => 'per month';

  @override
  String get gpx_importing_ellipsis => 'Importing…';

  @override
  String get gpx_export_label => 'Export GPX';

  @override
  String get gpx_exporting_ellipsis => 'Exporting…';

  @override
  String get home_open_settings_tooltip => 'Settings';

  @override
  String get home_settings_button_label => 'Settings';

  @override
  String get home_no_dogs_title => 'No dogs registered yet';

  @override
  String get home_no_dogs_message => 'Register your dogs to log training, hunting, and trials. You’ll get a clear history and a better view of progress over time.';

  @override
  String get home_no_dogs_bullet_history => 'History: keep sessions, notes, and locations in one place';

  @override
  String get home_no_dogs_bullet_progress => 'Progress: track points, flushes, and active time over time';

  @override
  String get home_no_dogs_bullet_stats => 'Stats: meaningful trends that support your hunting';

  @override
  String get home_wisdom_empty => 'A calm beginning leads to better hunting than haste.';

  @override
  String get wisdom_001 => 'A calm dog learns faster than a stressed one.';

  @override
  String get wisdom_002 => 'What you train today, you’ll get back in the autumn.';

  @override
  String get wisdom_003 => 'Repeat less. Wait more.';

  @override
  String get wisdom_004 => 'Silence is training too.';

  @override
  String get wisdom_005 => 'Progress often happens between sessions.';

  @override
  String get wisdom_006 => 'A timely break is better than one repetition too many.';

  @override
  String get wisdom_007 => 'Patience is the most underrated exercise.';

  @override
  String get wisdom_008 => 'Train what you want to see, not what you hope for.';

  @override
  String get wisdom_009 => 'A confident dog learns faster than an eager one.';

  @override
  String get wisdom_010 => 'It’s okay to end on a high note.';

  @override
  String get wisdom_011 => 'A point is built before the bird, not after.';

  @override
  String get wisdom_012 => 'Steadiness in the flush starts in the mind.';

  @override
  String get wisdom_013 => 'Steadiness is a choice the dog learns to make.';

  @override
  String get wisdom_014 => 'Pressure creates movement. Time creates steadiness.';

  @override
  String get wisdom_015 => 'A good point doesn’t need an audience.';

  @override
  String get wisdom_016 => 'When the dog points, let the world wait.';

  @override
  String get wisdom_017 => 'One calm point is better than three rushed ones.';

  @override
  String get wisdom_018 => 'The bird teaches the dog. You shape the reaction.';

  @override
  String get wisdom_019 => 'Pointing is a moment of balance.';

  @override
  String get wisdom_020 => 'Don’t rush through stillness.';

  @override
  String get wisdom_021 => 'Read the wind before you read the dog.';

  @override
  String get wisdom_022 => 'The terrain trains the dog as much as you do.';

  @override
  String get wisdom_023 => 'Every bird is a new lesson.';

  @override
  String get wisdom_024 => 'Bad conditions create good experience.';

  @override
  String get wisdom_025 => 'Hunting is cooperation, not competition.';

  @override
  String get wisdom_026 => 'Quality shows in a headwind.';

  @override
  String get wisdom_027 => 'An empty round can still be full of learning.';

  @override
  String get wisdom_028 => 'Let the dog find the solution.';

  @override
  String get wisdom_029 => 'A bird dog’s strength is independence with direction.';

  @override
  String get wisdom_030 => 'The field remembers everything.';

  @override
  String get wisdom_031 => 'Be consistent, not perfect.';

  @override
  String get wisdom_032 => 'The dog mirrors your pace.';

  @override
  String get wisdom_033 => 'What you don’t react to, you accept.';

  @override
  String get wisdom_034 => 'A clear mind makes a clear dog.';

  @override
  String get wisdom_035 => 'Fairness beats harshness.';

  @override
  String get wisdom_036 => 'Train with your head before your voice.';

  @override
  String get wisdom_037 => 'Don’t explain. Show.';

  @override
  String get wisdom_038 => 'A confident handler builds a confident dog.';

  @override
  String get wisdom_039 => 'Your calm is the dog’s framework.';

  @override
  String get wisdom_040 => 'Listen more than you correct.';

  @override
  String get wisdom_041 => 'The relationship is built even without birds.';

  @override
  String get wisdom_042 => 'A good walk is never wasted.';

  @override
  String get wisdom_043 => 'Trust takes time. Distrust takes seconds.';

  @override
  String get wisdom_044 => 'The dog works best for the one it trusts.';

  @override
  String get wisdom_045 => 'Small routines create big security.';

  @override
  String get wisdom_046 => 'It’s okay to just be a dog sometimes.';

  @override
  String get wisdom_047 => 'Playfulness isn’t lack of discipline.';

  @override
  String get wisdom_048 => 'A satisfied dog performs better.';

  @override
  String get wisdom_049 => 'Cooperation beats control.';

  @override
  String get wisdom_050 => 'Relationship before skills.';

  @override
  String get wisdom_051 => 'A trial is a snapshot, not a verdict.';

  @override
  String get wisdom_052 => 'The judge sees one day. You see the whole year.';

  @override
  String get wisdom_053 => 'Results are a bonus, not the goal.';

  @override
  String get wisdom_054 => 'A good experience beats a good placement.';

  @override
  String get wisdom_055 => 'Pressure at home creates calm at the trial.';

  @override
  String get wisdom_056 => 'Train situations, not points.';

  @override
  String get wisdom_057 => 'A steady dog is always competitive.';

  @override
  String get wisdom_058 => 'Learn from what didn’t work.';

  @override
  String get wisdom_059 => 'Trials are training with an audience.';

  @override
  String get wisdom_060 => 'Don’t chase prizes, build the dog.';

  @override
  String get wisdom_061 => 'A bird dog is never fully finished learning.';

  @override
  String get wisdom_062 => 'It’s the road to the point that matters.';

  @override
  String get wisdom_063 => 'Patience doesn’t smell like stress.';

  @override
  String get wisdom_064 => 'The best moments can’t be logged.';

  @override
  String get wisdom_065 => 'A bird dog is trust at speed.';

  @override
  String get wisdom_066 => 'Silence is often the answer.';

  @override
  String get wisdom_067 => 'Nature always sets the limits.';

  @override
  String get wisdom_068 => 'A good day in the field lasts a long time.';

  @override
  String get wisdom_069 => 'The dog remembers the mood.';

  @override
  String get wisdom_070 => 'Hunting is teamwork with the landscape.';

  @override
  String get wisdom_071 => 'A short lead today can create long calm tomorrow.';

  @override
  String get wisdom_072 => 'What gets rewarded, gets repeated.';

  @override
  String get wisdom_073 => 'Keep demands small, and build them big over time.';

  @override
  String get wisdom_074 => 'When you lose calm, you lose learning.';

  @override
  String get wisdom_075 => 'A clear start makes the finish easy.';

  @override
  String get wisdom_076 => 'Calm isn’t passive. Calm is control.';

  @override
  String get wisdom_077 => 'Train the boring stuff. It saves the day.';

  @override
  String get wisdom_078 => 'Good handling is often invisible.';

  @override
  String get wisdom_079 => 'When the dog succeeds, it’s because you were predictable.';

  @override
  String get wisdom_080 => 'Don’t chase speed. Chase quality.';

  @override
  String get wisdom_081 => 'Give the dog time to finish thinking.';

  @override
  String get wisdom_082 => 'A ‘no’ without anger is worth more than ten ‘yes’ with stress.';

  @override
  String get wisdom_083 => 'Stop before you have to stop.';

  @override
  String get wisdom_084 => 'You’re always training, even when you think you’re just walking.';

  @override
  String get wisdom_085 => 'The bird reveals the gaps. Train the gaps.';

  @override
  String get wisdom_086 => 'A good stop is the start of a good point.';

  @override
  String get wisdom_087 => 'A light hand builds heavy cooperation.';

  @override
  String get wisdom_088 => 'When things go sideways: slow down, increase clarity.';

  @override
  String get wisdom_089 => 'A reliable routine beats a perfect plan.';

  @override
  String get wisdom_090 => 'Your most important signal is your body language.';

  @override
  String get standsLabel => 'Points';

  @override
  String standsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
      zero: '0 points',
    );
    return '$_temp0';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_section_general => 'General';

  @override
  String get settings_section_milestones => 'Milestones';

  @override
  String get invitations_title => 'Invitations';

  @override
  String get invitations_empty => 'No pending invitations';

  @override
  String get settings_section_feedback => 'Feedback';

  @override
  String get supportEmail => 'support@gundogtracker.app';

  @override
  String get support_email => 'support@gundogtracker.app';

  @override
  String get settings_section_subscription => 'Subscription';

  @override
  String get settings_section_language => 'Language';

  @override
  String get settings_section_community => 'Community';

  @override
  String get settings_section_security => 'Security';

  @override
  String get settings_change_password_title => 'Change password';

  @override
  String get settings_change_password_current_password => 'Current password';

  @override
  String get settings_change_password_new_password => 'New password';

  @override
  String get settings_change_password_confirm_password => 'Confirm new password';

  @override
  String get settings_change_password_submit => 'Update password';

  @override
  String get settings_change_password_success => 'Password updated';

  @override
  String get settings_reset_password_button => 'Forgot password';

  @override
  String get settings_reset_password_sent => 'Check your email for a reset link';

  @override
  String get settings_reset_password_no_email => 'No email on record to reset password';

  @override
  String get settings_change_password_error_fields => 'Fill in all fields';

  @override
  String get settings_change_password_error_mismatch => 'New password and confirmation must match';

  @override
  String get forgot_password_title => 'Forgot password';

  @override
  String get forgot_password_description => 'Enter your email address and we will send you a link to reset your password.';

  @override
  String get forgot_password_email_label => 'Email';

  @override
  String get forgot_password_button => 'Send reset link';

  @override
  String get forgot_password_error_missing => 'Enter an email address.';

  @override
  String get forgot_password_error_invalid => 'Enter a valid email address.';

  @override
  String get forgot_password_check_spam_hint => 'Check your inbox. If the email doesn\'t show up, check Spam/Junk.';

  @override
  String get settings_backup_import_success => 'Backup imported';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_language_title => 'Language';

  @override
  String get settings_language_followSystem => 'Follow system';

  @override
  String get settings_language_nb => 'Norwegian (Bokmål)';

  @override
  String get settings_language_sv => 'Swedish';

  @override
  String get settings_language_da => 'Danish';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_milestones_enabled_title => 'Milestones';

  @override
  String get settings_milestones_enabled_subtitle => 'Show small moments when your dog reaches important steps.';

  @override
  String get settings_haptics_enabled_title => 'Haptics for milestones';

  @override
  String get settings_haptics_enabled_subtitle => 'Subtle vibration when milestones are achieved.';

  @override
  String get settings_restore_in_progress => 'Restore in progress… Please wait.';

  @override
  String get settings_section_backup => 'Backup';

  @override
  String get settings_backup_export_action => 'Export backup (ZIP)';

  @override
  String get settings_backup_exporting => 'Exporting…';

  @override
  String get settings_backup_subtitle => 'Export/import dogs, sessions, tracks, milestones, and media.';

  @override
  String get settings_backup_import_action => 'Import backup (ZIP)';

  @override
  String get settings_backup_importing => 'Importing…';

  @override
  String get settings_backup_import_description => 'Select a backup zip to restore data.';

  @override
  String get settings_backup_where_title => 'Where is backup stored?';

  @override
  String get settings_backup_where_action => 'Show storage folder';

  @override
  String get settings_backup_status_collectingData => 'Collecting data…';

  @override
  String get settings_backup_status_collectingMedia => 'Collecting media…';

  @override
  String get settings_backup_status_creatingZip => 'Creating ZIP…';

  @override
  String get settings_backup_status_sharing => 'Sharing…';

  @override
  String get settings_backup_status_selectZip => 'Select ZIP…';

  @override
  String get settings_backup_status_restoring => 'Restoring data…';

  @override
  String get settings_backup_share_subject => 'Fuglehund backup';

  @override
  String settings_backup_ready(Object fileName) {
    return 'Backup ready: $fileName ✅';
  }

  @override
  String settings_backup_failed(Object message) {
    return 'Backup failed: $message';
  }

  @override
  String get auth_profile_pending_title => 'Creating profile…';

  @override
  String get auth_profile_pending_body => 'Waiting for the backend document to exist. Tap \"Try again\" to re-check.';

  @override
  String get auth_profile_timeout_error => 'Could not find the user profile within a few seconds. Check your network or try again.';

  @override
  String get settings_backup_failed_unknown => 'Unknown error.';

  @override
  String settings_backup_import_failed(Object message) {
    return 'Import failed: $message';
  }

  @override
  String get settings_backup_restore_dialog_title => 'Restore backup';

  @override
  String get settings_backup_restore_dialog_content => 'This will restore data from a ZIP backup.\n\nTip: Restart the app once the import finishes.';

  @override
  String get settings_backup_restore_dialog_confirm => 'Restore';

  @override
  String get settings_backup_restore_prompt_title => 'Restore complete';

  @override
  String get settings_backup_restore_prompt_message => 'Restore finished. Restart the app now?';

  @override
  String get settings_backup_restore_saved => 'Restore saved. Restart the app when convenient.';

  @override
  String get settings_backup_restore_complete => 'Import complete';

  @override
  String get settings_backup_storage_title => 'Backup storage';

  @override
  String settings_backup_storage_description(String path) {
    return 'Backup files are saved here:\n\n$path';
  }

  @override
  String get settings_backup_restore_pending => 'Importing backup…';

  @override
  String get settings_backup_restore_pending_message => 'Restoring backup… please wait.';

  @override
  String get settings_section_appearance => 'Appearance';

  @override
  String get settings_season_title => 'Season theme';

  @override
  String get settings_season_subtitle => 'Colors for the top and bottom of the screen.';

  @override
  String get settings_season_auto => 'Automatic';

  @override
  String get settings_season_spring => '🌱 Spring';

  @override
  String get settings_season_summer => '☀️ Summer';

  @override
  String get settings_season_autumn => '🍁 Autumn';

  @override
  String get settings_season_winter => '❄️ Winter';

  @override
  String get settings_feedback_send_subtitle => 'Opens email with app info.';

  @override
  String get settings_feedback_bug_subtitle => 'Opens email with a bug report template.';

  @override
  String get settings_feedback_copy_subtitle => 'Copies app and device info.';

  @override
  String get settings_feedback_suggest_subtitle => 'Send suggestions via email.';

  @override
  String get settings_feedback_error_open_email => 'Couldn\'t open email.';

  @override
  String get settings_feedback_error_copy => 'Couldn\'t copy.';

  @override
  String get milestones_achieved_title => 'Achieved milestones';

  @override
  String get milestones_achieved_empty => 'No milestones yet.';

  @override
  String milestones_achieved_duration(String duration) {
    return 'Achieved $duration';
  }

  @override
  String get milestone_sheet_button_ok => 'Nice!';

  @override
  String get milestone_sheet_button_viewAll => 'View milestones';

  @override
  String get milestone_snackbar_new_title => 'New milestone!';

  @override
  String get milestone_snackbar_open_error => 'Could not open milestone';

  @override
  String milestone_stands_count_subtitle(Object dogName, Object countText) {
    return '$dogName has recorded $countText.';
  }

  @override
  String milestone_sessions_count_subtitle(Object dogName, Object countText) {
    return '$dogName has logged $countText.';
  }

  @override
  String milestone_birds_count_subtitle(Object dogName, Object countText) {
    return '$dogName has felled $countText.';
  }

  @override
  String get milestone_first_point_title => 'First point';

  @override
  String milestone_first_point_subtitle(String dogName) {
    return '$dogName recorded its first point.';
  }

  @override
  String get milestone_first_flush_title => 'First flush';

  @override
  String milestone_first_flush_subtitle(String dogName) {
    return '$dogName recorded its first flush.';
  }

  @override
  String get milestone_sessions_10_title => '10 sessions';

  @override
  String milestone_sessions_10_subtitle(String dogName) {
    return '$dogName has logged 10 sessions.';
  }

  @override
  String get milestone_active_hours_10_title => '10 active hours';

  @override
  String milestone_active_hours_10_subtitle(String dogName) {
    return '$dogName has passed 10 hours of active time.';
  }

  @override
  String get milestone_section_birds_down_title => 'Birds down';

  @override
  String get milestone_dog_fallback_name => 'The dog';

  @override
  String milestone_achieved_sentence(Object dog, Object milestone, Object date, Object age) {
    return '$dog achieved “$milestone” on $date$age';
  }

  @override
  String milestone_bird_threshold_label(Object threshold) {
    return '${threshold}th bird';
  }

  @override
  String get milestone_bird_label => 'Bird';

  @override
  String milestone_century_points_title(int count) {
    return '$count points';
  }

  @override
  String milestone_century_points_subtitle(String dogName, int count) {
    return '$dogName has passed $count points.';
  }

  @override
  String get subscription_title => 'Subscription';

  @override
  String get subscription_status_label => 'Status';

  @override
  String get subscription_status_active => 'Active';

  @override
  String get subscription_status_inactive => 'Not active';

  @override
  String get subscription_status_unknown => 'Unknown';

  @override
  String get subscription_subscribe_button => 'Subscribe';

  @override
  String get subscription_restore_button => 'Restore purchases';

  @override
  String get subscription_manage_button => 'Manage / Cancel';

  @override
  String get feedback_send_title => 'Send feedback';

  @override
  String get feedback_bug_title => 'Report a bug';

  @override
  String get feedback_copy_diagnostics_title => 'Copy diagnostics';

  @override
  String get feedback_suggest_milestone_title => 'Suggest a milestone';

  @override
  String get feedback_email_body_intro => 'Describe your feedback here.';

  @override
  String get feedback_bug_prompt => 'What happened?';

  @override
  String get feedback_bug_reproduce => 'How can we reproduce the issue?';

  @override
  String get feedback_suggest_title => 'Idea for a new milestone:';

  @override
  String get feedback_suggest_question_what_to_celebrate => 'What should be celebrated?';

  @override
  String get feedback_suggest_question_why_important => 'Why is this important in practice?';

  @override
  String get feedback_suggest_question_when_should_trigger => 'When should it trigger?';

  @override
  String get feedback_suggest_trigger_hint => '(first time, every 10th, every 100th, other)';

  @override
  String get feedback_suggest_comments => 'Any comments:';

  @override
  String get feedback_error_email_not_available => 'No email app is available.';

  @override
  String get community_open_discord => 'Open Discord group';

  @override
  String get community_open_facebook => 'Open Facebook group';

  @override
  String get home_continueActiveSessionTitle => 'Continue active session';

  @override
  String home_continueActiveSessionSubtitle(String dogName) {
    return 'Unfinished session for $dogName.';
  }

  @override
  String get home_continueActiveSessionMissingDogTitle => 'Active session cannot be restored';

  @override
  String get home_continueActiveSessionMissingDogSubtitle => 'The dog is no longer available. You can discard the draft.';

  @override
  String get home_continueActiveSessionButton => 'Continue active session';

  @override
  String get home_discardActiveSessionButton => 'Discard';

  @override
  String get home_discardActiveSessionSnackbar => 'Discarded active session';

  @override
  String get home_endActiveSessionButton => 'End active session';

  @override
  String get home_endActiveSessionConfirmTitle => 'End active session?';

  @override
  String get home_endActiveSessionConfirmSubtitle => 'Are you sure you want to discard the active session?';

  @override
  String get milestones_category_firsts => 'Firsts';

  @override
  String get milestones_category_sessions => 'Sessions';

  @override
  String get milestones_category_points => 'Stand';

  @override
  String get milestones_category_time => 'Time';

  @override
  String get milestones_category_contacts => 'Contacts';

  @override
  String birdsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count birds',
      one: '1 bird',
      zero: '0 birds',
    );
    return '$_temp0';
  }

  @override
  String birdsDownCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count birds down',
      one: '1 bird down',
      zero: '0 birds down',
    );
    return '$_temp0';
  }
}
