module SupportPortal
  class NotificationAdministrationController < ApplicationController
    before_action :find_notification, only: %i[show]

    # GET /
    def index; end

    def show; end

    # GET /search
    def search; end

    # GET /search-results
    def search_results
      @search_query = params[:q].presence

      users = if @search_query
                ::Investigation.where("investigations.pretty_id ILIKE ?", "%#{@search_query}%")
              else
                ::Investigation.all
              end

      @records_count = users.size
      @pagy, @records = pagy(users)
    end

    private

    def find_notification
      @notification_object = Investigation.find_by(pretty_id: params[:id])
      @notification = @notification_object.decorate
    end
  end
end
