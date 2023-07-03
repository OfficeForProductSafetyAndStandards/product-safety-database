module Prism
  class TasksController < ApplicationController
    before_action :set_prism_risk_assessment

    def index
      if @prism_risk_assessment.serious_risk?
        render :index_serious_risk, locals: { sections: serious_risk_sections, sections_complete: }
      else
        render :index_normal_risk, locals: { sections: normal_risk_sections, sections_complete: }
      end
    end

  private

    def set_prism_risk_assessment
      @prism_risk_assessment = Prism::RiskAssessment.find(params[:id])
    end

    def normal_risk_sections
      # TODO(ruben): add links and completion status
      [
        {
          title: "Define the product",
          tasks: [
            ["Add assessment details", ""],
            ["Search or add a new product", ""],
            ["Add details about products in use and safety", ""],
          ],
        },
        {
          title: "Identify product hazards and subjects of harm",
          tasks: [
            ["Add a number of hazards and subjects of harm", ""],
          ],
        },
        {
          title: "Create product harm scenarios",
          tasks: [
            ["Choose hazard type", ""],
            ["Add a harm scenario and probability of harm", ""],
            ["Determine severity of harm", ""],
            ["Add uncertainty and sensitivity analysis", ""],
            ["Confirm overall product risk", ""],
          ],
        },
        {
          title: "Evaluate product risk and submit assessment",
          tasks: [
            ["Complete product risk evaluation", ""],
            ["Review and submit results of the assessment", ""],
          ],
        },
      ]
    end

    def serious_risk_sections
      # TODO(ruben): add links and completion status
      [
        {
          title: "Define the product",
          tasks: [
            ["Add evaluation details", ""],
            ["Search or add a new product", ""],
          ],
        },
        {
          title: "Evaluate product risk and submit results",
          tasks: [
            ["Complete product risk evaluation", ""],
            ["Review and submit results of the evaluation", ""],
          ],
        },
      ]
    end

    def sections_complete
      # TODO(ruben): use wizard to count number of completed sections
      0
    end
  end
end
