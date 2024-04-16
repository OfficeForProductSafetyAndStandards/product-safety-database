module Prism
  class TasksController < ApplicationController
    before_action :prism_risk_assessment, except: %i[view_submitted_assessment download_assessment_pdf]
    before_action :disallow_changing_submitted_prism_risk_assessment, except: %i[confirmation view_submitted_assessment download_assessment_pdf]
    before_action :set_prism_risk_assessment_tasks_status, only: %i[index]
    before_action :ensure_associated_investigation_or_product, only: %i[index]
    before_action :ensure_one_harm_scenario, only: %i[index]
    before_action :clear_session_risk_assessment_id, only: %i[index]
    before_action :harm_scenario, only: %i[remove_harm_scenario delete_harm_scenario]

    def index
      if @prism_risk_assessment.serious_risk?
        render :index_serious_risk
      else
        render :index_normal_risk
      end
    end

    def create_harm_scenario
      build_harm_scenario if @prism_risk_assessment.harm_scenarios&.first&.confirmed?

      redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
    end

    def remove_harm_scenario; end

    def delete_harm_scenario
      @harm_scenario.destroy!
      @prism_risk_assessment.reload.complete_create_section!
      redirect_to risk_assessment_tasks_path(@prism_risk_assessment)
    end

    def confirmation
      redirect_to risk_assessment_tasks_path(@prism_risk_assessment) unless @prism_risk_assessment.submitted?
    end

    def view_submitted_assessment
      @prism_risk_assessment = Prism::RiskAssessment.includes(:harm_scenarios).find_by!(id: params[:risk_assessment_id])
      @harm_scenarios = @prism_risk_assessment.harm_scenarios

      redirect_to risk_assessment_tasks_path(@prism_risk_assessment) unless @prism_risk_assessment.submitted?
    end

    def download_assessment_pdf
      @prism_risk_assessment = Prism::RiskAssessment.includes(:product_market_detail, :product_hazard, :evaluation, harm_scenarios: :harm_scenario_steps).find_by!(id: params[:risk_assessment_id])

      return redirect_to "/404" unless @prism_risk_assessment.submitted? || (@prism_risk_assessment.created_by_user_id == current_user.id && @prism_risk_assessment.tasks_status["risk_evaluation_outcome"] == "completed")

      file = Tempfile.new(["prism-risk-assessment-#{@prism_risk_assessment.name.parameterize}-#{Time.zone.now.to_i}", ".pdf"], binmode: true)
      Prism::RiskAssessmentPdfService.generate_pdf(@prism_risk_assessment, file)
      file.rewind
      send_file file.path
    ensure
      file&.close
    end

    def remove; end

    def delete
      @prism_risk_assessment.destroy!

      if params[:back_to] == "dashboard"
        redirect_to main_app.your_prism_risk_assessments_path
      else
        redirect_to root_path
      end
    end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.includes(:harm_scenarios).find_by!(id: params[:risk_assessment_id], created_by_user_id: current_user.id)
    end

    def disallow_changing_submitted_prism_risk_assessment
      redirect_to view_submitted_assessment_risk_assessment_tasks_path(@prism_risk_assessment) if @prism_risk_assessment.submitted?
    end

    def set_prism_risk_assessment_tasks_status
      return unless @prism_risk_assessment.tasks_status.empty?

      # Exclude harm scenario steps since they are tracked per harm scenario
      all_steps = if @prism_risk_assessment.serious_risk?
                    SERIOUS_RISK_DEFINE_STEPS + SERIOUS_RISK_OUTCOME_STEPS + SERIOUS_RISK_EVALUATE_STEPS
                  else
                    NORMAL_RISK_DEFINE_STEPS + NORMAL_RISK_IDENTIFY_STEPS + NORMAL_RISK_OUTCOME_STEPS + NORMAL_RISK_EVALUATE_STEPS
                  end

      @prism_risk_assessment.tasks_status = all_steps.each_with_object({}) do |step, tasks|
        tasks[step.to_s] = "not_started"
      end

      @prism_risk_assessment.save!
    end

    def ensure_associated_investigation_or_product
      if params[:investigation_id].present? && params[:product_ids].present?
        associated_investigation = @prism_risk_assessment.associated_investigations.create!(investigation_id: params[:investigation_id])
        params[:product_ids].each { |product_id| associated_investigation.associated_investigation_products.create!(product_id:) }
      elsif params[:product_id].present?
        @prism_risk_assessment.associated_products.create!(product_id: params[:product_id])
      end

      redirect_to main_app.all_products_path if @prism_risk_assessment.associated_products.blank? && @prism_risk_assessment.associated_investigations.blank?
    end

    def ensure_one_harm_scenario
      build_harm_scenario if @prism_risk_assessment.harm_scenarios.blank?
    end

    def build_harm_scenario
      harm_scenario = @prism_risk_assessment.harm_scenarios.build

      harm_scenario.tasks_status = NORMAL_RISK_CREATE_STEPS.each_with_object({}) do |step, tasks|
        tasks[step.to_s] = "not_started"
      end

      harm_scenario.save!

      @prism_risk_assessment.uncomplete_create_section!
    end

    def harm_scenario
      @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by!(id: params[:harm_scenario_id])
    end

    def clear_session_risk_assessment_id
      session.delete(:prism_risk_assessment_id)
    end
  end
end
