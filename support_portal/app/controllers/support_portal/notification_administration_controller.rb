module SupportPortal
  class NotificationAdministrationController < ApplicationController
    before_action :find_notification, only: %i[show activity_details]

    # GET /
    def index; end

    def show

      @paper_trail_records = changes_from_paper_trail
      @activity_records = changes_from_activities
    end

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

    def activity_details
      @activity = @notification_object.activities.find(params[:activity_id])
    end

    private

    def changes_from_activities
      @notification_object.activities
    end

    def changes_from_paper_trail
      PaperTrail::Version
        .includes(:item)
        .joins("LEFT JOIN users ON users.id::text = versions.whodunnit")
        .where(item_type: %w[Investigation])
        .where(item_id: @notification_object.id)
        .select("versions.*, COALESCE(users.name, 'Unknown') AS whodunnit")
        .order(created_at: :desc)
    end

    def find_notification
      @notification_object = Investigation.find_by(pretty_id: params[:id])
      @notification = @notification_object.decorate
    end
  end
end
