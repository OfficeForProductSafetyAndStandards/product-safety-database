class AuditActivity::Investigation::TeamDeleted < AuditActivity::Investigation::Base
  def subtitle
    "Team deleted by #{source&.show}, #{pretty_date_stamp}"
  end
end
