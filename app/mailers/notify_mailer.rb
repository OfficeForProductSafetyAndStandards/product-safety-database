class NotifyMailer < GovukNotifyRails::Mailer
  include NotifyHelper

  TEMPLATES =
    {
      account_locked: "0a78e692-977e-4ca7-94e9-9de64ebd8a5d",
      account_locked_inactive: "4e5294f8-04ac-4791-a265-3504a1df964e",
      notification_risk_level_updated: "66c2f2dd-f3a1-4ef1-a9cc-a99a1b7dff22",
      expired_invitation: "e056e368-5abb-48f4-b98d-ad0933620cc2",
      notification_created: "b5457546-9633-4a9c-a844-b61f2e818c24",
      notification_updated: "10a5c3a6-9cc7-4edb-9536-37605e2c15ba",
      invitation: "7b80a680-f8b3-4032-982d-2a3a662b611a",
      reset_password_instruction: "cea1bb37-1d1c-4965-8999-6008d707b981",
      team_added_to_notification: "f16c2c44-a473-4550-a48a-ac50ef208d5c",
      team_removed_from_notification: "c3ab05a0-cbad-48d3-a271-fe20fda3a0e1",
      notification_permission_changed_for_team: "772f8eb6-2aa2-4ed3-92f2-78af24548303",
      welcome: "035876e3-5b97-4b4c-9bd5-c504b5158a85",
      risk_validation_updated: "a22d37b1-5dc0-4147-ac6d-826232ca8b7a",
      product_export: "1c88c503-638e-4f91-b55f-726900b83f92",
      notification_export: "f6c9a4ad-2050-4f76-bbad-d73bd9747d18",
      business_export: "68df2257-07f5-4768-b50a-74ffa3cb7fd3",
      unsafe_file: "3ba1da4f-a6e4-4d29-a03c-8996fe711c26",
      unsafe_attachment: "6960b99c-7c60-4e28-a7ea-d29a0d0f3d0e",
      draft_notification_reminder: "4defeadb-cb64-49dc-8e36-89e52e5ea3b1"
    }.freeze

  def reset_password_instructions(user, token)
    set_template(TEMPLATES[:reset_password_instruction])
    set_reference("Password reset")
    set_personalisation(
      name: user.name,
      edit_user_password_url_token: edit_user_password_url(reset_password_token: token)
    )

    mail(to: user.email)
  end

  def invitation_email(user, inviting_user = nil)
    set_template(TEMPLATES[:invitation])

    invitation_url = complete_registration_user_url(user.id, invitation: user.invitation_token)

    invited_by = inviting_user.try(&:name) || "a colleague"

    set_personalisation(invitation_url:, inviting_team_member_name: invited_by)
    mail(to: user.email)
  end

  def expired_invitation_email(user)
    set_template(TEMPLATES[:expired_invitation])
    mail(to: user.email)
  end

  def welcome(name, email)
    set_template(TEMPLATES[:welcome])
    set_reference("Welcome")

    set_personalisation(name:)

    mail(to: email)
  end

  def notification_updated(notification_pretty_id, name, email, update_text, subject_text)
    set_template(TEMPLATES[:notification_updated])
    set_reference("Notification updated")

    set_personalisation(
      name:,
      investigation_url: investigation_url(pretty_id: notification_pretty_id),
      update_text:,
      subject_text:
    )

    mail(to: email)
  end

  def notification_created(notification_pretty_id, name, email, notification_title, notification_type)
    set_template(TEMPLATES[:notification_created])
    set_reference("Notification created")

    set_personalisation(
      name:,
      case_title: notification_title,
      case_type: notification_type,
      capitalized_case_type: notification_type.capitalize,
      case_id: notification_pretty_id,
      investigation_url: investigation_url(pretty_id: notification_pretty_id)
    )

    mail(to: email)
  end

  def account_locked(user, tokens)
    set_template(TEMPLATES[:account_locked])

    personalization = {
      name: user.name,
      edit_user_password_url_token: edit_user_password_url(reset_password_token: tokens[:reset_password_token]),
      unlock_user_url_token: user_unlock_url(unlock_token: tokens[:unlock_token])
    }
    set_personalisation(personalization)
    mail(to: user.email)
  end

  def account_locked_inactive(user, token)
    set_template(TEMPLATES[:account_locked_inactive])

    personalization = {
      name: user.name,
      unlock_user_url_token: user_unlock_url(unlock_token: token)
    }
    set_personalisation(personalization)
    mail(to: user.email)
  end

  def team_added_to_notification_email(notification:, team:, added_by_user:, message:, to_email:)
    set_template(TEMPLATES[:team_added_to_notification])

    user_name = added_by_user.decorate.display_name(viewer: team)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name:,
                             scope: "mail.team_added_to_notification"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      updater_name: user_name,
      optional_message:,
      investigation_url: investigation_url(notification)
    )

    mail(to: to_email)
  end

  def team_removed_from_notification_email(message:, notification:, team_deleted:, user_who_deleted:, to_email:)
    set_template(TEMPLATES[:team_removed_from_notification])

    user_name = user_who_deleted.decorate.display_name(viewer: team_deleted)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name:,
                             scope: "mail.team_removed_from_notification"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      case_type: "notification",
      case_title: notification.decorate.title,
      case_id: notification.pretty_id,
      updater_name: user_name,
      optional_message:,
    )

    mail(to: to_email)
  end

  def risk_validation_updated(email:, updater:, investigation:, action:, name:)
    set_template(TEMPLATES[:risk_validation_updated])
    set_personalisation(
      case_type: "notification",
      case_title: investigation.decorate.title,
      case_id: investigation.pretty_id,
      updater_name: updater.name,
      updater_team_name: updater.team.name,
      action:,
      name:,
      investigation_url: investigation_url(pretty_id: investigation.pretty_id)
    )

    mail(to: email)
  end

  def notification_permission_changed_for_team(message:, notification:, team:, user:, to_email:, old_permission:, new_permission:)
    set_template(TEMPLATES[:notification_permission_changed_for_team])

    user_name = user.decorate.display_name(viewer: team)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name:,
                             scope: "mail.notification_permission_changed_for_team"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      case_type: "notification",
      case_title: notification.decorate.title,
      case_id: notification.pretty_id,
      updater_name: user_name,
      optional_message:,
      old_permission: I18n.t(".permission.#{old_permission}", scope: "mail.notification_permission_changed_for_team"),
      new_permission: I18n.t(".permission.#{new_permission}", scope: "mail.notification_permission_changed_for_team")
    )

    mail(to: to_email)
  end

  def notification_risk_level_updated(email:, name:, notification:, update_verb:, level:)
    set_template(TEMPLATES[:notification_risk_level_updated])
    verb_with_level = I18n.t(update_verb,
                             level: level.downcase,
                             scope: "mail.notification_risk_level_updated.verb_with_level")

    set_personalisation(
      verb_with_level:,
      name:,
      case_type: "notification",
      case_title: notification.decorate.title,
      case_id: notification.pretty_id,
      investigation_url: investigation_url(pretty_id: notification.pretty_id)
    )

    mail(to: email)
  end

  def product_export(email:, name:, product_export:)
    set_template(TEMPLATES[:product_export])
    set_reference("Product Export")

    set_personalisation(
      name:,
      download_export_url: product_export_url(product_export)
    )

    mail(to: email)
  end

  def notification_export(email:, name:, notification_export:)
    set_template(TEMPLATES[:notification_export])
    set_reference("Notification Export")

    set_personalisation(
      name:,
      download_export_url: notification_export_url(notification_export)
    )

    mail(to: email)
  end

  def business_export(email:, name:, business_export:)
    set_template(TEMPLATES[:business_export])
    set_reference("Business Export")

    set_personalisation(
      name:,
      download_export_url: business_export_url(business_export)
    )

    mail(to: email)
  end

  def unsafe_file(user:)
    set_template(TEMPLATES[:unsafe_file])
    set_reference("Unsafe file")

    set_personalisation(
      name: user.name,
    )

    mail(to: user.email)
  end

  def unsafe_attachment(user:, record_type:, id:)
    set_template(TEMPLATES[:unsafe_attachment])
    set_reference("Unsafe attachment")

    set_personalisation(
      name: user.name,
      record_type:,
      id:
    )

    mail(to: user.email)
  end

  def send_email_reminder(user:, remaining_days:, days:, title:, pretty_id:, last_reminder:, last_line:)
    set_template(TEMPLATES[:draft_notification_reminder])
    set_reference("Draft Notification submission reminder")

    set_personalisation(
      name: user.name,
      remaining_days:,
      days:,
      title:,
      investigation_url: notification_create_index_url(notification_pretty_id: pretty_id),
      last_reminder:,
      last_line:,
      notification_id: pretty_id
    )

    mail(to: user.email)
  end
end
