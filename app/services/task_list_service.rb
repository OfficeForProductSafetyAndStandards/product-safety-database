class TaskListService
  def self.previous_task(task:, all_tasks:, optional_tasks:)
    return if task.blank? || all_tasks.index(task).zero?

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
end
