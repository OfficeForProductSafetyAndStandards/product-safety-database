module Prism
  class TriageController < ApplicationController
    before_action :prism_risk_assessment, except: %i[index serious_risk serious_risk_choose perform_risk_triage]

    def index; end

    def serious_risk
      @prism_risk_assessment = Prism::RiskAssessment.new
    end

    def serious_risk_choose
      return redirect_to main_app.all_products_path if serious_risk_params[:product_id].present? && !Product.find_by(id: serious_risk_params[:product_id])

      @prism_risk_assessment = Prism::RiskAssessment.new(serious_risk_params.merge(created_by_user_id: current_user.id))

      if @prism_risk_assessment.save(context: :serious_risk)
        if @prism_risk_assessment.serious_risk?
          redirect_to serious_risk_rebuttable_path(@prism_risk_assessment)
        else
          redirect_to full_risk_assessment_required_path(@prism_risk_assessment)
        end
      else
        render :serious_risk
      end
    end

    def serious_risk_rebuttable; end

    def serious_risk_rebuttable_choose
      @prism_risk_assessment.assign_attributes(serious_risk_rebuttable_params)

      if @prism_risk_assessment.save(context: :serious_risk_rebuttable)
        if @prism_risk_assessment.less_than_serious_risk?
          redirect_to full_risk_assessment_required_path(@prism_risk_assessment)
        elsif @prism_risk_assessment.product_id.present?
          redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
        else
          session[:prism_risk_assessment_id] = @prism_risk_assessment.id
          redirect_to main_app.your_prism_risk_assessments_path
        end
      else
        render :serious_risk_rebuttable
      end
    end

    def full_risk_assessment_required
      @form_model = Prism::Form::FullRiskAssessmentRequired.new
    end

    def full_risk_assessment_required_choose
      @form_model = Prism::Form::FullRiskAssessmentRequired.new(full_risk_assessment_required_params)

      return render :full_risk_assessment_required unless @form_model.valid?

      if full_risk_assessment_required_params[:full_risk_assessment_required] == "false"
        redirect_to perform_risk_triage_path(@prism_risk_assessment)
      elsif @prism_risk_assessment.product_id.present?
        redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
      else
        session[:prism_risk_assessment_id] = @prism_risk_assessment.id
        redirect_to main_app.your_prism_risk_assessments_path
      end
    end

    def perform_risk_triage; end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.find_by!(id: params[:id], created_by_user_id: current_user.id)
    end

    def serious_risk_params
      params.require(:risk_assessment).permit(:risk_type, :product_id)
    end

    def serious_risk_rebuttable_params
      params.require(:risk_assessment).permit(:less_than_serious_risk, :serious_risk_rebuttable_factors)
    end

    def full_risk_assessment_required_params
      params.require(:form_full_risk_assessment_required).permit(:full_risk_assessment_required)
    end
  end
end
