class LogDbMetricsJob < ApplicationJob
  def perform
    stats = {
      total_number_of_cases: Investigation.count,
      total_number_of_users: User.count,
      total_number_of_products: Product.count,
      total_number_of_businesses: Business.count
    }

    Sidekiq.logger.info "PsdStatistics #{stats.to_a.map { |x| x.join('=') }.join(' ')}"
end
