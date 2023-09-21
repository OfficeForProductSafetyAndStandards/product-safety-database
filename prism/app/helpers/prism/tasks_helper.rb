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

    def normal_risk_sections_complete
      if @prism_risk_assessment.define_completed?
        1
      elsif @prism_risk_assessment.identify_completed?
        2
      elsif @prism_risk_assessment.create_completed?
        3
      elsif @prism_risk_assessment.submitted?
        4
      else
        0
      end
    end

    def serious_risk_sections_complete
      if @prism_risk_assessment.define_completed?
        1
      elsif @prism_risk_assessment.submitted?
        2
      else
        0
      end
    end

    def tasks_status
      original_tasks_status = @prism_risk_assessment.tasks_status
      @tasks_status ||= original_tasks_status.each_with_object({}).with_index do |((task, status), statuses), index|
        previous_section_completed = if (NORMAL_RISK_DEFINE_STEPS + SERIOUS_RISK_DEFINE_STEPS).include?(task.to_sym)
                                       true
                                     elsif NORMAL_RISK_IDENTIFY_STEPS.include?(task.to_sym)
                                       @prism_risk_assessment.define_completed?
                                     elsif NORMAL_RISK_CREATE_STEPS.include?(task.to_sym)
                                       @prism_risk_assessment.identify_completed?
                                     elsif NORMAL_RISK_EVALUATE_STEPS.include?(task.to_sym) && @prism_risk_assessment.normal_risk?
                                       @prism_risk_assessment.create_completed?
                                     elsif SERIOUS_RISK_EVALUATE_STEPS.include?(task.to_sym) && @prism_risk_assessment.serious_risk?
                                       @prism_risk_assessment.define_completed?
                                     end
        statuses[task] = if status == "not_started" && index.positive? && (original_tasks_status[original_tasks_status.keys[index - 1]] != "completed" || !previous_section_completed)
                           "cannot_start_yet"
                         else
                           status
                         end
      end
    end

    def harm_scenario_tasks_status(harm_scenario)
      original_tasks_status = harm_scenario.tasks_status
      original_tasks_status.each_with_object({}).with_index do |((task, status), statuses), index|
        statuses[task] = if status == "not_started" && ((index.positive? && original_tasks_status[original_tasks_status.keys[index - 1]] != "completed") || !@prism_risk_assessment.identify_completed?)
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

    def task_path(section, task, harm_scenario_id = nil)
      public_send("risk_assessment_#{section}_path", @prism_risk_assessment, task, harm_scenario_id)
    end
  end
end
