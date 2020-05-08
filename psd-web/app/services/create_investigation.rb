class CreateInvestigation
  include Interactor

  delegate :investigation_params, :current_user, to: :context

  def call
    investigation = Investigation.new(investigation_params)

    investigation.build_case_creator(
      team: current_user.teams.first,
      added_by_user: current_user,
      include_message: "Maybe this message should not be required when creating a case creator"
    )
    context.investigation = investigation
    return if investigation.save

    context.fail!
  end
end
