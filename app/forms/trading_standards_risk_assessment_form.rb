class TradingStandardsRiskAssessmentForm < RiskAssessmentForm
  attribute :businesses, :business_list
  attribute :further_risk_assessments

  def product=(product)
    self.product_ids = [product.id]
    @product = product
  end

  def products
    [{ text: product.name, value: product.name }]
  end

  def businesses_select_items
    EMPTY_PROMPT_OPTION.deep_dup + businesses
                            .sort_by(&:trading_name)
                            .map { |business| { text: business.trading_name, value: business.trading_name } }
  end

private

  attr_reader :product
end
