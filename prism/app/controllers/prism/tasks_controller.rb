module Prism
  class TasksController < ApplicationController
    include Wicked::Wizard

    before_action :prism_risk_assessment
    before_action :set_wizard_steps
    before_action :setup_wizard
    before_action :set_prism_risk_assessment_tasks_status
    before_action :validate_step, only: %i[show update]

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
      when :add_a_number_of_hazards_and_subjects_of_harm
        @product_hazard = @prism_risk_assessment.product_hazard || @prism_risk_assessment.build_product_hazard
      when :choose_hazard_type
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by(id: params[:harm_scenario_id]) || @prism_risk_assessment.harm_scenarios.build
      when :add_a_harm_scenario_and_probability_of_harm
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by!(id: params[:harm_scenario_id])
        @harm_scenario.harm_scenario_steps.build if @harm_scenario.harm_scenario_steps.blank?
        @harm_scenario.harm_scenario_steps.each { |hss| hss.build_harm_scenario_step_evidence if hss.harm_scenario_step_evidence.blank? }
      when :determine_severity_of_harm, :determine_severity_of_harm_casualties, :add_uncertainty_and_sensitivity_analysis, :check_your_harm_scenario
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by!(id: params[:harm_scenario_id])
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
      when :add_a_number_of_hazards_and_subjects_of_harm
        @product_hazard = @prism_risk_assessment.product_hazard || @prism_risk_assessment.build_product_hazard
        @product_hazard.assign_attributes(add_a_number_of_hazards_and_subjects_of_harm_params)
      when :choose_hazard_type
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by(id: params[:harm_scenario_id]) || @prism_risk_assessment.harm_scenarios.build
        @harm_scenario.assign_attributes(choose_hazard_type_params)
        # We have to save the harm scenario manually since one-to-many association record updates
        # do not mark the parent record as dirty, therefore saving the parent does not save changes
        # to the child even when using `autosave: true` on the association.
        # See https://github.com/rails/rails/issues/17466 for more details.
        unless @harm_scenario.save(context: step)
          return render_wizard
        end
      when :add_a_harm_scenario_and_probability_of_harm
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by!(id: params[:harm_scenario_id])
        @harm_scenario.assign_attributes(add_a_harm_scenario_and_probability_of_harm_params)
        # We have to save the harm scenario manually since one-to-many association record updates
        # do not mark the parent record as dirty, therefore saving the parent does not save changes
        # to the child even when using `autosave: true` on the association.
        # See https://github.com/rails/rails/issues/17466 for more details.
        unless @harm_scenario.save(context: step)
          @harm_scenario.harm_scenario_steps.build if @harm_scenario.harm_scenario_steps.blank?
          @harm_scenario.harm_scenario_steps.each { |hss| hss.build_harm_scenario_step_evidence if hss.harm_scenario_step_evidence.blank? }
          return render_wizard
        end
      when :determine_severity_of_harm, :determine_severity_of_harm_casualties, :add_uncertainty_and_sensitivity_analysis, :check_your_harm_scenario
        @harm_scenario = @prism_risk_assessment.harm_scenarios.find_by!(id: params[:harm_scenario_id])
        @harm_scenario.assign_attributes(send("#{step}_params"))
        # We have to save the harm scenario manually since one-to-many association record updates
        # do not mark the parent record as dirty, therefore saving the parent does not save changes
        # to the child even when using `autosave: true` on the association.
        # See https://github.com/rails/rails/issues/17466 for more details.
        unless @harm_scenario.save(context: step)
          return render_wizard
        end
      end

      @prism_risk_assessment.tasks_status[step.to_s] = "completed"

      if params[:draft] == "true" || params[:final] == "true"
        # "Save as draft" or final save button of the section clicked.
        # Manually save, then finish the wizard.
        if @prism_risk_assessment.save(context: step)
          redirect_to risk_assessment_task_path(@prism_risk_assessment, Wicked::FINISH_STEP)
        else
          render_wizard
        end
      else
        step_params = HARM_SCENARIO_STEPS.include?(step.to_s) ? { harm_scenario_id: @harm_scenario.id } : {}

        if HARM_SCENARIO_STEPS.include?(step.to_s) && params[:harm_scenario][:back_to] == "summary"
          redirect_to wizard_path(:check_your_harm_scenario)
        else
          render_wizard(@prism_risk_assessment, { context: step }, step_params)
        end
      end
    rescue ActiveRecord::NestedAttributes::TooManyRecords
      # The user has specified more than the maximum number of harm scenario steps.
      # We get around the lack of meaningful feedback to the user
      # by setting a virtual attribute to a value which is then
      # validated by the model so we can show a nice error message.
      if @harm_scenario
        @harm_scenario.too_many_harm_scenario_steps = true
        @harm_scenario.save!(context: step)
      end

      render_wizard
    end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.find_by!(id: params[:risk_assessment_id], created_by_user_id: current_user.id)
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

    def validate_step
      # Don't allow access to a step if the step before has not yet been completed.
      # Checks if the step is the first step or the autogenerated "finish" step.
      redirect_to risk_assessment_tasks_path(@prism_risk_assessment) unless step == previous_step || step == :wizard_finish || @prism_risk_assessment.tasks_status[previous_step.to_s] == "completed"
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

    def add_a_number_of_hazards_and_subjects_of_harm_params
      allowed_params = params
        .require(:product_hazard)
        .permit(:number_of_hazards, :product_aimed_at, :product_aimed_at_description, :final, unintended_risks_for: [])
      # The form builder inserts an empty hidden field that needs to be removed before validation and saving
      allowed_params[:unintended_risks_for].reject!(&:blank?)
      allowed_params
    end

    def choose_hazard_type_params
      params.require(:harm_scenario).permit(:hazard_type, :other_hazard_type, :description, :back_to, :draft)
    end

    def add_a_harm_scenario_and_probability_of_harm_params
      params.require(:harm_scenario).permit(:back_to, :draft, harm_scenario_steps_attributes: [:id, :_destroy, :description, :probability_type, :probability_decimal, :probability_frequency, :probability_evidence, :probability_evidence_description_limited, :probability_evidence_description_strong, { harm_scenario_step_evidence_attributes: %i[id evidence_file] }])
    end

    def determine_severity_of_harm_params
      params.require(:harm_scenario).permit(:severity, :back_to, :draft)
    end

    def determine_severity_of_harm_casualties_params
      params.require(:harm_scenario).permit(:multiple_casualties, :back_to, :draft)
    end

    def add_uncertainty_and_sensitivity_analysis_params
      params.require(:harm_scenario).permit(:level_of_uncertainty, :sensitivity_analysis, :back_to, :draft)
    end

    def check_your_harm_scenario_params
      params.require(:harm_scenario).permit(:confirmed)
    end

    def finish_wizard_path
      risk_assessment_tasks_path(@prism_risk_assessment)
    end
  end
end
