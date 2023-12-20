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
      "notification_details" => %i[add_product_notification_details add_product_safety_and_compliance_details add_product_identification_details],
      "business_details" => %i[select_business_type add_business_details],
      "evidence" => %i[add_test_reports add_supporting_images create_or_add_risk_assessment determine_overall_product_risk_level],
      "corrective_actions" => %i[record_a_corrective_action_for_the_product],
      "submit" => %i[check_notification_details_and_submit]
    }.freeze

    TASK_LIST_SECTIONS_OPTIONAL = %w[evidence corrective_actions].freeze

    def index
      if params[:notification_pretty_id].present?
        set_notification
        disallow_changing_submitted_notification
      else
        # Create a new draft notification then redirect to it
        investigation = Investigation::Notification.new(state: "draft")
        CreateNotification.call!(investigation:, user: current_user, from_task_list: true, silent: true)
        redirect_to notification_create_index_path(investigation)
      end
    end

    def from_product
      # Create a new draft notification with attached product, save progress, then redirect to it
      investigation = Investigation::Notification.new(state: "draft")
      product = Product.find(params[:product_id])
      CreateNotification.call!(investigation:, product:, user: current_user, from_task_list: true, silent: true)
      investigation.tasks_status["search_for_or_add_a_product"] = "completed"
      investigation.save!(context: :search_for_or_add_a_product)
      redirect_to notification_create_index_path(investigation)
    end

    def add_product
      # Add a newly-created product to an existing notification
      if @notification.investigation_products.blank?
        product = Product.find(params[:product_id])
        AddProductToCase.call!(investigation: @notification, product:, user: current_user, skip_email: true)
      end
      @notification.tasks_status["search_for_or_add_a_product"] = "completed"
      @notification.save!(context: :search_for_or_add_a_product)
      redirect_to notification_create_index_path(@notification)
    end

    def show
      case step
      when :search_for_or_add_a_product
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
      end

      render_wizard
    end

    def update
      case step
      when :search_for_or_add_a_product
        if @notification.investigation_products.blank?
          product = Product.find(params[:product_id])
          AddProductToCase.call!(investigation: @notification, product:, user: current_user, skip_email: true)
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
  end
end
