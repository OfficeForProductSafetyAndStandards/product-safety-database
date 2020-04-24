class AuditActivity::Investigation::TeamAdded < AuditActivity::Investigation::Base
  def subtitle
    "Team added by #{source&.show}, #{pretty_date_stamp}"
  end
end
