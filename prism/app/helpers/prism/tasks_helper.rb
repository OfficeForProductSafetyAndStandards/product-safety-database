module Prism
  module TasksHelper
    def normal_risk_sections
      {
        "define" => Prism::TasksController::NORMAL_RISK_DEFINE_STEPS.map(&:to_s),
        "identify" => Prism::TasksController::NORMAL_RISK_IDENTIFY_STEPS.map(&:to_s),
        "create" => Prism::TasksController::NORMAL_RISK_CREATE_STEPS.map(&:to_s),
        "evaluate" => Prism::TasksController::NORMAL_RISK_EVALUATE_STEPS.map(&:to_s),
      }
    end

    def serious_risk_sections
      {
        "define" => Prism::TasksController::SERIOUS_RISK_DEFINE_STEPS.map(&:to_s),
        "evaluate" => Prism::TasksController::SERIOUS_RISK_EVALUATE_STEPS.map(&:to_s),
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
      when "completed"
        govuk_tag(text: "Completed", colour: "blue")
      end
    end
  end
end
