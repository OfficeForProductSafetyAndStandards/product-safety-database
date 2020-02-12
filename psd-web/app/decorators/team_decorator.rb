class TeamDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(*)
    display_name
  end
end
