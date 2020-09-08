class TradingStandardRiskAssessmentForm < RiskAssessmentForm
  def products
    EMPTY_PROMPT_OPTION + [{ text: product.name, value: product.name }]
  end

  def businesses
    EMPTY_PROMPT_OPTION + [{ text: business.trading_name, value: business.trading_name }]
  end

  def product
    investigation.products.first
  end

  def business
    investigation.businesses.first
  end
end
