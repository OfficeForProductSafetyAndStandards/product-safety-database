class NotifyMailer < GovukNotifyRails::Mailer
  include NotifyHelper

  TEMPLATES =
    {
      account_locked: "0a78e692-977e-4ca7-94e9-9de64ebd8a5d",
      alert: "47fb7df9-2370-4307-9f86-69455597cdc1",
      case_risk_level_updated: "66c2f2dd-f3a1-4ef1-a9cc-a99a1b7dff22",
      expired_invitation: "e056e368-5abb-48f4-b98d-ad0933620cc2",
      investigation_created: "6da8e1d5-eb4d-4f9a-9c3c-948ef57d6136",
      investigation_updated: "10a5c3a6-9cc7-4edb-9536-37605e2c15ba",
      invitation: "7b80a680-f8b3-4032-982d-2a3a662b611a",
      reset_password_instruction: "cea1bb37-1d1c-4965-8999-6008d707b981",
      team_added_to_case: "f16c2c44-a473-4550-a48a-ac50ef208d5c",
      team_deleted_from_case: "c3ab05a0-cbad-48d3-a271-fe20fda3a0e1",
      case_permission_changed_for_team: "772f8eb6-2aa2-4ed3-92f2-78af24548303",
      welcome: "035876e3-5b97-4b4c-9bd5-c504b5158a85",
      risk_validation_updated: "a22d37b1-5dc0-4147-ac6d-826232ca8b7a",
      product_export: "1c88c503-638e-4f91-b55f-726900b83f92"
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

    set_personalisation(invitation_url: invitation_url, inviting_team_member_name: invited_by)
    mail(to: user.email)
  end

  def expired_invitation_email(user)
    set_template(TEMPLATES[:expired_invitation])
    mail(to: user.email)
  end

  def welcome(name, email)
    set_template(TEMPLATES[:welcome])
    set_reference("Welcome")

    set_personalisation(name: name)

    mail(to: email)
  end

  def investigation_updated(investigation_pretty_id, name, email, update_text, subject_text)
    set_template(TEMPLATES[:investigation_updated])
    set_reference("Case updated")

    set_personalisation(
      name: name,
      investigation_url: investigation_url(pretty_id: investigation_pretty_id),
      update_text: update_text,
      subject_text: subject_text
    )

    mail(to: email)
  end

  def alert(email, subject_text:, body_text:)
    set_template(TEMPLATES[:alert])
    set_reference("Alert")

    set_personalisation(
      subject_text: subject_text,
      email_text: body_text
    )

    mail(to: email)
  end

  def investigation_created(investigation_pretty_id, name, email, investigation_title, investigation_type)
    set_template(TEMPLATES[:investigation_created])
    set_reference("Case created")

    set_personalisation(
      name: name,
      case_title: investigation_title,
      case_type: investigation_type,
      case_id: investigation_pretty_id,
      investigation_url: investigation_url(pretty_id: investigation_pretty_id)
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

  def team_added_to_case_email(investigation:, team:, added_by_user:, message:, to_email:)
    set_template(TEMPLATES[:team_added_to_case])

    user_name = added_by_user.decorate.display_name(viewer: team)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name: user_name,
                             scope: "mail.team_added_to_case"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      updater_name: user_name,
      optional_message: optional_message,
      investigation_url: investigation_url(investigation)
    )

    mail(to: to_email)
  end

  def team_deleted_from_case_email(message:, investigation:, team_deleted:, user_who_deleted:, to_email:)
    set_template(TEMPLATES[:team_deleted_from_case])

    user_name = user_who_deleted.decorate.display_name(viewer: team_deleted)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name: user_name,
                             scope: "mail.team_removed_from_case"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      case_type: investigation.case_type.to_s.downcase,
      case_title: investigation.decorate.title,
      case_id: investigation.pretty_id,
      updater_name: user_name,
      optional_message: optional_message,
    )

    mail(to: to_email)
  end

  def risk_validation_updated(email:, updater:, investigation:, action:, name:)
    set_template(TEMPLATES[:risk_validation_updated])
    set_personalisation(
      case_type: investigation.case_type.to_s.downcase,
      case_title: investigation.decorate.title,
      case_id: investigation.pretty_id,
      updater_name: updater.name,
      updater_team_name: updater.team.name,
      action: action,
      name: name,
      investigation_url: investigation_url(pretty_id: investigation.pretty_id)
    )

    mail(to: email)
  end

  def case_permission_changed_for_team(message:, investigation:, team:, user:, to_email:, old_permission:, new_permission:)
    set_template(TEMPLATES[:case_permission_changed_for_team])

    user_name = user.decorate.display_name(viewer: team)

    optional_message = if message.present?
                         [
                           I18n.t(
                             :message_from,
                             user_name: user_name,
                             scope: "mail.case_permission_changed_for_team"
                           ),
                           inset_text_for_notify(message)
                         ].join("\n\n")
                       else
                         ""
                       end

    set_personalisation(
      case_type: investigation.case_type.to_s.downcase,
      case_title: investigation.decorate.title,
      case_id: investigation.pretty_id,
      updater_name: user_name,
      optional_message: optional_message,
      old_permission: I18n.t(".permission.#{old_permission}", scope: "mail.case_permission_changed_for_team"),
      new_permission: I18n.t(".permission.#{new_permission}", scope: "mail.case_permission_changed_for_team")
    )

    mail(to: to_email)
  end

  def case_risk_level_updated(email:, name:, investigation:, update_verb:, level:)
    set_template(TEMPLATES[:case_risk_level_updated])
    verb_with_level = I18n.t(update_verb,
                             level: level.downcase,
                             scope: "mail.case_risk_level_updated.verb_with_level")

    set_personalisation(
      verb_with_level: verb_with_level,
      name: name,
      case_type: investigation.case_type.to_s.downcase,
      case_title: investigation.decorate.title,
      case_id: investigation.pretty_id,
      investigation_url: investigation_url(pretty_id: investigation.pretty_id)
    )

    mail(to: email)
  end

  def product_export(email:, name:, product_export:)
    set_template(TEMPLATES[:product_export])
    set_reference("Product Export")

    set_personalisation(
      name: name,
      download_export_url: product_export_url(product_export)
    )

    mail(to: email)
  end
end
