class TeamDecorator < Draper::Decorator
  delegate_all

  def owner_short_name(*)
    display_name
  end
end
