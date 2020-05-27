class AuditActivity::Investigation::TeamAdded < AuditActivity::Investigation::Base
  def subtitle
    "Team added by #{source&.show}, #{pretty_date_stamp}"
  end

private

  # This is handled by the AddTeamToAnInvestigation service, but this
  # override is required to prevent a duplicate investigation_updated email
  # being enqueued, which will fail
  def notify_relevant_users; end
end
