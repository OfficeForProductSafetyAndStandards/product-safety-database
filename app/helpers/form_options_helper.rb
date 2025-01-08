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
end
