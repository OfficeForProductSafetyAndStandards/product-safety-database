class PrismProduct < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to create new
  # PRISM products. Creation and editing is handled
  # by the PRISM engine using the `Prism::Product` model.
  def readonly?
    true
  end
end
