class CreateOrganisationWithTeamAndAdminUser
  include Interactor

  def call
    context.fail!(error: "No organisation name supplied") unless context.org_name
    context.fail!(error: "No team admin email supplied") unless context.admin_email
    context.fail!(error: "No country supplied") unless context.country

    ActiveRecord::Base.transaction do
      context.org = Organisation.create!(name: context.org_name)
      context.team = context.org.teams.create!(name: context.org_name, country: context.country)

      context.user = context.team.users.create!(
        email: context.admin_email,
        organisation: context.org,
        skip_password_validation: true,
        team: context.team
      )

      context.user.roles.create!(name: "team_admin")

      SendUserInvitationJob.perform_later(context.user.id)
    end
  end
end
