module ReportPortal
  class DashboardController < ApplicationController
    skip_before_action :set_default_back_link

    def index; end
  end
end
