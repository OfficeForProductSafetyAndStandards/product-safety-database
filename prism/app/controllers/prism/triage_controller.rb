module Prism
  class TriageController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index]

    before_action :prism_risk_assessment, except: %i[index serious_risk serious_risk_choose perform_risk_triage]
    before_action :disallow_triage_reentry, except: %i[index serious_risk serious_risk_choose perform_risk_triage]

    def index; end

    def serious_risk
      @prism_risk_assessment = Prism::RiskAssessment.new
      @form = Prism::Form::SeriousRisk.new(product_id: params[:product_id])
    end

    def serious_risk_choose
      @prism_risk_assessment = Prism::RiskAssessment.new(serious_risk_params
        .merge(created_by_user_id: current_user.id)
        .except(:investigation_id, :product_id, :product_ids))

      @form = Prism::Form::SeriousRisk.new(
        product_id: serious_risk_params[:product_id] || params[:product_id],
        risk_type: serious_risk_params[:risk_type]
      )

      if @form.product_id.presence
        current_product_id = @form.product_id || params[:product_id] || serious_risk_params[:product_id]

        if @prism_risk_assessment.save(context: :serious_risk)
          if serious_risk_params[:investigation_id].present? && serious_risk_params[:product_ids].present?
            associated_investigation = @prism_risk_assessment.associated_investigations.create!(
              investigation_id: serious_risk_params[:investigation_id]
            )
            serious_risk_params[:product_ids].each do |product_id|
              associated_investigation.associated_investigation_products.create!(product_id:)
            end
          elsif current_product_id.presence
            @prism_risk_assessment.associated_products.create!(product_id: current_product_id)
          end

          if @prism_risk_assessment.serious_risk?
            redirect_to serious_risk_rebuttable_path(@prism_risk_assessment, product_id: current_product_id)
          else
            redirect_to full_risk_assessment_required_path(@prism_risk_assessment)
          end
        else
          render :serious_risk
        end
      else
        render :serious_risk
      end
    end

    def serious_risk_rebuttable; end

    def serious_risk_rebuttable_choose
      params[:product_id] = params[:risk_assessment][:product_id] if params[:product_id].blank? && params[:risk_assessment][:product_id].present?

      @prism_risk_assessment.assign_attributes(serious_risk_rebuttable_params)

      if @prism_risk_assessment.save(context: :serious_risk_rebuttable)
        if @prism_risk_assessment.less_than_serious_risk?
          redirect_to full_risk_assessment_required_path(@prism_risk_assessment)
        elsif @prism_risk_assessment.associated_investigations.present? || @prism_risk_assessment.associated_products.present?
          @prism_risk_assessment.update!(triage_complete: true)
          redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
        else
          @prism_risk_assessment.update!(triage_complete: true)
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
        redirect_to perform_risk_triage_path(@prism_risk_assessment, product_id: params[:product_id])
      elsif @prism_risk_assessment.associated_investigations.present? || @prism_risk_assessment.associated_products.present?
        @prism_risk_assessment.update!(triage_complete: true)
        redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
      else
        @prism_risk_assessment.update!(triage_complete: true)
        session[:prism_risk_assessment_id] = @prism_risk_assessment.id
        redirect_to main_app.your_prism_risk_assessments_path
      end
    end

    def perform_risk_triage; end

    def continue_with_risk_assessment
      @prism_risk_assessment.update!(triage_complete: true)

      if @prism_risk_assessment.associated_investigations.present? || @prism_risk_assessment.associated_products.present?
        redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
      else
        session[:prism_risk_assessment_id] = @prism_risk_assessment.id
        redirect_to main_app.all_products_path
      end
    end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.find_by!(id: params[:id], created_by_user_id: current_user.id)
    end

    def disallow_triage_reentry
      redirect_to risk_assessment_tasks_path(@prism_risk_assessment) if @prism_risk_assessment.triage_complete
    end

    def serious_risk_params
      params.require(:risk_assessment).permit(:risk_type, :product_id, :investigation_id, product_ids: [])
    end

    def serious_risk_rebuttable_params
      params.require(:risk_assessment).permit(:less_than_serious_risk, :serious_risk_rebuttable_factors)
    end

    def full_risk_assessment_required_params
      params.require(:form_full_risk_assessment_required).permit(:full_risk_assessment_required)
    end
  end
end
