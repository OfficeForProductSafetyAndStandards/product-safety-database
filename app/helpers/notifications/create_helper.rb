module Notifications
  module CreateHelper
    def sections_complete
      tasks_status = @notification.tasks_status
      Notifications::CreateController::TASK_LIST_SECTIONS.map { |_section, tasks|
        complete = tasks.map { |task|
          tasks_status[task.to_s] == "completed" ? 1 : 0
        }.exclude?(0)
        complete ? 1 : 0
      }.inject(&:+)
    end

    def task_status(task)
      previous_task = previous_task(task)

      if %w[in_progress completed].include?(@notification.tasks_status[task.to_s])
        @notification.tasks_status[task.to_s]
      elsif previous_task.nil? || @notification.tasks_status[previous_task.to_s] == "completed"
        "not_started"
      else
        "cannot_start_yet"
      end
    end

    def task_status_tag(status)
      case status
      when "cannot_start_yet"
        "Cannot start yet"
      when "not_started"
        govuk_tag(text: "Not yet started")
      when "in_progress"
        govuk_tag(text: "In progress", colour: "light-blue")
      when "completed"
        "Completed"
      end
    end

    def sort_by_options
      [
        OpenStruct.new(id: "newly_added", name: "Newly added"),
        OpenStruct.new(id: "name_a_z", name: "Name A-Z"),
        OpenStruct.new(id: "name_z_a", name: "Name Z-A")
      ]
    end

    def reported_reason_options
      [
        OpenStruct.new(id: "unsafe_or_non_compliant", name: "A product is unsafe or non-compliant", description: "Examples of non-compliance in products include missing or incomplete markings, errors in product labeling, or inadequate documentation."),
        OpenStruct.new(id: "safe_and_compliant", name: "A product is safe and compliant", description: "This helps other market surveillance authorities avoid testing the same product again.")
      ]
    end

    def hazards_options
      [OpenStruct.new(id: "", name: "")] +
        Rails.application.config.hazard_constants["hazard_type"].map do |hazard_type|
          OpenStruct.new(id: hazard_type.parameterize.underscore, name: hazard_type)
        end
    end

    def number_of_affected_units(affected_units_status, number_of_affected_units)
      case affected_units_status
      when "exact"
        number_of_affected_units
      when "approx"
        "Approximately #{number_of_affected_units}"
      when "unknown"
        "Unknown"
      when "not_relevant"
        "Not relevant"
      else
        "Not provided"
      end
    end

  private

    def previous_task(task)
      return if first_task?(task)

      all_tasks = wizard_steps
      optional_tasks = Notifications::CreateController::TASK_LIST_SECTIONS.slice(*Notifications::CreateController::TASK_LIST_SECTIONS_OPTIONAL).values.flatten
      mandatory_tasks = all_tasks - optional_tasks

      # Return the previous mandatory task or `nil` if this is the first mandatory task
      index = mandatory_tasks.index(task)
      unless index.nil?
        return if index.zero?

        return mandatory_tasks.at(index - 1)
      end

      # This is an optional task - find and return the last mandatory task or `nil` if we get to the first task without a match
      previous_index = all_tasks.index(task) - 1

      loop do
        previous_task = all_tasks.at(previous_index)
        return previous_task if mandatory_tasks.include?(previous_task)
        return if previous_index.zero?

        previous_index -= 1
      end
    end

    def first_task?(task)
      wizard_steps.index(task).zero?
    end
  end
end
