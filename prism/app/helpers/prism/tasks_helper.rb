module Prism
  module TasksHelper
    def normal_risk_sections
      {
        "define" => NORMAL_RISK_DEFINE_STEPS.map(&:to_s),
        "identify" => NORMAL_RISK_IDENTIFY_STEPS.map(&:to_s),
        "create" => NORMAL_RISK_CREATE_STEPS.map(&:to_s),
        "evaluate" => NORMAL_RISK_EVALUATE_STEPS.map(&:to_s),
      }
    end

    def serious_risk_sections
      {
        "define" => SERIOUS_RISK_DEFINE_STEPS.map(&:to_s),
        "evaluate" => SERIOUS_RISK_EVALUATE_STEPS.map(&:to_s),
      }
    end

    def sections_complete
      sections = @prism_risk_assessment.serious_risk? ? serious_risk_sections : normal_risk_sections
      statuses = @prism_risk_assessment.tasks_status
      sections.map { |_section, tasks| statuses.slice(*tasks).values.all?("completed") }.count(true)
    end

    def tasks_status
      original_tasks_status = @prism_risk_assessment.tasks_status
      @tasks_status ||= original_tasks_status.each_with_object({}).with_index do |((task, status), statuses), index|
        statuses[task] = if status == "not_started" && index.positive? && original_tasks_status[original_tasks_status.keys[index - 1]] == "not_started"
                           "cannot_start_yet"
                         else
                           status
                         end
      end
    end

    def task_status_tag(status)
      case status
      when "cannot_start_yet"
        govuk_tag(text: "Cannot start yet", colour: "grey")
      when "not_started"
        govuk_tag(text: "Not started", colour: "grey")
      when "in_progress"
        govuk_tag(text: "In progress")
      when "completed"
        govuk_tag(text: "Completed")
      end
    end

    def number_of_hazards_radios
      [
        OpenStruct.new(id: "one", name: "1"),
        OpenStruct.new(id: "two", name: "2"),
        OpenStruct.new(id: "three", name: "3"),
        OpenStruct.new(id: "four", name: "4"),
        OpenStruct.new(id: "five", name: "5"),
        OpenStruct.new(id: "more_than_five", name: "More than 5"),
      ]
    end

    def hazard_type
      return unless @harm_scenario

      @harm_scenario.other? ? @harm_scenario.other_hazard_type : I18n.t("prism.harm_scenarios.hazard_types.#{@harm_scenario.hazard_type}")
    end

    def affected_users
      return unless @prism_risk_assessment.product_hazard

      I18n.t("prism.product_hazard.product_aimed_at.#{@prism_risk_assessment.product_hazard.product_aimed_at}")
    end

    def probability_evidence_radios
      [
        OpenStruct.new(id: "sole_judgement_or_estimation", name: "Sole judgement or estimation"),
        OpenStruct.new(id: "some_limited_empirical_evidence", name: "Some limited empirical evidence"),
        OpenStruct.new(id: "strong_empirical_evidence", name: "Strong empirical evidence"),
      ]
    end

    def overall_probability_of_harm
      return unless @harm_scenario

      # Get the probability of harm for all harm scenario steps
      probabilities = []
      steps = @harm_scenario.harm_scenario_steps.select(:probability_type, :probability_decimal, :probability_frequency)
      steps.each do |step|
        probabilities << if step.probability_type == "decimal"
                           step.probability_decimal.zero? ? 0 : (1 / step.probability_decimal)
                         else
                           step.probability_frequency
                         end
      end
      probability = probabilities.reject(&:zero?).reduce(:*)&.round

      probability.present? ? "1 in #{probability}" : "N/A"
    end
  end
end
