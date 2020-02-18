class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unassigned" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def error_summary
    return unless object.errors.any?

    error_list = object.errors.map { |attribute, errors| { text: errors, href: "##{attribute}" } }
    h.govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

  def email_input(f)
    options = {
      id: "email",
      name: "user[email]",
      type: "email",
      classes: "app-!-max-width-two-thirds",
      label: { text: "Email address" }
    }

    options[:errorMessage] = format_errors_for(f.object.errors.full_messages_for(:email)) if f.object.errors.any?

    h.render "components/govuk_input", options
  end

  def password_input(f)
    options = {
      id: "password",
      name: "user[password]",
      type: "password",
      classes: "app-!-max-width-two-thirds",
      label: { text: "Password" }
    }

    options[:errorMessage] = format_errors_for(f.object.errors.full_messages_for(:passwor)) if f.object.errors.any?

    h.render "components/govuk_input", options
  end

private

  def format_errors_for(errors)
    { text: errors.to_sentence(last_word_connector: " and ") }
  end
end
