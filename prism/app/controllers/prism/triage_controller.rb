module Prism
  class TriageController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index full_risk_assessment_required full_risk_assessment_required_choose perform_risk_triage]
    before_action :set_prism_risk_assessment, only: %i[serious_risk_rebuttable serious_risk_rebuttable_choose]

    def index; end

    def full_risk_assessment_required
      @form_model = Prism::Form::FullRiskAssessmentRequired.new
    end

    def full_risk_assessment_required_choose
      @form_model = Prism::Form::FullRiskAssessmentRequired.new(full_risk_assessment_required_params)

      return render :full_risk_assessment_required unless @form_model.valid?

      if full_risk_assessment_required_params[:full_risk_assessment_required] == "false"
        redirect_to perform_risk_triage_path
      else
        redirect_to serious_risk_path
      end
    end

    def serious_risk
      @prism_risk_assessment = Prism::RiskAssessment.new
    end

    def serious_risk_choose
      @prism_risk_assessment = Prism::RiskAssessment.new(serious_risk_params)
      @prism_risk_assessment.created_by_user_id = current_user.id

      if @prism_risk_assessment.save(context: :serious_risk)
        if @prism_risk_assessment.serious_risk?
          redirect_to serious_risk_rebuttable_path(@prism_risk_assessment)
        else
          redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
        end
      else
        render :serious_risk
      end
    end

    def serious_risk_rebuttable; end

    def serious_risk_rebuttable_choose
      @prism_risk_assessment.assign_attributes(serious_risk_rebuttable_params)

      if @prism_risk_assessment.save(context: :serious_risk_rebuttable)
        redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
      else
        render :serious_risk_rebuttable
      end
    end

    def perform_risk_triage; end

  private

    def set_prism_risk_assessment
      @prism_risk_assessment = Prism::RiskAssessment.find_by!(id: params[:id], created_by_user_id: current_user.id)
    end

    def full_risk_assessment_required_params
      params.require(:form_full_risk_assessment_required).permit(:full_risk_assessment_required)
    end

    def serious_risk_params
      params.require(:risk_assessment).permit(:risk_type)
    end

    def serious_risk_rebuttable_params
      params.require(:risk_assessment).permit(:less_than_serious_risk, :serious_risk_rebuttable_factors)
    end
  end
end
