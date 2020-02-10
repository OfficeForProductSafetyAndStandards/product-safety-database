module TelephoneNumberHelper

  def telephoneNumber(params = {})
    params["type"] = "tel"
    params["autocomplete"] = "tel"

    render partial: "components/govuk_input", locals: params
  end

end
