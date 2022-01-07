class LogDbMetricsJob < ApplicationJob
  def perform
    stats = {
      total_number_of_cases: Investigation.count,
      total_number_of_users: User.not_deleted.count,
      total_number_of_products: Product.count,
      total_number_of_businesses: Business.count,
      total_number_of_locked_users: User.where.not(locked_at: nil).not_deleted.count,
      total_number_of_deleted_users: User.where.not(deleted_at: nil).count
    }

    Sidekiq.logger.info "PsdStatistics #{stats.to_a.map { |x| x.join('=') }.join(' ')}"
  end
end
