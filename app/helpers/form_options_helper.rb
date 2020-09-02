module FormOptionsHelper
  LEGISLATION_CACHE_KEY = "relevant_legislation".freeze

  def relevant_legislation
    Rails.application.config.legislation_constants["legislation"]&.sort
  end

  def hazard_types
    Rails.application.config.hazard_constants["hazard_type"]
  end

  def product_categories
    Rails.application.config.product_constants["product_category"]
  end

  def corrective_action_geographic_scope
    Rails.application.config.corrective_action_constants["geographic_scope"]
  end

  def corrective_action_summary_radio_items(form)
    CorrectiveAction.actions.map do |value, text|
      item = { text: text, value: value }

      if value == "other"
        item[:conditional] = {
          html: form.govuk_input(:other_action, label: "Other action", label_classes: "govuk-visually-hidden")
        }
      end

      item
    end
  end
end
