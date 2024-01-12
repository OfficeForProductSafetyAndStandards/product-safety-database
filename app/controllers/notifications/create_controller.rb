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
    before_action :set_notification_product, only: %i[show_batch_numbers show_customs_codes show_ucr_numbers show_number_of_affected_units update_batch_numbers update_customs_codes update_ucr_numbers update_number_of_affected_units delete_ucr_number]

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
      ahoy.track "Created notification from product", { notification_id: notification.id, product_id: product.id }
      redirect_to notification_create_index_path(notification)
    end

    def add_product
      # Add a newly-created product to an existing notification, save progress, then redirect to it
      product = Product.find(params[:product_id])
      AddProductToCase.call!(investigation: @notification, product:, user: current_user, skip_email: true)
      @notification.tasks_status["search_for_or_add_a_product"] = "completed"
      @notification.save!(context: :search_for_or_add_a_product)
      ahoy.track "Added product to existing notification", { notification_id: @notification.id, product_id: product.id }
      redirect_to notification_create_index_path(@notification)
    end

    def show
      case step
      when :search_for_or_add_a_product
        return redirect_to "#{wizard_path(:search_for_or_add_a_product)}?search" if params[:add_another_product] == "true"
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
          reported_reason: notification_reported_reason_summary(@notification)
        )
      when :add_product_safety_and_compliance_details
        @change_notification_product_safety_compliance_details_form = ChangeNotificationProductSafetyComplianceDetailsForm.new(
          unsafe: %w[unsafe unsafe_and_non_compliant].include?(@notification.reported_reason),
          noncompliant: %w[non_compliant unsafe_and_non_compliant].include?(@notification.reported_reason),
          primary_hazard: @notification.hazard_type,
          primary_hazard_description: @notification.hazard_description,
          noncompliance_description: @notification.non_compliant_reason,
          add_reference_number: @notification.complainant_reference.present? ? true : nil,
          reference_number: @notification.complainant_reference
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
          ChangeNotificationName.call!(
            notification: @notification,
            user_title: add_notification_details_params[:user_title],
            user: current_user,
            silent: true
          )
          ChangeCaseSummary.call!(
            investigation: @notification,
            summary: add_notification_details_params[:description],
            user: current_user,
            silent: true
          )
          ChangeSafetyAndComplianceData.call!(
            investigation: @notification,
            reported_reason: add_notification_details_params[:reported_reason],
            user: current_user,
            silent: true
          )
        else
          return render_wizard
        end
      when :add_product_safety_and_compliance_details
        @change_notification_product_safety_compliance_details_form = ChangeNotificationProductSafetyComplianceDetailsForm.new(add_product_safety_and_compliance_details_params.merge(safe_and_compliant: @notification.reported_reason&.safe_and_compliant?, current_user:))

        if @change_notification_product_safety_compliance_details_form.valid?
          unless @notification.reported_reason&.safe_and_compliant?
            ChangeSafetyAndComplianceData.call!(
              investigation: @notification,
              reported_reason: notification_reported_reason_detailed(unsafe: add_product_safety_and_compliance_details_params[:unsafe], noncompliant: add_product_safety_and_compliance_details_params[:noncompliant]),
              hazard_type: add_product_safety_and_compliance_details_params[:primary_hazard],
              hazard_description: add_product_safety_and_compliance_details_params[:primary_hazard_description],
              non_compliant_reason: add_product_safety_and_compliance_details_params[:noncompliance_description],
              user: current_user,
              silent: true
            )
          end
          ChangeNotificationReferenceNumber.call!(
            notification: @notification,
            reference_number: add_product_safety_and_compliance_details_params[:add_reference_number] ? add_product_safety_and_compliance_details_params[:reference_number] : nil,
            user: current_user
          )
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

    def show_batch_numbers
      render :add_product_identification_details_batch_numbers
    end

    def show_customs_codes
      render :add_product_identification_details_customs_codes
    end

    def show_ucr_numbers
      render :add_product_identification_details_ucr_numbers
    end

    def show_number_of_affected_units
      @number_of_affected_units_form = NumberOfAffectedUnitsForm.from(@investigation_product)
      render :add_product_identification_details_number_of_affected_units
    end

    def update_batch_numbers
      ChangeBatchNumber.call!(investigation_product: @investigation_product, batch_number: params[:batch_number], user: current_user, silent: true)
      redirect_to wizard_path(:add_product_identification_details)
    end

    def update_customs_codes
      ChangeCustomsCode.call!(investigation_product: @investigation_product, customs_code: params[:customs_code], user: current_user, silent: true)
      redirect_to wizard_path(:add_product_identification_details)
    end

    def update_ucr_numbers
      ChangeUcrNumbers.call!(investigation_product: @investigation_product, ucr_numbers: ucr_numbers_params, user: current_user, silent: true)
      redirect_to wizard_path(:add_product_identification_details)
    end

    def update_number_of_affected_units
      @number_of_affected_units_form = NumberOfAffectedUnitsForm.new(number_of_affected_units_params)

      if @number_of_affected_units_form.valid?
        ChangeNumberOfAffectedUnits.call!(
          investigation_product: @investigation_product,
          number_of_affected_units: @number_of_affected_units_form.number_of_affected_units,
          affected_units_status: @number_of_affected_units_form.affected_units_status,
          user: current_user,
          silent: true
        )
        redirect_to wizard_path(:add_product_identification_details)
      else
        render :add_product_identification_details_number_of_affected_units
      end
    end

    def delete_ucr_number
      ucr_number = @investigation_product.ucr_numbers.find(params[:ucr_number_id])
      ucr_number.destroy!
      redirect_to ucr_numbers_notification_create_index_path
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

    def set_notification_product
      @investigation_product = @notification.investigation_products.find(params[:investigation_product_id])
    end

    def finish_wizard_path
      notification_create_index_path(@notification)
    end

    def notification_reported_reason_summary(notification)
      if notification.reported_reason.present?
        if notification.reported_reason == "safe_and_compliant"
          "safe_and_compliant"
        else
          "unsafe_or_non_compliant"
        end
      elsif notification.tasks_status["add_notification_details"] == "completed"
        "unsafe_or_non_compliant"
      end
    end

    def notification_reported_reason_detailed(unsafe:, noncompliant:)
      unsafe = ActiveModel::Type::Boolean.new.cast(unsafe)
      noncompliant = ActiveModel::Type::Boolean.new.cast(noncompliant)

      if unsafe && noncompliant
        "unsafe_and_non_compliant"
      elsif unsafe
        "unsafe"
      else
        "non_compliant"
      end
    end

    def add_notification_details_params
      params.require(:change_notification_details_form).permit(:user_title, :description, :reported_reason, :draft)
    end

    def add_product_safety_and_compliance_details_params
      params.require(:change_notification_product_safety_compliance_details_form).permit(:unsafe, :noncompliant, :primary_hazard, :primary_hazard_description, :noncompliance_description, :add_reference_number, :reference_number, :draft)
    end

    def number_of_affected_units_params
      params.require(:number_of_affected_units_form).permit(:affected_units_status, :exact_units, :approx_units)
    end

    def ucr_numbers_params
      params.require(:investigation_product).permit(ucr_numbers_attributes: %i[id number _destroy])
    end
  end
end
