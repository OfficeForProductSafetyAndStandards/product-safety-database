module Prism
  class Tasks::OutcomeController < ApplicationController
    include Wicked::Wizard

    before_action :prism_risk_assessment
    before_action :disallow_editing_submitted_prism_risk_assessment
    before_action :harm_scenarios
    before_action :set_wizard_steps
    before_action :setup_wizard
    before_action :validate_step

    def show
      case step
      when :confirm_overall_product_risk
        @identical_severity_levels = @harm_scenarios.map(&:severity).uniq.length <= 1
      when :add_level_of_uncertainty_and_sensitivity_analysis
        @evaluation = @prism_risk_assessment.evaluation || @prism_risk_assessment.build_evaluation
      end

      render_wizard
    end

    def update
      case step
      when :confirm_overall_product_risk
        @identical_severity_levels = @harm_scenarios.map(&:severity).uniq.length <= 1
        @prism_risk_assessment.assign_attributes(confirm_overall_product_risk_params)
      when :add_level_of_uncertainty_and_sensitivity_analysis
        @evaluation = @prism_risk_assessment.evaluation || @prism_risk_assessment.build_evaluation
        @evaluation.assign_attributes(add_level_of_uncertainty_and_sensitivity_analysis_params)
      end

      @prism_risk_assessment.tasks_status[step.to_s] = "completed"
      @prism_risk_assessment.complete_outcome_section if step == wizard_steps.last

      if params[:draft] == "true" || params[:final] == "true"
        # "Save as draft" or final save button of the section clicked.
        # Manually save, then finish the wizard.
        if @prism_risk_assessment.save(context: step)
          redirect_to wizard_path(Wicked::FINISH_STEP)
        else
          render_wizard
        end
      else
        render_wizard(@prism_risk_assessment, { context: step })
      end
    end

  private

    def prism_risk_assessment
      @prism_risk_assessment ||= Prism::RiskAssessment.includes(:product_market_detail, :harm_scenarios, :evaluation).find_by!(id: params[:risk_assessment_id], created_by_user_id: current_user.id)
    end

    def disallow_editing_submitted_prism_risk_assessment
      redirect_to view_submitted_assessment_risk_assessment_tasks_path(@prism_risk_assessment) if @prism_risk_assessment.submitted?
    end

    def harm_scenarios
      @harm_scenarios ||= @prism_risk_assessment.harm_scenarios
    end

    def set_wizard_steps
      self.steps = @prism_risk_assessment.serious_risk? ? SERIOUS_RISK_OUTCOME_STEPS : NORMAL_RISK_OUTCOME_STEPS
    end

    def validate_step
      # Don't allow access to a step if the step before has not yet been completed.
      # Checks if the step is the first step or the autogenerated "finish" step.
      redirect_to risk_assessment_tasks_path(@prism_risk_assessment) unless (step == previous_step && @prism_risk_assessment.create_completed?) || step == :wizard_finish || @prism_risk_assessment.tasks_status[previous_step.to_s] == "completed"
    end

    def finish_wizard_path
      risk_assessment_tasks_path(@prism_risk_assessment)
    end

    def confirm_overall_product_risk_params
      params.require(:risk_assessment).permit(:overall_product_risk_methodology, :overall_product_risk_plus_label, :_dummy, :draft)
    end

    def add_level_of_uncertainty_and_sensitivity_analysis_params
      params.require(:evaluation).permit(:level_of_uncertainty, :sensitivity_analysis, :sensitivity_analysis_details, :final)
    end
  end
end
