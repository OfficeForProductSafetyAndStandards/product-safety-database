class PrismHarmScenario < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to create new
  # PRISM harm scenarios. Creation and editing is handled
  # by the PRISM engine using the `Prism::HarmScenario` model.
  def readonly?
    true
  end
end
