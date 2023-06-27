module Prism
  class TriageController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index full_risk_assessment_required full_risk_assessment_required_choose perform_risk_triage]

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
      @form_model = Prism::Form::SeriousRisk.new
    end

    def serious_risk_choose
      @form_model = Prism::Form::SeriousRisk.new(serious_risk_params)

      return render :serious_risk unless @form_model.valid?

      if serious_risk_params[:poses_a_serious_risk] == "false"
        redirect_to tasks_path
      else
        redirect_to serious_risk_rebuttable_path
      end
    end

    def serious_risk_rebuttable
      @form_model = Prism::Form::SeriousRiskRebuttable.new
    end

    def serious_risk_rebuttable_choose
      @form_model = Prism::Form::SeriousRiskRebuttable.new(serious_risk_rebuttable_params)

      return render :serious_risk_rebuttable unless @form_model.valid?

      redirect_to tasks_serious_risk_path
    end

    def perform_risk_triage; end

  private

    def full_risk_assessment_required_params
      params.require(:form_full_risk_assessment_required).permit(:full_risk_assessment_required)
    end

    def serious_risk_params
      params.require(:form_serious_risk).permit(:poses_a_serious_risk)
    end

    def serious_risk_rebuttable_params
      params.require(:form_serious_risk_rebuttable).permit(:less_than_serious_risk, :description)
    end
  end
end
