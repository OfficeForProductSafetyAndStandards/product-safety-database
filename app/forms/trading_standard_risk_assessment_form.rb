class TradingStandardRiskAssessmentForm < RiskAssessmentForm
  attribute :businesses, :business_list
  attribute :product

  def products
    EMPTY_PROMPT_OPTION.deep_dup + [{ text: product.name, value: product.name }]
  end

  def businesses_select_items
    EMPTY_PROMPT_OPTION.deep_dup + businesses
                            .sort_by(&:trading_name)
                            .map { |business| { text: business.trading_name, value: business.trading_name } }
  end
end
