module ReportPortal
  class DashboardController < ApplicationController
    def index
      @current_month = Date.today.strftime('%B %Y')
    end
  end
end
