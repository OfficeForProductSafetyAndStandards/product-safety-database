module PasswordHelper

  def password(params = {})
    params["type"] = "password"
    params["autocomplete"] = "tel"

    render partial: "components/govuk_input", locals: params
  end

end
