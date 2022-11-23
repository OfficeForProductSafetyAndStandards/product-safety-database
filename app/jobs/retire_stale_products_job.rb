class RetireStaleProductsJob < ApplicationJob
  def perform
    Product.retire_stale_products!
  end
end
