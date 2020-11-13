module Investigations
  class RiskAssessmentsController < ApplicationController
    def new
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate

      authorize @investigation, :update?

      @risk_assessment_form = RiskAssessmentForm.new(current_user: current_user, investigation: @investigation)

      return render "no_products" if @risk_assessment_form.products.length.zero?
    end

    def create
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @risk_assessment_form = RiskAssessmentForm.new(
        risk_assessment_params.merge(current_user: current_user, investigation: @investigation)
      )

      @risk_assessment_form.cache_file!
      @risk_assessment_form.load_risk_assessment_file

      if @risk_assessment_form.valid?

        result = AddRiskAssessmentToCase.call!(
          @risk_assessment_form.attributes.merge({
            investigation: @investigation,
            user: current_user,
            assessed_by_team_id: @risk_assessment_form.assessed_by_team_id
          })
        )

        if (result.risk_assessment.risk_level == @investigation.risk_level) && (result.risk_assessment.custom_risk_level == @investigation.custom_risk_level)
          redirect_to investigation_risk_assessment_path(@investigation, result.risk_assessment)
        else
          redirect_to investigation_risk_assessment_update_case_risk_level_path(@investigation, result.risk_assessment)
        end
      else
        @investigation = @investigation.decorate
        render :new
      end
    end

    def show
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      @risk_assessment = @investigation.risk_assessments.find(params[:id]).decorate
      @investigation = @investigation.decorate
    end

    def edit
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @risk_assessment = @investigation.risk_assessments.find(params[:id])

      assessed_by = if @risk_assessment.assessed_by_team == current_user.team
                      "my_team"
                    elsif @risk_assessment.assessed_by_team
                      "another_team"
                    elsif @risk_assessment.assessed_by_business
                      "business"
                    else
                      "other"
                    end

      @risk_assessment_form = RiskAssessmentForm.new(
        @risk_assessment.attributes.symbolize_keys.slice(
          :assessed_on, :risk_level, :custom_risk_level, :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :details
        ).merge({
          current_user: current_user,
          investigation: @investigation,
          assessed_by: assessed_by,
          product_ids: @risk_assessment.product_ids,
          old_file: @risk_assessment.risk_assessment_file
        })
      )

      @risk_assessment = @risk_assessment.decorate
      @investigation = @investigation.decorate
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @risk_assessment = @investigation.risk_assessments.find(params[:id])

      @risk_assessment_form = RiskAssessmentForm.new(
        current_user: current_user,
        investigation: @investigation,
        old_file: @risk_assessment.risk_assessment_file
      )

      @risk_assessment_form.attributes = risk_assessment_params

      if @risk_assessment_form.valid?
        result = UpdateRiskAssessment.call!(
          @risk_assessment_form.serializable_hash.merge({
            risk_assessment: @risk_assessment,
            user: current_user
          })
        )

        if (result.risk_assessment.risk_level == @investigation.risk_level) && (result.risk_assessment.custom_risk_level == @investigation.custom_risk_level)

          redirect_to investigation_risk_assessment_path(@investigation, result.risk_assessment)
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
      params.require(:risk_assessment_form).permit(
        :details,
        :risk_level,
        :risk_assessment_file,
        :assessed_by,
        :assessed_by_team_id,
        :assessed_by_business_id,
        :assessed_by_other,
        :custom_risk_level,
        :existing_risk_assessment_file_file_id,
        assessed_on: %i[day month year],
        product_ids: []
      )
    end
  end
end
