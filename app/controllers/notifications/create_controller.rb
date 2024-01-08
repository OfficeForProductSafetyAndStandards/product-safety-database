module Notifications
  class CreateController < ApplicationController
    include Wicked::Wizard
    include BreadcrumbHelper

    before_action :disallow_non_role_users
    before_action :set_notification, except: %i[index from_product]
    before_action :disallow_changing_submitted_notification, except: %i[index from_product]
    before_action :set_steps
    before_action :setup_wizard
    before_action :validate_step, except: %i[index from_product add_product]

    breadcrumb "cases.label", :your_cases_investigations

    TASK_LIST_SECTIONS = {
      "product" => %i[search_for_or_add_a_product],
      "notification_details" => %i[add_notification_details add_product_safety_and_compliance_details add_product_identification_details],
      "business_details" => %i[add_business_details],
      "evidence" => %i[add_test_reports add_supporting_images add_supporting_documents create_or_add_risk_assessment determine_notification_risk_level],
      "corrective_actions" => %i[record_a_corrective_action],
      "submit" => %i[check_notification_details_and_submit]
    }.freeze

    TASK_LIST_SECTIONS_OPTIONAL = %w[evidence].freeze

    def index
      if params[:notification_pretty_id].present?
        set_notification
        disallow_changing_submitted_notification
      else
        # Create a new draft notification then redirect to it
        notification = Investigation::Notification.new(state: "draft")
        CreateNotification.call!(notification:, user: current_user, from_task_list: true, silent: true)
        redirect_to notification_create_index_path(notification)
      end
    end

    def from_product
      # Create a new draft notification with attached product, save progress, then redirect to it
      notification = Investigation::Notification.new(state: "draft")
      product = Product.find(params[:product_id])
      CreateNotification.call!(notification:, product:, user: current_user, from_task_list: true, silent: true)
      notification.tasks_status["search_for_or_add_a_product"] = "completed"
      notification.save!(context: :search_for_or_add_a_product)
      redirect_to notification_create_index_path(notification)
    end

    def add_product
      # Add a newly-created product to an existing notification
      product = Product.find(params[:product_id])
      AddProductToCase.call!(investigation: @notification, product:, user: current_user, skip_email: true)
      @notification.tasks_status["search_for_or_add_a_product"] = "completed"
      @notification.save!(context: :search_for_or_add_a_product)
      redirect_to notification_create_index_path(@notification)
    end

    def show
      case step
      when :search_for_or_add_a_product
        return redirect_to wizard_path(:search_for_or_add_a_product) if params[:add_another_product] == "true"
        return redirect_to notification_create_index_path(@notification) if params[:add_another_product] == "false"

        @page_name = params[:page_name]
        @search_query = params[:q].presence
        sort_by = {
          "name_a_z" => { name: :asc },
          "name_z_a" => { name: :desc }
        }[params[:sort_by]] || { created_at: :desc }

        products = if @page_name == "your_products"
                     Product.includes(investigations: %i[owner_user owner_team])
                       .where(users: { id: current_user.id })
                       .order(sort_by)
                   elsif @page_name == "team_products"
                     team = current_user.team
                     Product.includes(investigations: %i[owner_user owner_team])
                       .where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
                       .order(sort_by)
                   elsif @search_query
                     @search_query.strip!
                     Product.where("products.name ILIKE ?", "%#{@search_query}%")
                       .or(Product.where("products.description ILIKE ?", "%#{@search_query}%"))
                       .or(Product.where("CONCAT('psd-', products.id) = LOWER(?)", @search_query))
                       .or(Product.where(id: @search_query))
                       .order(sort_by)
                   else
                     Product.all.order(sort_by)
                   end

        @records_count = products.size
        @pagy, @records = pagy(products)
        @existing_product_ids = InvestigationProduct.where(investigation: @notification).pluck(:product_id)
        @manage = request.query_string != "search" && @existing_product_ids.present?
      when :add_notification_details
        @change_notification_details_form = ChangeNotificationDetailsForm.new(
          user_title: @notification.user_title,
          description: @notification.description,
          reported_reason: notification_reported_reason(@notification)
        )
      end

      render_wizard
    end

    def update
      case step
      when :search_for_or_add_a_product
        product = Product.find(params[:product_id])
        AddProductToCase.call!(investigation: @notification, product:, user: current_user, skip_email: true)
      when :add_notification_details
        @change_notification_details_form = ChangeNotificationDetailsForm.new(add_notification_details_params.merge(current_user:, notification_id: @notification.id))

        if @change_notification_details_form.valid?
          ChangeNotificationName.call!(notification: @notification, user_title: add_notification_details_params[:user_title], user: current_user, silent: true)# unless @notification.user_title == add_notification_details_params[:user_title]
          ChangeCaseSummary.call!(investigation: @notification, summary: add_notification_details_params[:description], user: current_user, silent: true)
          ChangeReportedReason.call!(investigation: @notification, reported_reason: add_notification_details_params[:reported_reason], user: current_user, silent: true) if add_notification_details_params[:reported_reason] == "safe_and_compliant"
        else
          return render_wizard
        end
      end

      @notification.tasks_status[step.to_s] = "completed"

      if params[:draft] == "true" || params[:final] == "true"
        # "Save as draft" or final save button of the section clicked.
        # Manually save, then finish the wizard.
        if @notification.save(context: step)
          redirect_to notification_create_index_path(@notification)
        else
          render_wizard
        end
      else
        render_wizard(@notification, { context: step })
      end
    end

  private

    def disallow_non_role_users
      redirect_to notifications_path unless current_user.can_use_notification_task_list?
    end

    def set_notification
      @notification = Investigation::Notification.includes(:creator_user).where(pretty_id: params[:notification_pretty_id], creator_user: { id: current_user.id }).where.not(state: "submitted").first!
    end

    def disallow_changing_submitted_notification
      # TODO(ruben): redirect to view notification page once ready
      redirect_to notifications_path if @notification.submitted?
    end

    def set_steps
      self.steps = TASK_LIST_SECTIONS.values.flatten
    end

    def validate_step
      # Don't allow access to a step if the step before has not yet been completed.
      # Checks if the step is the first step or the autogenerated "finish" step.
      redirect_to notification_create_index_path(@notification) unless step == previous_step || step == :wizard_finish || @notification.tasks_status[previous_step.to_s] == "completed"
    end

    def finish_wizard_path
      notification_create_index_path(@notification)
    end

    def notification_reported_reason(notification)
      if notification.reported_reason.present?
        if notification.reported_reason == "safe_and_compliant"
          "safe_and_compliant"
        else
          "unsafe_or_non_compliant"
        end
      end
    end

    def add_notification_details_params
      params.require(:change_notification_details_form).permit(:user_title, :description, :reported_reason, :draft)
    end
  end
end
