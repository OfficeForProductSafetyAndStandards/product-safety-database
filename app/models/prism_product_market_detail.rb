class PrismProductMarketDetail < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to create new
  # PRISM produce market details. Creation and editing is handled
  # by the PRISM engine using the `Prism::ProductMarketDetail` model.
  def readonly?
    true
  end
end
