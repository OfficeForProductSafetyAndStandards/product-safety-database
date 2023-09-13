module Prism
  class TasksController < ApplicationController
    before_action :prism_risk_assessment
    before_action :set_prism_risk_assessment_tasks_status, only: %i[index]
    before_action :ensure_product_id, only: %i[index]
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

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.includes(:harm_scenarios).find_by!(id: params[:risk_assessment_id], created_by_user_id: current_user.id)
    end

    def set_prism_risk_assessment_tasks_status
      return unless @prism_risk_assessment.tasks_status.empty?

      # Exclude harm scenario steps since they are tracked per harm scenario
      all_steps = if @prism_risk_assessment.serious_risk?
                    SERIOUS_RISK_DEFINE_STEPS + SERIOUS_RISK_EVALUATE_STEPS
                  else
                    NORMAL_RISK_DEFINE_STEPS + NORMAL_RISK_IDENTIFY_STEPS + NORMAL_RISK_EVALUATE_STEPS
                  end

      @prism_risk_assessment.tasks_status = all_steps.each_with_object({}) do |step, tasks|
        tasks[step.to_s] = "not_started"
      end

      @prism_risk_assessment.save!
    end

    def ensure_product_id
      @prism_risk_assessment.update!(product_id: params[:product_id]) if params[:product_id].present? && @prism_risk_assessment.product_id.blank? && Product.find_by(id: params[:product_id])

      redirect_to main_app.all_products_path if @prism_risk_assessment.product_id.blank?
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
