module Investigations
  class RiskAssessmentsController < ApplicationController
    def new
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate

      authorize @investigation, :update?

      @risk_assessment_form = RiskAssessmentForm.new(current_user: current_user, investigation: @investigation)

      return render "no_products" if @risk_assessment_form.products.length.zero?
    end

    def create
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate

      authorize @investigation, :update?

      @risk_assessment_form = RiskAssessmentForm.new(current_user: current_user, investigation: @investigation)

      @risk_assessment_form.attributes = risk_assessment_params

      if @risk_assessment_form.valid?

        result = AddRiskAssessmentToCase.call!(
          @risk_assessment_form.attributes.merge({
            investigation: @investigation,
            user: current_user,
            assessed_by_team_id: @risk_assessment_form.assessed_by_team_id
          })
        )

        redirect_to investigation_risk_assessment_path(@investigation, result.risk_assessment)
      else
        render :new
      end
    end

    def show
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate

      @risk_assessment = @investigation.risk_assessments.find(params[:id]).decorate
    end

  private

    def risk_assessment_params
      params.require(:risk_assessment_form).permit(:details, :risk_level, :risk_assessment_file, :assessed_by, :assessed_by_team_id, :assessed_by_business_id, :assessed_by_other, :custom_risk_level, assessed_on: %i[day month year], product_ids: [])
    end
  end
end
