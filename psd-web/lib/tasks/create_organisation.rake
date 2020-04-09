namespace :organisation do
  desc "Creates an organisation, team, and team admin user, and sends an invitation email to the user"
  task create: :environment do
    result = CreateOrganisation.call(org_name: ENV.fetch("ORG_NAME"), admin_email: ENV.fetch("ADMIN_EMAIL"))
    puts "Organisation and team '#{result.org.name}' created. Invitation email sent to #{result.user.email}." if result.success?
  end
end
