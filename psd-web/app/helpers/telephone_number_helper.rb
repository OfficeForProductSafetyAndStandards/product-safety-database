module TelephoneNumberHelper
  # rubocop:disable Naming/MethodName
  def telephoneNumber(params = {})
    params["type"] = "tel"
    params["autocomplete"] = "tel"

    render partial: "components/govuk_input", locals: params
  end
  # rubocop:enable Naming/MethodName
end
