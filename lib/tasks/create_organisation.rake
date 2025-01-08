namespace :organisation do
  desc "Creates an organisation, team, and team admin user, and sends an invitation email to the user"
  task create: :environment do
    result = CreateOrganisationWithTeamAndAdminUser.call(org_name: ENV.fetch("ORG_NAME"), admin_email: ENV.fetch("ADMIN_EMAIL"), country: ENV.fetch("COUNTRY"))
    puts "Organisation and team '#{result.org.name}' created. Invitation email sent to #{result.user.email}." if result.success?
  end
end
