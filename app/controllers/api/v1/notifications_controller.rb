class Api::V1::NotificationsController < Api::BaseController
  include Pagy::Backend
  include InvestigationsHelper

  before_action :set_search_params, only: %i[index]
  before_action :notification, only: %i[show]

  def index
    @pagy, @answer  = pagy_searchkick(new_opensearch_for_investigations(20, paginate: true))
    @notifications = InvestigationDecorator
                        .decorate_collection(@answer.includes([{ owner_user: :organisation, owner_team: :organisation }, :products]))
  end

  def show; end

  def create
    @notification = Investigation::Notification.new(notification_create_params)

    unless @notification.valid_api_dataset?
      return render json: { error: "Notification parameters are not valid" }, status: :not_acceptable
    end

    @notification.state = "draft"
    CreateNotification.call!(notification: @notification, user: current_user, from_task_list: true, silent: true)

    @notification.tasks_status["search_for_or_add_a_product"] = "in_progress"
    @notification.save!(context: :search_for_or_add_a_product)

    render action: :show, status: :created
  end

private

  def default_params
    params["case_statuses"] == %w[open closed] && params[:q].blank?
  end

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def notification_create_params
    params.require(:notification).permit(
      :user_title, :complainant_reference, :reported_reason,
      :hazard_type, :hazard_description, :non_compliant_reason
    )
  end

  def notification
    @notification ||= Investigation.find_by(pretty_id: params[:id])&.decorate

    return render json: { error: "Notification not found" }, status: :not_found if @notification.blank?
  end
end
