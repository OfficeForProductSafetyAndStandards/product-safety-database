class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unassigned" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def error_summary
    return unless errors.any?

    error_list = errors.map { |attribute, error| { text: error, href: "##{attribute}" } }
    h.govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

  def email_input
    options = {
      id: "email",
      name: "user[email]",
      type: "email",
      classes: "app-!-max-width-two-thirds",
      label: { text: "Email address" },
      errorMessage: format_errors_for(errors.full_messages_for(:email))
    }

    h.render "components/govuk_input", options
  end

  def password_input
    options = {
      id: "password",
      name: "user[password]",
      type: "password",
      classes: "app-!-max-width-two-thirds",
      label: { text: "Password" },
      errorMessage: format_errors_for(errors.full_messages_for(:password))
    }

    h.render "components/govuk_input", options
  end

private

  def format_errors_for(errors_for_field)
    return base_errors if object.errors.include?(:base)
    return             if errors_for_field.empty?

    { text: errors_for_field.to_sentence(last_word_connector: " and ") }
  end

  def base_errors
    { text: errors.full_messages_for(:base).to_sentence(last_word_connector: " and ") }
  end
end
