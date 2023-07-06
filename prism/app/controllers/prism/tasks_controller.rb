module Prism
  class TasksController < ApplicationController
    include Wicked::Wizard

    # Define wizard steps for normal and serious risk pathways split by section
    NORMAL_RISK_DEFINE_STEPS = %i[
      add_assessment_details search_or_add_a_new_product add_details_about_products_in_use_and_safety
    ].freeze
    NORMAL_RISK_IDENTIFY_STEPS = %i[
      add_a_number_of_hazards_and_subjects_of_harm
    ].freeze
    NORMAL_RISK_CREATE_STEPS = %i[
      choose_hazard_type add_a_harm_scenario_and_probability_of_harm determine_severity_of_harm add_uncertainty_and_sensitivity_analysis confirm_overall_product_risk
    ].freeze
    NORMAL_RISK_EVALUATE_STEPS = %i[
      complete_product_risk_evaluation review_and_submit_results_of_the_assessment
    ].freeze
    SERIOUS_RISK_DEFINE_STEPS = %i[
      add_evaluation_details search_or_add_a_new_product
    ].freeze
    SERIOUS_RISK_EVALUATE_STEPS = %i[
      complete_product_risk_evaluation review_and_submit_results_of_the_evaluation
    ].freeze

    before_action :prism_risk_assessment
    before_action :set_wizard_steps
    before_action :setup_wizard
    before_action :set_prism_risk_assessment_tasks_status

    def index
      if @prism_risk_assessment.serious_risk?
        render :index_serious_risk
      else
        render :index_normal_risk
      end
    end

    def show
      case step
      when :add_details_about_products_in_use_and_safety
        @product_market_detail = @prism_risk_assessment.product_market_detail || @prism_risk_assessment.build_product_market_detail
      end

      render_wizard
    end

    def update
      case step
      when :add_assessment_details
        @prism_risk_assessment.assign_attributes(add_assessment_details_params)
      when :add_details_about_products_in_use_and_safety
        @product_market_detail = @prism_risk_assessment.product_market_detail || @prism_risk_assessment.build_product_market_detail
        @product_market_detail.assign_attributes(add_details_about_products_in_use_and_safety_params)
      end

      @prism_risk_assessment.tasks_status[step.to_s] = "completed"

      if params[:draft] == "true" || params[:final] == "true"
        # "Save as draft" or final save button of the section clicked
        # Manually save, then finish the wizard
        if @prism_risk_assessment.save(context: step)
          redirect_to risk_assessment_task_path(@prism_risk_assessment, Wicked::FINISH_STEP)
        else
          render_wizard
        end
      else
        render_wizard(@prism_risk_assessment, context: step)
      end
    end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.find(params[:risk_assessment_id])
    end

    def set_wizard_steps
      self.steps = if @prism_risk_assessment.serious_risk?
                     SERIOUS_RISK_DEFINE_STEPS + SERIOUS_RISK_EVALUATE_STEPS
                   else
                     NORMAL_RISK_DEFINE_STEPS + NORMAL_RISK_IDENTIFY_STEPS + NORMAL_RISK_CREATE_STEPS + NORMAL_RISK_EVALUATE_STEPS
                   end
    end

    def set_prism_risk_assessment_tasks_status
      return unless @prism_risk_assessment.tasks_status.empty?

      @prism_risk_assessment.tasks_status = wizard_steps.each_with_object({}) do |step, tasks|
        tasks[step.to_s] = "not_started"
      end
      @prism_risk_assessment.save!
    end

    def add_assessment_details_params
      params.require(:risk_assessment).permit(:assessor_name, :assessment_organisation, :draft)
    end

    def add_details_about_products_in_use_and_safety_params
      allowed_params = params
        .require(:product_market_detail)
        .permit(:selling_organisation, :total_products_sold_estimatable, :total_products_sold, :other_safety_legislation_standard, :final, safety_legislation_standards: [])
      # The form builder inserts an empty hidden field that needs to be removed before validation and saving
      allowed_params[:safety_legislation_standards].reject!(&:blank?)
      allowed_params
    end

    def finish_wizard_path
      risk_assessment_tasks_path(@prism_risk_assessment)
    end
  end
end
