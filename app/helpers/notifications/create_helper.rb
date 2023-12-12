module Notifications
  module CreateHelper
    include Pagy::Frontend

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
      if %w[in_progress completed].include?(@notification.tasks_status[task.to_s])
        @notification.tasks_status[task.to_s]
      elsif first_task?(task) || @notification.tasks_status[previous_task(task).to_s] == "completed"
        "not_started"
      else
        "cannot_start_yet"
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

    def sort_by_options
      [
        OpenStruct.new(id: "newly_added", name: "Newly added"),
        OpenStruct.new(id: "name_a_z", name: "Name A-Z"),
        OpenStruct.new(id: "name_z_a", name: "Name Z-A")
      ]
    end

  private

    def previous_task(task)
      task_index = wizard_steps.index(task)

      return task if task_index.zero? # The task is the first task

      wizard_steps.at(task_index - 1)
    end

    def first_task?(task)
      wizard_steps.index(task).zero?
    end
  end
end