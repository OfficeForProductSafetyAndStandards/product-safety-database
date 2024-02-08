module Notifications
  class CreateController < ApplicationController
    include Wicked::Wizard
    include BreadcrumbHelper

    before_action :disallow_non_role_users
    before_action :set_notification, except: %i[index from_product]
    before_action :disallow_changing_submitted_notification, except: %i[index from_product confirmation]
    before_action :set_steps
    before_action :setup_wizard
    before_action :validate_step, except: %i[index from_product add_product remove_product]
    before_action :set_notification_product, only: %i[show_batch_numbers show_customs_codes show_ucr_numbers show_number_of_affected_units update_batch_numbers update_customs_codes update_ucr_numbers update_number_of_affected_units delete_ucr_number show_with_notification_product update_with_notification_product remove_with_notification_product]

    breadcrumb "cases.label", :your_cases_investigations

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
      notification.tasks_status["search_for_or_add_a_product"] = "in_progress"
      notification.save!(context: :search_for_or_add_a_product)
      ahoy.track "Created notification from product", { notification_id: notification.id, product_id: product.id }
      redirect_to notification_create_path(notification, "search_for_or_add_a_product")
    end

    def add_product
      # Add a newly-created product to an existing notification, save progress, then redirect to it
      product = Product.find(params[:product_id])
      AddProductToNotification.call!(notification: @notification, product:, user: current_user, skip_email: true)
      @notification.tasks_status["search_for_or_add_a_product"] = "in_progress"
      @notification.save!(context: :search_for_or_add_a_product)
      ahoy.track "Added product to existing notification", { notification_id: @notification.id, product_id: product.id }
      redirect_to notification_create_path(@notification, "search_for_or_add_a_product")
    end

    def remove_product
      return redirect_to notification_create_index_path(@notification) if @notification.tasks_status["search_for_or_add_a_product"] == "completed"

      @investigation_product = @notification.investigation_products.find(params[:investigation_product_id])

      if request.delete?
        RemoveProductFromNotification.call!(notification: @notification, investigation_product: @investigation_product, user: current_user, silent: true)
        redirect_to notification_create_path(@notification, "search_for_or_add_a_product")
      end
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
          is_from_overseas_regulator: @notification.is_from_overseas_regulator,
          overseas_regulator_country: @notification.overseas_regulator_country,
          add_reference_number: @notification.complainant_reference.present? ? true : nil,
          reference_number: @notification.complainant_reference
        )
      when :add_business_details
        @add_business_details_form = AddBusinessDetailsForm.new
      when :add_location
        @add_location_form = AddLocationForm.new(business_id: params[:business_id])
      when :add_contact
        @add_contact_form = AddContactForm.new(business_id: params[:business_id])
      when :add_test_reports
        investigation_products = @notification.investigation_products
        @existing_test_results = @notification.test_results.includes(investigation_product: :product)
        @manage = request.query_string != "add" && @existing_test_results.present?
        return redirect_to with_product_notification_create_index_path(@notification, step: "add_test_reports", investigation_product_id: investigation_products.first.id) if investigation_products.count == 1 && !@manage

        @choose_investigation_product_form = ChooseInvestigationProductForm.new unless @manage
      when :add_supporting_images
        @image_upload = ImageUpload.new(upload_model: @notification)
      when :add_supporting_documents
        @document_form = DocumentForm.new
      when :add_risk_assessments
        investigation_products = @notification.investigation_products
        @existing_prism_associated_investigations = @notification.prism_associated_investigations.includes(:prism_risk_assessment)
        @existing_risk_assessments = @notification.risk_assessments.includes(investigation_products: :product)
        @manage = request.query_string != "add" && (@existing_prism_associated_investigations.present? || @existing_risk_assessments.present?)
        return redirect_to with_product_notification_create_index_path(@notification, step: "add_risk_assessments", investigation_product_id: investigation_products.first.id) if investigation_products.count == 1 && !@manage

        @choose_investigation_product_form = ChooseInvestigationProductForm.new unless @manage
      when :determine_notification_risk_level
        @risk_level_form = RiskLevelForm.new(risk_level: @notification.risk_level)
        highest_risk_level
      when :record_a_corrective_action
        if @notification.corrective_action_taken.blank?
          @corrective_action_taken_form = CorrectiveActionTakenForm.new
          return render :record_a_corrective_action_taken
        elsif params[:investigation_product_ids].present?
          @corrective_action_form = CorrectiveActionForm.new
          @investigation_products = @notification.investigation_products.where(id: params[:investigation_product_ids])

          return redirect_to wizard_path(:record_a_corrective_action) if @investigation_products.blank?

          return render :record_a_corrective_action_details
        elsif @notification.corrective_action_taken == "yes"
          investigation_products = @notification.investigation_products
          @existing_corrective_actions = @notification.corrective_actions.includes(investigation_product: :product)
          @manage = request.query_string != "add" && @existing_corrective_actions.present?
          return redirect_to wizard_path(:record_a_corrective_action, investigation_product_ids: [investigation_products.first.id]) if investigation_products.count == 1 && !@manage

          @choose_investigation_products_form = ChooseInvestigationProductsForm.new unless @manage
        else
          return render :record_a_corrective_action_later
        end
      end

      render_wizard
    end

    def update
      case step
      when :search_for_or_add_a_product
        return redirect_to "#{wizard_path(:search_for_or_add_a_product)}?search" if params[:add_another_product] == "true"
        return redirect_to wizard_path(:search_for_or_add_a_product) if params[:add_another_product].blank? && params[:final].present?

        if params[:add_another_product].blank?
          product = Product.find(params[:product_id])
          AddProductToNotification.call!(notification: @notification, product:, user: current_user, skip_email: true)
        end
      when :add_notification_details
        @change_notification_details_form = ChangeNotificationDetailsForm.new(add_notification_details_params.merge(current_user:, notification_id: @notification.id))

        if @change_notification_details_form.valid?
          ChangeNotificationName.call!(
            notification: @notification,
            user_title: add_notification_details_params[:user_title],
            user: current_user,
            silent: true
          )
          ChangeNotificationSummary.call!(
            notification: @notification,
            summary: add_notification_details_params[:description],
            user: current_user,
            silent: true
          )
          ChangeNotificationSafetyAndComplianceData.call!(
            notification: @notification,
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
            ChangeNotificationSafetyAndComplianceData.call!(
              notification: @notification,
              reported_reason: notification_reported_reason_detailed(unsafe: add_product_safety_and_compliance_details_params[:unsafe], noncompliant: add_product_safety_and_compliance_details_params[:noncompliant]),
              hazard_type: add_product_safety_and_compliance_details_params[:primary_hazard],
              hazard_description: add_product_safety_and_compliance_details_params[:primary_hazard_description],
              non_compliant_reason: add_product_safety_and_compliance_details_params[:noncompliance_description],
              user: current_user,
              silent: true
            )
          end
          ChangeNotificationOverseasRegulator.call!(
            notification: @notification,
            is_from_overseas_regulator: add_product_safety_and_compliance_details_params[:is_from_overseas_regulator],
            overseas_regulator_country: add_product_safety_and_compliance_details_params[:overseas_regulator_country],
            user: current_user,
            silent: true
          )
          ChangeNotificationReferenceNumber.call!(
            notification: @notification,
            reference_number: add_product_safety_and_compliance_details_params[:add_reference_number] ? add_product_safety_and_compliance_details_params[:reference_number] : nil,
            user: current_user,
            silent: true
          )
        else
          return render_wizard
        end
      when :add_business_details
        @add_business_details_form = AddBusinessDetailsForm.new(add_business_details_params)

        return render_wizard unless @add_business_details_form.valid?

        business = Business.new

        ChangeBusinessNames.call!(
          trading_name: @add_business_details_form.trading_name,
          legal_name: @add_business_details_form.legal_name,
          notification: @notification,
          user: current_user,
          business:
        )

        AddBusinessToNotification.call!(notification: @notification, business:, user: current_user)

        additional_params = { business_id: business.id }
      when :add_location
        @add_location_form = AddLocationForm.new(add_location_params)

        return render_wizard unless @add_location_form.valid?

        Location.create!(
          name: "Registered office address",
          address_line_1: @add_location_form.address_line_1,
          address_line_2: @add_location_form.address_line_2,
          city: @add_location_form.city,
          county: @add_location_form.county,
          country: @add_location_form.country,
          postal_code: @add_location_form.postal_code,
          business_id: @add_location_form.business_id
        )

        additional_params = { business_id: @add_location_form.business_id }
      when :add_test_reports
        return redirect_to "#{wizard_path(:add_test_reports)}?add" if params[:add_another_test_report] == "true"
        return redirect_to wizard_path(:add_test_reports) if params[:add_another_test_report].blank? && params[:final].present?

        if params[:add_another_test_report].blank?
          @choose_investigation_product_form = ChooseInvestigationProductForm.new(add_test_reports_params)

          if @choose_investigation_product_form.valid?
            return redirect_to with_product_notification_create_index_path(@notification, step: "add_test_reports", investigation_product_id: add_test_reports_params[:investigation_product_id])
          else
            return render_wizard
          end
        end
      when :add_supporting_images
        if params[:final].blank?
          flash[:success] = nil

          @image_upload = ImageUpload.new(upload_model: @notification)

          if image_upload_params[:file_upload].present?
            file = ActiveStorage::Blob.create_and_upload!(
              io: image_upload_params[:file_upload],
              filename: image_upload_params[:file_upload].original_filename,
              content_type: image_upload_params[:file_upload].content_type
            )
            file.analyze_later
            @image_upload = ImageUpload.new(file_upload: file, upload_model: @notification, created_by: current_user.id)

            if @image_upload.valid?
              @image_upload.save!
              @notification.image_upload_ids.push(@image_upload.id)
              @notification.save!
              flash[:success] = "Supporting image uploaded successfully"
            end
          end

          return render_wizard
        end
      when :add_supporting_documents
        if params[:final].blank?
          flash[:success] = nil

          @document_form = DocumentForm.new(document_upload_params)
          @document_form.cache_file!(current_user)

          if @document_form.valid?
            @notification.documents.attach(@document_form.document)
            flash[:success] = "Supporting document uploaded successfully"
          end

          return render_wizard
        end
      when :add_risk_assessments
        return redirect_to "#{wizard_path(:add_risk_assessments)}?add" if params[:add_another_risk_assessment] == "true"
        return redirect_to wizard_path(:add_risk_assessments) if params[:add_another_risk_assessment].blank? && params[:final].present?

        if params[:add_another_risk_assessment].blank?
          @choose_investigation_product_form = ChooseInvestigationProductForm.new(add_risk_assessments_params)

          if @choose_investigation_product_form.valid?
            return redirect_to with_product_notification_create_index_path(@notification, step: "add_risk_assessments", investigation_product_id: add_risk_assessments_params[:investigation_product_id])
          else
            return render_wizard
          end
        end
      when :determine_notification_risk_level
        @risk_level_form = RiskLevelForm.new(risk_level: determine_notification_risk_level_params[:risk_level])

        if @risk_level_form.valid?
          ChangeNotificationRiskLevel.call!(
            notification: @notification,
            risk_level: @risk_level_form.risk_level,
            user: current_user,
            silent: true
          )
        else
          highest_risk_level
          return render_wizard
        end
      when :record_a_corrective_action
        if @notification.corrective_action_taken.blank?
          @corrective_action_taken_form = CorrectiveActionTakenForm.new(corrective_action_taken_params)

          if @corrective_action_taken_form.valid?
            ChangeNotificationCorrectiveActionTaken.call!(
              notification: @notification,
              corrective_action_taken: @corrective_action_taken_form.corrective_action_taken,
              corrective_action_not_taken_reason: @corrective_action_taken_form.corrective_action_not_taken_reason,
              user: current_user,
              silent: true
            )

            if @corrective_action_taken_form.corrective_action_taken == "yes"
              return redirect_to wizard_path(:record_a_corrective_action)
            else
              return render :record_a_corrective_action_later
            end
          else
            return render :record_a_corrective_action_taken
          end
        elsif params[:investigation_product_ids].present?
          @corrective_action_form = CorrectiveActionForm.new(record_a_corrective_action_details_params.merge(duration: "unknown"))
          @investigation_products = @notification.investigation_products.where(id: params[:investigation_product_ids])

          if @corrective_action_form.valid?
            @investigation_products.each do |investigation_product|
              AddCorrectiveActionToNotification.call!(
                notification: @notification,
                investigation_product_id: investigation_product.id,
                action: @corrective_action_form.action,
                has_online_recall_information: @corrective_action_form.has_online_recall_information,
                online_recall_information: @corrective_action_form.online_recall_information,
                date_decided: @corrective_action_form.date_decided,
                legislation: @corrective_action_form.legislation,
                business_id: @corrective_action_form.business_id,
                measure_type: @corrective_action_form.measure_type,
                duration: @corrective_action_form.duration,
                geographic_scopes: @corrective_action_form.geographic_scopes,
                details: @corrective_action_form.details,
                document: @corrective_action_form.document,
                user: current_user,
                silent: true
              )
            end

            return redirect_to wizard_path(:record_a_corrective_action)
          else
            return render :record_a_corrective_action_details
          end
        elsif @notification.corrective_action_taken == "yes"
          return redirect_to "#{wizard_path(:record_a_corrective_action)}?add" if params[:add_another_corrective_action] == "true"
          return redirect_to wizard_path(:record_a_corrective_action) if params[:add_another_corrective_action].blank? && params[:final].present?

          if params[:add_another_corrective_action].blank?
            @choose_investigation_products_form = ChooseInvestigationProductsForm.new(record_a_corrective_action_params)

            if @choose_investigation_products_form.valid?
              return redirect_to wizard_path(:record_a_corrective_action, investigation_product_ids: @choose_investigation_products_form.investigation_product_ids)
            else
              return render_wizard
            end
          end
        end
      when :check_notification_details_and_submit
        return render_wizard unless @notification.ready_to_submit?
      end

      @notification.tasks_status[step.to_s] = "completed"

      if params[:draft] == "true" || params[:final] == "true"
        # "Save as draft" or final save button of the section clicked.
        # Manually save, then finish the wizard.
        if @notification.save(context: step)
          if step == :check_notification_details_and_submit
            @notification.submit!
            return redirect_to confirmation_notification_create_index_path(@notification)
          end

          redirect_to notification_create_index_path(@notification)
        else
          render_wizard
        end
      elsif additional_params
        @notification.save!(context: step)
        redirect_to wizard_path(@next_step, additional_params)
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
      ChangeNotificationBatchNumber.call!(notification_product: @investigation_product, batch_number: params[:batch_number], user: current_user, silent: true)
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

    def show_with_notification_product
      case params[:step].to_sym
      when :add_test_reports
        if params[:entity_id].present?
          @test_result = @investigation_product.test_results.find(params[:entity_id])

          if @test_result.tso_certificate_issue_date.present? || params[:opss_funded] == "false"
            @test_result_form = TestResultForm.from(@test_result)
            render :add_test_reports_details
          else
            @set_test_result_certificate_on_case_form = SetTestResultCertificateOnCaseForm.new
            render :add_test_reports_funding_details
          end
        else
          @set_test_result_funding_on_case_form = SetTestResultFundingOnCaseForm.new
          render :add_test_reports_opss_funding
        end
      when :add_risk_assessments
        if params[:entity_id] == "new"
          @risk_assessment_form = RiskAssessmentForm.new
          render :add_risk_assessments_legacy
        else
          # Find all submitted PRISM risk assessments that are associated with the chosen product
          # either directly or via a notification that is not the current notification.
          @related_prism_risk_assessments = PrismRiskAssessment
            .left_joins(:prism_associated_products, prism_associated_investigations: :prism_associated_investigation_products)
            .where(prism_associated_products: { product_id: @investigation_product.product.id })
            .or(PrismRiskAssessment.where(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @investigation_product.product.id } }))
            .where.not(id:
              PrismRiskAssessment
                .left_joins(prism_associated_investigations: :prism_associated_investigation_products)
                .where(prism_associated_investigations: { investigation_id: @notification.id }).where(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @investigation_product.product.id } })
                .submitted
                .distinct)
            .submitted
            .order(updated_at: :desc)
          render :add_risk_assessments_prism_or_legacy
        end
      end
    end

    def update_with_notification_product
      case params[:step].to_sym
      when :add_test_reports
        if params[:entity_id].present?
          @test_result = @investigation_product.test_results.find(params[:entity_id])

          if @test_result.tso_certificate_issue_date.present? || params[:opss_funded] == "false"
            @test_result_form = TestResultForm.new(test_details_params)
            @test_result_form.load_document_file

            if @test_result_form.valid?
              UpdateTestResult.call!(
                investigation: @notification,
                investigation_product_id: @investigation_product.id,
                test_result: @test_result,
                legislation: @test_result_form.legislation,
                standards_product_was_tested_against: @test_result_form.standards_product_was_tested_against,
                result: @test_result_form.result,
                failure_details: @test_result_form.failure_details,
                details: @test_result_form.details,
                document: @test_result_form.document,
                date: @test_result_form.date,
                changes: @test_result_form.changes,
                user: current_user,
                silent: true
              )
              redirect_to notification_create_path(@notification, id: "add_test_reports")
            else
              render :add_test_reports_details
            end
          else
            @set_test_result_certificate_on_case_form = SetTestResultCertificateOnCaseForm.new(opss_funding_details_params)

            if @set_test_result_certificate_on_case_form.valid?
              UpdateTestResult.call!(
                investigation: @notification,
                investigation_product_id: @investigation_product.id,
                test_result: @test_result,
                tso_certificate_reference_number: @set_test_result_certificate_on_case_form.tso_certificate_reference_number,
                tso_certificate_issue_date: @set_test_result_certificate_on_case_form.tso_certificate_issue_date,
                changes: {},
                user: current_user,
                silent: true
              )
              redirect_to with_product_and_entity_notification_create_index_path(@notification, step: "add_test_reports", investigation_product_id: @investigation_product.id, entity_id: @test_result.id, opss_funded: params[:opss_funded])
            else
              render :add_test_reports_funding_details
            end
          end
        else
          @set_test_result_funding_on_case_form = SetTestResultFundingOnCaseForm.new(opss_funding_params)

          if @set_test_result_funding_on_case_form.valid?
            test_result = @notification.test_results.create!(investigation_product: @investigation_product)
            redirect_to with_product_and_entity_notification_create_index_path(@notification, step: "add_test_reports", investigation_product_id: @investigation_product.id, entity_id: test_result.id, opss_funded: opss_funding_params[:opss_funded])
          else
            render :add_test_reports_opss_funding
          end
        end
      when :add_risk_assessments
        if params[:entity_id] == "new"
          # Create a legacy risk assessment
          @risk_assessment_form = RiskAssessmentForm.new(risk_assessments_params.merge(investigation_product_ids: [@investigation_product.id], current_user:))
          @risk_assessment_form.cache_file!
          @risk_assessment_form.load_risk_assessment_file

          if @risk_assessment_form.valid?
            AddRiskAssessmentToNotification.call!(
              notification: @notification,
              investigation_product_ids: [@investigation_product.id],
              assessed_on: @risk_assessment_form.assessed_on,
              risk_level: @risk_assessment_form.risk_level,
              assessed_by_team_id: @risk_assessment_form.assessed_by_team_id,
              assessed_by_other: @risk_assessment_form.assessed_by_other,
              details: @risk_assessment_form.details,
              risk_assessment_file: @risk_assessment_form.risk_assessment_file,
              user: current_user,
              silent: true
            )
            redirect_to notification_create_path(@notification, id: "add_risk_assessments")
          else
            render :add_risk_assessments_legacy
          end
        elsif params[:entity_id].present?
          # Attach an existing PRISM risk assessment
          prism_risk_assessment = PrismRiskAssessment.find(params[:entity_id])
          AddPrismRiskAssessmentToNotification.call!(notification: @notification, product: @investigation_product.product, prism_risk_assessment:)
          redirect_to notification_create_path(@notification, id: "add_risk_assessments")
        end
      end
    end

    def remove_with_notification_product
      case params[:step].to_sym
      when :add_test_reports
        @test_result = @investigation_product.test_results.find(params[:entity_id])
        if request.delete?
          @test_result.destroy!
          redirect_to notification_create_path(@notification, id: "add_test_reports")
        else
          render :remove_test_report
        end
      when :add_risk_assessments
        @risk_assessment = @investigation_product.risk_assessments.find(params[:entity_id])
        if request.delete?
          @risk_assessment.risk_assessed_products.destroy_all
          @risk_assessment.destroy!
          redirect_to notification_create_path(@notification, id: "add_risk_assessments")
        else
          render :remove_risk_assessment
        end
      end
    end

    def update_with_entity
      @corrective_action = @notification.corrective_actions.find(params[:entity_id])
      if request.patch? || request.put?
        @corrective_action_form = CorrectiveActionForm.new(record_a_corrective_action_details_params.merge(duration: "unknown"))

        if @corrective_action_form.valid?
          UpdateCorrectiveAction.call!(
            corrective_action: @corrective_action,
            investigation_product_id: @corrective_action.investigation_product_id,
            action: @corrective_action_form.action,
            has_online_recall_information: @corrective_action_form.has_online_recall_information,
            online_recall_information: @corrective_action_form.online_recall_information,
            date_decided: @corrective_action_form.date_decided,
            legislation: @corrective_action_form.legislation,
            business_id: @corrective_action_form.business_id,
            measure_type: @corrective_action_form.measure_type,
            duration: @corrective_action_form.duration,
            geographic_scopes: @corrective_action_form.geographic_scopes,
            details: @corrective_action_form.details,
            related_file: @corrective_action_form.related_file,
            document: @corrective_action_form.document,
            changes: @corrective_action_form.changes,
            user: current_user,
            silent: true
          )

          redirect_to notification_create_path(@notification, id: "record_a_corrective_action")
        else
          render :record_a_corrective_action_details
        end
      else
        @corrective_action_form = CorrectiveActionForm.from(@corrective_action)
        render :record_a_corrective_action_details
      end
    end

    def remove_with_entity
      case params[:step].to_sym
      when :add_risk_assessments
        @prism_associated_investigation = @notification.prism_associated_investigations.find(params[:entity_id])
        if request.delete?
          RemovePrismRiskAssessmentFromNotification.call!(notification: @notification, prism_risk_assessment: @prism_associated_investigation.prism_risk_assessment)
          redirect_to notification_create_path(@notification, id: "add_risk_assessments")
        else
          render :remove_prism_risk_assessment
        end
      when :record_a_corrective_action
        @corrective_action = @notification.corrective_actions.find(params[:entity_id])
        if request.delete?
          @corrective_action.destroy!
          redirect_to notification_create_path(@notification, id: "record_a_corrective_action")
        else
          render :remove_corrective_action
        end
      end
    end

    def remove_upload
      case params[:step].to_sym
      when :add_supporting_images
        @upload = @notification.image_uploads.find(params[:upload_id])
        @type = "supporting image"
      when :add_supporting_documents
        @upload = @notification.documents.find(params[:upload_id])
        @type = "supporting document"
      end

      if request.delete?
        @upload.destroy!
        redirect_to notification_create_path(@notification, id: params[:step])
      end
    end

    def confirmation
      redirect_to notification_create_index_path(@notification) unless @notification.submitted?

      @products = @notification.investigation_products.includes(:product).decorate.map(&:product).map(&:name_with_brand).to_sentence
    end

  private

    def disallow_non_role_users
      redirect_to notifications_path unless current_user.can_use_notification_task_list?
    end

    def set_notification
      @notification = Investigation::Notification.includes(:creator_user).where(pretty_id: params[:notification_pretty_id], creator_user: { id: current_user.id }).first!
    end

    def disallow_changing_submitted_notification
      redirect_to notification_path(@notification) unless @notification.draft?
    end

    def set_steps
      self.steps = Investigation::Notification::TASK_LIST_SECTIONS.values.flatten
    end

    def validate_step
      # Don't allow access to a step if the step before has not yet been completed (taking into account optional steps).
      # Checks if the step is the first step or the autogenerated "finish" step.
      optional_tasks = Investigation::Notification::TASK_LIST_SECTIONS.slice(*Investigation::Notification::TASK_LIST_SECTIONS_OPTIONAL).values.flatten
      previous_task = TaskListService.previous_task(task: step, all_tasks: wizard_steps, optional_tasks:)
      redirect_to notification_create_index_path(@notification) unless step == previous_step || step == :wizard_finish || @notification.tasks_status[previous_task.to_s] == "completed"
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
      params.require(:change_notification_product_safety_compliance_details_form).permit(:unsafe, :noncompliant, :primary_hazard, :primary_hazard_description, :noncompliance_description, :is_from_overseas_regulator, :overseas_regulator_country, :add_reference_number, :reference_number, :draft)
    end

    def number_of_affected_units_params
      params.require(:number_of_affected_units_form).permit(:affected_units_status, :exact_units, :approx_units)
    end

    def ucr_numbers_params
      params.require(:investigation_product).permit(ucr_numbers_attributes: %i[id number _destroy])
    end

    def add_test_reports_params
      params.require(:choose_investigation_product_form).permit(:investigation_product_id, :final)
    end

    def opss_funding_params
      params.require(:set_test_result_funding_on_case_form).permit(:opss_funded)
    end

    def opss_funding_details_params
      params.require(:set_test_result_certificate_on_case_form).permit(:tso_certificate_reference_number, tso_certificate_issue_date: %i[day month year])
    end

    def test_details_params
      params.require(:test_result_form).permit(:legislation, :standards_product_was_tested_against, :result, :failure_details, :details, :existing_document_file_id, :document, date: %i[day month year])
    end

    def image_upload_params
      params.require(:image_upload).permit(:file_upload, :final)
    end

    def document_upload_params
      params.require(:document_form).permit(:document, :title, :final)
    end

    def add_risk_assessments_params
      params.require(:choose_investigation_product_form).permit(:investigation_product_id, :final)
    end

    def risk_assessments_params
      params.require(:risk_assessment_form).permit(:risk_level, :assessed_by, :assessed_by_team_id, :assessed_by_other, :existing_risk_assessment_file_file_id, :risk_assessment_file, :details, assessed_on: %i[day month year])
    end

    def determine_notification_risk_level_params
      params.require(:risk_level_form).permit(:risk_level, :final)
    end

    def corrective_action_taken_params
      params.require(:corrective_action_taken_form).permit(:corrective_action_taken_yes_no, :corrective_action_taken_no_specific, :corrective_action_not_taken_reason)
    end

    def add_business_details_params
      params.require(:add_business_details_form).permit(:trading_name, :legal_name)
    end

    def add_location_params
      params.require(:add_location_form).permit(:address_line_1, :address_line_2, :city, :county, :postal_code, :country, :business_id)
    end

    def record_a_corrective_action_params
      allowed_params = params.require(:choose_investigation_products_form).permit(investigation_product_ids: [])
      # The form builder inserts an empty hidden field that needs to be removed before validation and saving
      allowed_params[:investigation_product_ids].reject!(&:blank?)
      allowed_params
    end

    def record_a_corrective_action_details_params
      allowed_params = params.require(:corrective_action_form).permit(:action, :has_online_recall_information, :online_recall_information, :business_id, :measure_type, :details, :related_file, :existing_document_file_id, :document, date_decided: %i[day month year], legislation: [], geographic_scopes: [])
      # The form builder inserts an empty hidden field that needs to be removed before validation and saving
      allowed_params[:legislation].reject!(&:blank?)
      allowed_params[:geographic_scopes].reject!(&:blank?)
      allowed_params
    end

    def highest_risk_level
      all_risk_levels = @notification.risk_assessments.map(&:risk_level) + @notification.prism_risk_assessments.map(&:overall_product_risk_level)
      @number_of_risk_assessments = all_risk_levels.size
      @highest_risk_level = case all_risk_levels
                            in [*, "serious", *]
                              "serious"
                            in [*, "high", *]
                              "high"
                            in [*, "medium", *]
                              "medium"
                            in [*, "low", *]
                              "low"
                            else
                              "unknown"
                            end
    end
  end
end
