class CreateInvestigation
  include Interactor

  delegate :investigation_params, :case_creator_params, :user, to: :context

  def call
    investigation = Investigation::Allegation.new(investigation_params)
    investigation.assignable = user
    investigation.build_case_owner(
      team: user.teams.first,
      added_by_user: user,
      include_message: "Maybe this message should not be required when creating a case creator"
    )
    context.investigation = investigation
    return if investigation.save

    context.fail!
  end
end
