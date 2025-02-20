module Investigations
  class RiskAssessmentsController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates, except: %i[show]
    before_action :set_investigation_breadcrumbs

    def new
      @risk_assessment_form = RiskAssessmentForm.new(current_user:, investigation: @investigation)
      render "no_products" if @risk_assessment_form.investigation_products.empty?
    end

    def create
      @risk_assessment_form = RiskAssessmentForm.new(
        risk_assessment_params.merge(current_user:, investigation: @investigation_object)
      )
      @risk_assessment_form.assessed_on = @risk_assessment_form.send(:set_date)
      @risk_assessment_form.cache_file!
      @risk_assessment_form.load_risk_assessment_file

      if @risk_assessment_form.valid?

        result = AddRiskAssessmentToNotification.call!(
          @risk_assessment_form.attributes.merge({
            notification: @investigation_object,
            user: current_user,
            assessed_by_team_id: @risk_assessment_form.assessed_by_team_id
          })
        )
        # If the risk level has not been set for the investigation, set it to the same
        # as the risk assessment. This will force the redirect to the supporting information
        # page below and skip the "Do you want to match this case risk level to the risk assessment level?"
        # page.
        if @investigation.risk_level.nil?
          ChangeNotificationRiskLevel.call!(
            notification: @investigation_object,
            user: current_user,
            risk_level: result.risk_assessment.risk_level
          )
        end

        if result.risk_assessment.risk_level == @investigation.risk_level
          redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
        else
          redirect_to investigation_risk_assessment_update_case_risk_level_path(@investigation, result.risk_assessment)
        end
      else
        @investigation = @investigation_object.decorate
        render :new
      end
    end

    def show
      @risk_assessment = @investigation_object.risk_assessments.find(params[:id]).decorate
      @investigation = @investigation_object.decorate
    end

    def edit
      @risk_assessment = @investigation_object.risk_assessments.find(params[:id])

      @risk_assessment_form = RiskAssessmentForm.new(
        @risk_assessment.serializable_hash(
          only: %i[assessed_on risk_level assessed_by_team_id assessed_by_business_id assessed_by_other details]
        ).merge(
          current_user:,
          investigation: @investigation_object,
          assessed_by:,
          investigation_product_ids: @risk_assessment.investigation_product_ids,
          old_file: @risk_assessment.risk_assessment_file_blob
        )
      )

      @risk_assessment = @risk_assessment.decorate
      @investigation = @investigation_object.decorate
    end

    def update
      @risk_assessment = @investigation_object.risk_assessments.find(params[:id])

      @risk_assessment_form = RiskAssessmentForm.new(
        risk_assessment_params.merge(
          current_user:,
          investigation: @investigation_object,
          old_file: @risk_assessment.risk_assessment_file_blob
        )
      )

      @risk_assessment_form.assessed_on = @risk_assessment_form.send(:set_date)
      @risk_assessment_form.attributes = risk_assessment_params

      if @risk_assessment_form.valid?
        result = UpdateRiskAssessment.call!(
          @risk_assessment_form.serializable_hash.merge({
            risk_assessment: @risk_assessment,
            user: current_user
          })
        )
        # If the risk level has not been set for the investigation, set it to the same
        # as the risk assessment. This will force the redirect to the supporting information
        # page below and skip the "Do you want to match this case risk level to the risk assessment level?"
        # page.
        if @investigation.risk_level.nil?
          ChangeNotificationRiskLevel.call!(
            notification: @investigation_object,
            user: current_user,
            risk_level: result.risk_assessment.risk_level
          )
        end

        if result.risk_assessment.risk_level == @investigation.risk_level
          redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
        else
          redirect_to investigation_risk_assessment_update_case_risk_level_path(@investigation, result.risk_assessment)
        end

      else
        @investigation = @investigation.decorate
        render :edit
      end
    end

  private

    def risk_assessment_params
      investigation_product_ids_arr = params[:risk_assessment_form][:investigation_product_ids]
      investigation_product_ids_arr.shift if investigation_product_ids_arr[0] == ""
      params.require(:risk_assessment_form).permit(
        :details,
        :risk_level,
        :risk_assessment_file,
        :assessed_by,
        :assessed_by_team_id,
        :assessed_by_business_id,
        :assessed_by_other,
        :existing_risk_assessment_file_file_id,
        :assessed_on,
        "assessed_on(1i)",
        "assessed_on(2i)",
        "assessed_on(3i)"
      ).merge(investigation_product_ids: investigation_product_ids_arr)
    end

    def assessed_by
      if @risk_assessment.assessed_by_team == current_user.team
        "my_team"
      elsif @risk_assessment.assessed_by_team
        "another_team"
      elsif @risk_assessment.assessed_by_business
        "business"
      else
        "other"
      end
    end
  end
end
