module ReportPortal
  class SummaryController < ApplicationController
    def index
      @month = Date.current.all_month
      @last_month = 1.month.ago.beginning_of_month
      @current_month = Date.current.beginning_of_month

      @active_users_this_month = Rollup.series("Active users", interval: :month)[@current_month]&.to_i || 0
      @active_users_last_month = Rollup.series("Active users", interval: :month)[@last_month]&.to_i || 0
      @active_users_change_pc = get_change_pc(@active_users_this_month, @active_users_last_month)

      @notifications_this_month = Rollup.series("New notifications", interval: :month)[@current_month]&.to_i || 0
      @notifications_last_month = Rollup.series("New notifications", interval: :month)[@last_month]&.to_i || 0
      @notifications_change_pc = get_change_pc(@notifications_this_month, @notifications_last_month)

      monthly_price_of_psd = Rails.application.config.statistics["yearly_price_of_psd"] / 12

      @cost_per_notification_this_month = cost_per_period(monthly_price_of_psd, @notifications_this_month)
      @cost_per_notification_last_month = cost_per_period(monthly_price_of_psd, @notifications_last_month)
      @cost_per_notification_change_pc = get_change_pc(@cost_per_notification_this_month, @cost_per_notification_last_month)
    end

  private

    def cost_per_period(cost, count)
      return cost if count.zero?

      cost / count
    end

    def get_change_pc(current, last)
      percent = (current - last) / last.to_f * 100

      if percent == Float::INFINITY
        100
      elsif percent.nan?
        0
      else
        percent.round(0)
      end
    end
  end
end
